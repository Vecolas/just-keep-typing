## Regua: quanto tempo a partida leva ate cada marco do Panorama.
##
##   godot --headless --path . tools/medir_ritmo.tscn
##
## REGUA NAO APROVA NEM REPROVA -- ela MEDE. A saida sao numeros para voce decidir; a
## decisao e sua. Sem numero medido, ajustar balanceamento e chute com etapa extra.
## Ver TUNING.md.
##
## E a regua que sustenta a issue #20 (curva do Panorama) e todo tuning daqui para a
## frente: os requisitos dos marcos definem, na pratica, quanto tempo o jogador leva para
## atravessar cada faixa de escala (decisao 0003), e ate esta regua existir esse numero
## nunca tinha sido olhado.
##
## ⚠️ A REGUA DE CAMPANHA (issue #59). Ate a v0.6 esta regua NAO executava eventos nem
## automacao, e o jogador simulado nunca prestigiava. Ela media um pedaco do jogo e o
## chamava de campanha.
##
## Agora ela roda a partida inteira: Eventos.tique, Automacao.tique e a decisao de
## prestigiar. As tres coisas que faltavam sao justamente as que mudam o RITMO -- um evento
## dobra a producao por trinta segundos, uma automacao compra macaco enquanto o jogador
## olha para outro lado, e o prestigio reinicia a run com multiplicador.
##
## ⚠️ TABELA MEDIDA ANTES DESTA ISSUE NAO SE COMPARA COM AS NOVAS. O instrumento mudou
## pela segunda vez (a primeira foi o jogador que passou a digitar). Ver TUNING.md.
##
## ⚠️ E NAO EXISTE UMA `medir_ritmo_v1` GUARDADA AO LADO. Duas fontes para a mesma verdade
## divergem, e a versao velha voltaria a rodar no dia em que alguem a chamasse -- medindo
## um jogo que ja nao existe. O historico mora no TUNING.md, que e onde ele nao pode ser
## executado por engano. Ver CONVENCOES.md, "Uma regua por assunto".
##
## ⚠️ E O SORTEIO DE DESCOBERTAS E SEMEADO -- ver SEMENTE_DO_SORTEIO. Sem isso a promessa
## do paragrafo abaixo e falsa, e foi falsa ate a issue #56.
##
## ⚠️ O JOGADOR SIMULADO NAO E O JOGADOR REAL. Ele faz a compra otima INGENUA: gasta em
## upgrade assim que da, e no resto compra o maximo de macacos que couber. Nenhum humano
## joga assim -- ninguem clica com cadencia constante nem compra no instante exato em que
## o saldo fecha. Isso e proposital: a regua precisa ser ESTAVEL, para que a diferenca
## entre duas medicoes seja a mudanca no .tres e nao o humor de quem jogou.
##
## Roda como cena, e nao com --script, porque toca autoload: avaliacao de GDScript solto
## nao passa pela lista de autoloads do project.godot (CONVENCOES.md).
extends Node

## Passo do relogio simulado. Meio segundo da resolucao de sobra para uma regua que mede
## minutos e horas, e deixa a simulacao de um dia inteiro terminar em segundos.
const PASSO: float = 0.5

## De quanto em quanto tempo o jogador simulado vai a loja. Comprar todo passo nao mudaria
## a curva e triplicaria o custo da medicao.
const INTERVALO_DE_COMPRA: float = 1.0

