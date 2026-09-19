## Suite da VITRINE DE UPGRADES e do ALCANCE: o que a loja mostra, e em que estado.
##
## As tres afirmacoes que valem a reforma da loja, e as tres pegam defeito SILENCIOSO:
##
##   1. ⚠️ TODO TIPO DE EFEITO TEM FRASE. A tabela de frases e varrida a partir do ENUM, e nao
##      dela mesma: tipo de efeito novo sem frase apareceria como um cartao com a linha de
##      efeito em branco -- sem erro, sem aviso, e exatamente no lugar que a reforma existe
##      para preencher. Varrer a tabela por ela mesma aprovaria qualquer tabela, inclusive uma
##      com uma entrada so.
##
##   2. ⚠️ DISPONIVEL E FUTURO PARTICIONAM O CATALOGO. Nenhum upgrade pode estar nos dois, e
##      nenhum nao comprado pode estar em nenhum dos dois: upgrade que cai fora das duas listas
##      desaparece da tela, e desaparecer e pior que reprovar (CONVENCOES, ponto cego).
##
##   3. ⚠️ O ICONE DE FAMILIA EXISTE NO DISCO. A tabela de icones e uma SEGUNDA FONTE em
##      relacao a AssetsDoMenu.PECAS: um id escrito errado nao da erro -- textura_de devolve
##      null e o cabecalho simplesmente sai sem icone, para sempre, em silencio.
##
## E o Alcance e cobrado com CONTROLE: nao basta afirmar que os tres estados existem, porque
## uma funcao que devolvesse sempre ALCANCAVEL passaria nisso. O que se afirma e que o estado
## MUDA com o saldo, nas duas direcoes.
##
## O bloco MEXE no autoload Jogo, que e estado global vivo, e devolve tudo no fim: sem isso a
## suite deixaria saldo e producao ligados para quem rodar depois.
extends TesteBase


func _init() -> void:
	nome = "vitrine e alcance"


func executar() -> void:
	var dinheiro := Jogo.dinheiro
	var total := Jogo.total_caracteres
	var comprados := Jogo.upgrades_comprados.duplicate()

	_toda_frase_de_efeito_existe()
	_o_efeito_em_texto_nunca_e_vazio()
	_as_duas_listas_particionam_o_catalogo()
	_o_futuro_e_ordenado_e_limitado()
	_o_que_falta_para_desbloquear()
	_o_icone_de_familia_existe_no_disco()
	_os_tres_estados_de_alcance()
	_a_fracao_do_custo()

	Jogo.dinheiro = dinheiro
	Jogo.total_caracteres = total
	Jogo.upgrades_comprados = comprados


## ⚠️ VARRE O ENUM, e nao a tabela. Este e o portao do item 1 do cabecalho.
func _toda_frase_de_efeito_existe() -> void:
	var tipos: Array = DadosUpgrade.Efeito.values()
	ok(not tipos.is_empty(), "ha tipo de efeito para conferir")
	for tipo in tipos:
		ok(
			VitrineDeUpgrades.FRASES_DE_EFEITO.has(tipo),
			"o tipo de efeito %d tem frase na vitrine" % tipo,
		)
		var frase := str(VitrineDeUpgrades.FRASES_DE_EFEITO.get(tipo, ""))
		ok(not frase.strip_edges().is_empty(), "e a frase do tipo %d nao e vazia" % tipo)

	# o controle: sem ele, uma tabela com uma entrada para cada tipo mas todas iguais passaria
	var vistas := {}
	for tipo in tipos:
		vistas[str(VitrineDeUpgrades.FRASES_DE_EFEITO.get(tipo, ""))] = true
	igual(
		vistas.size(), tipos.size(),
		"cada tipo de efeito tem uma frase PROPRIA, e nao a mesma repetida",
	)


