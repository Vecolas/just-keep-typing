## Numero com mantissa e expoente separados, para o contador de caracteres crescer sem
## teto de design. Logica pura: sem cena, sem autoload, testavel headless.
##
## Existe na PRIMEIRA issue de proposito. O tipo do recurso central aparece na economia,
## no custo exponencial, no requisito de cada marco, no save, no formatador e em toda a
## UI -- trocar depois significa mexer em todos esses sistemas ao mesmo tempo, que e o
## refactor que uma pessoa sozinha nao faz numa sessao. Ver
## docs/decisoes/0001-numeros-grandes.md
##
## Invariante: o sinal mora na mantissa e |mantissa| fica em [1, 10). O zero e o unico
## valor com mantissa exatamente 0.0, e sempre com expoente 0 -- por isso e_zero() olha
## a mantissa e nunca o expoente.
##
## Toda operacao devolve uma instancia NOVA e ja normalizada; nenhuma muda a si mesma.
## Guardar um Grande em campo e seguro sem copiar.
##
## Nao formata para tela. para_texto() e formato de SAVE, feito para ida e volta exata;
## quem escreve "5,28 x 10^4321" para o jogador e o Formatador (issue #2).
##
## LIMITE CONHECIDO: o expoente e int64 saturado em +-10^18. O 10^(10^100) que o GDD
## cita como endgame NAO cabe aqui -- precisaria de uma camada de torre de expoentes.
## Quando essa escala virar jogo de verdade, e decisao nova, nao remendo nesta classe.
class_name Grande
extends RefCounted

## Acima disto o expoente satura; abaixo do simetrico o numero vira zero. O corte em
## 10^18 e o que permite somar dois expoentes em vezes() sem estourar o int64.
const EXPOENTE_MAXIMO: int = 1_000_000_000_000_000_000
const EXPOENTE_MINIMO: int = -1_000_000_000_000_000_000

## Um double guarda ~16 digitos decimais. Com os expoentes mais distantes que isto, na
## soma, a parcela menor some por completo -- e esse e o resultado CERTO, nao um
## arredondamento a corrigir.
const DIGITOS_UTEIS: int = 17

## Tolerancia relativa padrao de igual_a(). Potencia e log erram na ultima casa;
## comparar double com == transforma esse erro em bug de gameplay.
const TOLERANCIA_PADRAO: float = 1e-9

const _LN_10: float = 2.302585092994045684

## Maior salto de expoente que cabe num pow(10, n) sem virar INF. Normalizar valor muito
## pequeno ou muito grande e feito em passos deste tamanho.
const _PASSO_MAXIMO: int = 150

## Quanto a mantissa pode ficar colada em 10 e ainda ser arredondada para 1.0 na casa de
## cima. Ver o fim de _normalizar(): sem isto a mesma quantia teria duas representacoes.
const _EPSILON_FRONTEIRA: float = 1e-12

## Os dois sao publicos porque o save grava cada um separado (decisao 0001). Nao atribua
## direto: fora dos construtores nada garante a normalizacao.
var mantissa: float = 0.0
var expoente: int = 0


func _init(nova_mantissa: float = 0.0, novo_expoente: int = 0) -> void:
	mantissa = nova_mantissa
	expoente = novo_expoente
	_normalizar()


static func zero() -> Grande:
	return Grande.new(0.0, 0)


static func um() -> Grande:
	return Grande.new(1.0, 0)


## Aceita qualquer float, inclusive fora de [1, 10): a normalizacao acerta o expoente.
static func de_float(valor: float) -> Grande:
	return Grande.new(valor, 0)


## Le o formato de save. Aceita "5.28e4321", "1e-5", "0" e tambem "1000" sem expoente.
static func de_texto(texto: String) -> Grande:
	var limpo := texto.strip_edges().to_lower()
	if limpo.is_empty():
		return Grande.zero()

	var partes := limpo.split("e")
	if partes.size() == 1:
		if not limpo.is_valid_float():
			push_error("Grande.de_texto: texto invalido %s" % texto)
			return Grande.zero()
		return Grande.de_float(limpo.to_float())

	if partes.size() != 2 or not partes[0].is_valid_float() or not partes[1].is_valid_int():
		push_error("Grande.de_texto: texto invalido %s" % texto)
		return Grande.zero()
	return Grande.new(partes[0].to_float(), partes[1].to_int())


