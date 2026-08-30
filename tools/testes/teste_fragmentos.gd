## Suite dos Fragmentos do Infinito (GDD §20).
##
## As duas afirmacoes que a issue #31 pede:
##
##   O CICLO COMPLETO -- teorema, fragmento, run nova -- NAO PERDE NADA QUE NAO DEVIA.
##   Este e o unico reset do jogo que apaga varias runs de trabalho de uma vez, e a
##   diferenca entre "apagou o que devia" e "apagou demais" e progresso de jogador.
##
##   A MIGRACAO DE SAVE. E aqui que save mal versionado destroi progresso de verdade: um
##   arquivo da versao 1 tem que abrir num jogo da versao 8 com tudo que ele guardava.
##
## Mais a regra que sustenta o sistema inteiro: TEM QUE EXISTIR MOTIVO CLARO PARA ACEITAR
## PERDER A ARVORE. Se o primeiro Fragmento nao muda a sensacao da run seguinte, o sistema
## nao esta pronto -- e a suite mede isso comparando a producao com a Arvore cheia contra
## a producao com um Fragmento e nenhuma Arvore.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_fragmentos_save.json"

func _init() -> void:
	nome = "Fragmentos"


func executar() -> void:
	_calculo()
	_o_que_se_perde_e_o_que_fica()
	_o_ciclo_completo()
	_vale_a_pena_perder_a_arvore()
	_migracao_de_save_antigo()


func _calculo() -> void:
	var guardado := _guardar()
	_zerar()

	ok(Fragmentos.ao_reescrever().e_zero(), "sem ponto de teorema nao ha Fragmento")
	ok(not Fragmentos.pode_reescrever(), "e nao da para reescrever o Universo")

	# fragmentos = log10(pontos_totais / limite): tres ordens de grandeza dao tres
	Jogo.pontos_totais = Grande.de_float(100.0).vezes(Grande.new(1.0, 3))
	_vale(Fragmentos.ao_reescrever(), 3.0, "tres ordens de grandeza dao tres Fragmentos")
	ok(Fragmentos.pode_reescrever(), "e ai da para reescrever")

	# le os pontos GANHOS e nao o saldo: gastar na Arvore e o jeito certo de jogar, e
	# cobrar por isso aqui puniria quem jogou direito
	Jogo.pontos_de_teorema = Grande.zero()
	_vale(Fragmentos.ao_reescrever(), 3.0, "gastar todos os pontos na Arvore nao muda nada")

	_devolver(guardado)


## A confirmacao precisa deixar explicito o que se perde, item por item -- e o que fica.
## Sem a segunda lista o jogador supoe que perde tudo e nunca aperta o botao.
func _o_que_se_perde_e_o_que_fica() -> void:
	ok(Fragmentos.o_que_se_perde().size() >= 3, "a lista do que se perde e item por item")
	ok(not Fragmentos.o_que_fica().is_empty(), "e existe lista do que fica")
	for texto in Fragmentos.o_que_se_perde():
		ok(not texto.strip_edges().is_empty(), "nenhum item da lista de perdas e vazio")
	for texto in Fragmentos.o_que_fica():
		ok(not texto.strip_edges().is_empty(), "nenhum item da lista do que fica e vazio")


