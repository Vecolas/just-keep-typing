## A FILA DE AVISOS (issue #69). Uma mensagem de prioridade menor nunca apaga uma maior.
##
## ⚠️ ELA EXISTE PORQUE UM SLOT SO NAO BASTA, e isso foi MEDIDO. Ate aqui a HUD tinha um
## unico rotulo de aviso: marco, descoberta e autosave escreviam por cima do anterior e
## reiniciavam o relogio. Em trinta minutos de partida:
##
##     avisos que a HUD mostrou:            82
##     apagados antes dos 1,6 s de leitura: 16  (20%)
##
## Um em cada cinco textos que o jogo escreve era fisicamente ilegivel. Conteudo que existe
## no banco de dados e o jogador nao consegue consumir nao e polimento -- e conteudo
## inexistente (decisao 0010).
##
## ⚠️ E A SOLUCAO NAO E AUMENTAR A DURACAO. Mais tempo na tela atrasa a fila inteira e faz
## o proximo aviso chegar depois do momento dele. O que resolve e PRIORIDADE: a mensagem
## importante espera menos, e nunca e apagada pela sem importancia.
##
## ⚠️ O QUE MUDOU DESDE ENTAO: AGORA SAO DUAS FILAS, E E POR ISSO QUE A DURACAO PODE CRESCER.
## A frase acima continua verdadeira DENTRO de uma fila -- e era so isso que ela dizia. Uma
## descoberta passou a ter faixa PROPRIA (o banner do topo), e numa fila em que so cabem
## descobertas e mudancas de era nao ha ruido operacional para atrasar. Sem a separacao, subir
## a duracao de uma descoberta Lendaria para 7 s seria atrasar sete segundos de autosave e de
## marco de tamanho; com ela, os 7 s nao custam nada a ninguem. Quem tem as duas instancias e
## o autoload Avisos.
##
## ⚠️ ELA NAO DESENHA NADA. E logica pura, sem no e sem cena -- por isso a suite consegue
## afirmar a ordem sem subir a HUD. Quem desenha e a hud.gd e o BannerDeDestaque.
class_name FilaDeAvisos
extends RefCounted

## ⚠️ A ORDEM DO ENUM E A PRIORIDADE, e maior valor ganha. Entrada nova entra NO LUGAR
## certo da escala, e nao no fim: aqui o enum nao e serializado em .tres nenhum, entao a
## regra do "valor novo entra no fim" nao se aplica -- o que manda e a leitura.
##
##   CRITICA   descoberta rara, teorema, mudanca de era
##   ALTA      descoberta, marco conceitual
##   NORMAL    marco comum, upgrade desbloqueado
##   BAIXA     mensagens operacionais
enum Prioridade {
	BAIXA,
	NORMAL,
	ALTA,
	CRITICA,
}

## EM QUE FAIXA DA TELA O ACONTECIMENTO APARECE (plano §9.4).
##
## São duas de propósito, e a separação é o que torna o banner possível:
##
##   RODAPE     linha discreta embaixo. Confirmação: marco de tamanho, operacional
##   DESTAQUE   banner grande no topo. Acontecimento: descoberta, era, teorema
##
## ⚠️ RODAPE E O ZERO, e isso e deliberado. Zero e o que todo acontecimento esquecido recebe,
## e o esquecido tem que cair na faixa que afirma MENOS: um banner gigante por omissao seria
## a tela inteira interrompida por uma gravacao automatica (CONVENCOES, "o valor zero de um
## enum").
enum Faixa {
	RODAPE,
	DESTAQUE,
}

## Quanto tempo cada prioridade fica na tela.
##
## ⚠️ INDEXADO PELO ENUM, e o tamanho sai de Prioridade.size(). Coleção dimensionada por
## literal e indexada por enum e uma bomba com timer (CONVENCOES).
const SEGUNDOS_POR_PRIORIDADE: Array[float] = [1.2, 1.6, 2.2, 3.0]

## Quanto tempo uma DESCOBERTA fica no banner, por raridade (plano §9.3).
##
## ⚠️ INDEXADO POR DadosDescoberta.Categoria, e o portao exige que o tamanho saia do enum.
##
## ⚠️ E ELES SAO MAIORES QUE OS DA TABELA DE PRIORIDADE, o que só pode existir porque o banner
## tem fila própria: a descoberta não disputa slot com autosave nem com marco de tamanho. O
## que estes números respondem é "quanto tempo leva para LER três linhas", e não "quanto uma
## descoberta vale" -- por isso o crescimento é suave, e não proporcional à raridade.
##
## ⚠️ Limite de DESIGN, e nao botao de tuning: tempo de leitura nao e balanceamento, e girar
## isto numa sessao de ajuste mexeria na legibilidade e em nada mais.
const SEGUNDOS_POR_CATEGORIA: Array[float] = [3.5, 4.0, 4.5, 5.0, 5.5, 6.5, 7.0]

