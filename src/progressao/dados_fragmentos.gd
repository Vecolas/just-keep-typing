## Os numeros do segundo prestigio (GDD §20). Um .tres so para eles pelo mesmo motivo do
## primeiro: sao o que muda numa sessao de tuning.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO: limite zero faria log10(pontos/0), e ganho 1 faria
## o Fragmento nao mudar nada -- que e pior que nao existir, porque o jogador ja teria
## pagado a arvore inteira por ele.
class_name DadosFragmentos
extends Resource

## Divisor do calculo: fragmentos = log10(pontos_totais / limite). Decide quando Reescrever
## o Universo fica disponivel pela primeira vez.
@export var limite_inicial: float = 0.0

## Multiplicador de producao POR FRAGMENTO. O GDD §20 pede bonus "extremamente grandes", e
## o numero precisa ser grande de verdade: se o primeiro Fragmento nao muda a sensacao da
## run seguinte, o sistema nao esta pronto (cuidado da issue #31).
##
## A conta que fixa o piso: os Fragmentos sao log10(pontos/limite) e o multiplicador deles
## e ganho^fragmentos, enquanto a Arvore rende algo proporcional a pontos. Para o PRIMEIRO
## Fragmento ja bater a Arvore inteira que ele custou, o ganho precisa passar de mil. A
## suite mede exatamente isso, e reprovou o valor 25 -- com ele, reescrever o Universo era
## um rebaixamento disfarcado de conquista.
@export var ganho_por_fragmento: float = 1.0

## Minimo para o botao aparecer. Reescrever o Universo por menos de um Fragmento seria
## apagar a arvore inteira de graca.
@export var minimo: float = 1.0