func _o_ciclo_completo() -> void:
	var guardado := _guardar()
	_zerar()

	# uma run que ja provou o Teorema varias vezes e comprou na Arvore
	Jogo.total_caracteres = Grande.new(1.0, 30)
	Jogo.pontos_totais = Grande.de_float(1e6)
	Jogo.pontos_de_teorema = Grande.de_float(1e6)
	Jogo.prestigios = 7
	Jogo.marcos_alcancados = ["uma_pagina", "um_livro"] as Array[String]
	Jogo.macacos_comprados = Grande.de_float(4321.0)
	Jogo.recorde_por_segundo = Grande.new(9.9, 20)
	Jogo.total_offline = Grande.new(3.3, 15)
	Jogo.tempo_jogado = 99999.0
	Jogo.automacoes = {"gerente_macaco": true}
	Teoremas.comprar("memoria_genetica")
	Jogo.macacos = Grande.de_float(500.0)
	Jogo.maquina_atual = "maquina_eletrica"
	Jogo.sala_atual = "galpao"
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.descobertas = ["um_poema"] as Array[String]

	var reescritas: Array[Grande] = []
	var ouvinte := func(g: Grande) -> void: reescritas.append(g)
	EventBus.universo_reescrito.connect(ouvinte)
	var ganhos := Fragmentos.reescrever()
	EventBus.universo_reescrito.disconnect(ouvinte)

	ok(ganhos.sinal() > 0, "reescrever devolve Fragmentos")
	igual(reescritas.size(), 1, "e o EventBus avisou")
	ok(Jogo.fragmentos.igual_a(ganhos), "e eles entram no saldo")
	igual(Jogo.reescritas, 1, "e o contador de reescritas sobe")

	# o que se perde -- exatamente o que a lista promete
	ok(Jogo.pontos_de_teorema.e_zero(), "os Pontos de Teorema somem")
	ok(Jogo.pontos_totais.e_zero(), "inclusive os ganhos na vida")
	ok(Jogo.teoremas.is_empty(), "a Arvore inteira some")
	ok(Jogo.macacos.igual_a(Grande.um()), "os macacos voltam para um")
	igual(Jogo.maquina_atual, "", "a maquina volta para a do inicio")
	igual(Jogo.sala_atual, "", "e a sala tambem")
	ok(Jogo.upgrades_comprados.is_empty(), "os upgrades somem")
	ok(Jogo.descobertas.is_empty(), "e as descobertas desta run tambem")

	# o que fica -- e e aqui que "apagou demais" apareceria
	_exato(Jogo.total_caracteres, Grande.new(1.0, 30), "o total do Panorama nao desce")
	igual(Jogo.marcos_alcancados.size(), 2, "os marcos alcancados ficam")
	igual(Jogo.prestigios, 7, "o contador de prestigios nao zera")
	_exato(Jogo.macacos_comprados, Grande.de_float(4321.0), "macacos comprados na vida ficam")
	_exato(Jogo.recorde_por_segundo, Grande.new(9.9, 20), "o recorde fica")
	_exato(Jogo.total_offline, Grande.new(3.3, 15), "o offline acumulado fica")
	perto(Jogo.tempo_jogado, 99999.0, 1e-6, "o tempo total de jogo fica")
	ok(Jogo.automacoes.has("gerente_macaco"), "as automacoes compradas ficam")

	# reset acidental de reset e pior ainda que reset acidental
	_zerar()
	Jogo.macacos = Grande.de_float(77.0)
	ok(Fragmentos.reescrever().e_zero(), "reescrever sem Fragmento devolve zero")
	_vale(Jogo.macacos, 77.0, "e nao reinicia nada")

	_devolver(guardado)


## O motivo de aceitar perder a Arvore precisa ser visivel no numero, e nao so no texto.
func _vale_a_pena_perder_a_arvore() -> void:
	var guardado := _guardar()
	_zerar()

	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	Jogo.pontos_totais = Grande.de_float(1e5)
	# a Arvore gasta o SALDO; pontos_totais so alimenta o multiplicador
	Jogo.pontos_de_teorema = Grande.de_float(1e5)
	for volta in 30:
		for no in Teoremas.nos():
			Teoremas.comprar(no.id)
	ok(not Jogo.teoremas.is_empty(), "a Arvore foi comprada para a comparacao")
	var com_a_arvore := Economia.producao_por_segundo()

	Fragmentos.reescrever()
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	var com_um_fragmento := Economia.producao_por_segundo()

	ok(Jogo.teoremas.is_empty(), "a Arvore realmente sumiu")
	ok(
		com_um_fragmento.maior_que(com_a_arvore),
		"e mesmo assim a run nova rende mais: %s contra %s" % [
			com_um_fragmento.para_texto(), com_a_arvore.para_texto(),
		],
	)

	_devolver(guardado)


