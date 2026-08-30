## Uma sala e o espaco que ela oferece. Nome do GDD §15 -- ver
## docs/decisoes/0002-codigo-em-portugues.md.
##
## Sala e o SEGUNDO EIXO da progressao: o GDD §15 lista quatro coisas que o jogador
## precisa aumentar -- quantidade de macacos, velocidade, qualidade das maquinas e espaco.
## Sem o espaco, comprar macaco vira reflexo; com ele, vira decisao.
##
## Como maquina, sala e TIER e nao quantidade: o jogador ocupa uma e se muda para a
## seguinte. Por isso nao ha custo_base nem crescimento -- a mudanca e unica.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO: capacidade 0 reprova na suite, e sala sem vaga
## nenhuma pararia o jogo inteiro em silencio.
class_name DadosSala
extends Resource

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Posicao na escada do GDD §15, de 1 (Sala Pequena) a 5 (Cidade). E ela que define a
## ordem e qual e a proxima -- nao o nome do arquivo nem o custo.
@export_range(1, 10) var tier: int = 1

## Quantos macacos cabem. Float e nao Grande porque a maior do GDD §15 e uma cidade, na
## casa dos milhoes: cabe no double com folga de trezentas ordens de grandeza.
@export var capacidade: float = 0.0

## Custo da mudanca, em caracteres (decisao 0004). Compra unica: nao tem crescimento.
@export var custo: float = 0.0

@export var icone: Texture2D

## Progressao visual por tier (docs/ARTE.md, secao 10): a sala e o fundo que vai virando
## escritorio, fabrica, cidade. O asset entra com a issue #26.
@export var arte: Texture2D