## Teto da fila. ⚠️ SEM ELE, uma avalanche de eventos vira uma fila de trinta segundos que
## o jogador assiste sem poder pular -- e a issue #32 ja ensinou que seis avisos empilhados
## nao sao seis momentos: sao um so, e barulhento.
##
## Quando estoura, o que SAI e o de menor prioridade -- nunca o mais recente, que costuma
## ser o mais importante.
const CABEM: int = 6

## O que esta na tela agora, e por quanto tempo ainda.
var _atual: Dictionary = {}
var _ate_trocar: float = 0.0

## QUANTAS VEZES O CONTEUDO DA TELA JA TROCOU. So cresce.
##
## ⚠️ ELE EXISTE PORQUE `tique()` NAO CONSEGUE AVISAR A PRIMEIRA TROCA, e isso era um defeito
## SILENCIOSO de verdade: quando a fila esta vazia, `acrescentar()` mostra o aviso na hora --
## sem passar por `tique()` --, entao o tique daquele quadro devolve `false` e a tela nunca
## recebe ordem de pintar. O aviso ficava os 2,2 segundos dele NA FILA, invisivel, e sumia. So
## apareciam os que chegavam ATRAS de outro.
##
## A tela guarda o numero que ela desenhou e compara: diferente, repinta. Comparar o TEXTO nao
## serviria -- dois avisos iguais em sequencia dariam a mesma string e o segundo nao repintaria.
##
## ⚠️ E ELE NAO ZERA em limpar(): a tela guarda o ultimo numero que viu, e zerar aqui faria o
## proximo aviso nascer com a sequencia que a tela ja considera desenhada.
var _sequencia: int = 0

## Os que esperam. Ordenados por prioridade decrescente, e por chegada dentro dela.
var _esperando: Array[Dictionary] = []

## Tudo que passou, do mais recente para o mais antigo (issue #69).
##
## ⚠️ EXISTE PARA A MENSAGEM NAO SUMIR DO UNIVERSO. Se o jogador perdeu o aviso, ele ainda
## consegue saber o que aconteceu -- e isso reduz a ansiedade de leitura, que e o que fazia
## o aviso precisar ser grande e demorado.
##
## Estado de SESSAO: nao vai para o save. Registro de quinze minutos atras nao e progresso.
var _registro: Array[Dictionary] = []

const REGISTRO_MAXIMO: int = 20


## Poe um aviso na fila. `instante` e o tempo de jogo, para o registro.
##
## `extras` e a carga que a TELA le e a fila nao interpreta -- titulo, marca de raridade,
## detalhe do efeito. A unica chave que esta classe entende e `segundos`, que substitui a
## duracao da tabela de prioridade.
##
## ⚠️ `segundos` AUSENTE E DIFERENTE DE `segundos` ZERO, e por isso o sentinela e a AUSENCIA
## da chave e nao um zero: zero significaria "sai da tela no mesmo quadro em que entrou", que
## e um aviso que nao existe. Sentinela que colide com valor valido transforma um ajuste
## legitimo em "nao faz nada", em silencio (CONVENCOES).
func acrescentar(
	texto: String,
	prioridade: Prioridade,
	instante: float = 0.0,
	extras: Dictionary = {},
) -> void:
	if texto.strip_edges().is_empty():
		return
	var aviso := {
		"texto": texto,
		"prioridade": int(prioridade),
		"instante": instante,
		"extras": extras.duplicate(),
	}

	_registro.push_front(aviso)
	while _registro.size() > REGISTRO_MAXIMO:
		_registro.pop_back()

	# ⚠️ NADA INTERROMPE O QUE JA ESTA NA TELA, nem uma CRITICA. Trocar no meio da leitura e
	# exatamente o defeito que esta issue conserta, so que com regra: a critica fura a FILA,
	# e nao o aviso em exibicao.
	if _atual.is_empty():
		_mostrar(aviso)
		return

	_esperando.append(aviso)
	# ordem estavel por prioridade: quem chegou antes, dentro da mesma prioridade, sai antes
	_esperando.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["prioridade"]) > int(b["prioridade"]))
	while _esperando.size() > CABEM:
		_esperando.pop_back()


## Passa o tempo. Devolve `true` quando o que esta na tela mudou.
func tique(delta: float) -> bool:
	if _atual.is_empty() or delta <= 0.0:
		return false
	_ate_trocar -= delta
	if _ate_trocar > 0.0:
		return false
	if _esperando.is_empty():
		_atual = {}
		return true
	_mostrar(_esperando.pop_front())
	return true


func texto_atual() -> String:
	return str(_atual.get("texto", ""))


func prioridade_atual() -> int:
	return int(_atual.get("prioridade", Prioridade.BAIXA))


## A carga que a tela le. Vazia quando nao ha aviso, e vazia tambem quando quem acrescentou
## nao mandou nada -- a tela trata as duas do mesmo jeito.
func extras_atuais() -> Dictionary:
	return _atual.get("extras", {})


## De 0 a 1: quanto do tempo do aviso atual ainda resta. A HUD usa para o desvanecimento.
func quanto_resta() -> float:
	if _atual.is_empty():
		return 0.0
	return clampf(_ate_trocar, 0.0, 1.0)


