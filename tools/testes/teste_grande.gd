## Suite de Grande: normalizacao, fronteiras e ida e volta para texto.
##
## E a suite mais densa do projeto de proposito. Grande e o tipo do recurso central --
## toda a economia, todo custo, todo requisito de marco e todo save passam por ela --
## entao uma soma errada aqui nao quebra uma tela, quebra o jogo inteiro em silencio.
## Ver docs/decisoes/0001-numeros-grandes.md.
##
## As afirmacoes de fronteira valem mais que as de caso feliz: soma com expoentes muito
## distantes, log10 batendo em potencia exata de 10, -0.0 no save, saturacao do expoente.
## E ai que double engana.
extends TesteBase

func _init() -> void:
	nome = "Grande"


func executar() -> void:
	_normalizacao()
	_conversao_float()
	_soma_e_subtracao()
	_multiplicacao_e_divisao()
	_potencia_e_log()
	_comparacao()
	_texto()
	_fronteiras()
	_entradas_invalidas()


func _normalizacao() -> void:
	_partes(Grande.new(1234.5, 0), 1.2345, 3, "1234.5 normaliza")
	_partes(Grande.new(0.00042, 0), 4.2, -4, "0.00042 normaliza para expoente negativo")
	_partes(Grande.new(-1234.5, 0), -1.2345, 3, "o sinal fica na mantissa")
	_partes(Grande.new(10.0, 5), 1.0, 6, "mantissa 10 sobe um expoente")
	_partes(Grande.new(1.0, 5), 1.0, 5, "ja normalizado nao muda")
	_partes(Grande.new(0.0, 5), 0.0, 0, "zero absorve o expoente")

	# log10(1000) sai 2.9999999999999996 no double: sem a correcao a mantissa ficaria
	# em 9.999... e o expoente uma casa abaixo
	_partes(Grande.de_float(1000.0), 1.0, 3, "potencia exata de 10 nao escorrega")
	_partes(Grande.de_float(1e100), 1.0, 100, "1e100 normaliza")
	_partes(Grande.de_float(1e308), 1.0, 308, "1e308, o teto do double, normaliza")
	_partes(Grande.de_float(1e-300), 1.0, -300, "1e-300 normaliza em passos")
	# 1e100 * 1e-99 sai 9.999999999999998 e escapa do laco de correcao por ser menor que
	# 10; sem o arredondamento de fronteira a mesma quantia teria duas representacoes
	_partes(Grande.new(9.999999999999999, 5), 1.0, 6, "mantissa colada em 10 sobe a casa")
	_partes(Grande.new(9.9999999999, 5), 9.9999999999, 5, "mantissa so perto de 10 fica")

	ok(Grande.zero().e_zero(), "zero() e zero")
	ok(not Grande.um().e_zero(), "um() nao e zero")
	igual(Grande.um().sinal(), 1, "sinal de um()")
	igual(Grande.zero().sinal(), 0, "sinal de zero()")
	igual(Grande.de_float(-5.0).sinal(), -1, "sinal de negativo")

	# -0.0 passa no == 0.0 e sobreviveria ate o save, saindo como "-0"
	igual(Grande.de_float(-0.0).para_texto(), "0", "-0.0 vira zero limpo")

	ok(Grande.de_float(INF).expoente == Grande.EXPOENTE_MAXIMO, "INF satura no teto")


func _conversao_float() -> void:
	perto(Grande.de_float(1234.5).para_float(), 1234.5, 1e-9, "ida e volta de 1234.5")
	perto(Grande.de_float(-0.25).para_float(), -0.25, 1e-12, "ida e volta de -0.25")
	perto(Grande.zero().para_float(), 0.0, 0.0, "zero vira 0.0")
	ok(is_inf(Grande.new(1.0, 400).para_float()), "acima de 10^308 satura em INF")
	ok(Grande.new(-1.0, 400).para_float() < 0.0, "a saturacao guarda o sinal")
	perto(Grande.new(1.0, -400).para_float(), 0.0, 0.0, "abaixo de 10^-308 vira 0.0")


