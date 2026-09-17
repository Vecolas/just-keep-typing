## Um botao que so dispara depois de ficar APERTADO por um tempo, com a barra enchendo por
## baixo do texto (issue #40).
##
## Existe por uma acao so: excluir Manuscrito e a unica coisa do jogo que nao tem volta.
## Confirmacao de um clique e o gesto que a mao faz sozinha depois da terceira vez; um
## segundo de pressao nao. E a barra nao e enfeite -- ela e o que transforma "o botao nao
## funcionou" em "ainda falta um pouco".
##
## ⚠️ SOLTAR ANTES DO FIM ZERA, e nao pausa. Progresso que fica guardado transforma tres
## toques distraidos num save apagado, que e exatamente o acidente que este botao existe
## para impedir.
##
## ⚠️ E SO DISPARA UMA VEZ POR PRESSAO. Sem a trava, segurar um quadro a mais depois do
## limiar emite o sinal de novo -- e quem escuta e um codigo que apaga arquivo.
##
## Teclado e controle contam igual ao mouse: button_pressed e verdadeiro para os tres
## enquanto a tecla estiver em baixo (CONVENCOES.md, "Foco, teclado e controle").
class_name BotaoDeSegurar
extends Button

## Disparado quando a pressao completou o tempo.
signal segurado()

## Quanto tempo de pressao. Limite de DESIGN e nao botao de tuning: um segundo e o que
## separa "aperto distraido" de "decisao", e ajustavel viraria 0,2 s na primeira vez que
## alguem achasse o gesto lento.
const SEGUNDOS: float = 1.0

## Altura da barra de progresso, colada no rodape do botao.
const ALTURA_DA_BARRA: int = 4

var _acumulado: float = 0.0
var _ja_disparou: bool = false


func _ready() -> void:
	# a barra e desenhada por cima do StyleBox do proprio botao, entao ela precisa de um
	# _draw -- e _draw so acontece de novo quando alguem pede
	button_up.connect(_zerar)
	set_process(true)


func _process(delta: float) -> void:
	if not button_pressed:
		if _acumulado > 0.0:
			_zerar()
		return
	if _ja_disparou:
		return

	_acumulado += delta
	queue_redraw()
	if _acumulado >= SEGUNDOS:
		_ja_disparou = true
		segurado.emit()


## Quanto da pressao ja foi feita, de 0 a 1. A tela le isto para escrever quanto falta, e a
## suite le para afirmar que um toque curto nao chega no fim.
func progresso() -> float:
	return clampf(_acumulado / SEGUNDOS, 0.0, 1.0)


func _zerar() -> void:
	_acumulado = 0.0
	_ja_disparou = false
	queue_redraw()


func _draw() -> void:
	var quanto := progresso()
	if quanto <= 0.0:
		return
	var largura := size.x * quanto
	draw_rect(
		Rect2(0.0, size.y - float(ALTURA_DA_BARRA), largura, float(ALTURA_DA_BARRA)),
		Paleta.BANANA_GOLD,
	)
