## O no que tem o quadro. Abre a partida, faz o relogio andar e transforma clique em
## caractere.
##
## QUANDO gravar nao mora mais aqui (issue #37): quem decide e o Autosave, porque os
## gatilhos que importam sao sinais do EventBus e nao um contador de quadro. Esta cena
## continua sendo o tique dele, como e de Eventos e Automacao.
##
## E o unico lugar do jogo com _process, e de proposito: Jogo so guarda estado e Economia
## so calcula, entao alguem precisa ser o tique -- e quem tem quadro e a cena.
##
## ⚠️ CARREGAR O SAVE SAIU DAQUI (issue #38). Ela abria a partida sozinha porque ate a v0.4
## abrir o jogo ERA estar jogando; com menu, quem escolhe o Manuscrito e o jogador, antes
## de esta cena existir. Carregar de novo aqui creditaria a producao offline DUAS VEZES --
## uma no Cenas e outra ao montar. Esta cena chega com o Jogo ja pronto.
##
## Nao desenha nada. A HUD e um irmao no CanvasLayer, ouvindo o EventBus; este script
## continua sem saber que ela existe.
extends Node

func _process(delta: float) -> void:
	Eventos.tique(delta)
	Automacao.tique(delta)
	Economia.acumular(delta)
	Marcos.verificar()
	# o som da digitacao e ritmo, e ritmo precisa de quadro. Quem tem quadro e a cena
	# (issue #42) -- como e de Eventos e de Automacao.
	Audio.tique(delta)
	# QUANDO gravar saiu daqui na issue #37: os gatilhos que importam sao sinais do
	# EventBus (prestigio, reescrita, troca de era) e nao cabiam num contador de quadro.
	Autosave.tique(delta)


## Fechar a janela grava. Sem isto, tudo que foi produzido desde a ultima gravacao
## automatica some -- e some justamente no gesto que o jogador entende como "sair", que e
## quando ele mais espera que o jogo tenha guardado.
func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		Autosave.gravar_agora()


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
