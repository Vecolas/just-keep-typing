## Suite da Economia: custo exponencial, serie geometrica e compra maxima.
##
## Os numeros de entrada sao os do GDD §31 -- base 10, crescimento 1,15, terceira compra
## custando 13,2 -- de proposito. Nao sao balanceamento morando no teste: sao o exemplo
## que o GDD promete, e a suite reprova quem mudar a formula sem mudar o documento.
##
## As duas afirmacoes que a issue pede valem mais que todas as outras juntas:
##
##   comprar 100 de uma vez custa igual a 100 compras de 1
##   comprar maximo nunca gasta mais do que se tem, e nunca compra 0 por arredondamento
##
## A primeira e o unico jeito de pegar um erro na serie geometrica -- ela devolve um
## numero plausivel para qualquer formula errada, e o jogador so descobre comparando os
## dois botoes. A segunda protege o saldo de quem clica.
##
## O bloco de producao MEXE no autoload Jogo, que e estado global vivo, e devolve tudo no
## fim: sem isso a suite deixaria macaco e multiplicador ligados para quem rodar depois.
extends TesteBase

const BASE: float = 10.0
const CRESCIMENTO: float = 1.15

func _init() -> void:
	nome = "Economia"


func executar() -> void:
	_custo_do_proximo()
	_serie_geometrica()
	_compra_maxima()
	_producao()
	_entradas_invalidas()


func _custo_do_proximo() -> void:
	var base := Grande.de_float(BASE)
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 0.0), 10.0, "GDD §31: primeiro custa 10")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 1.0), 11.5, "GDD §31: segundo custa 11,5")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 2.0), 13.225, "GDD §31: terceiro custa 13,2")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 10.0), 40.4555773570, "decima primeira")

	# o custo tem que crescer sempre: custo nao crescente e compra infinita, e esta na
	# lista de erros de tuning da CONVENCOES.md
	var anterior := Economia.custo_do_proximo(base, CRESCIMENTO, 0.0)
	var sempre_sobe := true
	for i in range(1, 60):
		var atual := Economia.custo_do_proximo(base, CRESCIMENTO, float(i))
		if not atual.maior_que(anterior):
			sempre_sobe = false
		anterior = atual
	ok(sempre_sobe, "o custo sobe a cada unidade, sem excecao em 60 compras")


func _serie_geometrica() -> void:
	var base := Grande.de_float(BASE)

	ok(Economia.custo_de(base, CRESCIMENTO, 0.0, 0).e_zero(), "comprar zero custa zero")
	ok(Economia.custo_de(base, CRESCIMENTO, 0.0, -5).e_zero(), "comprar negativo custa zero")
	ok(
		Economia.custo_de(base, CRESCIMENTO, 7.0, 1).igual_a(
			Economia.custo_do_proximo(base, CRESCIMENTO, 7.0)
		),
		"comprar 1 e o custo do proximo, sem passar pela serie",
	)

	# a afirmacao central da issue
	ok(
		Economia.custo_de(base, CRESCIMENTO, 0.0, 100).igual_a(_somar_uma_a_uma(0.0, 100)),
		"comprar 100 de uma vez custa igual a 100 compras de 1",
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, 37.0, 10).igual_a(_somar_uma_a_uma(37.0, 10)),
		"e continua valendo comecando de uma quantidade qualquer",
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, 0.0, 500).igual_a(_somar_uma_a_uma(0.0, 500)),
		"e continua valendo em 500 compras, onde o erro acumulado apareceria",
	)


func _compra_maxima() -> void:
	var base := Grande.de_float(BASE)

	ok(Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.zero()) == 0, "sem saldo, nada cabe")
	ok(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.de_float(-50.0)) == 0,
		"saldo negativo nao compra",
	)
	ok(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.de_float(9.99)) == 0,
		"saldo abaixo do primeiro custo nao compra",
	)

	# arredondamento comendo uma compra legitima e o segundo erro que a issue proibe
	var exato := Economia.custo_do_proximo(base, CRESCIMENTO, 0.0)
	igual(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, exato),
		1,
		"saldo exatamente igual ao custo compra 1, nunca 0",
	)

	# saldo exatamente igual a soma de dez compras tem que comprar as dez
	igual(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Economia.custo_de(base, CRESCIMENTO, 0.0, 10)),
		10,
		"saldo exatamente igual a dez compras leva as dez",
	)

	for disponivel in [
		Grande.de_float(10.0),
		Grande.de_float(123.45),
		Grande.de_float(1000.0),
		Grande.de_float(1e6),
		Grande.new(7.3, 40),
		Grande.new(1.0, 100),
	]:
		_invariantes_do_maximo(base, 0.0, disponivel)
	_invariantes_do_maximo(base, 250.0, Grande.new(4.0, 30))