func copia() -> Grande:
	return Grande.new(mantissa, expoente)


func e_zero() -> bool:
	return mantissa == 0.0


## -1, 0 ou 1.
func sinal() -> int:
	if mantissa > 0.0:
		return 1
	if mantissa < 0.0:
		return -1
	return 0


func negativo() -> Grande:
	return Grande.new(-mantissa, expoente)


func absoluto() -> Grande:
	return Grande.new(absf(mantissa), expoente)


func mais(outro: Grande) -> Grande:
	if e_zero():
		return outro.copia()
	if outro.e_zero():
		return copia()

	var maior := self
	var menor := outro
	if outro.expoente > expoente:
		maior = outro
		menor = self

	var distancia := maior.expoente - menor.expoente
	# a parcela menor nao tem um digito sequer dentro do double do resultado
	if distancia > DIGITOS_UTEIS:
		return maior.copia()
	return Grande.new(maior.mantissa + menor.mantissa * pow(10.0, float(-distancia)), maior.expoente)


func menos(outro: Grande) -> Grande:
	return mais(outro.negativo())


func vezes(outro: Grande) -> Grande:
	if e_zero() or outro.e_zero():
		return Grande.zero()
	return Grande.new(mantissa * outro.mantissa, expoente + outro.expoente)


func dividido(outro: Grande) -> Grande:
	if outro.e_zero():
		# divisor zerado quase sempre e erro de tuning (cadencia 0, custo 0) e sumiria
		# se devolvessemos zero calado -- ver CONVENCOES.md, "Mexeu num numero de
		# balanceamento?"
		push_error("Grande.dividido: divisao por zero")
		return Grande.zero()
	if e_zero():
		return Grande.zero()
	return Grande.new(mantissa / outro.mantissa, expoente - outro.expoente)


## Base negativa so tem resultado real com expoente inteiro; fora disso empurra erro e
## devolve zero.
func potencia(expoente_da_potencia: float) -> Grande:
	if expoente_da_potencia == 0.0:
		return Grande.um()
	if e_zero():
		return Grande.zero()

	var sinal_do_resultado := 1.0
	if mantissa < 0.0:
		if expoente_da_potencia != floorf(expoente_da_potencia):
			push_error("Grande.potencia: base negativa com expoente fracionario")
			return Grande.zero()
		if fmod(absf(expoente_da_potencia), 2.0) == 1.0:
			sinal_do_resultado = -1.0

	# trabalha no log porque pow() direto na mantissa jogaria fora o expoente inteiro
	var log_do_resultado := expoente_da_potencia * log10()
	var novo_expoente := floorf(log_do_resultado)
	var nova_mantissa := pow(10.0, log_do_resultado - novo_expoente) * sinal_do_resultado
	return Grande.new(nova_mantissa, _expoente_seguro(novo_expoente))


## Log na base 10 do valor absoluto. Zero devolve -INF, como manda a matematica.
func log10() -> float:
	if e_zero():
		return -INF
	return log(absf(mantissa)) / _LN_10 + float(expoente)


func maior_que(outro: Grande) -> bool:
	var meu_sinal := sinal()
	var sinal_do_outro := outro.sinal()
	if meu_sinal != sinal_do_outro:
		return meu_sinal > sinal_do_outro
	if meu_sinal == 0:
		return false
	if expoente != outro.expoente:
		# com os dois negativos, expoente maior significa valor MENOR
		return expoente > outro.expoente if meu_sinal > 0 else expoente < outro.expoente
	return mantissa > outro.mantissa


func menor_que(outro: Grande) -> bool:
	return outro.maior_que(self)


func maior_ou_igual(outro: Grande) -> bool:
	return not menor_que(outro)


func menor_ou_igual(outro: Grande) -> bool:
	return not maior_que(outro)


