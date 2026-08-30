## Um marco do Panorama: o requisito e a frase que diz o que aquele numero SIGNIFICA.
## Nome traduzido do Milestone do GDD §35 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## MARCO NAO DA BONUS. Ele da significado (decisao 0003). Bonus e assunto de descoberta
## (GDD §9) e de upgrade -- misturar as duas coisas faria o jogador ler o Panorama como
## uma loja, e o Panorama e a unica tela do jogo que nao e uma loja.
##
## Nao existe campo `ordem`. A ordem do Panorama E a ordem dos requisitos, e um campo
## paralelo mantido a mao desincronizaria na primeira sessao de tuning.
class_name DadosMarco
extends Resource

## A escala conceitual do GDD §45: letras -> palavras -> livros -> humanidade -> toda
## informacao -> todas as possibilidades -> infinito. Sao os sete degraus de significado
## que o jogo atravessa, e nao uma taxonomia inventada aqui.
enum Categoria {
	LETRAS,
	PALAVRAS,
	LIVROS,
	HUMANIDADE,
	INFORMACAO,
	POSSIBILIDADES,
	INFINITO,
}

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Quantos caracteres totais cruzam este marco, no formato de texto do Grande ("5e10").
##
## Texto e nao float porque o endgame passa de 10^308 e um .tres nao guarda Grande. E o
## mesmo formato que o save usa, entao ele ja e ida e volta exata (decisao 0001).
@export var requisito: String = "0":
	set(valor):
		requisito = valor
		_requisito = null

## Texto que o jogador le -- os dois entram em i18n/textos.csv na mesma mudanca.
@export var titulo: String = ""

## A frase do Panorama. E a estrela da tela: e ela que transforma "1e9" em alguma coisa.
@export var texto: String = ""

@export var icone: Texture2D

@export var categoria: Categoria = Categoria.LETRAS

## Era visual em que este marco cai (docs/ARTE.md, secao 10). A cena das eras e a issue
## #26; ate la o campo so existe para o Panorama poder agrupar.
@export_range(1, 8) var era: int = 1

var _requisito: Grande = null


## O requisito ja como Grande. Guardado depois da primeira leitura porque isto e chamado
## uma vez por marco por quadro, e converter texto em Grande sessenta vezes por segundo
## para um numero que nunca muda seria lixo puro.
func requisito_grande() -> Grande:
	if _requisito == null:
		_requisito = Grande.de_texto(requisito)
	return _requisito