## ⚠️ E O NUMERO APARECE NA FRASE. Uma frase que esquecesse o %s mostraria "x na velocidade de
## cada macaco" -- gramaticalmente inteira, e sem dizer quanto.
func _o_efeito_em_texto_nunca_e_vazio() -> void:
	var conferidos := 0
	for dados in Economia.upgrades():
		conferidos += 1
		var texto := VitrineDeUpgrades.efeito_em_texto(dados)
		ok(
			not texto.strip_edges().is_empty(),
			"%s tem efeito em texto" % dados.id,
		)
		if dados.tipo_de_efeito == DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA:
			# interruptor nao tem numero: ele liga ou nao liga
			continue
		# ⚠️ .get E NAO [], e por um motivo medido: com o acesso direto, um tipo sem frase
		# derruba o laco e a suite PARA -- as afirmacoes seguintes nunca rodam, e a tabela sai
		# com menos linhas medidas do que deveria. Portao que aborta no primeiro defeito mede
		# menos do que diz medir.
		ok(
			texto != str(VitrineDeUpgrades.FRASES_DE_EFEITO.get(dados.tipo_de_efeito, "")),
			"%s teve o %%s substituido por um numero de verdade" % dados.id,
		)
	# ⚠️ portao com zero verificacoes tem que REPROVAR: um catalogo vazio deixaria o laco cair
	# inteiro e a suite imprimiria "tudo certo" sem ter olhado nada
	ok(conferidos > 0, "e houve upgrade para conferir (%d)" % conferidos)


## ⚠️ O portao do item 2 do cabecalho, e ele morde dos DOIS lados: com o total em zero quase
## tudo e futuro, e com o total no teto nao sobra futuro nenhum.
func _as_duas_listas_particionam_o_catalogo() -> void:
	Jogo.upgrades_comprados = []
	Jogo.total_caracteres = Grande.zero()

	var no_comeco := VitrineDeUpgrades.disponiveis()
	var futuros_no_comeco := VitrineDeUpgrades.futuros(9999)
	igual(
		no_comeco.size() + futuros_no_comeco.size(), Economia.upgrades().size(),
		"com o total em zero, disponivel + futuro da o catalogo inteiro",
	)
	var ids := {}
	for dados in no_comeco:
		ids[dados.id] = true
	var repetidos := 0
	for dados in futuros_no_comeco:
		if ids.has(dados.id):
			repetidos += 1
	igual(repetidos, 0, "e nenhum upgrade esta nas duas listas")
	ok(
		not futuros_no_comeco.is_empty(),
		"com o total em zero ha futuro a mostrar (%d)" % futuros_no_comeco.size(),
	)

	# o outro lado do portao: com o total gigante, requisito nenhum bloqueia mais nada
	Jogo.total_caracteres = Grande.new(1.0, 60)
	igual(
		VitrineDeUpgrades.futuros(9999).size(), 0,
		"com o total no teto, nao sobra upgrade bloqueado por requisito",
	)
	igual(
		VitrineDeUpgrades.disponiveis().size(), Economia.upgrades().size(),
		"e a loja mostra o catalogo inteiro",
	)

	# e o comprado sai das DUAS listas: ele nao e disponivel nem futuro, ele acabou
	var primeiro: DadosUpgrade = Economia.upgrades()[0]
	Jogo.upgrades_comprados = [primeiro.id]
	var apos := VitrineDeUpgrades.disponiveis()
	var achou := false
	for dados in apos:
		if dados.id == primeiro.id:
			achou = true
	ok(not achou, "upgrade comprado sai da lista de disponiveis")
	igual(
		apos.size(), Economia.upgrades().size() - 1,
		"e sai exatamente um, e nao a familia dele",
	)
	Jogo.upgrades_comprados = []