func tem_aviso() -> bool:
	return not _atual.is_empty()


func quantos_esperando() -> int:
	return _esperando.size()


## O registro recente, do mais novo para o mais velho.
func registro() -> Array[Dictionary]:
	return _registro


func limpar() -> void:
	_atual = {}
	_ate_trocar = 0.0
	_esperando.clear()
	_registro.clear()
	# a sequencia NAO zera: ver o aviso em _sequencia
	_sequencia += 1


## Quantas vezes o conteudo da tela ja trocou. Quem desenha guarda este numero e repinta
## quando ele muda -- inclusive na PRIMEIRA vez, que e o caso que o tique nao alcanca.
func sequencia() -> int:
	return _sequencia


func _mostrar(aviso: Dictionary) -> void:
	_atual = aviso
	_ate_trocar = _duracao_de(aviso)
	_sequencia += 1


func _duracao_de(aviso: Dictionary) -> float:
	var extras: Dictionary = aviso.get("extras", {})
	if extras.has("segundos"):
		# piso: duracao invalida vinda de fora nao pode virar um aviso que nunca aparece
		return maxf(float(extras["segundos"]), SEGUNDOS_POR_PRIORIDADE[Prioridade.BAIXA])
	var prioridade: int = clampi(
		int(aviso["prioridade"]), 0, SEGUNDOS_POR_PRIORIDADE.size() - 1
	)
	return SEGUNDOS_POR_PRIORIDADE[prioridade]


# --- a classificacao ------------------------------------------------------------------
#
# ⚠️ AS QUATRO FUNCOES ABAIXO SAO ESTATICAS DE PROPOSITO, e isso mata uma segunda fonte que
# ja existia. As regras de "descoberta Lendaria e critica, marco de tamanho e normal" viviam
# em DOIS lugares: no autoload Avisos, que manda na tela, e em tools/observar.gd, que MEDE
# quantos avisos o jogador nao conseguiu ler. Copia da regra na regua e a pior copia
# possivel -- ela nao muda o jogo, ela muda o NUMERO que decide se o jogo esta bom.
#
# Ficam aqui, e nao no autoload, porque uma regua precisa chamar isto sem subir autoload
# nenhum. Aqui e a classe que ja e a dona do enum Prioridade.


## A prioridade de um marco. ⚠️ SAI DO DADO, e nao de uma lista de ids: marco conceitual e o
## que prepara a transicao para o endgame (issue #51), e ele espera menos que um marco de
## tamanho -- que e mais um numero grande entre noventa e um.
static func prioridade_de_marco(marco: DadosMarco) -> Prioridade:
	return (
		Prioridade.ALTA if marco.tipo == DadosMarco.Tipo.CONCEITUAL else Prioridade.NORMAL
	)


## A prioridade de uma descoberta. ⚠️ IDEM: a raridade ja existe no dado desde a issue #17.
## Uma Lendaria que chega igual a uma Comum e a promessa do sistema de raridade sendo
## desmentida pela interface.
static func prioridade_de_descoberta(descoberta: DadosDescoberta) -> Prioridade:
	return (
		Prioridade.CRITICA
		if descoberta.categoria >= DadosDescoberta.Categoria.LENDARIO
		else Prioridade.ALTA
	)


## Em que faixa da tela um marco aparece.
##
## ⚠️ SO O CONCEITUAL VAI PARA O BANNER, e a razao e a mesma pela qual o ciano e raro: o
## banner só continua significando "aconteceu algo" enquanto nao acontecer o tempo todo. Sao
## noventa e cinco marcos numa campanha, e a grande maioria e mais um numero grande -- esses
## confirmam no rodape, que e o papel deles. O conceitual e o que diz que as comparacoes
## pararam de servir, e esse muda o que o jogador entende.
static func faixa_de_marco(marco: DadosMarco) -> Faixa:
	return (
		Faixa.DESTAQUE if marco.tipo == DadosMarco.Tipo.CONCEITUAL else Faixa.RODAPE
	)


## Em que faixa uma descoberta aparece. ⚠️ TODAS VAO PARA O BANNER, inclusive a Comum: a
## descoberta e o texto que o macaco produziu por acidente (GDD §9) -- e o conteudo
## colecionavel do jogo, e nao uma confirmacao de sistema. Era justamente ela que aparecia e
## sumia numa linha de rodape de treze pixels.
static func faixa_de_descoberta(_descoberta: DadosDescoberta) -> Faixa:
	return Faixa.DESTAQUE


## Quantos segundos a descoberta fica no banner. Categoria fora da faixa cai na Comum em vez
## de estourar o indice -- e ela e a MENOR das duracoes, entao o erro aparece como um banner
## curto e nao como um banner preso na tela.
static func segundos_de_descoberta(categoria: int) -> float:
	if categoria < 0 or categoria >= SEGUNDOS_POR_CATEGORIA.size():
		return SEGUNDOS_POR_CATEGORIA[0]
	return SEGUNDOS_POR_CATEGORIA[categoria]
