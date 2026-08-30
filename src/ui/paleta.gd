## Paleta canonica da identidade visual. Ver docs/ARTE.md, secao 6.
##
## E constante e nao .tres de proposito: cor de identidade nao e numero de balanceamento.
## Ninguem vai querer mexer nela numa sessao de tuning, e uma paleta que muda por arquivo
## de dados e uma paleta que vai divergir entre telas. Ver CONVENCOES.md, "Checagem de arte".
##
## O jogador aprende sozinho, por repeticao e nunca por tutorial, que dourado e producao,
## ciano e automacao e magenta e prestigio. Quebrar essa associacao numa tela custa mais do
## que qualquer ganho estetico daquela tela.
##
## ⚠️ Evite branco puro: o claro do jogo e PAPER_CREAM.
## ⚠️ Ciano com moderacao -- ele so continua especial enquanto for raro.
class_name Paleta

const BANANA_GOLD := Color("F6C74F")
const MECHANICAL_GOLD := Color("E8B12E")
const MONKEY_BROWN := Color("8B5E34")
const INK_BROWN := Color("2B1E14")
const PAPER_CREAM := Color("F4E9D8")
const COSMIC_NAVY := Color("0E1B2E")
const INFINITY_CYAN := Color("00E5FF")
const VIOLETA_PROFUNDO := Color("663399")
const MAGENTA_COSMICO := Color("B14CFF")

## Cores de raridade da secao 9 do docs/ARTE.md. Cinco das sete sao cores oficiais da
## paleta; as outras duas o documento nomeia sem dar hex, e por isso sao DERIVADAS daqui
## em vez de inventadas do zero:
##
##   azul  -- entre os dois azuis oficiais, porque Cosmic Navy sozinho e fundo e nao texto
##   verde -- ⚠️ O UNICO VALOR SEM ORIGEM NO DOCUMENTO. Escolhido para conviver com o
##            marrom e o dourado do early game. Precisa entrar na ARTE.md para virar
##            canone; ate la e proposta, e nao cor oficial.
const RARIDADE_COMUM := PAPER_CREAM
const RARIDADE_INCOMUM := Color("8FA55A")
const RARIDADE_RARO := Color("3E7FA8")
const RARIDADE_EPICO := VIOLETA_PROFUNDO
const RARIDADE_LENDARIO := BANANA_GOLD
const RARIDADE_IMPOSSIVEL := INFINITY_CYAN
const RARIDADE_PARADOXAL := MAGENTA_COSMICO

## Na ordem do enum DadosDescoberta.Categoria.
const RARIDADES: Array[Color] = [
	RARIDADE_COMUM,
	RARIDADE_INCOMUM,
	RARIDADE_RARO,
	RARIDADE_EPICO,
	RARIDADE_LENDARIO,
	RARIDADE_IMPOSSIVEL,
	RARIDADE_PARADOXAL,
]