## ⚠️ ORDENADO POR REQUISITO, e nao por custo. A hud le o PRIMEIRO da lista como o proximo
## desbloqueio -- se a ordem for outra, ela remonta a loja no momento errado.
func _o_futuro_e_ordenado_e_limitado() -> void:
	Jogo.upgrades_comprados = []
	Jogo.total_caracteres = Grande.zero()

	var futuros := VitrineDeUpgrades.futuros(9999)
	var em_ordem := true
	for i in range(1, futuros.size()):
		if futuros[i].requisito < futuros[i - 1].requisito:
			em_ordem = false
	ok(em_ordem, "os futuros vem do requisito menor para o maior")

	# ⚠️ E AQUI ESTA O CONTROLE, SEM O QUAL A LINHA ACIMA E UM CARIMBO -- isto foi MEDIDO:
	# trocando a ordenacao de `requisito` para `custo`, a afirmacao acima continuou passando.
	# No catalogo de hoje as duas ordens coincidem, entao o dado real nao distingue a regra
	# certa da errada. A lista abaixo e construida de proposito com as duas ordens INVERTIDAS.
	var caro_e_proximo := DadosUpgrade.new()
	caro_e_proximo.id = "caro_e_proximo"
	caro_e_proximo.custo = 1000.0
	caro_e_proximo.requisito = 10.0
	var barato_e_distante := DadosUpgrade.new()
	barato_e_distante.id = "barato_e_distante"
	barato_e_distante.custo = 1.0
	barato_e_distante.requisito = 999.0

	var invertida: Array[DadosUpgrade] = [barato_e_distante, caro_e_proximo]
	var ordenada := VitrineDeUpgrades.ordenar_por_requisito(invertida)
	igual(
		ordenada[0].id, "caro_e_proximo",
		"⚠️ o que desbloqueia PRIMEIRO vem primeiro, mesmo sendo o mais CARO da lista",
	)
	igual(ordenada[1].id, "barato_e_distante", "e o barato de requisito distante vem depois")

	igual(
		VitrineDeUpgrades.futuros(3).size(), 3, "pedir tres devolve tres",
	)
	igual(
		VitrineDeUpgrades.futuros(1)[0].requisito, futuros[0].requisito,
		"e o primeiro de um e o mesmo primeiro da lista inteira",
	)
	# limite negativo nao estoura o slice nem devolve a lista toda
	igual(VitrineDeUpgrades.futuros(-1).size(), 0, "pedir menos que zero devolve nada")


## ⚠️ NUNCA NEGATIVO. "faltam -300 caracteres" e um texto que o jogador le como defeito, e ele
## sairia sozinho no quadro em que o requisito e cruzado.
func _o_que_falta_para_desbloquear() -> void:
	Jogo.upgrades_comprados = []
	Jogo.total_caracteres = Grande.zero()

	var futuros := VitrineDeUpgrades.futuros(1)
	ok(not futuros.is_empty(), "ha futuro para medir o que falta")
	if futuros.is_empty():
		return
	var bloqueado: DadosUpgrade = futuros[0]
	ok(
		VitrineDeUpgrades.falta_para(bloqueado).sinal() > 0,
		"o que falta para um bloqueado e positivo",
	)

	Jogo.total_caracteres = Grande.new(1.0, 60)
	ok(
		VitrineDeUpgrades.falta_para(bloqueado).e_zero(),
		"e o que falta para um ja desbloqueado e ZERO, nunca negativo",
	)
	ok(
		not VitrineDeUpgrades.desbloqueio_em_texto(bloqueado).strip_edges().is_empty(),
		"e a frase de desbloqueio nunca sai vazia",
	)


## ⚠️ CRUZA AS DUAS FONTES: a tabela de icones da vitrine contra a tabela de pecas do
## AssetsDoMenu. Id escrito errado nao da erro -- ele da um cabecalho sem icone, para sempre.
func _o_icone_de_familia_existe_no_disco() -> void:
	var familias: Array = DadosUpgrade.Familia.values()
	igual(
		VitrineDeUpgrades.ICONES_DE_FAMILIA.size(), familias.size(),
		"ha uma entrada de icone para cada familia -- o tamanho sai do enum",
	)
	igual(
		VitrineDeUpgrades.icone_de_familia(DadosUpgrade.Familia.SEM_FAMILIA), "",
		"SEM_FAMILIA nao tem icone: e a familia que a suite de dados nao deixa ninguem usar",
	)

	var conferidos := 0
	for familia in familias:
		if familia == DadosUpgrade.Familia.SEM_FAMILIA:
			continue
		var id := VitrineDeUpgrades.icone_de_familia(familia)
		ok(not id.is_empty(), "a familia %d tem icone declarado" % familia)
		ok(
			not AssetsDoMenu.peca(id).is_empty(),
			"e o icone %s e uma peca declarada no AssetsDoMenu" % id,
		)
		conferidos += 1
	ok(conferidos > 0, "e houve familia para conferir (%d)" % conferidos)

	# familia fora da faixa nao estoura o indice, pelos dois lados
	igual(VitrineDeUpgrades.icone_de_familia(-1), "", "familia invalida nao tem icone")
	igual(VitrineDeUpgrades.icone_de_familia(999), "", "e pelo outro lado tambem")


