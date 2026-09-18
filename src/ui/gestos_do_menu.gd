## Os gestos do menu vivo (issue #48): o macaco pisca, ajusta os oculos, coca a cabeca,
## olha para o jogador; a maquina bate uma tecla.
##
## ⚠️ SAO GESTOS INDEPENDENTES E SORTEADOS, e nao um video unico que sempre toca igual. Um
## video de dez segundos e reconhecivel na terceira vez e irritante na decima -- e este e um
## menu que fica aberto atras de outra coisa. Sorteados, eles nunca se repetem na mesma
## ordem, e a tabela cresce sem ninguem reeditar animacao nenhuma.
##
## ⚠️ NADA EXCESSIVAMENTE MOVIMENTADO. O plano §23 diz, o ARTE.md §11 diz: os deslocamentos
## sao de UM OU DOIS PIXELS DE ARTE, e entre um gesto e outro o menu fica parado por
## segundos. Um menu que nunca para e um menu que compete com o que a pessoa esta fazendo na
## outra janela.
##
## ⚠️ UM POR VEZ. Dois gestos ao mesmo tempo somam deslocamento e o macaco sai do lugar; e
## "independentes" quer dizer que eles nao formam uma sequencia, e nao que eles se empilham.
##
## ⚠️ REDUZIR MOVIMENTO (issue #43) DESLIGA TUDO, e o menu continua utilizavel: os botoes
## funcionam, o cenario esta la, e o que some e so o movimento.
##
## O relogio e do CENARIO, que tem quadro. Este no nao tem _process de proposito -- a ordem
## do que acontece no quadro e de quem desenha.
class_name GestosDoMenu
extends RefCounted

## Como um gesto mexe no alvo. Tres formas, e cada uma le diferente sem cor e sem som:
##
##   AFUNDA   desce e volta -- a tecla batendo, o macaco piscando
##   INCLINA  gira e volta -- olhar para o lado, ajustar os oculos
##   BALANCA  vai e vem na horizontal -- cocar a cabeca
enum Forma { AFUNDA, INCLINA, BALANCA }

## A tabela. Gesto novo e UMA LINHA aqui; nenhuma linha de codigo muda.
##
##   alvo      "macaco" ou "maquina"
##   forma     uma de Forma
##   quanto    pixels de ARTE (AFUNDA, BALANCA) ou radianos (INCLINA)
##   duracao   segundos
##   peso      quantas vezes mais provavel que um gesto de peso 1
##   clack     se o gesto toca o som de tecla
const GESTOS: Array[Dictionary] = [
	{
		"id": "macaco_pisca", "alvo": "macaco", "forma": Forma.AFUNDA,
		"quanto": 0.6, "duracao": 0.16, "peso": 5, "clack": false,
	},
	{
		"id": "macaco_oculos", "alvo": "macaco", "forma": Forma.INCLINA,
		"quanto": 0.035, "duracao": 0.55, "peso": 3, "clack": false,
	},
	{
		"id": "macaco_coca", "alvo": "macaco", "forma": Forma.BALANCA,
		"quanto": 1.0, "duracao": 0.9, "peso": 2, "clack": false,
	},
	{
		"id": "macaco_olha", "alvo": "macaco", "forma": Forma.INCLINA,
		"quanto": -0.03, "duracao": 1.4, "peso": 2, "clack": false,
	},
	{
		"id": "maquina_tecla", "alvo": "maquina", "forma": Forma.AFUNDA,
		"quanto": 0.8, "duracao": 0.18, "peso": 4, "clack": true,
	},
]

## Quanto tempo entre o fim de um gesto e o comeco do proximo. Limite de design: menos que
## isso o menu fica agitado, mais que isso ele parece congelado.
const ESPERA_MINIMA: float = 1.8
const ESPERA_MAXIMA: float = 4.5

## ⚠️ O MESMO GESTO NAO SAI DUAS VEZES SEGUIDAS. Sem esta regra o sorteio com peso 5
## entrega "pisca, pisca, pisca" com frequencia perfeitamente normal para um sorteio e
## perfeitamente errada para um olho -- e o jogador nao ve probabilidade, ve um tique.
var _ultimo: String = ""

var _atual: Dictionary = {}
var _decorrido: float = 0.0
var _ate_o_proximo: float = 0.0
var _sorteio := RandomNumberGenerator.new()


func _init() -> void:
	_sorteio.randomize()
	_ate_o_proximo = _sorteio.randf_range(ESPERA_MINIMA, ESPERA_MAXIMA)


## O gesto em andamento, ou vazio. A suite le isto.
func atual() -> Dictionary:
	return _atual


## Faz o relogio andar e devolve COMO o alvo deve estar agora: um dicionario por alvo, com
## deslocamento em pixels de arte e giro em radianos.
##
## ⚠️ DEVOLVE O ESTADO, e nao mexe em no nenhum. Quem desenha e o cenario; este arquivo so
## sabe de gesto. Mexer nos nos daqui espalharia o conhecimento da arvore por dois lugares,
## e o segundo sempre esquece de desfazer alguma coisa.
func tique(delta: float) -> Dictionary:
	var parado := {
		"macaco": {"desloca": Vector2.ZERO, "gira": 0.0},
		"maquina": {"desloca": Vector2.ZERO, "gira": 0.0},
	}
	if not ligado():
		_atual = {}
		return parado

	if _atual.is_empty():
		_ate_o_proximo -= delta
		if _ate_o_proximo <= 0.0:
			_comecar()
		return parado

	_decorrido += delta
	var quanto := float(_atual["duracao"])
	if _decorrido >= quanto:
		_atual = {}
		_ate_o_proximo = _sorteio.randf_range(ESPERA_MINIMA, ESPERA_MAXIMA)
		return parado

	# envelope de ida e volta: 0 -> 1 -> 0. Sem a volta, o gesto TERMINA deslocado e o
	# macaco vai andando para o lado a cada sorteio
	var fase := sin(PI * _decorrido / quanto)
	var alvo := str(_atual["alvo"])
	var valor := float(_atual["quanto"]) * fase
	match int(_atual["forma"]):
		Forma.AFUNDA:
			parado[alvo]["desloca"] = Vector2(0.0, valor)
		Forma.BALANCA:
			parado[alvo]["desloca"] = Vector2(valor, 0.0)
		Forma.INCLINA:
			parado[alvo]["gira"] = valor
	return parado


## Se os gestos devem acontecer agora. Lido na hora de usar, e nunca guardado (issue #43).
func ligado() -> bool:
	return not Config.ligado("reduzir_movimento")


## Sorteio com peso, e sem repetir o anterior.
func _comecar() -> void:
	var candidatos: Array[Dictionary] = []
	var total := 0
	for gesto in GESTOS:
		if str(gesto["id"]) == _ultimo:
			continue
		candidatos.append(gesto)
		total += int(gesto["peso"])
	# ⚠️ PISO NO SORTEIO. Tabela com um gesto so deixaria `candidatos` vazio depois de
	# excluir o anterior, e randi_range(0, -1) nao e sorteio, e travamento.
	if candidatos.is_empty() or total <= 0:
		return

	var bilhete := _sorteio.randi_range(0, total - 1)
	for gesto in candidatos:
		bilhete -= int(gesto["peso"])
		if bilhete < 0:
			_atual = gesto
			break
	if _atual.is_empty():
		_atual = candidatos[0]

	_ultimo = str(_atual["id"])
	_decorrido = 0.0
	if bool(_atual.get("clack", false)):
		Audio.tocar_clack()