func _soma_e_subtracao() -> void:
	_partes(Grande.new(1.5, 3).mais(Grande.new(1.5, 3)), 3.0, 3, "soma de iguais")
	_partes(Grande.new(9.9, 3).mais(Grande.new(9.9, 3)), 1.98, 4, "soma renormaliza")
	_partes(Grande.new(5.0, 3).menos(Grande.new(2.0, 3)), 3.0, 3, "subtracao simples")
	_partes(Grande.new(1.0, 3).menos(Grande.new(5.0, 3)), -4.0, 3, "subtracao passa do zero")

	var x := Grande.new(7.25, 42)
	ok(x.mais(Grande.zero()).igual_a(x), "somar zero nao muda")
	ok(Grande.zero().mais(x).igual_a(x), "zero mais x e x")
	ok(x.menos(x).e_zero(), "x menos x e zero")

	# a 15 casas de distancia o double ainda enxerga a parcela menor
	perto(
		Grande.new(1.0, 15).mais(Grande.um()).para_float(),
		1000000000000001.0,
		1.0,
		"parcela pequena ainda conta a 15 casas",
	)
	# a 18 casas ela nao tem um digito sequer dentro do resultado, e sumir e o certo
	_partes(Grande.new(1.0, 18).mais(Grande.um()), 1.0, 18, "parcela pequena some a 18 casas")
	_partes(Grande.new(1.0, 100).mais(Grande.um()), 1.0, 100, "1e100 mais 1 continua 1e100")
	_partes(Grande.um().mais(Grande.new(1.0, 100)), 1.0, 100, "e a ordem nao importa")


func _multiplicacao_e_divisao() -> void:
	_partes(Grande.new(5.28, 4321).vezes(Grande.new(2.0, 100)), 1.056, 4422, "produto renormaliza")
	_partes(Grande.new(-2.0, 3).vezes(Grande.new(3.0, 2)), -6.0, 5, "produto guarda o sinal")
	_partes(Grande.new(-2.0, 3).vezes(Grande.new(-3.0, 2)), 6.0, 5, "dois negativos dao positivo")
	ok(Grande.new(3.0, 7).vezes(Grande.zero()).e_zero(), "vezes zero e zero")
	ok(Grande.zero().vezes(Grande.new(3.0, 7)).e_zero(), "zero vezes e zero")

	_partes(Grande.new(1.0, 10).dividido(Grande.new(2.0, 3)), 5.0, 6, "divisao renormaliza")
	var y := Grande.new(3.75, 91)
	ok(y.dividido(y).igual_a(Grande.um()), "x dividido por x e um")
	ok(Grande.zero().dividido(y).e_zero(), "zero dividido e zero")


func _potencia_e_log() -> void:
	perto(Grande.de_float(2.0).potencia(10.0).para_float(), 1024.0, 1e-6, "2^10")
	_partes(Grande.new(1.0, 100).potencia(2.0), 1.0, 200, "(1e100)^2")
	perto(Grande.de_float(9.0).potencia(0.5).para_float(), 3.0, 1e-9, "raiz por expoente 0.5")
	perto(Grande.de_float(-2.0).potencia(3.0).para_float(), -8.0, 1e-9, "base negativa, expoente impar")
	perto(Grande.de_float(-2.0).potencia(2.0).para_float(), 4.0, 1e-9, "base negativa, expoente par")
	ok(Grande.new(5.0, 20).potencia(0.0).igual_a(Grande.um()), "qualquer coisa elevado a 0 e um")
	ok(Grande.zero().potencia(2.0).e_zero(), "zero elevado e zero")

	perto(Grande.new(1.0, 100).log10(), 100.0, 1e-9, "log10 de 1e100")
	perto(Grande.new(5.28, 4321).log10(), 4321.722633923, 1e-6, "log10 soma mantissa e expoente")
	perto(Grande.new(-1.0, 50).log10(), 50.0, 1e-9, "log10 usa o valor absoluto")
	ok(is_inf(Grande.zero().log10()) and Grande.zero().log10() < 0.0, "log10 de zero e -INF")


