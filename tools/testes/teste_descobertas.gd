## Suite das descobertas: o teto da chance, a ordem das raridades e o sorteio reprodutivel.
##
## As tres afirmacoes que a issue #16 pede, e cada uma protege uma coisa diferente:
##
##   TETO -- a chance nunca passa de 1. Sem ele, meia hora de endgame daria chance 10^40,
##   que nao significa nada e faria o catalogo inteiro cair no mesmo quadro, esvaziando o
##   sistema justamente quando ele deveria estar mais raro.
##
##   ORDEM -- categoria mais rara nunca sai antes da menos rara na mesma faixa de
##   producao. E uma regra sobre os DADOS, e nao sobre o codigo: basta alguem digitar um
##   zero a menos num .tres para o Epico virar mais provavel que o Comum.
##
##   SEMENTE -- o sorteio tem gerador proprio. Sem isso a suite dependeria do randi()
##   global e falharia de vez em quando, que e o pior tipo de teste que existe.
##
## ⚠️ Nenhuma afirmacao aqui olha texto gerado, porque o jogo NAO GERA TEXTO (GDD §10). O
## que se testa e a conta.
extends TesteBase

func _init() -> void:
	nome = "descobertas"


## Os treze degraus do plano v0.6 §3, e a faixa de raridade em que cada um deve cair.
##
## ⚠️ ISTO E O ESQUELETO DO CONTEUDO, e nao uma taxonomia decorativa. Um degrau vazio e um
## buraco na escada que o jogador sobe -- ele passa de PALAVRA para PARAGRAFO sem encontrar
## uma FRASE, e a progressao que o sistema promete deixa de acontecer.
## ⚠️ OS DEGRAUS SAO AS FAIXAS DO ARQUIVO, e desde a issue #55 eles NAO moram mais aqui.
##
## Esta tabela era a definicao das faixas quando so a suite precisava delas. No instante em
## que o Arquivo (issue #55) passou a agrupar por faixa, manter a copia daria duas tabelas
## para a mesma verdade -- e elas divergiriam na primeira faixa nova, com a suite
## continuando verde sobre a divisao ANTIGA enquanto a tela mostra a nova.
##
## O que sobra aqui e so o que e de teste: QUANTAS cada faixa precisa ter. O minimo e
## indexado pela faixa, e a suite reprova se as duas listas tiverem tamanhos diferentes --
## faixa nova sem minimo passaria despercebida.
const MINIMO_POR_FAIXA: Array[int] = [8, 8, 8, 12, 5, 5]

## As sete autorais do plano v0.6 §4. Elas sao O PRODUTO desta versao -- o resto e o
## caminho ate elas --, e por isso sao cobradas por id.
const AUTORAIS: PackedStringArray = [
	"banana", "eu", "ola", "uma_frase_gramatical", "um_poema",
	"sua_propria_descoberta", "just_keep_typing",
]


func executar() -> void:
	_catalogo()
	_ordem_das_raridades()
	_teto_da_chance()
	_sorteio_reprodutivel()
	_o_papel_separa_sem_bonus_de_esquecido()
	_os_degraus_estao_cheios()
	_as_autorais_existem()
	_o_poema_tem_versos()
	_o_papel_interface_tem_o_que_entregar()
	_bonus_permanente()
	_as_lendarias_e_o_espaco_entre_elas()
	_as_faixas_cobrem_toda_raridade()
	_a_contagem_por_faixa_fecha()
	_o_carimbo_do_arquivo()
	_quem_produz_caractere_semeia_o_sorteio()


