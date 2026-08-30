## Escreve um Grande para o jogador ler. Logica pura, so metodos estaticos, sem estado.
##
## Tres regimes, e a TROCA entre eles e o que faz o numero continuar legivel a vida
## inteira (GDD §34). Cada um existe porque o anterior parou de caber:
##
##   1  separador de milhar   999, 1.240, 15.000        ate 10^5
##   2  escala por nome       821 mil, 2,5 milhoes       ate 10^12
##   3  cientifico            4,83e28, depois 5,28 x 10^4321, depois 10^(10^9)
##
## TRUNCA, nunca arredonda. Num incremental o numero na tela e o que o jogador tem para
## gastar: arredondar 999.999 para "1 milhao" ao lado de uma loja que pede 1 milhao e
## mostrar dinheiro que nao existe. Truncar erra sempre para baixo, que e o lado seguro.
##
## A vírgula decimal e o separador de milhar vem de uma TABELA por idioma, nunca de um
## if por lingua -- idioma novo e uma linha aqui mais uma coluna no CSV. Numero nao e
## convertido entre idiomas, so reescrito: a quantia e a mesma, muda a pontuacao.
## Ver CONVENCOES.md, "Idioma traz as convencoes junto".
##
## ONDE A TABELA VAI MORAR: em Config, junto de relogio_12h e moeda, quando o autoload
## existir (ver docs/ARQUITETURA.md). Ele ainda nao existe -- nenhuma issue da v0.1 o
## cria -- entao ela mora aqui e o Formatador le TranslationServer.get_locale(), que e a
## mesma fonte que o Config vai alimentar. Quando Config entrar, esta constante muda de
## casa e _convencao() passa a ler Config.IDIOMAS; nada mais nesta classe muda.
##
## Nao escuta EventBus.idioma_mudou de proposito: e sem estado e nao tem rotulo para
## repintar. Quem monta texto e guarda na tela -- HUD, Panorama -- e que precisa escutar,
## porque o Godot so retraduz sozinho o text que veio da CENA.
class_name Formatador
extends RefCounted

## Abaixo disto o numero sai por extenso, com separador de milhar. GDD §34 mostra 15.000
## nesta forma e 821 mil na seguinte, entao o corte fica nas cinco casas.
const LIMITE_SEPARADOR: int = 5

## Abaixo disto o numero ganha nome de escala. Acima, nem bilhao segura mais: GDD §2 vai
## de "17 bilhoes" direto para notacao cientifica.
const LIMITE_ESCALA: int = 12

## Expoente abaixo do qual o cientifico usa a forma compacta (4,83e28). Acima dela o "e"
## deixa de ser lido como notacao e o numero vira potencia explicita.
const LIMITE_EXPOENTE_COMPACTO: int = 1000

## Expoente abaixo do qual ele ainda e escrito digito a digito (10^1000000, do GDD §34).
## Acima, o proprio expoente vira notacao cientifica: 10^(10^9).
const LIMITE_EXPOENTE_TORRE: int = 10_000_000

## Quantos digitos significativos a escala por nome mostra. Tres e o que produz os quatro
## exemplos do GDD ao mesmo tempo: 821 mil, 2,5 milhoes, 42 milhoes, 17 bilhoes.
const SIGNIFICATIVOS: int = 3

## Casas decimais da mantissa no cientifico (4,83e28) e do numero pequeno (0,25).
const CASAS_DECIMAIS: int = 2

## Abaixo de cem as casas decimais ainda significam alguma coisa -- producao por segundo
## comeca em fracao de caractere, e "0" no lugar de "0,5" faria a HUD parecer travada.
const LIMITE_DECIMAIS: int = 100

## Uma entrada por potencia de mil. Portugues nao pluraliza "mil" ("dois mil"), por isso
## singular e plural sao campos separados em vez de um sufixo colado.
##
## O molde inteiro e que e traduzido, com o %s dentro: em outra lingua a ordem das
## palavras pode mudar, e traduzir so a palavra deixaria a frase montada errada.
const ESCALAS: Array = [
	{"expoente": 3, "singular": "%s mil", "plural": "%s mil"},
	{"expoente": 6, "singular": "%s milhão", "plural": "%s milhões"},
	{"expoente": 9, "singular": "%s bilhão", "plural": "%s bilhões"},
]