## OS TRES PERFIS DE JOGADOR (issue #63). ⚠️ NAO EXISTE "JOGADOR MATEMATICO PERFEITO"
## REAL, e a pergunta que tres perfis respondem -- e que um so nunca responde -- e:
##
##     a campanha funciona apenas se a pessoa jogar de uma maneira especifica?
##
## ⚠️ E ELES SAO DADOS, e nao tres copias do laco. Tres funcoes parecidas divergem na
## primeira mudanca; o que muda entre eles cabe em cinco numeros.
##
## ⚠️ OS TRES USAM A MESMA SEMENTE. Semente por perfil misturaria comportamento com
## sorteio, e a diferenca entre as tabelas deixaria de querer dizer alguma coisa.
##
##   cliques_por_segundo   cadencia enquanto ele esta digitando
##   digita_depois_da_automacao  se ele continua digitando depois que a producao acende
##   atraso_de_compra      segundos ALEM do INTERVALO_DE_COMPRA ate ele ir a loja
##   resolve_eventos       se ele clica para encerrar o evento ruim
##
## ⚠️ O PERFIL "normal" E O QUE MANDA no criterio de aceite (issue #62). Os outros dois
## existem para achar o caso em que a campanha so fecha num extremo -- e o PASSIVO e quem
## nao pode digitar rapido: se a campanha so fechar para o ativo, a issue #54 foi violada,
## porque "atividade acelera, nunca obriga".
const PERFIS: Dictionary = {
	"ativo": {
		"cliques_por_segundo": 6.0,
		"digita_depois_da_automacao": true,
		"atraso_de_compra": 0.0,
		"resolve_eventos": true,
	},
	"normal": {
		"cliques_por_segundo": 3.0,
		"digita_depois_da_automacao": true,
		"atraso_de_compra": 5.0,
		"resolve_eventos": true,
	},
	# ⚠️ ele AINDA digita antes da automacao acender, e nao por escolha: a producao
	# automatica custa caracteres, e antes dela o clique e a unica fonte (GDD §3). Um
	# perfil que nao clicasse nada nunca sairia do zero, e mediria uma tela parada.
	"passivo": {
		"cliques_por_segundo": 2.0,
		"digita_depois_da_automacao": false,
		"atraso_de_compra": 15.0,
		"resolve_eventos": false,
	},
}

## O perfil histórico das medicoes anteriores a issue #63, para as tabelas antigas
## continuarem tendo um nome. Ver TUNING.md.
const PERFIL_PADRAO := "normal"

## Ate onde a medicao vai. Marco que nao cai em um dia de jogo aparece como NAO ALCANCADO,
## que e um resultado tao util quanto um tempo.
const LIMITE_SEGUNDOS: float = 24.0 * 3600.0


## ⚠️ O CONTROLE DA ISSUE #54. `-- sem_combo=1` zera o combo depois de cada clique, o que
## simula um jogador que digita sem nenhuma cadencia -- e da a MESMA medicao sem o efeito.
##
## Piso escrito a mao inventa a propria escala: "o combo acelera" so quer dizer alguma
## coisa contra a mesma corrida sem ele.
##
## E ele nao precisa de porta de tras no Combo: zerar e a operacao que ja existe para o
## prestigio, e o que muda aqui e o JOGADOR simulado, nao o sistema medido.
var _sem_combo: bool = false

## Os instantes em que o jogador simulado prestigiou. Guardado para o _imprimir.
var _prestigios: Array[float] = []

## O perfil em uso, lido de "-- perfil=<nome>". Cai no padrao quando nao pedido.
var _perfil: Dictionary = {}
var _nome_do_perfil: String = PERFIL_PADRAO


## ⚠️ A SEMENTE DO SORTEIO DE DESCOBERTAS. SEM ELA A REGUA NAO E REGUA.
##
## Descobertas.gerador chama randomize() no _ready, e descoberta DA BONUS DE PRODUCAO:
## duas corridas do mesmo commit sorteavam em instantes diferentes, a producao divergia, e
## a curva inteira andava junto. Medido: 35 segundos de diferenca no primeiro Teorema entre
## duas corridas identicas.
##
## Isso valia desde que a regua existe, e o cabecalho dela AFIRMAVA O CONTRARIO -- "a regua
## precisa ser ESTAVEL, para que a diferenca entre duas medicoes seja a mudanca no .tres e
## nao o humor de quem jogou". A suite e a ferramenta de captura ja semeavam; as reguas,
## nao. Uma verdade por assunto, e este assunto tinha duas.
##
## ⚠️ E O NUMERO E UM SO, COMPARTILHADO. Semente diferente por ferramenta daria tabelas que
## nao se comparam entre si, que e metade do problema de volta.
const SEMENTE_DO_SORTEIO: int = 1


