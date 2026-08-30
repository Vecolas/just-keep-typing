## Reescrever o Universo: o segundo prestigio (GDD §20).
##
##   fragmentos = log10(pontos_de_teorema_ganhos_na_vida / limite_inicial)
##
## ⚠️ E O RESET DO RESET. Ele sacrifica os Pontos de Teorema, a Arvore inteira e a run --
## tudo que o primeiro prestigio construiu ao longo de varias runs. Por isso a lista do que
## se perde e PUBLICA e item por item: uma confirmacao que diz "isto reinicia bastante
## coisa" nao e confirmacao, e um susto adiado.
##
## ⚠️ TEM QUE EXISTIR MOTIVO CLARO PARA ACEITAR PERDER A ARVORE. O ganho por Fragmento e
## grande de proposito: se o primeiro nao muda a sensacao da run seguinte, o sistema nao
## esta pronto (issue #31). A suite afirma que um Fragmento sozinho ja rende mais que a
## arvore inteira que ele custou.
##
## O QUE SOBREVIVE E O QUE E REGISTRO, e nao poder: total de caracteres, marcos do
## Panorama, recordes, estatisticas de vida e as automacoes ja compradas. Apagar o Panorama
## seria apagar a memoria do jogador, e o Panorama e a unica tela que nao e loja.
extends Node

const CAMINHO := "res://data/fragmentos.tres"

var _dados: DadosFragmentos = null


func _ready() -> void:
	_dados = ResourceLoader.load(CAMINHO) as DadosFragmentos
	if _dados == null:
		push_error("Fragmentos: %s nao carregou" % CAMINHO)


## Quantos Fragmentos o jogador levaria se reescrevesse o Universo agora.
##
## Le os pontos GANHOS na vida e nao o saldo: gastar na Arvore e o caminho certo de jogar,
## e cobrar por isso na hora do segundo prestigio puniria quem jogou direito.
func ao_reescrever() -> Grande:
	if _dados == null or _dados.limite_inicial <= 0.0:
		return Grande.zero()
	var limite := Grande.de_float(_dados.limite_inicial)
	if not Jogo.pontos_totais.maior_que(limite):
		return Grande.zero()
	return Grande.de_float(floorf(Jogo.pontos_totais.dividido(limite).log10()))


func pode_reescrever() -> bool:
	if _dados == null:
		return false
	return not ao_reescrever().menor_que(Grande.de_float(_dados.minimo))


## O multiplicador dos Fragmentos ja ganhados. Cresce por POTENCIA e nao por soma: o GDD
## §20 pede bonus extremamente grandes, e soma nao e extremamente grande.
func multiplicador() -> float:
	if _dados == null or Jogo.fragmentos.sinal() <= 0:
		return 1.0
	return pow(_dados.ganho_por_fragmento, Jogo.fragmentos.para_float())


## O que se perde, item por item, em chave de traducao. A tela lista isto -- e a lista mora
## aqui e nao la porque ela e a verdade sobre o que reescrever() faz, e nao um texto
## decorativo: mudar o reset sem mudar a lista tem que ser desconfortavel.
func o_que_se_perde() -> PackedStringArray:
	return [
		"Todos os Pontos de Teorema",
		"A Árvore de Teoremas inteira",
		"Macacos, máquinas, salas e upgrades",
		"As descobertas desta run",
	]


## O que fica. Tao importante de dizer quanto o que se perde: sem esta lista o jogador
## supoe que perde tudo, e nunca aperta o botao.
func o_que_fica() -> PackedStringArray:
	return [
		"O total de caracteres e o Panorama",
		"As estatísticas de sempre",
		"As automações já compradas",
		"Os Fragmentos do Infinito",
	]


## Reescreve o Universo e devolve os Fragmentos ganhos. Zero e nada acontece quando nao da:
## reset de reset acidental e pior ainda que reset acidental.
func reescrever() -> Grande:
	if not pode_reescrever():
		return Grande.zero()
	var ganhos := ao_reescrever()
	Jogo.fragmentos = Jogo.fragmentos.mais(ganhos)
	Jogo.reescritas += 1

	# tudo que o primeiro prestigio construiu
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.pontos_totais = Grande.zero()
	Jogo.teoremas = {}

	# e a run, como no primeiro prestigio
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.tempo_da_run = 0.0
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]

	EventBus.universo_reescrito.emit(ganhos)
	return ganhos
