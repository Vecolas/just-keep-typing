## O no que tem o quadro. Faz o relogio da partida andar e transforma clique em caractere.
##
## E o unico lugar do jogo com _process, e de proposito: Jogo so guarda estado e Economia
## so calcula, entao alguem precisa ser o tique -- e quem tem quadro e a cena.
##
## Nao desenha nada. A HUD e a issue #7 e vai entrar ao lado deste no, ouvindo o EventBus;
## este script continua sem saber que ela existe.
extends Node

func _process(delta: float) -> void:
	Economia.acumular(delta)


## _unhandled_input, e nao _input, de proposito: assim o botao da loja consome o clique
## antes de chegar aqui, e comprar um macaco nao digita um caractere de brinde.
##
## A tecla existe porque a mao cansa antes da primeira compra: sao dez cliques ate o
## Instinto Digitador, e obrigar todos eles no mouse e o tipo de atrito que faz alguem
## fechar o jogo nos primeiros trinta segundos.
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_accept"):
		_digitar()
		return
	if (
		evento is InputEventMouseButton
		and evento.button_index == MOUSE_BUTTON_LEFT
		and evento.pressed
	):
		_digitar()


func _digitar() -> void:
	Economia.digitar()
	get_viewport().set_input_as_handled()