func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento == "sem_combo=1":
			_sem_combo = true
		elif argumento.begins_with("perfil="):
			var pedido := argumento.trim_prefix("perfil=")
			# ⚠️ perfil desconhecido REPROVA em vez de cair no padrao em silencio: uma
			# medicao rotulada "ativo" que na verdade rodou "normal" e pior que nenhuma
			if not PERFIS.has(pedido):
				printerr("FALHA  perfil desconhecido: %s (ha %s)" % [
					pedido, ", ".join(PackedStringArray(PERFIS.keys())),
				])
				get_tree().quit(1)
				return
			_nome_do_perfil = pedido
	_perfil = PERFIS[_nome_do_perfil]
	# ⚠️ OS DOIS GERADORES, e nao so um. Eventos tem gerador proprio e tambem chama
	# randomize() no _ready: semear so Descobertas deixaria metade da aleatoriedade solta,
	# e a regua voltaria a nao ser deterministica -- so que agora com um motivo a menos
	# para alguem desconfiar, porque "a semente esta la".
	Descobertas.gerador.seed = SEMENTE_DO_SORTEIO
	Eventos.gerador.seed = SEMENTE_DO_SORTEIO
	Eventos.limpar()
	_zerar_a_partida()

	var tempos := {}
	var producoes := {}
	var ouvinte := func(marco: DadosMarco) -> void:
		tempos[marco.id] = Jogo.tempo_jogado
		producoes[marco.id] = Jogo.caracteres_por_segundo
	EventBus.marco_alcancado.connect(ouvinte)

	# ⚠️ OS TRES OUVINTES DA ISSUE #56. A regua media SO marco ate aqui, e a versao se
	# chama "A primeira hora": sem saber quando o jogador compra e quando ele DESCOBRE,
	# metade do que acontece na primeira hora era invisivel para quem ajusta os numeros.
	# ⚠️ A PRIMEIRA COMPRA, e nao a ultima. Desde que o jogador simulado passou a prestigiar
	# (issue #59), ele REcompra tudo a cada run -- e guardar `upgrades[id] = agora` sem
	# guarda sobrescreve o instante original pelo da ultima recompra.
	#
	# Isso nao da erro: a tabela sai coerente, com 1 upgrade na primeira hora em vez de 44,
	# e a leitura seria "a curva foi consertada". O defeito era da regua, e nao do jogo.
	var upgrades := {}
	var ouvinte_upgrade := func(id: String) -> void:
		if not upgrades.has(id):
			upgrades[id] = Jogo.tempo_jogado
	EventBus.upgrade_comprado.connect(ouvinte_upgrade)

	# a PRIMEIRA de cada categoria, e nao todas: o que conta e quando a faixa comeca a
	# sair, que e a pergunta que a issue #52 deixou aberta
	var primeira_da_categoria := {}
	var ouvinte_descoberta := func(descoberta: DadosDescoberta) -> void:
		if not primeira_da_categoria.has(descoberta.categoria):
			primeira_da_categoria[descoberta.categoria] = [
				Jogo.tempo_jogado, descoberta.id,
			]
	EventBus.descoberta_encontrada.connect(ouvinte_descoberta)

	var teorema_disponivel := -1.0
	var teorema_vale := -1.0
	var prestigios: Array[float] = []

	var relogio := 0.0
	var ate_comprar := 0.0
	while relogio < LIMITE_SEGUNDOS and Marcos.proximo() != null:
		if _vale_a_pena_digitar():
			var quantos := int(float(_perfil["cliques_por_segundo"]) * PASSO)
			if quantos > 0:
				Economia.digitar(quantos)
			if _sem_combo:
				Combo._zerar()
		if bool(_perfil["resolve_eventos"]):
			# ele so encerra o que da para encerrar com clique; o resto espera o relogio
			for id in Eventos.ativos():
				Eventos.resolver(str(id))
		Economia.acumular(PASSO)
		# ⚠️ NA MESMA ORDEM DA PARTIDA (src/cena/partida.gd): eventos antes de automacao.
		# Ordem diferente aqui mediria um jogo que ninguem joga.
		Eventos.tique(PASSO)
		Automacao.tique(PASSO)
		Marcos.verificar()

		# ⚠️ CURTO-CIRCUITO, e nao uma amostragem mais rala. pode_provar() faz um log10
		# sobre Grande, e a versao ingenua o chamava DUAS vezes por passo, 172 mil vezes --
		# a regua ficou duas vezes mais lenta antes de alguem ligar as duas coisas.
		#
		# A conta e feita uma vez por passo e para de vez assim que a resposta e conhecida,
		# o que acontece aos 3 min de 24 h: 99,7% do laco nem entra aqui. O RESULTADO e
		# identico ao da versao ingenua -- medir mais raro mudaria os numeros, e isso nao
		# seria otimizar, seria medir outra coisa.
		if teorema_vale < 0.0:
			var pode := Teoremas.pode_provar()
			if pode and teorema_disponivel < 0.0:
				teorema_disponivel = Jogo.tempo_jogado
			if pode and _o_teorema_dobra_a_producao():
				teorema_vale = Jogo.tempo_jogado

		ate_comprar -= PASSO
		if ate_comprar <= 0.0:
			ate_comprar = INTERVALO_DE_COMPRA + float(_perfil["atraso_de_compra"])
			_comprar_o_que_der()
			if _hora_de_prestigiar():
				prestigios.append(Jogo.tempo_jogado)
				Teoremas.provar()
				_gastar_os_pontos()
		relogio += PASSO

	EventBus.marco_alcancado.disconnect(ouvinte)
	EventBus.upgrade_comprado.disconnect(ouvinte_upgrade)
	EventBus.descoberta_encontrada.disconnect(ouvinte_descoberta)
	_imprimir(tempos, producoes, relogio)
	_prestigios = prestigios
	_imprimir_a_primeira_hora(tempos, upgrades, primeira_da_categoria,
		teorema_disponivel, teorema_vale)
	get_tree().quit(0)


