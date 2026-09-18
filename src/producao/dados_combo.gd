## O combo de digitacao (issue #54): digitar acelera, parar nunca pune.
##
## Um .tres so para estes quatro numeros porque eles sao exatamente o tipo de coisa que se
## gira numa sessao de tuning, e porque errar qualquer um deles transforma o combo em
## OBRIGACAO -- que e o oposto do que ele existe para ser.
##
## ⚠️ OS PADRAO SAO INVALIDOS DE PROPOSITO, e um deles por um motivo especifico:
##
##   teto 1,0        -- combo que nao multiplica nada
##   ganho_por_tecla 0,0 -- combo que nunca sobe
##   decaimento 0,0  -- ⚠️ combo que NUNCA DESCE, que e a falha grave
##   graca 0,0       -- este e valido: sem carencia, decai no instante seguinte
##
## Decaimento zero e o unico defeito desta lista que o jogador nao percebe como defeito:
## o combo simplesmente fica ligado para sempre, e "deixar o dedo no teclado" vira a
## jogada dominante. A suite reprova zero aqui, e a sentinela nao pode ser zero-desliga
## por isso mesmo.
class_name DadosCombo
extends Resource

## Multiplicador maximo. ⚠️ "PEQUENO" E O ADJETIVO MAIS IMPORTANTE DA ISSUE #54: um teto
## grande transforma o combo em imposto, porque quem nao digita fica para tras e o jogo
## vira teste de resistencia de dedo.
@export var teto: float = 1.0

## Quanto de intensidade (0 a 1) cada caractere digitado acrescenta. O inverso deste
## numero e quantas teclas levam do zero ao teto.
@export var ganho_por_tecla: float = 0.0

## Quanto de intensidade se perde por segundo parado. ⚠️ E a metade que impede a
## obrigacao: sem ela, o combo nao e um bonus por estar presente, e sim uma punicao por
## estar ausente.
@export var decaimento_por_segundo: float = 0.0

## Quanto tempo o combo segura antes de comecar a cair. Existe para que a cadencia humana
## normal -- que tem pausa para pensar e para clicar na loja -- nao seja lida como parar.
## Zero e legitimo aqui: significa que cai no instante seguinte.
@export var segundos_de_graca: float = 0.0


## Quantas teclas levam do zero ao teto. Derivado, e nao um quinto campo: dois numeros
## dizendo a mesma coisa divergem no primeiro tuning, e a que vale costuma ser a errada.
func teclas_ate_o_teto() -> int:
	if ganho_por_tecla <= 0.0:
		return 0
	return int(ceilf(1.0 / ganho_por_tecla))


## Quantos segundos parado zeram um combo cheio, carencia incluida.
func segundos_ate_zerar() -> float:
	if decaimento_por_segundo <= 0.0:
		return 0.0
	return segundos_de_graca + 1.0 / decaimento_por_segundo
