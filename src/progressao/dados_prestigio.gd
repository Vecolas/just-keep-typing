## Os numeros do prestigio (GDD §18). Um .tres so para eles porque sao exatamente o tipo
## de coisa que muda numa sessao de tuning -- e porque a pergunta que o §18 quer criar,
## "faco prestigio agora ou continuo?", so existe se a curva estiver ajustada.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO: limite zero faria log10(total/0) e ganho zero
## faria o prestigio nao dar nada, que e pior que nao existir.
class_name DadosPrestigio
extends Resource

## Divisor do GDD §18: pontos = log10(total_de_caracteres / limite_inicial). E ele que
## decide quando o primeiro prestigio fica disponivel.
@export var limite_inicial: float = 0.0

## Quanto cada ponto de teorema ja ganhado na vida acrescenta ao multiplicador global.
##
## Usa os pontos GANHOS e nao os disponiveis: gastar na arvore nao pode encolher a
## producao, senao comprar um no deixaria a run seguinte mais lenta -- que e exatamente o
## que a issue #25 proibe.
@export var ganho_por_ponto: float = 0.0

## Minimo de pontos para o botao aparecer. Provar o Teorema por menos de um ponto seria
## resetar a partida de graca.
@export var pontos_minimos: float = 1.0