## ⚠️ O CONSERTO DO MODELO QUE A ISSUE #54 ACHOU.
##
## Ate aqui o jogador simulado parava de digitar no INSTANTE em que a producao automatica
## acendia -- e nos primeiros minutos clicar a 4/s rende MUITO mais que a automacao
## recem-ligada. O efeito media a ingenuidade do modelo e nao o jogo: o combo, por fazer a
## primeira compra chegar um segundo antes, aparecia como 37 segundos de ATRASO na
## campanha inteira.
##
## A regra nova nao tem numero magico e nao precisa de nenhum: ele digita enquanto digitar
## render mais do que esperar. E o mesmo criterio de "compra otima ingenua" aplicado a mao,
## e ele se desliga sozinho quando o jogador vira administrador -- que e exatamente o arco
## que o plano da v0.6 descreve.
##
## ⚠️ TABELA MEDIDA ANTES DESTA MUDANCA NAO SE COMPARA COM AS NOVAS. Ver TUNING.md.
func _vale_a_pena_digitar() -> bool:
	if not Economia.producao_automatica():
		return true
	if not bool(_perfil["digita_depois_da_automacao"]):
		return false
	var da_mao := Grande.de_float(
		float(_perfil["cliques_por_segundo"]) * Combo.multiplicador()
	)
	return da_mao.maior_que(Economia.producao_por_segundo())


## O primeiro Teorema "vale a pena" quando provar multiplica a producao por pelo menos o
## DOBRO. Disponivel e vale a pena sao coisas diferentes: pode_provar() abre com um ponto
## so, e um ponto so nao compensa perder a run.
##
## O numero mora aqui e nao num .tres de proposito: e um criterio de LEITURA da regua, e
## nao um botao do jogo. Regua nao aprova nem reprova -- ela mede, e este e o limiar a
## partir do qual ela conta a historia.
const DOBRO: float = 2.0


## Chamado so quando pode_provar() ja deu verdadeiro -- por isso nao repete a pergunta.
func _o_teorema_dobra_a_producao() -> bool:
	var agora := Teoremas.multiplicador()
	if agora <= 0.0:
		return false
	return Teoremas.multiplicador_se_provar() / agora >= DOBRO


## ⚠️ QUANDO O JOGADOR SIMULADO PRESTIGIA (issue #59). Ate aqui ele NUNCA prestigiava, e
## isso nao era uma decisao -- era a ausencia de uma. A regua media uma campanha em que o
## sistema central da progressao de longo prazo simplesmente nao existia.
##
## A politica declarada: ele prestigia quando provar DOBRA a producao. E o mesmo criterio
## de "vale a pena" que a tabela da primeira hora ja reportava -- agora ele tambem AGE.
##
## Prestigiar nao apaga marco: total_caracteres nunca desce, e e ele que o Panorama le. O
## que volta ao comeco e a run -- dinheiro, macacos, upgrades.
func _hora_de_prestigiar() -> bool:
	return Teoremas.pode_provar() and _o_teorema_dobra_a_producao()