func _catalogo() -> void:
	var todas := Descobertas.todas()
	ok(not todas.is_empty(), "o autoload carregou algum .tres")

	var ids := {}
	for descoberta in todas:
		ok(not ids.has(descoberta.id), "%s -- id nao repete" % descoberta.id)
		ids[descoberta.id] = true
		ok(descoberta.chance_base > 0.0, "%s -- chance_base positiva" % descoberta.id)
		# ⚠️ ESTA REGRA FICOU MAIS PRECISA NA ISSUE #52, e nao mais frouxa.
		#
		# Ate a v0.5 ela era "toda descoberta tem bonus > 1", e servia para pegar dado
		# esquecido pela metade. Com descobertas que existem SO pela piada, 1.0 virou um
		# valor legitimo -- e a regra passou a ser condicional ao papel declarado:
		#
		#   papel BONUS  exige bonus > 1.0   (e o que esta linha cobra)
		#   outro papel  exige bonus == 1.0  (cobrado em _o_papel_separa_sem_bonus_de_esquecido)
		#
		# As duas juntas pegam MAIS do que a antiga pegava: a antiga nao percebia um bonus
		# escondido numa descoberta que anuncia nao ter nenhum.
		#
		# ⚠️ E O RAMO E UM `if`, E NAO UM `continue`. A primeira versao saiu do laco com
		# continue, e com isso as afirmacoes ABAIXO -- nome preenchido, texto preenchido --
		# deixaram de rodar para toda descoberta de humor. Nove descobertas passariam a nao
		# ter nome conferido, e a suite continuaria verde.
		if descoberta.papel == DadosDescoberta.Papel.BONUS:
			ok(descoberta.bonus > 1.0, "%s -- bonus %s recompensa alguma coisa" % [
				descoberta.id, descoberta.bonus,
			])
		ok(not descoberta.nome.strip_edges().is_empty(), "%s -- nome preenchido" % descoberta.id)
		ok(not descoberta.texto.strip_edges().is_empty(), "%s -- texto preenchido" % descoberta.id)
		ok(
			descoberta.categoria in DadosDescoberta.Categoria.values(),
			"%s -- categoria e um valor do enum" % descoberta.id,
		)
		ok(Descobertas.de(descoberta.id) == descoberta, "%s -- e achada por id" % descoberta.id)


## Regra sobre os dados: a categoria seguinte tem que ser toda mais rara que a anterior.
## Um zero a menos num .tres faria o Epico sair antes do Comum, e nada mais no jogo
## perceberia.
func _ordem_das_raridades() -> void:
	var menor_da_categoria := {}
	var maior_da_categoria := {}
	for descoberta in Descobertas.todas():
		var c: int = descoberta.categoria
		menor_da_categoria[c] = minf(menor_da_categoria.get(c, INF), descoberta.chance_base)
		maior_da_categoria[c] = maxf(maior_da_categoria.get(c, 0.0), descoberta.chance_base)

	var categorias := menor_da_categoria.keys()
	categorias.sort()
	for i in range(1, categorias.size()):
		var anterior: int = categorias[i - 1]
		var atual: int = categorias[i]
		ok(
			maior_da_categoria[atual] < menor_da_categoria[anterior],
			"a categoria %d e toda mais rara que a %d" % [atual, anterior],
		)

	# e a lista sai ordenada da mais comum para a mais rara, que e como a tela mostra
	var ordem_certa := true
	var anterior_categoria := -1
	for descoberta in Descobertas.todas():
		if descoberta.categoria < anterior_categoria:
			ordem_certa = false
		anterior_categoria = descoberta.categoria
	ok(ordem_certa, "a lista sai da mais comum para a mais rara")


func _teto_da_chance() -> void:
	var comum := Descobertas.todas()[0]

	perto(Descobertas.chance_de(comum, Grande.zero()), 0.0, 0.0, "zero caractere, zero chance")
	perto(
		Descobertas.chance_de(comum, Grande.de_float(-5.0)), 0.0, 0.0,
		"producao negativa nao vira chance",
	)
	perto(
		Descobertas.chance_de(comum, Grande.de_float(1.0)), comum.chance_base, 1e-15,
		"um caractere da exatamente a chance base",
	)
	perto(
		Descobertas.chance_de(comum, Grande.de_float(1.0 / comum.chance_base)), 1.0, 1e-9,
		"o inverso da chance base satura em 1",
	)

	# o caso que o teto existe para aguentar: producao que nem cabe em float
	perto(
		Descobertas.chance_de(comum, Grande.new(1.0, 400)), 1.0, 0.0,
		"10^400 caracteres continuam dando chance 1 e nao INF",
	)
	for descoberta in Descobertas.todas():
		var chance := Descobertas.chance_de(descoberta, Grande.new(1.0, 300))
		ok(chance <= 1.0 and chance >= 0.0, "%s -- a chance fica em [0, 1]" % descoberta.id)


