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
## ⚠️ VALOR NOVO ENTRA NO FIM. O enum e serializado como INTEIRO nos .tres: inserir uma
## entrada no meio reescreve o significado de todo arquivo ja salvo -- "Duas Maos" viraria
## outra coisa -- sem uma linha no console.
##
## ⚠️ E NEM TODO BONUS PRECISA SER MULTIPLICADOR. Ate a issue #60 os 44 upgrades eram 38
## multiplicadores que COMPOEM, e a conta era esta:
##
##   VELOCIDADE_DO_MACACO  17 upgrades  ->  x5.627
##   PRODUCAO_GLOBAL       21 upgrades  ->  x15.650.000
##   CAPACIDADE             5 upgrades  ->  x112
##
## Juntos, mais de 10^13 -- e nenhuma tabela manual de precos sobrevive a isso. Foi essa
## composicao que fez a campanha inteira caber em quatro minutos (decisao 0007).
##
## Os tipos abaixo estao ordenados pelo quanto compoem, do menos para o mais:
##
##   VELOCIDADE_SOMADA   soma na base de cada macaco. NAO compoe: dez deles sao dez, e
##                       nao 2^10. E o tipo da MAIORIA depois desta issue.
##   CUSTO_DE_MACACO     desconto no proximo macaco. Compoe, mas para baixo e com PISO.
##   VELOCIDADE_DO_MACACO  multiplica a velocidade. Compoe -- use pouco.
##   PRODUCAO_GLOBAL     multiplica TUDO. ⚠️ Compoe com tudo: tem que ser um MOMENTO, e
##                       nao mais um upgrade da lista. Um x2 em tudo merece nome proprio.
enum Efeito {
	VELOCIDADE_DO_MACACO,
	PRODUCAO_GLOBAL,
	LIGA_PRODUCAO_AUTOMATICA,
	CAPACIDADE,
	VELOCIDADE_SOMADA,
	CUSTO_DE_MACACO,
}

## Os tipos em que `valor` e um multiplicador (> 1). Fora daqui, `valor` quer dizer outra
## coisa -- e a suite cobra cada um pela regra DELE.
##
## ⚠️ Lista derivada do enum e nao escrita a mao seria melhor, mas nao ha como derivar
## "isto multiplica" de um inteiro. Entao ela e uma SEGUNDA FONTE, e existe portao cruzando
## as duas: tipo que nao esta em nenhuma das tres listas abaixo reprova.
const MULTIPLICADORES: Array[Efeito] = [
	Efeito.VELOCIDADE_DO_MACACO,
	Efeito.PRODUCAO_GLOBAL,
	Efeito.CAPACIDADE,
]

## Os tipos em que `valor` e uma PARCELA, somada e nunca multiplicada.
const SOMADORES: Array[Efeito] = [Efeito.VELOCIDADE_SOMADA]

## Os tipos em que `valor` e um DESCONTO: entre 0 e 1, e quanto menor, melhor.
const DESCONTOS: Array[Efeito] = [Efeito.CUSTO_DE_MACACO]

## ⚠️ O PISO DO DESCONTO. Multiplicar descontos sem piso leva o custo a zero, e custo zero
## e macaco infinito -- a familia de bug que a CONVENCOES chama de "zero num divisor". Ele
## e constante no codigo de proposito: nao e botao de tuning, e o limite que impede o
## sistema de se anular.
const DESCONTO_MINIMO: float = 0.1

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

## O QUE A PECA E (issue #72). ⚠️ E ELE IMPOE INVARIANTE, senao e so mais um rotulo.
##
## Dois erros da v0.7 vieram da mesma causa -- regra geral aplicada sem olhar o que a peca
## E --, e nos dois a semantica vivia so no TEXTO DA DESCRICAO, que nenhuma ferramenta le:
##
##   mesas_empilhadas    virou parcela de VELOCIDADE. O texto dele fala de empilhar mesas,
##                       ou seja, de VAGA. Quem acusou foi a composicao de capacidade cair
##                       de x112 para x45 sem ninguem ter tocado em capacidade.
##
##   instinto_digitador  recebeu requisito 20 como qualquer outro da fila. Ele e o
##                       INTERRUPTOR que liga a producao automatica (GDD §3), e tem que
##                       estar na loja no primeiro quadro. Quem acusou foi a suite de
##                       Economia reprovando quatro afirmacoes de compra.
##
## Com o papel declarado, os dois reprovariam por si: papel CAPACIDADE com efeito de
## velocidade, e papel INTERRUPTOR com requisito diferente de zero.
##
## ⚠️ E ELE NAO E A FAMILIA. Familia e leitura para o jogador ("O Macaco"); papel e contrato
## com o codigo. E, como a familia, o gameplay NAO o consulta -- ha portao varrendo a
## economia atras dos dois.
##
## SEM_PAPEL e o zero de proposito: e o que todo recurso esquecido recebe, e a suite
## reprova quem ficar nele.
enum Papel {
	SEM_PAPEL,
	ECONOMICO,
	CAPACIDADE,
	VELOCIDADE,
	AUTOMACAO,
	INTERRUPTOR,
	CONVENIENCIA,
}

@export var papel_do_upgrade: Papel = Papel.SEM_PAPEL

## Que efeitos cada papel aceita. ⚠️ A INVARIANTE E ISTO: papel que nao casa com o efeito
## reprova, e e o que teria pego os dois erros da v0.7.
##
## Papel fora desta tabela reprova tambem -- papel novo sem invariante e um rotulo que nao
## cobra nada, e a issue existe justamente contra rotulos que nao cobram.
const EFEITOS_DO_PAPEL: Dictionary = {
	Papel.ECONOMICO: [Efeito.PRODUCAO_GLOBAL, Efeito.CUSTO_DE_MACACO],
	Papel.CAPACIDADE: [Efeito.CAPACIDADE],
	Papel.VELOCIDADE: [Efeito.VELOCIDADE_SOMADA, Efeito.VELOCIDADE_DO_MACACO],
	Papel.AUTOMACAO: [Efeito.LIGA_PRODUCAO_AUTOMATICA],
	Papel.INTERRUPTOR: [Efeito.LIGA_PRODUCAO_AUTOMATICA],
	Papel.CONVENIENCIA: [Efeito.CUSTO_DE_MACACO],
}

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
