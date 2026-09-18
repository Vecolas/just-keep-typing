## Os barramentos de audio e os sons do jogo (issue #42).
##
## ⚠️ O AUDIO E UMA REPRESENTACAO DA ATIVIDADE, E NUNCA UM CONTADOR. No fim do jogo sao
## 10^50 caracteres por segundo: um som por caractere produzido nao e "alto demais", e
## impossivel -- e a mesma regra do GDD §10 que proibe gerar os caracteres de verdade,
## aplicada ao ouvido. A taxa de CLACK sobe com a producao e SATURA num teto que e
## constante: ele nao sai de conta nenhuma sobre quanto o jogador produz.
##
## ⚠️ OS BARRAMENTOS SAO CRIADOS AQUI, e nao num default_bus_layout.tres. O .tres seria um
## arquivo reescrito pela ferramenta -- hostil a merge, sem espaco para comentario, e a
## decisao de por que Interface e separada de Efeitos moraria fora dele de qualquer jeito.
## Em codigo, a tabela E a documentacao.
##
## ⚠️ ESTE AUTOLOAD VEM ANTES DO Config. Config._aplicar_audio() ajusta o volume de cada
## barramento na abertura, e barramento que ainda nao existe nao tem volume para ajustar --
## quem vem depois PUXA o que precisa (docs/ARQUITETURA.md). Por isso aqui nada le o Config
## no _ready: a leitura acontece quando o Config pede.
##
## ⚠️ NADA ALOCA POR SOM TOCADO. As formas de onda sao construidas UMA vez e os tocadores
## sao uma piscina fixa, em rodizio. Som que aloca por evento aparece na medir_quadro, e a
## regra veio de la.
extends Node

## Os cinco barramentos do plano do menu §18. Master ja existe e e o indice 0; os outros
## quatro sao criados aqui e mandam para ele.
##
## `campo` e a opcao do Config que controla o volume daquele barramento. Vazio significa
## que o barramento ainda NAO TEM FONTE nenhuma -- ver SEM_FONTE_AINDA.
##
## ⚠️ Interface e separada de Efeitos de proposito: este jogo vai ter muito clique, clack e
## ding, e os dois no mesmo controle viram irritante em vinte minutos.
const BARRAMENTOS: Array[Dictionary] = [
	{"nome": &"Master", "campo": "volume"},
	{"nome": &"Musica", "campo": ""},
	{"nome": &"Efeitos", "campo": "volume_efeitos"},
	{"nome": &"Interface", "campo": "volume_interface"},
	{"nome": &"Ambiente", "campo": ""},
]

## ⚠️ DIVIDA DECLARADA, e nao esquecimento. Barramento que ainda nao tem nada tocando nele
## NAO ganha barra de volume: controle que nao faz nada e parece que faz e controle que a
## pessoa mexe e conclui que o jogo ignorou (a mesma regra da resolucao apagada em tela
## cheia, issue #34).
##
## A lista morde dos DOIS lados no teste_audio: nome que nao esta aqui tem que ter campo, e
## nome que esta aqui tem que continuar SEM campo. Sem a segunda metade, esta linha
## passaria a cobrir em silencio o dia em que a musica chegasse e ninguem pudesse
## controla-la.
##
##   Musica    entra com a trilha do menu
##   Ambiente  entra com o menu vivo (issue #48): poeira, estrelas, o zumbido da sala
const SEM_FONTE_AINDA: Array[StringName] = [&"Musica", &"Ambiente"]

## ⚠️ O TETO, e ele e CONSTANTE. Dez CLACKs por segundo e o limite de design do ouvido --
## acima disso o som deixa de ser digitacao e vira chuvisco. Ele nao depende da producao,
## e e essa independencia que a suite afirma.
const CLACKS_POR_SEGUNDO_NO_TETO: float = 10.0

## Quantas ordens de grandeza de producao levam do silencio ao teto. Seis: um milhao de
## caracteres por segundo ja e a maquina a todo vapor, e o resto do jogo -- mais quarenta e
## quatro ordens de grandeza -- soa igual, de proposito.
const ORDENS_ATE_O_TETO: float = 6.0

## Quantos tocadores de efeito ao mesmo tempo. Com o teto em dez por segundo e o CLACK
## durando menos de um decimo, seis sobram -- e o rodizio nunca corta um som pela metade.
const TOCADORES: int = 6

## ⚠️ TETO DE ATRASO ACUMULADO. Quando o jogo volta de uma pausa longa -- alt-tab, ponto de
## interrupcao -- o delta chega inteiro de uma vez. Sem este limite, a volta dispararia uma
## rajada de CLACKs de tudo que "deveria" ter tocado enquanto ninguem ouvia.
const ATRASO_MAXIMO: float = 0.25