## Mesma semente, mesmo resultado. E o que permite a suite afirmar qualquer coisa sobre um
## sorteio.
func _sorteio_reprodutivel() -> void:
	var guardado := Jogo.descobertas.duplicate()
	var semente_original := Descobertas.gerador.seed

	var primeira := _sortear_com(1234, 12)
	var segunda := _sortear_com(1234, 12)
	igual(primeira, segunda, "a mesma semente sorteia a mesma sequencia")

	var terceira := _sortear_com(999, 12)
	ok(primeira != terceira or primeira.is_empty(), "sementes diferentes divergem")

	# producao que satura a chance: com chance 1 em tudo, a primeira da lista sai sempre,
	# e sai UMA por credito -- voltar de quatro horas offline nao despeja o catalogo
	Jogo.descobertas = [] as Array[String]
	Descobertas.gerador.seed = 7
	Descobertas.sortear(Grande.new(1.0, 300))
	igual(Jogo.descobertas.size(), 1, "chance saturada solta uma descoberta, nao todas")
	igual(Jogo.descobertas[0], Descobertas.todas()[0].id, "e e a mais comum da lista")

	# e nao repete a que ja saiu
	Descobertas.sortear(Grande.new(1.0, 300))
	igual(Jogo.descobertas.size(), 2, "o credito seguinte solta a proxima")
	ok(Jogo.descobertas[1] != Jogo.descobertas[0], "e nao repete a anterior")

	Descobertas.gerador.seed = semente_original
	Jogo.descobertas = guardado


func _sortear_com(semente: int, creditos: int) -> Array:
	Jogo.descobertas = [] as Array[String]
	Descobertas.gerador.seed = semente
	for i in creditos:
		Descobertas.sortear(Grande.de_float(500.0))
	return Jogo.descobertas.duplicate()


## Descoberta da bonus; marco nao da. Sao os dois sistemas de recompensa do jogo e eles
## nao se misturam (decisao 0003).
func _bonus_permanente() -> void:
	var guardado := Jogo.descobertas.duplicate()
	Jogo.descobertas = [] as Array[String]
	perto(Economia.multiplicador_de_descobertas(), 1.0, 1e-12, "sem descoberta, bonus neutro")

	var primeira := Descobertas.todas()[0]
	Jogo.descobertas = [primeira.id] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), primeira.bonus, 1e-12,
		"uma descoberta vale o bonus dela",
	)

	var segunda := Descobertas.todas()[1]
	Jogo.descobertas = [primeira.id, segunda.id] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), primeira.bonus * segunda.bonus, 1e-12,
		"duas descobertas multiplicam, nunca somam",
	)

	Jogo.descobertas = ["id_que_nao_existe"] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), 1.0, 1e-12,
		"id de save antigo que nao existe mais e ignorado, e nao quebra a producao",
	)

	Jogo.descobertas = guardado


