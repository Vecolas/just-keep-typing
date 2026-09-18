## Um upgrade comprável: quanto custa e que multiplicador ele acrescenta. Nome traduzido
## do GDD §36 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## O par (tipo_de_efeito, valor) e o que sustenta a regra que vale ouro na CONVENCOES.md:
## o gameplay pergunta QUANTO BONUS DE UM TIPO existe no total, nunca o nivel de um
## upgrade especifico. E o que permite as vinte entradas da issue #18 sem tocar em uma
## linha de codigo de gameplay -- upgrade novo e um .tres, e mais nada.
##
## OS PADRAO SAO INVALIDOS DE PROPOSITO: custo 0, valor 1 e familia SEM_FAMILIA reprovam
## na suite, entao upgrade esquecido pela metade falha alto em vez de virar bonus de graca
## que nao multiplica nada.
class_name DadosUpgrade
extends Resource

## Onde o multiplicador entra na formula do GDD §5 e §30:
##
##   producao = macacos x VELOCIDADE x mult_maquina x mult_sala x MULT_GLOBAL
##
## Sao dois slots diferentes e nao um so porque o GDD §4 separa os dois casos: "Dedos
## Mais Ageis" mexe na velocidade de cada macaco, "Duas Maos" multiplica o resultado
## inteiro. Tipo novo entra junto do sistema que le ele -- capacidade com as salas
## (issue #15), e nao antes: entrada de enum que ninguem le e cerimonia.
## LIGA_PRODUCAO_AUTOMATICA nao multiplica nada: e um interruptor. O macaco comeca sem
## saber digitar sozinho (GDD §3) e um upgrade acende a producao automatica. Fica aqui, e
## nao numa flag no Jogo, porque assim o gameplay continua perguntando pelo TIPO de efeito
## e nunca por um id -- trocar qual upgrade acende a producao nao mexe em codigo nenhum.
enum Efeito {
	VELOCIDADE_DO_MACACO,
	PRODUCAO_GLOBAL,
	LIGA_PRODUCAO_AUTOMATICA,
	CAPACIDADE,
}

## A que familia tematica o upgrade pertence (issue #53). Dezenas de "+25%" sao
## NECESSARIOS economicamente e ruins como conteudo: a familia e o que transforma vinte
## multiplicadores soltos em quatro escadas que contam uma historia cada.
##
## ⚠️ A FAMILIA E UMA COLUNA DESTE RECURSO, e nao uma pasta nem um prefixo de id. Prefixo
## de id seria uma segunda fonte para a mesma verdade, e as duas divergem no primeiro
## rename -- com o id indo para o save e a pasta nao, quem perde e sempre o jogador.
##
## ⚠️ E ELA E PARA LEITURA. O gameplay continua perguntando pelo TIPO de efeito
## (Economia.bonus_de), nunca pela familia: no dia em que aparecer um
## `if familia == MACACO` dentro da economia, a generalizacao que sustenta "upgrade novo
## e um .tres, e mais nada" ja quebrou.
##
## SEM_FAMILIA E O ZERO DE PROPOSITO. Zero e o que todo recurso esquecido recebe, entao
## ele tem que ser o valor que REPROVA -- do contrario um upgrade criado pela metade
## nasceria dizendo que e da familia Macaco, e ninguem descobriria lendo o arquivo.
enum Familia {
	SEM_FAMILIA,
	MACACO,
	MAQUINA,
	ORGANIZACAO,
	CONHECIMENTO,
}

## O nome de cada familia, na ordem do enum. Indexado por `Familia`, e nao uma segunda
## lista escrita a mao: a entrada de SEM_FAMILIA existe para o indice bater, e nenhuma
## tela chega a mostra-la porque a suite nao deixa upgrade nenhum ficar nela.
const NOMES_DE_FAMILIA: PackedStringArray = [
	"Sem família",
	"O Macaco",
	"A Máquina",
	"A Organização",
	"O Conhecimento",
]

@export var familia: Familia = Familia.SEM_FAMILIA

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Custo em caracteres (decisao 0004: um caractere digitado vale uma moeda). Compra
## unica, entao nao tem crescimento: upgrade repetivel seria outro campo e outro sistema.
@export var custo: float = 0.0

@export var tipo_de_efeito: Efeito = Efeito.VELOCIDADE_DO_MACACO

## Multiplicador, nunca soma: "+50% velocidade" do GDD §4 se escreve 1.5, e "x2 producao"
## se escreve 2.0. Multiplicador compoe em qualquer ordem; soma nao, e a ordem de compra
## acabaria mudando o resultado.
##
## Efeito de interruptor (LIGA_PRODUCAO_AUTOMATICA) ignora este campo, e a suite exige
## que ele fique em 1.0 ali: numero solto num campo que ninguem le faz a proxima pessoa
## procurar um multiplicador que nao existe.
@export var valor: float = 1.0

## Quantos caracteres totais fazem este upgrade aparecer na loja. Zero aparece desde o
## inicio.
@export var requisito: float = 0.0