## Depois de prestigiar, gasta o que der na Arvore -- do mais barato para o mais caro.
##
## ⚠️ SEM ISTO O PRESTIGIO SERIA SO PERDA. O jogador recebe pontos e nao compra nada com
## eles: a run nova comeca sem os upgrades, sem os macacos e sem nenhum no da Arvore, e a
## regua mediria uma jogada que nenhum humano faria duas vezes.
func _gastar_os_pontos() -> void:
	var comprou := true
	while comprou:
		comprou = false
		var candidatos: Array[DadosTeorema] = []
		for no in Teoremas.nos():
			if Teoremas.pode_comprar(no.id):
				candidatos.append(no)
		candidatos.sort_custom(func(a: DadosTeorema, b: DadosTeorema) -> bool:
			return Teoremas.custo_do_proximo(b.id).maior_que(Teoremas.custo_do_proximo(a.id)))
		for no in candidatos:
			if Teoremas.comprar(no.id):
				comprou = true
				break


## A compra otima ingenua: upgrade primeiro, porque multiplicador vale para sempre e o
## macaco seguinte so vale por si; depois automacao, depois o maximo de macacos que couber.
##
## ⚠️ A AUTOMACAO ENTRA NA COMPRA (issue #59). Ela nao e producao bruta, e conveniencia --
## mas conveniencia que compra macaco sozinha muda o ritmo, e a regua nao pode fingir que
## o jogador ignora um sistema inteiro que esta na tela dele.
func _comprar_o_que_der() -> void:
	for dados in Economia.upgrades():
		Economia.comprar_upgrade(dados.id)
	for automacao in Automacao.todas():
		Automacao.comprar(automacao.id)
	var proxima := Economia.proxima_maquina()
	if proxima != null:
		Economia.comprar_maquina(proxima.id)
	var sala := Economia.proxima_sala()
	if sala != null:
		Economia.expandir_sala(sala.id)
	var cabem := Economia.macacos_que_cabem()
	if cabem > 0:
		Economia.comprar_macacos(cabem)


## Parte de partida nova. A regua nao le nem escreve save: ela mede a curva do zero, que e
## a unica medicao que da para comparar entre duas sessoes de tuning.
func _zerar_a_partida() -> void:
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.fragmentos = Grande.zero()
	Jogo.multiplicador_global = 1.0
	Jogo.tempo_jogado = 0.0
	Jogo.tempo_da_run = 0.0
	Jogo.recorde_por_segundo = Grande.zero()
	Jogo.macacos_comprados = Grande.zero()
	Jogo.total_offline = Grande.zero()
	Jogo.prestigios = 0
	Jogo.pontos_totais = Grande.zero()
	Jogo.recorde_de_total = Grande.zero()
	Jogo.teoremas = {}
	Jogo.automacoes = {}
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]