## As seis do GDD §11, e a regra que faz elas VALEREM alguma coisa.
##
## "Se o jogador ve duas lendarias na mesma sessao, elas deixam de ser lendarias." Esta e a
## afirmacao que a issue #32 pede, e ela nao e sobre chance: no endgame a chance de tudo
## que ainda falta vale 1, entao sem quarentena as seis caem no MESMO QUADRO. Seis avisos
## empilhados nao sao seis momentos raros -- sao um so, e barulhento.
func _as_lendarias_e_o_espaco_entre_elas() -> void:
	var guardado_descobertas := Jogo.descobertas.duplicate()
	var guardado_tempo := Jogo.tempo_jogado
	var guardado_ultima := Jogo.tempo_da_ultima_rara
	var semente_original := Descobertas.gerador.seed

	# as seis do GDD §11 existem, e cada uma das tres faixas de cima tem alguem
	var faixas := {}
	for id in [
		"hamlet", "romance_inedito", "minha_biografia",
		"o_jogo", "essa_mensagem", "o_proximo_texto",
	]:
		var dados := Descobertas.de(id)
		ok(dados != null, "%s existe no catalogo" % id)
		if dados == null:
			continue
		ok(
			dados.categoria >= DadosDescoberta.Categoria.LENDARIO,
			"%s e Lendaria ou acima" % id,
		)
		faixas[dados.categoria] = true
	for categoria in [
		DadosDescoberta.Categoria.LENDARIO,
		DadosDescoberta.Categoria.IMPOSSIVEL,
		DadosDescoberta.Categoria.PARADOXAL,
	]:
		ok(faixas.has(categoria), "a faixa %d tem pelo menos uma descoberta" % categoria)

	# Hamlet e o unico bonus que o GDD crava: x10 permanente (§11)
	perto(Descobertas.de("hamlet").bonus, 10.0, 1e-12, "Hamlet vale os x10 do GDD §11")

	# O CASO QUE IMPORTA: chance saturada, credito atras de credito, e as raras uma so vez
	Jogo.descobertas = [] as Array[String]
	Jogo.tempo_jogado = 0.0
	# negativo e o "nenhuma rara ainda" -- zero seria uma rara achada no instante zero
	Jogo.tempo_da_ultima_rara = -1.0
	Descobertas.gerador.seed = 42
	var raras := 0
	for i in 200:
		Descobertas.sortear(Grande.new(1.0, 300))
	for id in Jogo.descobertas:
		if Descobertas.de(id).categoria >= DadosDescoberta.Categoria.LENDARIO:
			raras += 1
	igual(raras, 1, "duzentos creditos no mesmo instante soltam UMA rara, e nao seis")

	# e as comuns continuam saindo: a quarentena espaca as raras, nao congela o sistema
	ok(Jogo.descobertas.size() > raras, "as comuns continuam caindo durante a quarentena")

	# passado o intervalo, a proxima rara pode sair
	var quarentena: DadosDescoberta = null
	for descoberta in Descobertas.todas():
		if not Descobertas.encontrada(descoberta.id) 				and descoberta.categoria >= DadosDescoberta.Categoria.LENDARIO:
			quarentena = descoberta
			break
	ok(quarentena != null, "ainda ha rara por achar depois da primeira")
	ok(Descobertas.em_quarentena(quarentena), "e ela esta em quarentena no mesmo instante")

	Jogo.tempo_jogado = Jogo.tempo_da_ultima_rara + 10000.0
	ok(not Descobertas.em_quarentena(quarentena), "passado o intervalo, ela e liberada")
	Descobertas.sortear(Grande.new(1.0, 300))
	ok(Descobertas.encontrada(quarentena.id), "e o credito seguinte a solta")

	# e a quarentena nunca vale para as comuns -- elas nao prometem raridade nenhuma
	ok(
		not Descobertas.em_quarentena(Descobertas.todas()[0]),
		"a mais comum do catalogo nunca fica em quarentena",
	)

	Descobertas.gerador.seed = semente_original
	Jogo.descobertas = guardado_descobertas
	Jogo.tempo_jogado = guardado_tempo
	Jogo.tempo_da_ultima_rara = guardado_ultima


# ── issue #52: o conteudo ───────────────────────────────────────────────────────────────

