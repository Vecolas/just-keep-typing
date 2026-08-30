## Suite do Formatador: as fronteiras de cada regime e a troca entre eles.
##
## O que importa aqui nao e o caso feliz no meio de cada faixa, e o ponto exato em que a
## forma muda -- 999 virando 1.000, 999 mil virando 1 milhao, o ultimo bilhao virando
## notacao cientifica. E ali que um erro de um digito passa despercebido por meses.
##
## Os exemplos vem do GDD (§2 e §34) de proposito: sao o contrato do que o jogador le, e
## a suite existe para que mudar o formatador sem mudar o GDD reprove.
##
## As traducoes ainda NAO estao registradas no project.godot -- isso e a issue #23 -- e
## por isso _traduzir devolve a chave, que ja e o portugues. As afirmacoes de escala aqui
## provam o molde e a escolha singular/plural; provar o ingles delas so depois de #23.
extends TesteBase

func _init() -> void:
	nome = "Formatador"


func executar() -> void:
	_separador_de_milhar()
	_numero_pequeno()
	_escala_por_nome()
	_cientifico()
	_torre_de_expoentes()
	_negativos()
	_fronteiras_entre_regimes()
	_convencao_por_idioma()


func _separador_de_milhar() -> void:
	_texto(Grande.zero(), "0", "zero")
	_texto(Grande.de_float(12.0), "12", "GDD §2: 12 caracteres")
	_texto(Grande.de_float(999.0), "999", "999 ainda nao tem separador")
	_texto(Grande.de_float(1000.0), "1.000", "GDD §34: 1.000")
	_texto(Grande.de_float(1240.0), "1.240", "GDD §2: 1.240")
	_texto(Grande.de_float(15000.0), "15.000", "GDD §34: 15.000")
	_texto(Grande.de_float(99999.0), "99.999", "ultimo numero antes da escala por nome")


func _numero_pequeno() -> void:
	# producao por segundo comeca em fracao de caractere: sem estas casas a HUD do inicio
	# do jogo mostraria 0 e pareceria travada
	_texto(Grande.de_float(0.5), "0,5", "meia unidade")
	_texto(Grande.de_float(0.05), "0,05", "casa decimal com zero na frente")
	_texto(Grande.de_float(2.5), "2,5", "unidade com fracao")
	_texto(Grande.de_float(99.99), "99,99", "duas casas, o maximo")
	_texto(Grande.de_float(0.004), "0", "abaixo de duas casas nao sobra digito")
	# truncar nunca faz vai-um: sem o teto a fracao viraria 100 centesimos e sairia "0,1"
	_texto(Grande.de_float(0.99999999999), "0,99", "fracao colada em 1 nao sobe de casa")
	_texto(Grande.de_float(100.5), "100", "de cem em diante a fracao nao interessa mais")


func _escala_por_nome() -> void:
	_texto(Grande.de_float(100000.0), "100 mil", "primeiro numero com nome de escala")
	_texto(Grande.de_float(821000.0), "821 mil", "GDD §2: 821 mil")
	_texto(Grande.de_float(1000000.0), "1 milhão", "um milhao usa o singular")
	_texto(Grande.de_float(1500000.0), "1,5 milhões", "um e meio ja usa o plural")
	_texto(Grande.de_float(2500000.0), "2,5 milhões", "GDD §34: 2,5 milhoes")
	_texto(Grande.de_float(42000000.0), "42 milhões", "GDD §2: 42 milhoes")
	_texto(Grande.de_float(1000000000.0), "1 bilhão", "um bilhao usa o singular")
	_texto(Grande.de_float(17000000000.0), "17 bilhões", "GDD §2: 17 bilhoes")

	# trunca, nunca arredonda: mostrar "3 milhoes" para quem tem 2.999.999 e oferecer
	# dinheiro que nao existe na loja
	_texto(Grande.de_float(2999999.0), "2,99 milhões", "arredondar para cima seria mentira")