## ⚠️ COM CONTROLE. Uma funcao que devolvesse sempre ALCANCAVEL passaria em "os tres estados
## existem" -- o que se afirma aqui e que o estado MUDA com o saldo, nas duas direcoes.
func _os_tres_estados_de_alcance() -> void:
	igual(
		Alcance.BRILHO.size(), Alcance.Estado.values().size(),
		"ha um brilho para cada estado -- o tamanho sai do enum",
	)
	var caindo := true
	for i in range(1, Alcance.BRILHO.size()):
		if Alcance.BRILHO[i] >= Alcance.BRILHO[i - 1]:
			caindo = false
	ok(caindo, "o brilho cai de ALCANCAVEL para LONGE: o distante nao compete com o proximo")
	ok(
		Alcance.BRILHO[Alcance.Estado.LONGE] > 0.0,
		"⚠️ e o LONGE nao chega a zero: ele e a promessa do que vem depois, e nao um vazio",
	)

	var custo := Grande.de_float(100.0)

	Jogo.dinheiro = Grande.de_float(100.0)
	igual(Alcance.de(custo), Alcance.Estado.ALCANCAVEL, "saldo exato ja e alcancavel")
	Jogo.dinheiro = Grande.de_float(250.0)
	igual(Alcance.de(custo), Alcance.Estado.ALCANCAVEL, "saldo de sobra tambem")

	Jogo.dinheiro = Grande.de_float(100.0 * Alcance.PERTO_O_BASTANTE)
	igual(
		Alcance.de(custo), Alcance.Estado.PERTO,
		"no limiar exato o item ja e o proximo objetivo",
	)
	Jogo.dinheiro = Grande.de_float(99.0)
	igual(Alcance.de(custo), Alcance.Estado.PERTO, "quase pagando tambem e PERTO")

	Jogo.dinheiro = Grande.de_float(100.0 * Alcance.PERTO_O_BASTANTE - 1.0)
	igual(Alcance.de(custo), Alcance.Estado.LONGE, "um caractere abaixo do limiar e LONGE")
	Jogo.dinheiro = Grande.zero()
	igual(Alcance.de(custo), Alcance.Estado.LONGE, "e saldo zero e LONGE")

	# estado fora da faixa nao estoura o indice
	ok(Alcance.brilho_de(-1) > 0.0, "estado invalido ainda tem brilho")
	ok(Alcance.brilho_de(999) > 0.0, "e pelo outro lado tambem")


## ⚠️ CUSTO ZERO DEVOLVE 1, e nao infinito. Divisao por zero num contador de interface nao
## quebra o jogo: ela desenha "inf%" e ninguem descobre de onde veio.
func _a_fracao_do_custo() -> void:
	Jogo.dinheiro = Grande.de_float(50.0)
	perto(Alcance.fracao(Grande.de_float(100.0)), 0.5, 0.001, "metade do custo da 0,5")
	perto(Alcance.fracao(Grande.de_float(50.0)), 1.0, 0.001, "custo pago da 1")
	perto(
		Alcance.fracao(Grande.de_float(10.0)), 1.0, 0.001,
		"e saldo de sobra tambem da 1, e nao 5 -- a fracao e limitada",
	)
	perto(Alcance.fracao(Grande.zero()), 1.0, 0.001, "custo zero da 1")
	perto(
		Alcance.fracao(Grande.de_float(-10.0)), 1.0, 0.001,
		"e custo negativo tambem, em vez de uma fracao negativa",
	)
