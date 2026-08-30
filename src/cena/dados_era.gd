## Uma era visual (GDD §6). Cânone visual em docs/ARTE.md, secao 10.
##
## A era nao muda nenhuma conta: ela so muda o que se ve. Producao, custo e chance
## continuam iguais atravessando qualquer uma delas -- se um dia uma era mexer em numero,
## ela virou upgrade disfarcado de cenario, e o jogador vai procurar o botao.
class_name DadosEra
extends Resource

## De 1 a 14 (GDD §6). As de 8 a 14 entram na issue #30.
@export_range(1, 14) var numero: int = 1

## snake_case sem acento: vai para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Quantos caracteres totais entram nesta era, no formato de texto do Grande.
@export var requisito: String = "0":
	set(valor):
		requisito = valor
		_requisito = null

## Quantas maquinas aparecem na tela nesta era. A camera se afasta e cabe mais coisa: e o
## unico jeito de um incremental mostrar escala sem ser pelo numero (GDD §27).
@export_range(1, 400) var maquinas_visiveis: int = 1

## A CAMERA NAO AFASTA PARA SEMPRE. Em algum ponto a metafora troca: na era 14 a contagem
## de macacos deixa de fazer sentido e o jogador passa a manipular probabilidade,
## informacao e possibilidade (GDD §6). Era abstrata para de desenhar a grade de maquinas
## e desenha simbolos -- afastar mais seria so deixar tudo menor, e menor nao e "outra
## coisa".
##
## ⚠️ Mesmo abstrata, O MACACO CONTINUA LA. O docs/ARTE.md secao 10 e categorico: no fim
## do universo ainda existe um macaco digitando, e isso nao e negociavel.
@export var abstrata: bool = false

## Como o jogo chama a unidade que o jogador acumula nesta era. "macacos" ate a metafora
## trocar; depois vira o que a era manipula. A UI le daqui em vez de ter a palavra
## escrita: a issue #30 pede que a troca de unidade apareca na interface, e nao so no
## fundo.
@export var unidade: String = "macacos"

## Arte da era. O asset entra quando existir; ate la a cena desenha com o que tem.
@export var arte: Texture2D

var _requisito: Grande = null


func requisito_grande() -> Grande:
	if _requisito == null:
		_requisito = Grande.de_texto(requisito)
	return _requisito
