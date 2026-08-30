## Teto da producao offline (GDD §38). Um .tres so para isto porque ele e exatamente o
## tipo de numero que muda numa sessao de tuning, e porque ele VIRA UPGRADE: o §38 ja
## prevê 4 h, 8 h, 12 h, 24 h, 72 h e sem limite conforme o prestigio avanca.
##
## Zero ou negativo significa SEM LIMITE, que e o ultimo degrau dessa escada. Nao e caso
## de erro -- e o fim da progressao.
class_name DadosOffline
extends Resource

@export var teto_horas: float = 0.0


func teto_segundos() -> float:
	return teto_horas * 3600.0