## Convencao de escrita por idioma. NAO e balanceamento: nao vai para .tres e nao muda em
## sessao de tuning.
const CONVENCOES_DE_IDIOMA: Dictionary = {
	"pt_BR": {"milhar": ".", "decimal": ","},
	"en": {"milhar": ",", "decimal": "."},
}

const IDIOMA_PADRAO: String = "pt_BR"

## Marca de formato, nao texto: nunca passa por traducao. Quando o portao de texto da
## issue #23 existir, esta lista entra na constante SEM_TRADUCAO dele.
const SIMBOLO_MULTIPLICACAO: String = "×"
const SIMBOLO_POTENCIA: String = "10^"
const SIMBOLO_EXPOENTE: String = "e"

## O double erra na ultima casa e a truncagem transforma esse erro em digito perdido:
## 9.12 e guardado como 9.119999999999999, e truncar em duas casas daria 9,11. A margem
## e menor que qualquer diferenca que o jogador consiga enxergar.
const _EPSILON_TRUNCAMENTO: float = 1e-9


## Ponto de entrada. Escolhe o regime pela ordem de grandeza e nunca pelo valor em float,
## que satura em 10^308 muito antes de o jogo acabar.
static func formatar(valor: Grande) -> String:
	if valor.e_zero():
		return "0"

	var sinal := "-" if valor.sinal() < 0 else ""
	var modulo := valor.absoluto()
	if modulo.expoente < LIMITE_SEPARADOR:
		return sinal + _com_separador(modulo)
	if modulo.expoente < LIMITE_ESCALA:
		return sinal + _por_escala(modulo)
	return sinal + _cientifico(modulo)


## A convencao do idioma corrente, com "en_US" caindo em "en": a lingua traz a pontuacao,
## a regiao nao. Idioma desconhecido cai no padrao em vez de quebrar a tela.
static func convencao() -> Dictionary:
	var codigo := TranslationServer.get_locale()
	if CONVENCOES_DE_IDIOMA.has(codigo):
		return CONVENCOES_DE_IDIOMA[codigo]
	var raiz := codigo.split("_")[0]
	if CONVENCOES_DE_IDIOMA.has(raiz):
		return CONVENCOES_DE_IDIOMA[raiz]
	return CONVENCOES_DE_IDIOMA[IDIOMA_PADRAO]


static func _com_separador(modulo: Grande) -> String:
	# seguro: o regime so vale abaixo de 10^5, muito dentro do double
	var numero := modulo.para_float()
	var inteiro := floori(numero)
	var texto := _agrupar_milhares(inteiro)
	if inteiro < LIMITE_DECIMAIS:
		texto = _juntar_decimais(texto, numero - float(inteiro))
	return texto


static func _por_escala(modulo: Grande) -> String:
	var escala: Dictionary = ESCALAS[0]
	for candidata in ESCALAS:
		if modulo.expoente >= int(candidata["expoente"]):
			escala = candidata

	var quociente := modulo.dividido(Grande.new(1.0, int(escala["expoente"]))).para_float()
	var truncado := _truncar_significativos(quociente)
	var molde: String = escala["singular"] if truncado == 1.0 else escala["plural"]
	return _traduzir(molde) % _numero_curto(truncado)