## ⚠️ O PORTAO QUE A ISSUE PEDE, e ele morde dos dois lados.
##
## Ate a v0.5 toda descoberta dava bonus, e o padrao invalido (1.0) protegia contra dado
## esquecido pela metade. Com descobertas de HUMOR, 1.0 virou legitimo -- e sem declarar
## qual e qual, a suite teria que escolher entre aceitar o esquecido ou reprovar a piada.
##
##   papel BONUS  exige bonus > 1.0   senao e dado esquecido
##   outro papel  exige bonus == 1.0  senao e bonus escondido num papel que nao o anuncia
func _o_papel_separa_sem_bonus_de_esquecido() -> void:
	var por_papel := {}
	for descoberta in Descobertas.todas():
		por_papel[descoberta.papel] = int(por_papel.get(descoberta.papel, 0)) + 1
		if descoberta.papel == DadosDescoberta.Papel.BONUS:
			ok(
				descoberta.bonus > 1.0,
				"%s -- papel BONUS com bonus de verdade (%s)" % [descoberta.id, descoberta.bonus],
			)
			continue
		perto(
			descoberta.bonus, 1.0, 1e-6,
			"%s -- papel %d nao esconde bonus" % [descoberta.id, descoberta.papel],
		)

	# ⚠️ e os papeis que nao sao BONUS EXISTEM de verdade. Sem esta linha, um catalogo
	# inteiro de BONUS passaria em tudo acima -- e o campo seria coluna morta.
	var sem_bonus := 0
	for papel in [
		DadosDescoberta.Papel.HUMOR, DadosDescoberta.Papel.EXPLICACAO,
		DadosDescoberta.Papel.INTERFACE,
	]:
		var quantas := int(por_papel.get(papel, 0))
		ok(quantas > 0, "o papel %d e usado por alguma descoberta (%d)" % [papel, quantas])
		sem_bonus += quantas
	ok(sem_bonus >= 3, "ha descoberta que existe sem dar bonus (%d)" % sem_bonus)

	# EXPLICACAO sem curiosidade e um papel que promete e nao entrega
	for descoberta in Descobertas.todas():
		if descoberta.papel != DadosDescoberta.Papel.EXPLICACAO:
			continue
		ok(
			not descoberta.curiosidade.strip_edges().is_empty(),
			"%s -- papel EXPLICACAO traz curiosidade" % descoberta.id,
		)


## Nenhum degrau da escada fica vazio.
func _os_degraus_estao_cheios() -> void:
	var por_categoria := {}
	for descoberta in Descobertas.todas():
		por_categoria[descoberta.categoria] = int(por_categoria.get(descoberta.categoria, 0)) + 1

	igual(
		MINIMO_POR_FAIXA.size(),
		DadosDescoberta.FAIXAS.size(),
		"ha um minimo para cada faixa -- faixa nova sem minimo passaria despercebida",
	)

	for i in DadosDescoberta.FAIXAS.size():
		if i >= MINIMO_POR_FAIXA.size():
			break
		var faixa: Dictionary = DadosDescoberta.FAIXAS[i]
		var quantas := 0
		for categoria in range(int(faixa["de"]), int(faixa["ate"]) + 1):
			quantas += int(por_categoria.get(categoria, 0))
		ok(
			quantas >= MINIMO_POR_FAIXA[i],
			"a faixa %s tem %d descobertas (minimo %d)" % [
				faixa["nome"], quantas, MINIMO_POR_FAIXA[i],
			],
		)

	ok(
		Descobertas.todas().size() >= 60,
		"o catalogo chegou a sessenta (%d)" % Descobertas.todas().size(),
	)


## ⚠️ FERRAMENTA QUE PRODUZ CARACTERE E NAO FIXA A SEMENTE NAO E DETERMINISTICA.
##
## Descobertas.gerador chama randomize() no _ready, e descoberta DA BONUS DE PRODUCAO:
## duas corridas do mesmo commit divergem, e a divergencia cresce com o tempo simulado.
## Medido em medir_ritmo: 35 segundos de diferenca no primeiro Teorema entre duas corridas
## identicas -- com o cabecalho da regua afirmando, desde sempre, que ela era estavel.
##
## O defeito sobreviveu porque ninguem roda uma regua duas vezes para comparar consigo
## mesma. Este portao roda.
##
## ⚠️ VARRE A PASTA, e nao uma lista: ferramenta nova entra na conta sozinha. E a divida e
## NOMEADA e morde dos dois lados -- nome fora dela tem que semear, nome dentro tem que
## continuar sem produzir caractere nenhum.
## ⚠️ QUEM PRECISA SEMEAR E O PONTO DE ENTRADA, e nao todo arquivo que produz caractere.
##
## A primeira versao deste portao varria todo .gd e reprovou teste_cenas, teste_combo e
## teste_economia -- que sao SUITES, e rodam sob o runner. Exigir a linha em cada uma seria
## N lugares para esquecer, com a suite nova nascendo sem ela. O runner semeia uma vez, e o
## portao confere quem de fato inicia uma execucao.
##
## Ponto de entrada e DERIVADO da pasta: todo .gd com um .tscn irmao. Ferramenta nova entra
## na conta sozinha, sem ninguem lembrar de acrescentar uma linha aqui.
const SEM_SORTEIO_AINDA: PackedStringArray = [
	# nao produzem caractere: um mede quadro com o multiplicador cravado na mao, o outro so
	# monta a galeria a partir de imagens que ja existem
	"medir_quadro.gd",
	"gerar_galeria.gd",
]


