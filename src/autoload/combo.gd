## O combo de digitacao (issue #54). Digitar acelera; parar nunca pune.
##
##   atividade -> ACELERA      ✅
##   atividade -> OBRIGATORIA  ❌
##
## ⚠️ ELE MULTIPLICA SO O QUE O JOGADOR DIGITA -- nunca a producao automatica. Essa e a
## decisao inteira desta issue, e ela resolve sozinha tres exigencias que de outro jeito
## precisariam de tres mecanismos:
##
##   ENVELHECE SOZINHO. O plano pede que o combo deixe de ser relevante conforme a
##   automacao cresce, quando o jogador passa de operador a administrador. Um multiplicador
##   global de x1,5 continuaria valendo x1,5 na era 14 -- ele nunca envelheceria. Preso ao
##   clique, ele se apaga sozinho: quando o macaco produz um bilhao por segundo, o que a
##   mao acrescenta ja nao aparece no numero, sem ninguem ter desligado nada.
##
##   NAO VIRA IMPOSTO. A progressao roda inteira na producao automatica, que o combo nao
##   toca. Quem nao pode digitar rapido nao fica preso atras dele -- ele acelera os
##   primeiros minutos e some do calculo depois.
##
##   NAO PRECISA DE TETO CONTRA ABUSO. Nao existe estrategia de segurar o dedo no teclado
##   por uma hora: o retorno do clique e minusculo contra a automacao, e a carencia mais o
##   decaimento ja limitam o resto.
##
## ⚠️ E ELE NAO ENCOSTA NO EASTER EGG DO MENU (issue #49). Sao duas coisas com a mesma
## entrada e propositos opostos: aquele e visual e nao toca no save, este mexe em producao
## e so existe dentro da partida. O combo nao escuta tecla nenhuma -- ele e AVISADO por
## Economia.digitar(), que e o unico caminho pelo qual um caractere nasce da mao do
## jogador. Um segundo _unhandled_input escutando ui_accept seria um segundo caminho para
## a mesma coisa, e os dois divergiriam.
extends Node

const CAMINHO := "res://data/combo.tres"

## Intensidade de 0 a 1. O multiplicador SAI dela e nunca e guardado multiplicado
## (CONVENCOES.md, regra 2): quem quiser o numero pergunta na hora.
##
## ⚠️ NAO VAI PARA O SAVE, de proposito. Combo e estado de sessao: gravar o combo faria
## fechar o jogo no pico e reabrir depois valer mais do que continuar jogando, que e o
## incentivo exatamente ao contrario do que a issue pede.
var _intensidade: float = 0.0

## Quanto falta da carencia antes de voltar a cair.
var _graca: float = 0.0

var _dados: DadosCombo = null


func _ready() -> void:
	_dados = ResourceLoader.load(CAMINHO) as DadosCombo
	if _dados == null:
		push_error("Combo: %s nao carregou" % CAMINHO)

	# ⚠️ Quem liga, desliga -- e no ciclo de vida de quem ligou. Os dois prestigios e a
	# carga de um save comecam uma partida diferente, e um combo sobrevivente seria
	# producao da partida anterior entrando na nova sem ninguem ter digitado nada.
	#
	# Sao os DOIS prestigios porque sao dois sistemas: teorema (GDD §23) e reescrita do
	# universo (GDD §29). Ligar so num deles deixaria o outro com o defeito, e nada
	# apontaria para ca.
	EventBus.teorema_provado.connect(_ao_prestigiar)
	EventBus.universo_reescrito.connect(_ao_prestigiar)
	EventBus.jogo_carregado.connect(_zerar)


## O multiplicador de agora, entre 1,0 e o teto. Lido na hora, sempre.
func multiplicador() -> float:
	if _dados == null:
		return 1.0
	return 1.0 + _intensidade * (_dados.teto - 1.0)


func intensidade() -> float:
	return _intensidade


func teto() -> float:
	return _dados.teto if _dados != null else 1.0


## Um ou mais caracteres acabaram de sair da mao do jogador.
##
## ⚠️ QUEM CHAMA ISTO CREDITA ANTES E MARCA DEPOIS. A ordem e contrato: marcando primeiro,
## a propria tecla ganharia o aumento que ela mesma causou, e o primeiro caractere de uma
## partida nova sairia valendo mais que um. Ver Economia.digitar().
func marcar(quantos: int = 1) -> void:
	if _dados == null or quantos <= 0:
		return
	_intensidade = minf(1.0, _intensidade + _dados.ganho_por_tecla * float(quantos))
	_graca = _dados.segundos_de_graca


## Passa o tempo. Chamado pelo tique da partida, junto de Economia.acumular().
func decair(delta: float) -> void:
	if _dados == null or delta <= 0.0 or _intensidade <= 0.0:
		return
	if _graca > 0.0:
		_graca -= delta
		if _graca > 0.0:
			return
		# o que sobrou do delta depois da carencia ainda derruba combo: descartar isso
		# faria um tique grande custar menos que dois pequenos, e o decaimento passaria a
		# depender da taxa de quadros
		delta = -_graca
		_graca = 0.0
	_intensidade = maxf(0.0, _intensidade - _dados.decaimento_por_segundo * delta)


## Os dois sinais de prestigio carregam um Grande que nao interessa aqui: quem zera o
## combo nao se importa com QUANTO rendeu, so com o fato de a partida ter recomecado.
func _ao_prestigiar(_quanto: Grande) -> void:
	_zerar()


func _zerar() -> void:
	_intensidade = 0.0
	_graca = 0.0
