## PEDIR O FOCO DO TECLADO NO QUADRO SEGUINTE, sem gritar quando o alvo ja saiu da tela.
##
## ⚠️ ELE EXISTE PORQUE `call_deferred("grab_focus")` ESTAVA ERRANDO EM SILENCIO -- cinco vezes
## por corrida da suite:
##
##     ERROR: Condition "!is_inside_tree()" is true.
##        at: grab_focus (scene/gui/control.cpp:3001)
##
## O foco **tem** que ser adiado: quem acabou de ficar visivel ainda nao esta posicionado no
## quadro em que `abrir()` roda. Mas entre o pedido e o quadro seguinte a tela pode ter sido
## fechada, trocada ou desmontada -- e ai o Godot reclama e nao foca nada.
##
## ⚠️ E `is_instance_valid()` NAO RESOLVE. Ele responde "este objeto ainda existe", e o objeto
## existe: ele so nao esta mais na arvore. Sao duas perguntas diferentes, e a segunda e a que
## o `grab_focus` faz.
##
## ⚠️ TRES TELAS PEDIAM FOCO ADIADO, CADA UMA COM A PROPRIA LINHA. Esta classe existe para a
## guarda ser UMA: a quarta tela que precisar de foco nao vai lembrar de escrever a condicao,
## e o defeito dela seria mais uma linha de erro que ninguem le (CONVENCOES, "comportamento
## novo nao se escreve na mao").
##
## Nao desenha nada e nao guarda estado.
class_name Foco


## Pede o foco para `alvo` no quadro seguinte. Alvo nulo, ja liberado, fora da arvore ou
## invisivel simplesmente nao recebe foco -- e isso nao e erro, e o caso normal de uma tela
## que fechou antes do quadro chegar.
static func pedir(alvo: Control) -> void:
	if alvo == null:
		return
	var focar := func() -> void:
		# ⚠️ AS TRES CONDICOES, E NAO SO A PRIMEIRA. "existe", "esta na arvore" e "esta
		# visivel" sao perguntas diferentes, e o grab_focus exige as tres.
		if (
			is_instance_valid(alvo)
			and alvo.is_inside_tree()
			and alvo.is_visible_in_tree()
		):
			alvo.grab_focus()
	focar.call_deferred()