static func _cientifico(modulo: Grande) -> String:
	var mantissa := _mantissa_curta(modulo.mantissa)
	if modulo.expoente < LIMITE_EXPOENTE_COMPACTO:
		return "%s%s%d" % [mantissa, SIMBOLO_EXPOENTE, modulo.expoente]
	if modulo.expoente < LIMITE_EXPOENTE_TORRE:
		# expoente sem separador de milhar: 10^1000, nao 10^1.000 -- ali o ponto seria
		# lido como virgula decimal por metade do mundo
		return _potencia(mantissa, str(modulo.expoente))

	# o expoente ficou grande demais para ser lido digito a digito e vira, ele proprio,
	# notacao cientifica. E a forma que o GDD §34 chama de 10^(10^100) -- que esta classe
	# escreve, mas Grande ainda nao alcanca: o expoente dele satura em 10^18.
	var altura := Grande.de_float(float(modulo.expoente))
	return "%s(%s)" % [SIMBOLO_POTENCIA, _potencia(_mantissa_curta(altura.mantissa), str(altura.expoente))]


## Mantissa 1 nao se escreve: 10^1000, e nao 1 x 10^1000.
static func _potencia(mantissa: String, expoente: String) -> String:
	if mantissa == "1":
		return SIMBOLO_POTENCIA + expoente
	return "%s %s %s%s" % [mantissa, SIMBOLO_MULTIPLICACAO, SIMBOLO_POTENCIA, expoente]


static func _agrupar_milhares(inteiro: int) -> String:
	var digitos := str(absi(inteiro))
	var grupos := PackedStringArray()
	var corte := digitos.length()
	while corte > 3:
		grupos.insert(0, digitos.substr(corte - 3, 3))
		corte -= 3
	grupos.insert(0, digitos.substr(0, corte))
	return String(convencao()["milhar"]).join(grupos)


static func _numero_curto(valor: float) -> String:
	var inteiro := floori(valor)
	return _juntar_decimais(str(inteiro), valor - float(inteiro))


static func _mantissa_curta(valor: float) -> String:
	return _numero_curto(_truncar_casas(absf(valor), CASAS_DECIMAIS, 10.0))


static func _juntar_decimais(inteiro: String, fracao: float) -> String:
	var casas := _casas_truncadas(fracao, CASAS_DECIMAIS)
	if casas.is_empty():
		return inteiro
	return inteiro + String(convencao()["decimal"]) + casas


## Devolve so os digitos depois da virgula, ja truncados e sem os zeros do fim: 0.5 vira
## "5", 0.05 vira "05" e 0.004 vira "" (nao ha casa que sobreviva a truncagem).
static func _casas_truncadas(fracao: float, quantidade: int) -> String:
	var fator := int(pow(10.0, float(quantidade)))
	# a margem pode empurrar 0,99999999999 para 100 centesimos, que viraria "0,1" -- o
	# vai-um teria de entrar na parte inteira, e truncar nunca faz vai-um
	var digitos := mini(floori(fracao * float(fator) + _EPSILON_TRUNCAMENTO), fator - 1)
	if digitos <= 0:
		return ""
	return str(digitos).lpad(quantidade, "0").rstrip("0")


## Trunca mantendo SIGNIFICATIVOS digitos, para um valor que ja esta em [1, 1000).
static func _truncar_significativos(valor: float) -> float:
	var inteiras := 1
	if valor >= 100.0:
		inteiras = 3
	elif valor >= 10.0:
		inteiras = 2
	return _truncar_casas(valor, SIGNIFICATIVOS - inteiras, 1000.0)


## O teto e a maior forma valida da faixa: mantissa vai ate 9,99 e quociente de escala
## ate 999. A margem de truncamento pode empurrar 9,999999999 para 10 e 999,999999999
## para 1000, e nenhum dos dois e forma que exista -- dariam "10e28" e "1000 bilhoes".
static func _truncar_casas(valor: float, casas: int, teto: float) -> float:
	var fator := pow(10.0, float(casas))
	var truncado := floorf(valor * fator + _EPSILON_TRUNCAMENTO) / fator
	if truncado >= teto:
		return teto - 1.0 / fator
	return truncado


## Equivale ao tr() das cenas. Uma classe estatica nao tem self, entao chama direto o
## servidor -- e a mesma busca que o tr() faz por baixo. A traducao vem ANTES do %s:
## traduz-se o molde, nunca o resultado (CONVENCOES.md, regra 2 de idioma).
static func _traduzir(molde: String) -> String:
	return String(TranslationServer.translate(molde))