## A SEGUNDA TABELA: o que acontece na PRIMEIRA HORA, que e o nome da versao.
##
## Ela e separada da primeira de proposito. A tabela de marcos e a curva inteira, de 24
## horas; esta responde outra pergunta -- "a primeira hora tem acontecimento denso?" --, e
## misturar as duas daria uma so que nao responde nenhuma direito.
##
## ⚠️ REGUA NAO APROVA NEM REPROVA. Nada aqui diz "bom" ou "ruim": ela conta QUANTOS
## acontecimentos caem em cada faixa de dez minutos e QUANDO cada coisa comeca. A decisao
## sobre os numeros e de quem le.
func _imprimir_a_primeira_hora(
	marcos: Dictionary, upgrades: Dictionary, descobertas: Dictionary,
	teorema_disponivel: float, teorema_vale: float
) -> void:
	print("")
	print("──── a primeira hora ────")
	print("")

	# quantos acontecimentos por faixa de dez minutos. E a medida mais direta de
	# "densidade", que e a palavra que o plano da v0.6 usa.
	var faixas := [600.0, 1200.0, 1800.0, 2400.0, 3000.0, 3600.0]
	print("%-14s %8s %10s %12s" % ["ate", "marcos", "upgrades", "descobertas"])
	print("%-14s %8s %10s %12s" % ["-".repeat(14), "-".repeat(8), "-".repeat(10), "-".repeat(12)])
	var anterior := 0.0
	for limite in faixas:
		print("%-14s %8d %10d %12d" % [
			_como_tempo(limite),
			_quantos_entre(marcos.values(), anterior, limite),
			_quantos_entre(upgrades.values(), anterior, limite),
			_quantos_primeiros_entre(descobertas, anterior, limite),
		])
		anterior = limite

	print("")
	print("upgrades da primeira hora, por familia:")
	var por_familia := {}
	for id in upgrades:
		if float(upgrades[id]) > 3600.0:
			continue
		var dados := Economia.upgrade_de(id)
		if dados == null:
			continue
		var familia: int = dados.familia
		if not por_familia.has(familia):
			por_familia[familia] = []
		por_familia[familia].append([float(upgrades[id]), id])
	for familia in DadosUpgrade.Familia.values():
		if not por_familia.has(familia):
			continue
		var lista: Array = por_familia[familia]
		lista.sort()
		var nomes := PackedStringArray()
		for item in lista:
			nomes.append("%s %s" % [_como_tempo(float(item[0])), item[1]])
		print("  %-16s %d: %s" % [
			DadosUpgrade.NOMES_DE_FAMILIA[familia], lista.size(), ", ".join(nomes),
		])
	# ⚠️ familia sem NENHUM upgrade na primeira hora e um resultado, e nao um vazio: sem
	# esta linha, a familia ausente simplesmente nao apareceria e ninguem repararia
	for familia in DadosUpgrade.Familia.values():
		if familia == DadosUpgrade.Familia.SEM_FAMILIA or por_familia.has(familia):
			continue
		print("  %-16s 0: NENHUM na primeira hora" % DadosUpgrade.NOMES_DE_FAMILIA[familia])

	print("")
	print("a primeira descoberta de cada categoria:")
	for categoria in DadosDescoberta.Categoria.values():
		if descobertas.has(categoria):
			var dado: Array = descobertas[categoria]
			print("  %-14s %s  %s" % [
				DescobertasTela.NOMES_DE_CATEGORIA[categoria],
				_como_tempo(float(dado[0])), dado[1],
			])
		else:
			print("  %-14s NAO SAIU em 24 h" % DescobertasTela.NOMES_DE_CATEGORIA[categoria])

	print("")
	print("prestigios na medicao: %d" % _prestigios.size())
	for i in _prestigios.size():
		print("  %d.  %s" % [i + 1, _como_tempo(_prestigios[i])])
	if _prestigios.is_empty():
		print("  NENHUM -- o jogador simulado nunca achou que valia a pena")

	_imprimir_as_fontes()

	print("")
	print("o primeiro Teorema:")
	print("  disponivel      %s" % (
		"NUNCA" if teorema_disponivel < 0.0 else _como_tempo(teorema_disponivel)))
	print("  vale a pena     %s  (dobrar a producao)" % (
		"NUNCA" if teorema_vale < 0.0 else _como_tempo(teorema_vale)))


## A PRODUCAO DECOMPOSTA POR FONTE, no estado em que a medicao terminou (issue #71).
##
## ⚠️ ELA EXISTE PORQUE "producao = 8,4e17" NAO PERMITE PERGUNTAR DE ONDE VEIO. A v0.7
## gastou uma investigacao inteira separando os 38 multiplicadores dos upgrades -- o
## suspeito obvio -- e isso moveu o primeiro Teorema de 04:22 para 04:01. O numero estava
## nas descobertas, vinte e oito ordens de grandeza acima.
##
## ⚠️ E ELA SAI DA MESMA FORMULA que a producao: ha portao em teste_economia reconstruindo
## a producao a partir desta arvore. Fonte nova que entre na formula sem entrar aqui
## reprova.
func _imprimir_as_fontes() -> void:
	print("")
	print("──── a producao, por fonte ────")
	print("")
	print("%-30s %6s %s" % ["fonte", "tipo", "fator"])
	print("%-30s %6s %s" % ["-".repeat(30), "-".repeat(6), "-".repeat(20)])
	for fonte in Economia.producao_por_fonte():
		# ⚠️ IMPRIME O VALOR CRU ao lado do legivel. Formato humano e terminal, nunca fonte
		# de dados: o script de analise da v0.7 leu "64 bilhoes" como 64, e isso fez dois
		# instrumentos PARECEREM discordar em oito ordens de grandeza.
		var fator := float(fonte["fator"])
		print("%-30s %6s %-20s  %s" % [
			fonte["nome"], fonte["tipo"],
			Formatador.formatar(Grande.de_float(fator)), _cru(fator),
		])