## Um save da versao 1 tem que abrir num jogo da versao 8 sem perder o que ele guardava.
## Este e o teste que a issue #31 pede antes de mergear, e o motivo e direto: aqui e onde
## save mal versionado destroi progresso de verdade.
func _migracao_de_save_antigo() -> void:
	var guardado := _guardar()
	var caminho_original := Save.caminho
	Save.caminho = CAMINHO_DE_TESTE
	Save.apagar()

	# exatamente a forma da versao 1: sem maquina_atual, sem sala, sem descobertas, sem
	# teoremas, sem automacoes, sem fragmentos
	var antigo := {
		"versao": 1,
		"gravado_em": 1000.0,
		"total_caracteres": "1.5e25",
		"caracteres_da_run": "1.5e25",
		"dinheiro": "3e20",
		"macacos": "8765",
		"maquinas": "12",
		"pontos_de_teorema": "42",
		"fragmentos": "0",
		"multiplicador_global": 3.5,
		"tempo_jogado": 54321.0,
		"upgrades_comprados": ["instinto_digitador", "duas_maos"],
		"marcos_alcancados": ["uma_pagina", "um_livro", "uma_estante"],
	}
	var arquivo := FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(antigo))
	arquivo.close()

	_zerar()
	ok(Save.carregar() > 0.0, "o save da versao 1 carrega num jogo da versao 8")

	# nada que ele guardava se perdeu
	_exato(Jogo.total_caracteres, Grande.new(1.5, 25), "o total sobreviveu a sete versoes")
	_exato(Jogo.dinheiro, Grande.new(3.0, 20), "o dinheiro tambem")
	_exato(Jogo.macacos, Grande.de_float(8765.0), "e a contagem de macacos")
	_exato(Jogo.pontos_de_teorema, Grande.de_float(42.0), "e os Pontos de Teorema")
	perto(Jogo.multiplicador_global, 3.5, 0.0, "e o multiplicador global")
	perto(Jogo.tempo_jogado, 54321.0, 1e-6, "e o tempo jogado")
	igual(Jogo.upgrades_comprados.size(), 2, "e os upgrades comprados")
	igual(Jogo.marcos_alcancados.size(), 3, "e os marcos alcancados")

	# e o que ele nao conhecia veio com o padrao de partida nova, e nao com lixo
	igual(Jogo.maquina_atual, "", "campo que nao existia na versao 1 vem vazio")
	igual(Jogo.sala_atual, "", "e a sala tambem")
	ok(Jogo.descobertas.is_empty(), "e as descobertas vem vazias")
	ok(Jogo.teoremas.is_empty(), "e a Arvore tambem")
	ok(Jogo.automacoes.is_empty(), "e as automacoes")
	igual(Jogo.reescritas, 0, "e o contador de reescritas comeca em zero")
	ok(Jogo.fragmentos.e_zero(), "e os Fragmentos em zero")

	# e regravar sobe o arquivo para a versao atual
	ok(Save.gravar(), "grava por cima do migrado")
	var relido = JSON.parse_string(FileAccess.open(CAMINHO_DE_TESTE, FileAccess.READ).get_as_text())
	igual(int(relido["versao"]), Save.VERSAO, "e o arquivo passa a ser da versao atual")

	Save.apagar()
	Save.caminho = caminho_original
	_devolver(guardado)


func _vale(obtido: Grande, esperado: float, descricao: String) -> void:
	perto(obtido.para_float(), esperado, absf(esperado) * 1e-9 + 1e-9, descricao)


func _exato(obtido: Grande, esperado: Grande, descricao: String) -> void:
	igual(obtido.para_texto(), esperado.para_texto(), descricao)


func _zerar() -> void:
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.multiplicador_global = 1.0
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.pontos_totais = Grande.zero()
	Jogo.fragmentos = Grande.zero()
	Jogo.recorde_de_total = Grande.zero()
	Jogo.recorde_por_segundo = Grande.zero()
	Jogo.macacos_comprados = Grande.zero()
	Jogo.total_offline = Grande.zero()
	Jogo.prestigios = 0
	Jogo.reescritas = 0
	Jogo.tempo_jogado = 0.0
	Jogo.tempo_da_run = 0.0
	Jogo.teoremas = {}
	Jogo.automacoes = {}
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]


func _guardar() -> Dictionary:
	var estado := {}
	for campo in [
		"total_caracteres", "caracteres_da_run", "caracteres_por_segundo", "dinheiro",
		"macacos", "maquina_atual", "sala_atual", "multiplicador_global",
		"pontos_de_teorema", "pontos_totais", "fragmentos", "recorde_de_total",
		"recorde_por_segundo", "macacos_comprados", "total_offline", "prestigios",
		"reescritas", "tempo_jogado", "tempo_da_run",
	]:
		estado[campo] = Jogo.get(campo)
	for campo in ["teoremas", "automacoes"]:
		estado[campo] = Jogo.get(campo).duplicate()
	for campo in ["upgrades_comprados", "descobertas", "marcos_alcancados"]:
		estado[campo] = Jogo.get(campo).duplicate()
	return estado


func _devolver(estado: Dictionary) -> void:
	for campo in estado:
		Jogo.set(campo, estado[campo])