## A forma de onda de cada som de digitacao. Timbre novo e uma entrada aqui mais um valor
## em Config; nenhuma linha de codigo muda.
##
##   duracao      segundos da amostra
##   frequencia   o "thunk" grave por baixo do estalo
##   ruido        quanto do som e estalo (1.0) e quanto e tom (0.0)
##   decaimento   quao rapido ele morre. Maior = mais seco
##   volume       amplitude, de 0 a 1
const TIMBRES: Dictionary = {
	"normal": {
		"duracao": 0.06, "frequencia": 220.0, "ruido": 0.70,
		"decaimento": 60.0, "volume": 0.55,
	},
	"suave": {
		"duracao": 0.05, "frequencia": 160.0, "ruido": 0.35,
		"decaimento": 90.0, "volume": 0.35,
	},
	"mecanico": {
		"duracao": 0.09, "frequencia": 320.0, "ruido": 0.90,
		"decaimento": 38.0, "volume": 0.70,
	},
}

## Som de interface: mais curto e mais agudo que o CLACK, para nao se confundir com ele.
const TIMBRE_DE_INTERFACE: Dictionary = {
	"duracao": 0.035, "frequencia": 900.0, "ruido": 0.55,
	"decaimento": 140.0, "volume": 0.30,
}

## Taxa de amostragem das formas de onda. Baixa de proposito: sao estalos de um decimo de
## segundo, e 22 kHz e metade da memoria de 44 kHz sem diferenca audivel num clack.
const AMOSTRAGEM: int = 22050

## ⚠️ SEMENTE FIXA. O ruido e sorteado uma vez, na construcao da onda -- com semente do
## relogio, duas aberturas do jogo teriam CLACKs diferentes e qualquer medicao futura
## deixaria de ser comparavel consigo mesma.
const SEMENTE_DO_RUIDO: int = 20260917

## Variacao de tom entre um CLACK e o seguinte. Sem ela, dez por segundo viram metralhadora
## em vez de maquina de escrever.
const VARIACAO_DE_TOM: float = 0.12

var _ondas: Dictionary = {}
var _onda_de_interface: AudioStreamWAV = null
var _tocadores: Array[AudioStreamPlayer] = []
var _tocador_de_interface: Array[AudioStreamPlayer] = []
var _proximo: int = 0
var _proximo_de_interface: int = 0
var _ate_o_clack: float = 0.0
var _sorteio := RandomNumberGenerator.new()


func _ready() -> void:
	_criar_barramentos()
	_construir_ondas()
	_montar_tocadores()
	# ⚠️ UM LUGAR SO LIGA O SOM DE INTERFACE. A alternativa era cada tela conectar o proprio
	# clique, e espalhar esse par por seis telas e garantir que a setima nasca muda -- sem
	# erro nenhum, so em silencio. Aqui todo Button que entra na arvore ganha o som.
	get_tree().node_added.connect(_ao_entrar_na_arvore)


# -------------------------------------------------------------------------- barramentos

func _criar_barramentos() -> void:
	for barramento in BARRAMENTOS:
		var nome: StringName = barramento["nome"]
		if AudioServer.get_bus_index(nome) >= 0:
			continue
		var indice := AudioServer.bus_count
		AudioServer.add_bus(indice)
		AudioServer.set_bus_name(indice, nome)
		# tudo desagua no Master: sao controles separados, e nao saidas separadas
		AudioServer.set_bus_send(indice, &"Master")


## Poe no mundo o volume de cada barramento. Chamada pelo Config, que e quem guarda as
## opcoes -- este autoload nao le configuracao no _ready porque ele SOBE ANTES dela.
##
## ⚠️ ZERO MUTA, e nao so abaixa. Em -80 dB o barramento continua sendo processado a cada
## quadro: volume zero que nao muta e trabalho que ninguem ouve, todo quadro, para sempre.
func aplicar_volumes() -> void:
	for barramento in BARRAMENTOS:
		var campo := str(barramento["campo"])
		if campo.is_empty():
			continue
		definir_volume(barramento["nome"], Config.valor_de(campo))


func definir_volume(barramento: StringName, valor: float) -> void:
	var indice := AudioServer.get_bus_index(barramento)
	if indice < 0:
		push_error("Audio: nao existe o barramento %s" % barramento)
		return
	var nivel := clampf(valor, 0.0, 1.0)
	# o piso no linear_to_db evita -inf; quem de fato cala e o mute abaixo
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(nivel, 0.0001)))
	AudioServer.set_bus_mute(indice, nivel <= 0.0)


# ---------------------------------------------------------------------------- digitacao

## Quantos CLACKs por segundo uma producao merece. Sobe com a ORDEM DE GRANDEZA e satura.
##
## ⚠️ O TETO E CONSTANTE, e nao uma fracao da producao: e essa independencia que faz a
## regra valer tanto no primeiro caractere quanto em 10^50 por segundo.
##
## Pura e estatica para a suite poder afirmar a curva inteira sem tocar som nenhum.
static func clacks_por_segundo(producao: Grande) -> float:
	if producao.sinal() <= 0:
		return 0.0
	# a ordem de grandeza de um Grande: o expoente mais o log da mantissa
	var ordem := float(producao.expoente) + log(maxf(absf(producao.mantissa), 1e-12)) / log(10.0)
	return CLACKS_POR_SEGUNDO_NO_TETO * clampf(ordem / ORDENS_ATE_O_TETO, 0.0, 1.0)