## As duas promessas, conferidas contra a mesma custo_de() que vai debitar a compra:
## o que cabe cabe mesmo, e nao cabia mais um.
func _invariantes_do_maximo(base: Grande, quantidade: float, disponivel: Grande) -> void:
	var quantos := Economia.quantos_cabem(base, CRESCIMENTO, quantidade, disponivel)
	var rotulo := "maximo com %s a partir de %d" % [disponivel.para_texto(), int(quantidade)]

	ok(quantos >= 1, "%s -- comprou pelo menos uma" % rotulo)
	ok(
		not Economia.custo_de(base, CRESCIMENTO, quantidade, quantos).maior_que(disponivel),
		"%s -- nao gastou mais do que tinha" % rotulo,
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, quantidade, quantos + 1).maior_que(disponivel),
		"%s -- mais uma nao caberia" % rotulo,
	)


func _producao() -> void:
	var macacos_originais := Jogo.macacos
	var multiplicador_original := Jogo.multiplicador_global
	var total_original := Jogo.total_caracteres
	var run_original := Jogo.caracteres_da_run
	var cps_original := Jogo.caracteres_por_segundo

	Jogo.macacos = Grande.de_float(10.0)
	Jogo.multiplicador_global = 2.0
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()

	perto(Economia.multiplicador_total(), 2.0, 1e-12, "so o multiplicador global esta ligado")
	_vale(Economia.producao_por_segundo(1.5), 30.0, "10 macacos x 1,5 x 2")

	Economia.acumular(0.5, 1.5)
	_vale(Jogo.caracteres_por_segundo, 30.0, "acumular grava o cps para a HUD ler")
	_vale(Jogo.total_caracteres, 15.0, "meio segundo de 30/s soma 15 no total")
	_vale(Jogo.caracteres_da_run, 15.0, "e soma 15 na run")

	Economia.acumular(0.5, 1.5)
	_vale(Jogo.total_caracteres, 30.0, "o acumulo e cumulativo")

	# delta nao positivo nao produz, mas o cps continua sendo atualizado: deixar o valor
	# velho na tela mostraria producao que acabou de ser zerada
	Economia.acumular(0.0, 1.5)
	_vale(Jogo.total_caracteres, 30.0, "delta zero nao produz nada")
	_vale(Jogo.caracteres_por_segundo, 30.0, "e mesmo assim atualiza o cps")

	Jogo.macacos = Grande.zero()
	Economia.acumular(1.0, 1.5)
	ok(Jogo.caracteres_por_segundo.e_zero(), "sem macaco o cps zera de verdade")
	_vale(Jogo.total_caracteres, 30.0, "sem macaco nada e produzido")

	Jogo.macacos = macacos_originais
	Jogo.multiplicador_global = multiplicador_original
	Jogo.total_caracteres = total_original
	Jogo.caracteres_da_run = run_original
	Jogo.caracteres_por_segundo = cps_original
	ok(Jogo.macacos == macacos_originais, "a suite devolveu o estado do Jogo")


## Crescimento que nao cresce e o erro de tuning que permite compra infinita. As linhas
## ERROR no stderr durante a suite sao esperadas: a Economia grita em vez de dividir por
## zero calada. Ver CONVENCOES.md, "Mexeu num numero de balanceamento?".
func _entradas_invalidas() -> void:
	print("    (as linhas ERROR abaixo sao de proposito -- crescimento invalido sob teste)")
	var base := Grande.de_float(BASE)

	# com crescimento 1 o custo e constante, que e o limite da serie: 10 compras custam 100
	_vale(Economia.custo_de(base, 1.0, 0.0, 10), 100.0, "crescimento 1 vira soma linear")
	igual(
		Economia.quantos_cabem(base, 1.0, 0.0, Grande.de_float(95.0)),
		9,
		"crescimento 1 ainda respeita o saldo",
	)
	igual(
		Economia.quantos_cabem(Grande.zero(), CRESCIMENTO, 0.0, Grande.de_float(100.0)),
		0,
		"custo zerado nao vira compra infinita",
	)


func _somar_uma_a_uma(quantidade: float, quantos: int) -> Grande:
	var somado := Grande.zero()
	for i in quantos:
		somado = somado.mais(
			Economia.custo_do_proximo(Grande.de_float(BASE), CRESCIMENTO, quantidade + float(i))
		)
	return somado


func _vale(obtido: Grande, esperado: float, descricao: String) -> void:
	perto(obtido.para_float(), esperado, absf(esperado) * 1e-9 + 1e-9, descricao)