func _quem_produz_caractere_semeia_o_sorteio() -> void:
	var conferidas := 0
	for pasta in ["res://tools", "res://tools/testes"]:
		var dir := DirAccess.open(pasta)
		if dir == null:
			continue
		dir.list_dir_begin()
		var item := dir.get_next()
		while item != "":
			if not dir.current_is_dir() and item.ends_with(".tscn"):
				var script := item.replace(".tscn", ".gd")
				conferidas += _conferir_semente(pasta + "/" + script, script)
			item = dir.get_next()
		dir.list_dir_end()

	# ⚠️ portao com zero verificacoes tem que REPROVAR: pasta vazia nao e aprovacao
	ok(conferidas > 0, "conferiu a semente de %d ponto(s) de entrada" % conferidas)


## Devolve 1 quando o ponto de entrada foi conferido, 0 quando ele esta na divida.
func _conferir_semente(caminho: String, nome_do_arquivo: String) -> int:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return 0
	var texto := arquivo.get_as_text()
	arquivo.close()

	var produz := texto.contains("Economia.digitar") or texto.contains("Economia.acumular")

	if nome_do_arquivo in SEM_SORTEIO_AINDA:
		# a outra metade da divida: se este arquivo passar a produzir caractere, ele sai da
		# lista -- senao a linha fica cobrindo em silencio o dia em que ele mudar
		ok(
			not produz,
			"%s esta em SEM_SORTEIO_AINDA e continua sem produzir caractere" % nome_do_arquivo,
		)
		return 0

	ok(
		texto.contains("Descobertas.gerador.seed"),
		"o ponto de entrada %s fixa Descobertas.gerador.seed" % nome_do_arquivo,
	)
	return 1


## ⚠️ RARIDADE FORA DE FAIXA SOME DO ARQUIVO, e sumir e pior que reprovar. Varre o ENUM,
## que e a fonte, e nao a lista de faixas: uma raridade nova entraria no enum e cairia fora
## de toda faixa em silencio -- as descobertas dela simplesmente nao apareceriam na tela, e
## nada no console diria por que.
func _as_faixas_cobrem_toda_raridade() -> void:
	var quantas_faixas := {}
	for categoria in DadosDescoberta.Categoria.values():
		var faixa := DadosDescoberta.faixa_de(categoria)
		ok(faixa >= 0, "a raridade %d cai em alguma faixa" % categoria)
		# e em UMA so: faixas que se sobrepoem fariam a mesma descoberta aparecer duas
		# vezes, com as duas contagens certas e o total errado
		var cobrem := 0
		for i in DadosDescoberta.FAIXAS.size():
			var f: Dictionary = DadosDescoberta.FAIXAS[i]
			if categoria >= int(f["de"]) and categoria <= int(f["ate"]):
				cobrem += 1
		igual(cobrem, 1, "a raridade %d cai em exatamente uma faixa" % categoria)
		quantas_faixas[faixa] = true

	# ⚠️ E SO A PARADOXAL ESCONDE O TOTAL. `0/?` e a promessa da ultima faixa; uma segunda
	# faixa oculta transformaria a marca registrada em ruido.
	var ocultas := 0
	for faixa_dados in DadosDescoberta.FAIXAS:
		if bool(faixa_dados["oculta"]):
			ocultas += 1
	igual(ocultas, 1, "exatamente uma faixa esconde o total")
	ok(
		bool(DadosDescoberta.FAIXAS[DadosDescoberta.FAIXAS.size() - 1]["oculta"]),
		"e a que esconde e a ultima, a paradoxal",
	)


