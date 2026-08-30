## O no que tem o quadro. Abre a partida, faz o relogio andar, transforma clique em
## caractere e grava de tempos em tempos.
##
## E o unico lugar do jogo com _process, e de proposito: Jogo so guarda estado e Economia
## so calcula, entao alguem precisa ser o tique -- e quem tem quadro e a cena. Pelo mesmo
## motivo a SEQUENCIA DE ABERTURA mora aqui: carregar o save, creditar o offline e comecar
## a contar sao tres coisas em ordem, e ordem e responsabilidade de quem orquestra.
##
## Nao desenha nada. A HUD e um irmao no CanvasLayer, ouvindo o EventBus; este script
## continua sem saber que ela existe.
extends Node

## De quanto em quanto tempo a partida e gravada. Trinta segundos e o maximo de progresso
## que um desligamento na tomada pode custar -- e o minimo de escrita em disco que nao
## incomoda. Gravar todo quadro seria escrever num arquivo sessenta vezes por segundo
## para salvar uma diferenca que o jogador nem enxerga.
const INTERVALO_DE_GRAVACAO: float = 30.0

var _ate_gravar: float = INTERVALO_DE_GRAVACAO


func _ready() -> void:
	var gravado_em := Save.carregar()
	if gravado_em > 0.0:
		# o relogio entra AQUI e nao dentro da conta: a conta e pura para poder ser
		# testada em 4 horas sem ninguem esperar 4 horas (issue #9)
		Economia.creditar_offline(Time.get_unix_time_from_system() - gravado_em)
	# quatro horas fora podem atravessar tres faixas de escala de uma vez
	Marcos.verificar()


func _process(delta: float) -> void:
	Economia.acumular(delta)
	Marcos.verificar()

	_ate_gravar -= delta
	if _ate_gravar <= 0.0:
		_ate_gravar = INTERVALO_DE_GRAVACAO
		Save.gravar()


## Fechar a janela grava. Sem isto, tudo que foi produzido desde a ultima gravacao
## automatica some -- e some justamente no gesto que o jogador entende como "sair", que e
## quando ele mais espera que o jogo tenha guardado.
func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.gravar()


## _unhandled_input, e nao _input, de proposito: assim o botao da loja consome o clique
## antes de chegar aqui, e comprar um macaco nao digita um caractere de brinde.
##
## A tecla existe porque a mao cansa antes da primeira compra: sao dez cliques ate o
## Instinto Digitador, e obrigar todos eles no mouse e o tipo de atrito que faz alguem
## fechar o jogo nos primeiros trinta segundos.
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_accept"):
		_digitar()
		return
	if (
		evento is InputEventMouseButton
		and evento.button_index == MOUSE_BUTTON_LEFT
		and evento.pressed
	):
		_digitar()


func _digitar() -> void:
	Economia.digitar()
	get_viewport().set_input_as_handled()
