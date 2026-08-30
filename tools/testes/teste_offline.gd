## Suite da producao offline: as quatro fronteiras do relogio (GDD §38).
##
## Toda afirmacao aqui existe porque o relogio e INJETADO. Se a conta lesse Time por
## dentro, testar "exatamente 4 horas" exigiria esperar 4 horas -- e a fronteira do teto,
## que e o unico ponto interessante da conta, nunca seria testada.
##
##   1 h        passa inteiro
##   4 h        exatamente o teto, ainda passa inteiro
##   100 h      bate no teto e vira 4 h
##   negativo   vira zero, sem punir ninguem
extends TesteBase

const HORA: float = 3600.0
const TETO: float = 4.0 * HORA

func _init() -> void:
	nome = "producao offline"


func executar() -> void:
	_segundos_creditados()
	_producao()
	_creditar_de_verdade()


func _segundos_creditados() -> void:
	perto(
		ProgressoOffline.segundos_creditados(HORA, TETO), HORA, 0.0,
		"1 h fica em 1 h",
	)
	# a fronteira exata: um <= trocado por < aqui roubaria um segundo de todo mundo
	perto(
		ProgressoOffline.segundos_creditados(TETO, TETO), TETO, 0.0,
		"exatamente 4 h ainda passa inteiro",
	)
	perto(
		ProgressoOffline.segundos_creditados(TETO + 1.0, TETO), TETO, 0.0,
		"um segundo alem do teto ja e cortado",
	)
	perto(
		ProgressoOffline.segundos_creditados(100.0 * HORA, TETO), TETO, 0.0,
		"100 h batem no teto de 4 h",
	)

	# relogio do sistema para tras acontece de verdade: fuso, horario de verao, maquina
	# com a hora errada. Vira zero em vez de descontar producao de quem nao fez nada.
	perto(
		ProgressoOffline.segundos_creditados(-500.0, TETO), 0.0, 0.0,
		"tempo negativo vira zero",
	)
	perto(ProgressoOffline.segundos_creditados(0.0, TETO), 0.0, 0.0, "zero continua zero")
	perto(ProgressoOffline.segundos_creditados(NAN, TETO), 0.0, 0.0, "NAN vira zero")

	# teto zero e o ultimo degrau dos upgrades do GDD §38, e nao um caso de erro
	perto(
		ProgressoOffline.segundos_creditados(100.0 * HORA, 0.0), 100.0 * HORA, 0.0,
		"teto zero significa sem limite",
	)


func _producao() -> void:
	var cps := Grande.de_float(30.0)
	perto(
		ProgressoOffline.producao(cps, HORA).para_float(), 108000.0, 1e-6,
		"30/s durante 1 h dao 108 mil",
	)
	ok(ProgressoOffline.producao(cps, 0.0).e_zero(), "zero segundo nao produz")
	ok(ProgressoOffline.producao(cps, -10.0).e_zero(), "tempo negativo nao produz")
	ok(ProgressoOffline.producao(Grande.zero(), HORA).e_zero(), "sem producao, nada offline")

	# e o caso que a conta existe para aguentar: 4 h de producao no fim do jogo nao cabem
	# em float nem de longe
	var enorme := Grande.new(1.0, 200)
	var produzido := ProgressoOffline.producao(enorme, TETO)
	igual(produzido.expoente, 204, "producao gigante nao satura")


## A ponta que liga tudo: creditar de verdade tem que passar pelo mesmo acumulador do
## clique e do quadro, e avisar quem vai mostrar a tela de volta.
func _creditar_de_verdade() -> void:
	var guardado := {
		"total": Jogo.total_caracteres,
		"run": Jogo.caracteres_da_run,
		"dinheiro": Jogo.dinheiro,
		"macacos": Jogo.macacos,
		"tempo": Jogo.tempo_jogado,
		"upgrades": Jogo.upgrades_comprados.duplicate(),
	}

	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.tempo_jogado = 0.0
	Jogo.macacos = Grande.de_float(10.0)
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]

	var avisos: Array = []
	var ouvinte := func(produzido: Grande, segundos: float) -> void:
		avisos.append([produzido, segundos])
	EventBus.voltou_do_offline.connect(ouvinte)

	var por_segundo := Economia.producao_por_segundo()
	var creditado := Economia.creditar_offline(HORA)
	ok(creditado.igual_a(por_segundo.vezes(Grande.de_float(HORA))), "creditou uma hora de producao")
	ok(Jogo.total_caracteres.igual_a(creditado), "e entrou no total")
	ok(Jogo.dinheiro.igual_a(creditado), "e no dinheiro, um caractere por moeda")
	perto(Jogo.tempo_jogado, HORA, 1e-6, "e o relogio da partida andou junto")
	igual(avisos.size(), 1, "avisou quem vai mostrar a tela de volta")

	# fora por mais que o teto: credita o teto, e o aviso diz quantos segundos contaram
	Jogo.total_caracteres = Grande.zero()
	Economia.creditar_offline(100.0 * HORA)
	ok(
		Jogo.total_caracteres.igual_a(por_segundo.vezes(Grande.de_float(Economia.teto_offline_segundos()))),
		"cem horas fora creditam so o teto",
	)
	igual(avisos.size(), 2, "e avisou de novo")
	perto(avisos[1][1], Economia.teto_offline_segundos(), 1e-6, "com os segundos que contaram")

	# volta sem tempo nenhum: nao credita, mas AVISA, para a tela saber que a conta foi
	# feita e decidir nao aparecer
	Jogo.total_caracteres = Grande.zero()
	ok(Economia.creditar_offline(-1.0).e_zero(), "voltar com relogio para tras nao credita")
	ok(Jogo.total_caracteres.e_zero(), "e nao mexe no total")
	igual(avisos.size(), 3, "e mesmo assim avisa")

	EventBus.voltou_do_offline.disconnect(ouvinte)
	ok(Economia.teto_offline_segundos() > 0.0, "o teto veio do .tres e nao do codigo")

	Jogo.total_caracteres = guardado["total"]
	Jogo.caracteres_da_run = guardado["run"]
	Jogo.dinheiro = guardado["dinheiro"]
	Jogo.macacos = guardado["macacos"]
	Jogo.tempo_jogado = guardado["tempo"]
	Jogo.upgrades_comprados = guardado["upgrades"]