## A soma das contagens por faixa tem que dar o catalogo inteiro: descoberta que caisse
## fora de toda faixa nao apareceria na tela, e o total de cima continuaria certo.
func _a_contagem_por_faixa_fecha() -> void:
	var total := 0
	var achadas := 0
	for i in DadosDescoberta.FAIXAS.size():
		var contagem: Array = Descobertas.contagem_da_faixa(i)
		achadas += int(contagem[0])
		total += int(contagem[1])
	igual(
		total,
		Descobertas.todas().size(),
		"a soma das faixas cobre o catalogo inteiro",
	)
	igual(achadas, Descobertas.quantas_encontradas(), "e as achadas tambem fecham")


## O carimbo da issue #55: quando a descoberta saiu e com que ordem de grandeza.
func _o_carimbo_do_arquivo() -> void:
	var guardado := Jogo.descobertas.duplicate()
	var quando_guardado := Jogo.descobertas_quando.duplicate()
	var grandeza_guardada := Jogo.descobertas_grandeza.duplicate()
	var total_guardado := Jogo.total_caracteres

	Jogo.esquecer_descobertas()
	ok(Jogo.descobertas_quando.is_empty(), "esquecer_descobertas limpa o carimbo do quando")
	ok(Jogo.descobertas_grandeza.is_empty(), "e o da ordem de grandeza tambem")

	var alguma: DadosDescoberta = Descobertas.todas()[0]
	ok(
		Descobertas.detalhe_de(alguma.id).is_empty(),
		"descoberta sem carimbo devolve VAZIO -- e nao um zero que mente",
	)

	# ⚠️ ORDEM DE GRANDEZA ZERO E LEGITIMA (de 1 a 9 caracteres). Este caso existe para
	# provar que a sentinela e a AUSENCIA, e nao o valor: com zero como sentinela, a
	# primeira descoberta de uma partida nova perderia a linha na tela.
	Jogo.total_caracteres = Grande.de_float(5.0)
	Jogo.descobertas.append(alguma.id)
	Descobertas._carimbar(alguma.id)
	var detalhe := Descobertas.detalhe_de(alguma.id)
	ok(not detalhe.is_empty(), "com carimbo, o detalhe existe")
	igual(int(detalhe["grandeza"]), 0, "5 caracteres sao ordem de grandeza ZERO, e ela conta")

	# a data vai em segundos inteiros, pelo mesmo motivo de Save.gravar: o JSON guarda 15
	# digitos significativos e um horario unix ja gasta dez antes da virgula
	var data := float(detalhe["quando"])
	ok(data > 0.0, "a data foi carimbada")
	perto(data - floorf(data), 0.0, 0.0, "e vem em segundos inteiros, que o JSON devolve igual")

	Jogo.total_caracteres = Grande.de_float(1.0e12)
	Descobertas._carimbar(alguma.id)
	igual(
		int(Descobertas.detalhe_de(alguma.id)["grandeza"]),
		12,
		"um trilhao de caracteres e ordem de grandeza 12",
	)

	Jogo.descobertas = guardado
	Jogo.descobertas_quando = quando_guardado
	Jogo.descobertas_grandeza = grandeza_guardada
	Jogo.total_caracteres = total_guardado


