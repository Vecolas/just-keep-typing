## Um tipo de macaco: quanto custa, quanto cresce e quanto produz. Nome traduzido do
## MonkeyData do GDD §36 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## Existe para que balancear macaco seja abrir um .tres e nao um .gd (GDD §36,
## CONVENCOES.md "Numeros vao para .tres"). Sessao de tuning boa e aquela em que voce nao
## abre um script nenhuma vez.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO. custo_base 0 e crescimento_custo 1 reprovam na
## suite, entao um .tres criado e esquecido pela metade falha alto em vez de virar macaco
## de graca com custo que nao cresce -- que e compra infinita, o erro de tuning que a
## CONVENCOES.md lista por nome.
class_name DadosMacaco
extends Resource

## snake_case sem acento: vai para o save e para chave de dicionario, e acento em chave de
## save e fonte de bug de codificacao, nao de clareza (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Custo do primeiro. Continua float, e nao Grande, porque custo BASE nao e acumulador:
## a escala vem do crescimento, nao daqui (decisao 0001). Quem calcula converte.
@export var custo_base: float = 0.0

## Multiplicador do custo a cada compra (GDD §31: custo = base x crescimento^quantidade).
## Tem que ser maior que 1 -- em 1 o custo nao cresce e a compra vira infinita.
@export var crescimento_custo: float = 1.0

## Caracteres por segundo de UM macaco, antes de qualquer multiplicador.
@export var producao_base: float = 0.0

@export var icone: Texture2D

## Quantos caracteres totais liberam este macaco na loja. Zero aparece desde o inicio.
@export var requisito_desbloqueio: float = 0.0
