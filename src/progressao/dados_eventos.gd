## A frequencia dos eventos (GDD §22). Um .tres so para ela porque evento e a coisa mais
## facil de deixar irritante por numero errado -- e ajustar isso nao pode exigir abrir um
## .gd (cuidado da issue #27).
class_name DadosEventos
extends Resource

## Segundos, em media, entre um evento e o seguinte. O sorteio e por quadro, com chance
## delta/intervalo -- assim o intervalo medio sai certo sem ninguem guardar um cronometro.
@export var intervalo_medio: float = 0.0

## Quantos eventos podem estar ativos ao mesmo tempo. E o teto que impede a pilha de
## multiplicadores virar produto absurdo por acidente.
@export_range(1, 8) var maximo_simultaneos: int = 1

## So comeca a sortear depois deste tanto de caracteres. Evento no primeiro minuto e
## ruido: o jogador ainda nao sabe o que e producao normal, e nao tem como notar que ela
## mudou.
@export var requisito: float = 0.0