func _cientifico() -> void:
	_texto(Grande.new(1.0, 12), "1e12", "a mantissa 1 no compacto continua explicita")
	_texto(Grande.new(1.25, 12), "1,25e12", "GDD §34: 1,25e12")
	_texto(Grande.new(4.83, 28), "4,83e28", "GDD §34: 4,83e28")
	_texto(Grande.new(9.12, 140), "9,12e140", "GDD §34: 9,12e140")
	_texto(Grande.new(1.0, 999), "1e999", "ultimo expoente na forma compacta")
	# a margem de truncamento empurraria a mantissa para 10, e "10e28" nao e forma nenhuma
	_texto(Grande.new(9.99999999999, 28), "9,99e28", "mantissa colada em 10 nao sobe de casa")

	_texto(Grande.new(1.0, 1000), "10^1000", "GDD §34: 10^1000")
	_texto(Grande.new(1.0, 1000000), "10^1000000", "GDD §34: 10^1000000")
	_texto(Grande.new(5.28, 4321), "5,28 × 10^4321", "decisao 0001: 5,28 x 10^4321")


func _torre_de_expoentes() -> void:
	# a forma que o GDD §34 chama de 10^(10^100). Grande nao alcanca 10^100 de expoente
	# -- ele satura em 10^18 -- mas a FORMA existe, e passa a valer sozinha no dia em que
	# um tipo com torre de expoentes entrar
	_texto(Grande.new(1.0, 10000000), "10^(10^7)", "expoente grande demais vira potencia")
	_texto(Grande.new(1.0, 5000000000), "10^(5 × 10^9)", "expoente com mantissa propria")
	_texto(
		Grande.new(1.0, Grande.EXPOENTE_MAXIMO),
		"10^(10^18)",
		"o teto do Grande tem forma legivel",
	)


func _negativos() -> void:
	_texto(Grande.de_float(-1240.0), "-1.240", "negativo com separador")
	_texto(Grande.de_float(-1000000.0), "-1 milhão", "negativo com nome de escala")
	_texto(Grande.new(-4.83, 28), "-4,83e28", "negativo no cientifico")
	_texto(Grande.de_float(-0.5), "-0,5", "negativo pequeno")


## As tres trocas de regime que a issue pede. Cada par e o ultimo numero de uma forma e o
## primeiro da seguinte.
func _fronteiras_entre_regimes() -> void:
	_texto(Grande.de_float(999.0), "999", "fronteira 1: antes")
	_texto(Grande.de_float(1000.0), "1.000", "fronteira 1: depois")

	_texto(Grande.de_float(99999.0), "99.999", "fronteira 2: antes")
	_texto(Grande.de_float(100000.0), "100 mil", "fronteira 2: depois")

	_texto(Grande.de_float(999999.0), "999 mil", "fronteira 3: antes")
	_texto(Grande.de_float(1000000.0), "1 milhão", "fronteira 3: depois")

	_texto(Grande.new(9.99999999999, 11), "999 bilhões", "fronteira 4: antes")
	_texto(Grande.new(1.0, 12), "1e12", "fronteira 4: depois")

	_texto(Grande.new(9.99, 999), "9,99e999", "fronteira 5: antes")
	_texto(Grande.new(1.0, 1000), "10^1000", "fronteira 5: depois")


## Numero nao e convertido entre idiomas, so reescrito: a quantia e a mesma e muda a
## pontuacao. A suite fixa pt_BR (ver runner.gd), entao aqui ela troca e devolve.
func _convencao_por_idioma() -> void:
	var locale_original := TranslationServer.get_locale()

	TranslationServer.set_locale("en")
	_texto(Grande.de_float(1240.0), "1,240", "en usa virgula no milhar")
	_texto(Grande.de_float(0.5), "0.5", "en usa ponto no decimal")
	_texto(Grande.new(1.25, 12), "1.25e12", "en no cientifico")
	_texto(Grande.new(5.28, 4321), "5.28 × 10^4321", "o simbolo x nao e traduzido")

	# a lingua traz a convencao; a regiao nao acrescenta nada
	TranslationServer.set_locale("en_US")
	igual(Formatador.convencao()["milhar"], ",", "en_US cai na convencao de en")

	# idioma que ninguem cadastrou nao pode quebrar a tela
	TranslationServer.set_locale("fr")
	igual(Formatador.convencao()["decimal"], ",", "idioma desconhecido cai no padrao")

	TranslationServer.set_locale(locale_original)
	igual(TranslationServer.get_locale(), locale_original, "a suite devolveu o locale")


func _texto(valor: Grande, esperado: String, descricao: String) -> void:
	igual(Formatador.formatar(valor), esperado, descricao)
