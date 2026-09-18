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


## Quatro versos deste poema, sorteados de forma ESTAVEL para uma partida.
##
## ⚠️ ESTAVEL, E NAO ALEATORIO A CADA ABERTURA. O poema que o jogador achou e o poema dele:
## reabrir o Arquivo e ver outras quatro linhas transformaria a descoberta numa maquina de
## frases, que e exatamente o que o GDD §10 proibe. A semente vem da partida, entao dois
## jogadores veem poemas diferentes e cada um ve sempre o mesmo.
func versos_sorteados(semente: int) -> PackedStringArray:
	if versos.size() <= VERSOS_MOSTRADOS:
		return versos

	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = semente
	var indices: Array[int] = []
	for i in versos.size():
		indices.append(i)
	# embaralha os INDICES e corta: sortear com repeticao entregaria o mesmo verso duas
	# vezes, e poema com linha repetida parece defeito, nao poesia
	for i in range(indices.size() - 1, 0, -1):
		var j := sorteio.randi_range(0, i)
		var guardado := indices[i]
		indices[i] = indices[j]
		indices[j] = guardado

	var escolhidos := PackedStringArray()
	for i in VERSOS_MOSTRADOS:
		escolhidos.append(versos[indices[i]])
	return escolhidos

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

## O QUE A DESCOBERTA FAZ ALEM DE APARECER (issue #52).
##
## Ate a v0.5 toda descoberta dava bonus, e isso fazia o sistema parecer uma segunda loja.
## Descoberta e conteudo antes de ser economia: algumas existem so pela piada.
##
##   BONUS       da multiplicador. E o papel de quase todas, e o que a economia le
##   HUMOR       existe so pela piada. bonus 1.0 aqui e um valor LEGITIMO
##   EXPLICACAO  traz uma curiosidade que o Arquivo mostra (issue #55)
##   INTERFACE   muda a interface por alguns segundos quando sai
##
## ⚠️ O PAPEL E O QUE SEPARA "SEM BONUS" DE "CAMPO ESQUECIDO", e ate esta issue os dois
## eram a mesma coisa. O padrao invalido (bonus 1.0) protegia contra dado pela metade; com
## descoberta de humor, 1.0 passou a ser legitimo -- e sem declarar qual e qual, a suite
## teria que escolher entre aceitar o esquecido ou reprovar a piada.
##
## A regra que a suite cobra, e ela morde dos dois lados:
##
##   papel BONUS  exige bonus > 1.0   (senao e dado esquecido)
##   outro papel  exige bonus == 1.0  (senao e bonus escondido num papel que nao o anuncia)
##
## ⚠️ BONUS e o ZERO porque e o que as dezesseis descobertas anteriores ja eram: dado
## antigo sem o campo cai no papel que ele de fato tinha, e a migracao e nenhuma.
enum Papel {
	BONUS,
	HUMOR,
	EXPLICACAO,
	INTERFACE,
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
##
## ⚠️ 1.0 SO E VALIDO COM papel != BONUS -- ver o aviso no enum Papel.
@export var bonus: float = 1.0

@export var papel: Papel = Papel.BONUS

## A curiosidade que o Arquivo mostra ao abrir a entrada (issue #55). Vazia na maioria; o
## papel EXPLICACAO exige que ela exista.
##
## ⚠️ E TEXTO QUE O JOGADOR LE -- entra no i18n/textos.csv nas duas colunas, como o nome e
## o texto. Ela nao e nota de rodape de balanceamento; a nota do .tres de marco e que e.
@export_multiline var curiosidade: String = ""

## Os versos do POEMA (plano v0.6 §4). Vazio em todas as outras.
##
## ⚠️ O JOGO NUNCA GERA TEXTO (GDD §10). O poema mostra quatro linhas SORTEADAS de um
## conjunto escrito a mao -- o sorteio escolhe entre textos curados, e nao monta verso
## nenhum. Uma feature que precisasse gerar verso de verdade estaria errada por construcao.
@export var versos: PackedStringArray = PackedStringArray()

## Quantos versos o poema mostra de uma vez.
const VERSOS_MOSTRADOS: int = 4

@export var icone: Texture2D