## Igualdade por diferenca RELATIVA: 1e300 e 1e300 + 1e290 sao o mesmo numero para o
## jogo, e nenhuma tolerancia absoluta daria conta das duas pontas da escala.
func igual_a(outro: Grande, tolerancia: float = TOLERANCIA_PADRAO) -> bool:
	if sinal() != outro.sinal():
		return false
	if e_zero():
		return true
	if absi(expoente - outro.expoente) > 1:
		return false
	var alinhada := outro.mantissa * pow(10.0, float(outro.expoente - expoente))
	return absf(mantissa - alinhada) <= tolerancia * maxf(absf(mantissa), absf(alinhada))


## -1, 0 ou 1. Existe para ordenar marco por requisito sem repetir o mesmo if em cada
## lugar que ordena.
func comparar(outro: Grande) -> int:
	if maior_que(outro):
		return 1
	if outro.maior_que(self):
		return -1
	return 0


## Perde precisao e satura em INF acima de 10^308 -- use so onde o valor comprovadamente
## cabe (delta, multiplicador, probabilidade).
func para_float() -> float:
	if e_zero():
		return 0.0
	if expoente > 308:
		return INF * signf(mantissa)
	if expoente < -308:
		return 0.0
	return mantissa * pow(10.0, float(expoente))


## Formato do save, nao da tela. Guarda digito suficiente para a ida e volta ser exata.
func para_texto() -> String:
	if e_zero():
		return "0"
	return "%se%d" % [_mantissa_em_texto(), expoente]


func _to_string() -> String:
	return para_texto()


func _normalizar() -> void:
	if is_nan(mantissa):
		push_error("Grande: mantissa NAN virou zero")
		mantissa = 0.0
		expoente = 0
		return
	if is_inf(mantissa):
		mantissa = signf(mantissa)
		expoente = EXPOENTE_MAXIMO
		return
	if mantissa == 0.0:
		# a atribuicao tambem mata o -0.0, que passa no == e sairia como "-0" no save
		mantissa = 0.0
		expoente = 0
		return

	# o log10 diz de quantas casas a mantissa precisa andar; em passos porque
	# pow(10, n) vira INF passando de ~308
	var passos := floori(log(absf(mantissa)) / _LN_10)
	while passos != 0:
		var passo := clampi(passos, -_PASSO_MAXIMO, _PASSO_MAXIMO)
		mantissa *= pow(10.0, float(-passo))
		expoente += passo
		passos -= passo

	# o log em ponto flutuante erra na fronteira: log10(1000) sai 2.9999999999999996 e
	# deixaria a mantissa em 9.999... em vez de 1.0
	while absf(mantissa) >= 10.0:
		mantissa /= 10.0
		expoente += 1
	while absf(mantissa) < 1.0 and mantissa != 0.0:
		mantissa *= 10.0
		expoente -= 1

	# pow(10, n) nao e exato em double: 1e100 * 1e-99 sai 9.999999999999998, que e menor
	# que 10 e por isso escapa do laco acima. Sem este arredondamento a MESMA quantia
	# teria duas representacoes -- o save gravaria 9.999999999999998e99 para o numero que
	# o resto do jogo escreve 1e100, e a ida e volta pelo texto deixaria de ser identidade.
	if absf(mantissa) >= 10.0 - _EPSILON_FRONTEIRA:
		mantissa = signf(mantissa)
		expoente += 1

	if expoente > EXPOENTE_MAXIMO:
		expoente = EXPOENTE_MAXIMO
	elif expoente < EXPOENTE_MINIMO:
		mantissa = 0.0
		expoente = 0


func _mantissa_em_texto() -> String:
	var texto := String.num(mantissa, DIGITOS_UTEIS)
	if not texto.contains("."):
		return texto
	return texto.rstrip("0").rstrip(".")


static func _expoente_seguro(valor: float) -> int:
	if valor >= float(EXPOENTE_MAXIMO):
		return EXPOENTE_MAXIMO
	if valor <= float(EXPOENTE_MINIMO):
		return EXPOENTE_MINIMO
	return int(valor)