func _comparacao() -> void:
	ok(Grande.new(1.0, 100).maior_que(Grande.new(1.0, 99)), "expoente maior ganha")
	ok(Grande.new(2.0, 5).maior_que(Grande.new(1.0, 5)), "mesmo expoente, mantissa decide")
	ok(Grande.new(1.0, 5).maior_que(Grande.new(-1.0, 100)), "positivo ganha de negativo")

	# com os dois negativos o expoente maior significa valor MENOR
	ok(Grande.new(-1.0, 100).menor_que(Grande.new(-1.0, 99)), "-1e100 e menor que -1e99")
	ok(Grande.new(-2.0, 5).menor_que(Grande.new(-1.0, 5)), "-2e5 e menor que -1e5")

	var v := Grande.new(4.0, 12)
	ok(not v.maior_que(v.copia()), "nao e maior que si mesmo")
	ok(v.maior_ou_igual(v.copia()), "e maior ou igual a si mesmo")
	ok(v.menor_ou_igual(v.copia()), "e menor ou igual a si mesmo")
	ok(not Grande.zero().maior_que(Grande.zero()), "zero nao e maior que zero")

	igual(Grande.new(1.0, 100).comparar(Grande.new(1.0, 99)), 1, "comparar devolve 1")
	igual(Grande.new(1.0, 99).comparar(Grande.new(1.0, 100)), -1, "comparar devolve -1")
	igual(v.comparar(v.copia()), 0, "comparar devolve 0")

	ok(Grande.zero().igual_a(Grande.zero()), "zero e igual a zero")
	ok(not Grande.zero().igual_a(Grande.um()), "zero nao e igual a um")
	ok(Grande.new(1.0, 10).igual_a(Grande.new(1.0000000001, 10)), "tolerancia absorve a ultima casa")
	ok(not Grande.new(1.0, 10).igual_a(Grande.new(1.001, 10)), "tolerancia nao absorve 0.1%")
	ok(not Grande.um().igual_a(Grande.new(-1.0, 0)), "sinais diferentes nunca sao iguais")

	# vizinhos de expoente: 9.99999999999e9 e 1e10 sao o mesmo numero, 9.9999e9 nao
	ok(Grande.new(9.99999999999, 9).igual_a(Grande.new(1.0, 10)), "igual_a atravessa o expoente")
	ok(not Grande.new(9.9999, 9).igual_a(Grande.new(1.0, 10)), "e nao atravessa quando difere")


func _texto() -> void:
	for original in [
		Grande.new(5.28, 4321),
		Grande.new(-1.0, 0),
		Grande.new(1.0, -300),
		Grande.new(3.14159265358979, 17),
		Grande.new(-9.87654321, -12),
		Grande.zero(),
	]:
		var volta := Grande.de_texto(original.para_texto())
		# exato, nao aproximado: o save nao pode perder digito na ida e volta
		igual(volta.mantissa, original.mantissa, "%s ida e volta -- mantissa" % original.para_texto())
		igual(volta.expoente, original.expoente, "%s ida e volta -- expoente" % original.para_texto())

	igual(Grande.zero().para_texto(), "0", "zero sai como 0")
	_partes(Grande.de_texto("0"), 0.0, 0, "le 0")
	_partes(Grande.de_texto("1000"), 1.0, 3, "le numero sem expoente")
	_partes(Grande.de_texto("1e-5"), 1.0, -5, "le expoente negativo")
	_partes(Grande.de_texto("  2.5E10  "), 2.5, 10, "le com espaco e E maiusculo")
	ok(Grande.de_texto("").e_zero(), "texto vazio vira zero")


func _fronteiras() -> void:
	var teto := Grande.new(1.0, Grande.EXPOENTE_MAXIMO)
	igual(teto.vezes(Grande.new(1.0, 10)).expoente, Grande.EXPOENTE_MAXIMO, "expoente satura no teto")

	var piso := Grande.new(1.0, Grande.EXPOENTE_MINIMO)
	ok(piso.dividido(Grande.new(1.0, 10)).e_zero(), "abaixo do piso o numero vira zero")

	# o produto de dois expoentes de 10^18 ainda cabe no int64 antes de saturar
	igual(teto.vezes(teto).expoente, Grande.EXPOENTE_MAXIMO, "somar dois tetos nao estoura o int64")


## As entradas invalidas ficam juntas porque cada uma empurra um push_error de proposito:
## as linhas ERROR no stderr durante a suite sao ESPERADAS. Divisor zerado e NAN quase
## sempre sao erro de tuning vindo de outro sistema, e sumiriam se a classe devolvesse
## zero calada -- ver CONVENCOES.md, "Mexeu num numero de balanceamento?".
func _entradas_invalidas() -> void:
	print("    (as linhas ERROR abaixo sao de proposito -- entradas invalidas sob teste)")
	ok(Grande.um().dividido(Grande.zero()).e_zero(), "divisao por zero devolve zero e grita")
	ok(Grande.de_float(NAN).e_zero(), "NAN vira zero e grita")
	ok(Grande.de_texto("2.5e").e_zero(), "expoente faltando vira zero e grita")
	ok(Grande.de_float(-2.0).potencia(0.5).e_zero(), "raiz de negativo vira zero e grita")


func _partes(valor: Grande, mantissa: float, expoente: int, descricao: String) -> void:
	perto(valor.mantissa, mantissa, 1e-12, "%s -- mantissa" % descricao)
	igual(valor.expoente, expoente, "%s -- expoente" % descricao)