## ⚠️ AS SETE AUTORAIS SAO O PRODUTO DESTA VERSAO. Cobradas por id: renomear uma delas sem
## perceber apagaria a descoberta que o jogador ja tinha achado -- o id vai para o save.
func _as_autorais_existem() -> void:
	for id_autoral in AUTORAIS:
		var achada := Descobertas.de(id_autoral)
		ok(achada != null, "a descoberta autoral %s existe" % id_autoral)
		if achada == null:
			continue
		ok(not achada.texto.strip_edges().is_empty(), "%s -- tem texto" % id_autoral)

	# ⚠️ JUST KEEP TYPING E TARDIA, e isso e a issue inteira dela: ela e o fecho circular
	# do jogo, e sair cedo a desperdica.
	var fecho := Descobertas.de("just_keep_typing")
	if fecho != null:
		igual(
			fecho.categoria, DadosDescoberta.Categoria.PARADOXAL,
			"JUST KEEP TYPING e paradoxal",
		)
		var mais_rara := true
		for descoberta in Descobertas.todas():
			if descoberta.id != fecho.id and descoberta.chance_base <= fecho.chance_base:
				mais_rara = false
		ok(mais_rara, "e e a descoberta MAIS RARA do jogo -- o fecho nao sai cedo")


## O poema mostra quatro linhas de um conjunto CURADO, e o sorteio e estavel.
##
## ⚠️ O JOGO NUNCA GERA TEXTO (GDD §10). O que se prova aqui e que ele escolhe entre linhas
## escritas a mao, e que a mesma partida ve sempre o mesmo poema -- reabrir o Arquivo e ver
## outras quatro linhas transformaria a descoberta numa maquina de frases.
func _o_poema_tem_versos() -> void:
	var poema := Descobertas.de("um_poema")
	ok(poema != null, "o poema existe")
	if poema == null:
		return

	ok(
		poema.versos.size() > DadosDescoberta.VERSOS_MOSTRADOS,
		"ha mais versos curados do que os mostrados (%d de %d)" % [
			DadosDescoberta.VERSOS_MOSTRADOS, poema.versos.size(),
		],
	)

	var primeiros := poema.versos_sorteados(1234)
	igual(primeiros.size(), DadosDescoberta.VERSOS_MOSTRADOS, "mostra quatro versos")
	igual(
		poema.versos_sorteados(1234), primeiros,
		"a mesma semente da o mesmo poema -- o poema do jogador e o poema dele",
	)
	ok(
		poema.versos_sorteados(4321) != primeiros,
		"e sementes diferentes dao poemas diferentes",
	)

	# verso repetido dentro do mesmo poema parece defeito, e nao poesia
	var vistos := {}
	for verso in primeiros:
		ok(not vistos.has(verso), "nenhum verso se repete no mesmo poema")
		vistos[verso] = true

	# e todo verso e texto escrito a mao, com linha no CSV -- o portao de texto cobra pela
	# fonte, e esta linha garante que a fonte nao esta vazia
	for verso in poema.versos:
		ok(not verso.strip_edges().is_empty(), "nenhum verso curado esta vazio")


## ⚠️ O PAPEL `INTERFACE` PRECISA TER O QUE ENTREGAR. Ate esta linha existir, ele era uma
## promessa: a descoberta anunciava mudar a interface e nada mudava -- que e a mesma
## familia de defeito da opcao sem consumidor (issue #41).
##
## O efeito e o das letras: por alguns segundos, a palavra que o macaco produziu toma o
## lugar do alfabeto de decoracao. A suite prova a REGRA (tomar e devolver) sem subir cena
## nenhuma; que ela aparece na tela e assunto de captura.
func _o_papel_interface_tem_o_que_entregar() -> void:
	var quantas := 0
	for descoberta in Descobertas.todas():
		if descoberta.papel == DadosDescoberta.Papel.INTERFACE:
			quantas += 1
	ok(quantas > 0, "ha descoberta de papel INTERFACE (%d)" % quantas)

	# ⚠️ e o efeito EXISTE. Uma descoberta de interface sem nada que a interface faca e a
	# promessa de novo, so que com o campo declarado.
	var letras := Letras.new()
	ok(not letras.tomada(), "as letras comecam sem palavra nenhuma tomando conta")
	letras.tomar("BANANA")
	ok(letras.tomada(), "uma palavra toma conta das letras")

	# palavra vazia nao toma: seis segundos de nada seria o efeito parecendo quebrado
	var vazias := Letras.new()
	vazias.tomar("   ")
	ok(not vazias.tomada(), "palavra em branco nao toma a tela")

	letras.free()
	vazias.free()
