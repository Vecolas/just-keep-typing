## Quanto o jogo produziu enquanto estava fechado (GDD §38). Logica pura, so estatica.
##
##   tempo_offline = min(agora - ultimo_save, teto)
##   producao      = cps x tempo_offline
##
## O RELOGIO E INJETADO, nunca lido de Time aqui dentro. Uma conta que le o relogio do
## sistema nao tem como ser testada em 4 horas -- e 4 horas e justamente a fronteira que
## precisa de teste, porque e onde o teto entra.
##
## Relogio do sistema para tras da tempo negativo, e isso acontece de verdade: fuso,
## horario de verao, maquina com a hora errada. Vira zero, sem punir ninguem -- descontar
## producao de quem mexeu no relogio castiga o inocente junto com o esperto.
class_name ProgressoOffline
extends RefCounted

## Quantos segundos de fato contam. Teto zero ou negativo significa sem limite, que e o
## ultimo degrau dos upgrades de prestigio do GDD §38.
static func segundos_creditados(segundos_ausente: float, teto_segundos: float) -> float:
	if is_nan(segundos_ausente) or segundos_ausente <= 0.0:
		return 0.0
	if teto_segundos <= 0.0:
		return segundos_ausente
	return minf(segundos_ausente, teto_segundos)


## O que aquele tempo produziu, na producao corrente. Grande porque no fim do jogo quatro
## horas de producao nao cabem em float nem de longe.
static func producao(por_segundo: Grande, segundos: float) -> Grande:
	if segundos <= 0.0 or por_segundo.sinal() <= 0:
		return Grande.zero()
	return por_segundo.vezes(Grande.de_float(segundos))
