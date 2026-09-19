## Base das telas que abrem POR CIMA de outra: opcoes, creditos e as que vierem.
##
## Existe porque as tres regras de uma tela modal ja estavam copiadas em cada arquivo, e
## copia que diverge aqui nao da erro nenhum -- ela vira uma tela que fecha no ESC e outra
## que nao, no mesmo jogo.
##
## As tres regras:
##
##   ESC FECHA, e enquanto a tela estiver aberta ela COME o resto da entrada. Sem isso o
##   jogador mexe nas opcoes digitando sem querer -- dentro da partida o espaco produz um
##   caractere (issue #6).
##
##   ⚠️ E ELA TOMA O FOCO. `_unhandled_input` nao alcanca o que o foco de interface ja
##   consumiu: com um botao do menu focado atras do painel, apertar espaco aperta o botao
##   de TRAS -- inclusive o que acabou de abrir esta tela. Modal que nao toma o foco e
##   modal so para o mouse.
##
##   ⚠️ E DEVOLVE O FOCO A QUEM O TINHA. Fechar deixando o foco no vazio e o menu parando
##   de responder ao teclado sem uma linha no console: a pessoa aperta seta e nada anda.
##
## Quem herda monta o conteudo e chama super() se sobrescrever abrir/fechar.
class_name TelaSobreposta
extends Control

## Quem tinha o foco quando esta tela abriu. Null significa ninguem -- e ai nao ha o que
## devolver, o que e o caso normal de quem abriu a tela com o mouse.
var _foco_anterior: Control = null


func abrir() -> void:
	_foco_anterior = get_viewport().gui_get_focus_owner()
	visible = true
	# o foco e adiado porque quem acabou de ficar visivel ainda nao esta posicionado -- e
	# passa pelo Foco porque entre o pedido e o quadro seguinte a tela pode ter fechado
	Foco.pedir(_primeiro_foco())


func fechar() -> void:
	visible = false
	Foco.pedir(_foco_anterior)
	_foco_anterior = null


## Onde o foco pousa ao abrir. Quem herda devolve o proprio controle; null significa "esta
## tela nao tem o que focar", e ai o foco fica onde estava.
func _primeiro_foco() -> Control:
	return null


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()
