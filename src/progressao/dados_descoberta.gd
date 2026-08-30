## Uma descoberta: o padrao que os macacos produziram por acidente (GDD §9).
##
## ⚠️ O JOGO NUNCA GERA TEXTO. O GDD §10 e categorico: calcula-se a CHANCE, nao se
## produzem os caracteres. O `texto` daqui e escrito a mao por quem faz o jogo, e nao
## sorteado; a piada e que o jogador acredita que o macaco escreveu. Feature nova que
## precise gerar texto de verdade para funcionar esta errada por construcao
## (CONVENCOES.md, terceira pergunta da checagem de design).
##
## DESCOBERTA DA BONUS. Marco nao da. Sao os dois sistemas de recompensa do jogo e eles
## nao se misturam: o Panorama da significado, a descoberta da numero. Se o jogador
## comecar a ler o Panorama como loja, os dois perderam a graca (decisao 0003).
class_name DadosDescoberta
extends Resource

## As sete do GDD §12. A ordem importa: chance_base tem que cair de uma para a seguinte, e
## a suite reprova quem inverter -- categoria mais rara saindo antes da menos rara na mesma
## faixa de producao quebraria a leitura inteira do sistema.
enum Categoria {
	COMUM,
	INCOMUM,
	RARO,
	EPICO,
	LENDARIO,
	IMPOSSIVEL,
	PARADOXAL,
}

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

## A frase que aparece quando ela sai. E o produto inteiro desta feature: o numero e so a
## desculpa para mostrar esta linha.
@export var texto: String = ""

@export var categoria: Categoria = Categoria.COMUM

## Chance por caractere produzido (GDD §10):
##
##   chance = caracteres_produzidos x chance_base x bonus
##
## Na pratica e o inverso de quantos caracteres se espera digitar ate achar: 1e-3 sai por
## volta do milesimo caractere, 1e-10 por volta do decimo bilionesimo.
@export var chance_base: float = 0.0

## Multiplicador permanente de producao. O GDD §9 fixa um: a primeira palavra da +10%.
@export var bonus: float = 1.0

@export var icone: Texture2D
