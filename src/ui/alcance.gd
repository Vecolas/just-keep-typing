## OS TRES ESTADOS DE UM ITEM DE LOJA (issue #67), extraidos da hud.gd.
##
## ⚠️ "DESABILITADO" REPRESENTAVA SITUACOES ECONOMICAMENTE MUITO DIFERENTES, e o jogador via
## o mesmo cinza nas tres. A sessao observada achou a coluna inteira apagada no minuto 1 e
## no minuto 30 -- e a tabela da regua registrava aquilo como "3 na loja", que le como um
## minuto saudavel. "Tres na loja" e "tres botoes apagados" eram o mesmo numero.
##
##   ALCANCAVEL   da para comprar agora
##   PERTO        ainda nao, mas voce esta chegando -- mostra a porcentagem
##   LONGE        nao compete visualmente com o proximo objetivo
##
## A regra que separa os tres, e ela cabe numa linha:
##
##   botao caro e META. ausencia e VAZIO. botao que nunca acende e PROMESSA FALSA.
##
## ⚠️ E A PORCENTAGEM E TEXTO, e nao cor (issue #43). "72%" se le em qualquer monitor e em
## qualquer daltonismo; a cor so acompanha.
##
## ⚠️ SAIU DA hud.gd PARA SER UMA FONTE SO. Com a reforma da loja em cartoes, quem precisa
## responder "este item esta ao alcance?" passou a ser TRES: o botao da hud, o cartao de
## upgrade e a suite. A regra copiada em cada um deles e a familia "duas fontes para a mesma
## verdade" da CONVENCOES -- e aqui a divergencia seria silenciosa: um cartao mostrando
## "Comprar" aceso ao lado de um botao apagado pelo mesmo saldo.
##
## Logica pura, sem no e sem cena: a suite afirma os tres estados sem subir a HUD.
class_name Alcance

enum Estado { ALCANCAVEL, PERTO, LONGE }

## A partir de quanto do custo o item vira "proximo objetivo".
##
## ⚠️ Limite de DESIGN, e nao botao de tuning: ele responde "a partir de quando vale a pena
## mostrar que voce esta chegando", e nao "quanto o jogo deve custar". Numero ajustavel e
## ajustado, e este nao tem por que ser.
const PERTO_O_BASTANTE: float = 0.4

## Quanto brilho cada estado conserva. ⚠️ INDEXADO PELO ENUM, e o tamanho sai de
## Estado.size(): colecao dimensionada por literal e indexada por enum e uma bomba com
## timer (CONVENCOES).
##
## ⚠️ O LONGE NAO SOME. Ele e apagado de proposito -- o distante nao pode competir com o
## proximo objetivo --, mas continua sendo a promessa do que vem depois.
const BRILHO: Array[float] = [1.0, 0.85, 0.45]


## Em que estado esta um item que custa `custo`, lido no instante em que se desenha.
static func de(custo: Grande) -> Estado:
	if not custo.maior_que(Jogo.dinheiro):
		return Estado.ALCANCAVEL
	if fracao(custo) >= PERTO_O_BASTANTE:
		return Estado.PERTO
	return Estado.LONGE


## Que fracao do custo o jogador ja tem, de 0 a 1.
##
## ⚠️ Custo zero ou negativo devolve 1: divisao por zero num contador de interface nao
## quebra o jogo, ela desenha "inf%" e ninguem descobre de onde veio.
static func fracao(custo: Grande) -> float:
	if custo.sinal() <= 0:
		return 1.0
	return clampf(Jogo.dinheiro.dividido(custo).para_float(), 0.0, 1.0)


## O brilho do estado. Estado fora da faixa cai no mais apagado em vez de estourar o
## indice: rotulo invisivel e ruim, quadro derrubado e pior.
static func brilho_de(estado: int) -> float:
	if estado < 0 or estado >= BRILHO.size():
		return BRILHO[BRILHO.size() - 1]
	return BRILHO[estado]