## O timbre escolhido agora, ou vazio quando o jogador desligou o som de digitacao.
## Lido na hora de usar, e nunca guardado: mudar a opcao no meio da partida vale na hora.
func timbre_atual() -> String:
	var escolhido := str(Config.som_de_digitacao())
	return escolhido if TIMBRES.has(escolhido) else ""


## Quem tem quadro chama, como chama Eventos.tique e Automacao.tique.
func tique(delta: float) -> void:
	if timbre_atual().is_empty():
		return
	var taxa := clacks_por_segundo(Jogo.caracteres_por_segundo)
	if taxa <= 0.0:
		_ate_o_clack = 0.0
		return

	# ⚠️ o delta e GRAMPEADO antes de entrar: volta de pausa longa nao vira rajada
	_ate_o_clack -= minf(delta, ATRASO_MAXIMO)
	if _ate_o_clack > 0.0:
		return
	# e o proximo e agendado a partir de AGORA, e nao somando ao que ficou negativo: somar
	# devolveria a rajada pela porta dos fundos
	_ate_o_clack = 1.0 / taxa
	tocar_clack()


func tocar_clack() -> void:
	var timbre := timbre_atual()
	if timbre.is_empty() or _tocadores.is_empty():
		return
	var tocador := _tocadores[_proximo]
	_proximo = (_proximo + 1) % _tocadores.size()
	tocador.stream = _ondas.get(timbre)
	tocador.pitch_scale = 1.0 + _sorteio.randf_range(-VARIACAO_DE_TOM, VARIACAO_DE_TOM)
	tocador.play()


func tocar_interface() -> void:
	if _tocador_de_interface.is_empty():
		return
	var tocador := _tocador_de_interface[_proximo_de_interface]
	_proximo_de_interface = (_proximo_de_interface + 1) % _tocador_de_interface.size()
	tocador.pitch_scale = 1.0 + _sorteio.randf_range(-VARIACAO_DE_TOM, VARIACAO_DE_TOM)
	tocador.play()


func _ao_entrar_na_arvore(no: Node) -> void:
	var botao := no as BaseButton
	if botao == null:
		return
	botao.pressed.connect(tocar_interface)


# -------------------------------------------------------------------------------- ondas

func _construir_ondas() -> void:
	for nome in TIMBRES:
		_ondas[nome] = onda(TIMBRES[nome])
	_onda_de_interface = onda(TIMBRE_DE_INTERFACE)


## Um estalo: ruido e tom, os dois morrendo junto. Estatica e sem estado para a suite poder
## construir uma onda e conferir o formato dela sem subir audio nenhum.
static func onda(timbre: Dictionary) -> AudioStreamWAV:
	var duracao := float(timbre["duracao"])
	var quantas := maxi(int(duracao * float(AMOSTRAGEM)), 1)
	var mistura := clampf(float(timbre["ruido"]), 0.0, 1.0)
	var decaimento := float(timbre["decaimento"])
	var frequencia := float(timbre["frequencia"])
	var amplitude := clampf(float(timbre["volume"]), 0.0, 1.0)

	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = SEMENTE_DO_RUIDO

	var bytes := PackedByteArray()
	bytes.resize(quantas * 2)
	for i in quantas:
		var t := float(i) / float(AMOSTRAGEM)
		var envelope := exp(-t * decaimento)
		var estalo := sorteio.randf_range(-1.0, 1.0)
		var tom := sin(TAU * frequencia * t)
		var valor := (estalo * mistura + tom * (1.0 - mistura)) * envelope * amplitude
		# 16 bits com sinal, e o teto em 32767 para o pico nao dar a volta e virar estouro
		var inteiro := clampi(int(valor * 32767.0), -32767, 32767)
		bytes.encode_s16(i * 2, inteiro)

	var onda_pronta := AudioStreamWAV.new()
	onda_pronta.format = AudioStreamWAV.FORMAT_16_BITS
	onda_pronta.mix_rate = AMOSTRAGEM
	onda_pronta.stereo = false
	onda_pronta.data = bytes
	return onda_pronta


func _montar_tocadores() -> void:
	for i in TOCADORES:
		_tocadores.append(_tocador(&"Efeitos", null))
	# dois bastam para a interface: ninguem aperta tres botoes em trinta e cinco
	# milesimos de segundo
	for i in 2:
		_tocador_de_interface.append(_tocador(&"Interface", _onda_de_interface))


func _tocador(barramento: StringName, corrente: AudioStreamWAV) -> AudioStreamPlayer:
	var tocador := AudioStreamPlayer.new()
	tocador.bus = barramento
	tocador.stream = corrente
	add_child(tocador)
	return tocador
