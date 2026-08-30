## Um tier de maquina de escrever: o multiplicador que ela da e quanto custa trocar para
## ela. Nome traduzido do MachineData do GDD §36 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## Maquina e TIER, e nao quantidade. O jogador tem uma maquina de cada vez e troca para a
## seguinte; e a formula do GDD §30 que tem um multiplicador de maquina, no singular. Por
## isso nao ha custo_base nem crescimento aqui: a compra e unica.
##
## ⚠️ A Maquina de Possibilidades do GDD §13 NAO esta entre as instancias, e nao e
## esquecimento. Ela "produz combinacoes diretamente" -- muda o RECURSO, e nao o
## multiplicador -- e nao cabe na formula da Economia sem gambiarra. Fica para a v0.4,
## junto do resto do endgame, como a propria issue #14 autoriza. As outras nove entram.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO: custo 0 e multiplicador 1 reprovam na suite, entao
## .tres esquecido pela metade falha alto em vez de virar maquina de graca que nao
## multiplica nada.
class_name DadosMaquina
extends Resource

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Posicao na escada do GDD §13, de 1 (Velha) a 9 (Computador Probabilistico). E ela que
## define a ordem da loja e qual e a proxima -- nao o nome do arquivo nem o custo.
@export_range(1, 10) var tier: int = 1

## Multiplicador de producao. Entra na formula da Economia, NUNCA multiplicado dentro do
## macaco: valor derivado de estado global se calcula na hora de usar, e um macaco que
## nasceu com a maquina velha tem que passar a produzir mais no instante em que a maquina
## e trocada (CONVENCOES.md, regra 2 de arquitetura).
@export var multiplicador: float = 1.0

## Custo da troca, em caracteres (decisao 0004). Compra unica: nao tem crescimento.
@export var custo: float = 0.0

@export var icone: Texture2D

## Progressao visual por tier: a maquina muda de CARA, e nao so de numero
## (docs/ARTE.md, secao 4). O asset entra com a issue #26; ate la o campo espera.
@export var arte: Texture2D