## O numero cru, para quem le com maquina.
##
## ⚠️ var_to_str, e nao "%.17g": o `%` do GDScript NAO suporta %g, e a primeira versao disto
## imprimiu a propria marca de formato como se fosse o numero -- "base do macaco 1 %.17g".
## Um dado ilegivel que PARECE dado e o defeito que esta issue existe para impedir.
##
## var_to_str faz ida e volta pelo str_to_var, que e o que "cru" quer dizer aqui.
func _cru(valor: float) -> String:
	return var_to_str(valor)


## Quantos instantes de uma lista caem em (de, ate].
func _quantos_entre(instantes: Array, de: float, ate: float) -> int:
	var quantos := 0
	for instante in instantes:
		var t := float(instante)
		if t > de and t <= ate:
			quantos += 1
	return quantos


func _quantos_primeiros_entre(primeiras: Dictionary, de: float, ate: float) -> int:
	var quantos := 0
	for categoria in primeiras:
		var t := float((primeiras[categoria] as Array)[0])
		if t > de and t <= ate:
			quantos += 1
	return quantos


func _como_tempo(segundos: float) -> String:
	return "%02d:%02d:%02d" % [
		int(segundos) / 3600, (int(segundos) / 60) % 60, int(segundos) % 60,
	]


## Texto, e nao CSV nem JSON, porque a saida de uma regua serve para dar DIFF entre duas
## sessoes de tuning -- e diff de texto alinhado se le a olho nu.
func _imprimir(tempos: Dictionary, producoes: Dictionary, relogio: float) -> void:
	print("medir_ritmo -- passo %.1fs, compra a cada %.1fs, %.0f cliques/s ate a automacao" % [
		PASSO, INTERVALO_DE_COMPRA + float(_perfil["atraso_de_compra"]),
		float(_perfil["cliques_por_segundo"]),
	])
	print("perfil: %s  (digita depois da automacao: %s, resolve eventos: %s)" % [
		_nome_do_perfil,
		"sim" if bool(_perfil["digita_depois_da_automacao"]) else "NAO",
		"sim" if bool(_perfil["resolve_eventos"]) else "nao",
	])
	print("jogador simulado: compra otima ingenua (upgrade assim que da, depois macaco maximo)")
	print("combo de digitacao: %s" % ("DESLIGADO (sem_combo=1)" if _sem_combo else "ligado"))
	# ⚠️ E ELE PARA DE DIGITAR quando a producao automatica acende, que sao os primeiros
	# dez caracteres. O resto da campanha inteira roda sem um clique -- o que e, por si
	# so, a prova de que a progressao nao depende do combo.
	print("o jogador digita enquanto digitar render mais do que esperar")
	print("")
	print("%-22s %-12s %-14s %s" % ["marco", "tempo", "requisito", "cps no momento"])
	print("%-22s %-12s %-14s %s" % ["-".repeat(22), "-".repeat(12), "-".repeat(14), "-".repeat(14)])

	for marco in Marcos.todos():
		if tempos.has(marco.id):
			print("%-22s %-12s %-14s %s" % [
				marco.id,
				_relogio(tempos[marco.id]),
				Formatador.formatar(marco.requisito_grande()),
				Formatador.formatar(producoes[marco.id]),
			])
		else:
			print("%-22s %-12s %-14s %s" % [
				marco.id, "NAO ALCANCADO", Formatador.formatar(marco.requisito_grande()), "-",
			])

	print("")
	print("parou em %s com %s macacos, %s caracteres e %s/s" % [
		_relogio(relogio),
		Formatador.formatar(Jogo.macacos),
		Formatador.formatar(Jogo.total_caracteres),
		Formatador.formatar(Jogo.caracteres_por_segundo),
	])


static func _relogio(segundos: float) -> String:
	var inteiros := int(segundos)
	return "%02d:%02d:%02d" % [inteiros / 3600, (inteiros / 60) % 60, inteiros % 60]
