## O menu principal, em rascunho (issue #38).
##
## ⚠️ FEIO DE PROPOSITO. Esta e a Fase 2 do plano do menu: fluxo solido com interface
## temporaria. O menu que o jogador vai ver -- cenario, logo, botoes de placa, a mesa ao
## fundo -- e a issue #46, e a abertura datilografada e a #47. O que existe aqui e o
## caminho: daqui da para chegar na partida e voltar.
##
## CONTINUAR nao carrega nada por conta propria: ele so diz ao Cenas qual Manuscrito abrir,
## que e o mesmo que a tela de Arquivos faz. Dois caminhos ate uma partida seriam dois
## lugares para esquecer de creditar o offline.
##
## Le o metadado do slot, e nao a partida dele (issue #35): saber se ha o que continuar nao
## pode custar abrir um save.
extends Control

const TITULO: int = 64
const LARGURA_DO_BOTAO: int = 420

var _titulo: Label = null
var _continuar: Button = null
var _manuscritos: Button = null
var _sair: Button = null


func _ready() -> void:
	theme = Tema.montar()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Paleta.INK_BROWN.darkened(0.4)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := VBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 16)
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", TITULO)
	_titulo.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	centro.add_child(_titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 48)
	centro.add_child(espaco)

	# os nos ganham nome porque a fumaca aperta ESTES botoes, e nao chama o Cenas por
	# baixo: o que se prova aqui e a ligacao, e find_child por indice quebraria na primeira
	# vez que alguem acrescentasse uma opcao no meio
	_continuar = _botao(centro, "BotaoContinuar")
	_continuar.pressed.connect(_ao_continuar)
	_manuscritos = _botao(centro, "BotaoManuscritos")
	_manuscritos.pressed.connect(Cenas.ir_para_arquivos)
	_sair = _botao(centro, "BotaoSair")
	_sair.pressed.connect(_ao_sair)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	_pintar()


## Repintar nao e remontar: os botoes ja existem, e so o texto deles muda de lingua
## (CONVENCOES.md). Chamar isto de novo nao pode empilhar botao nenhum.
func _pintar() -> void:
	# o titulo do jogo nao se traduz, mas passa por tr() do mesmo jeito: a linha existe no
	# CSV nas duas colunas, e assim o dia em que ele mudar de nome numa lingua so nao exige
	# tocar em codigo
	_titulo.text = tr("JUST KEEP TYPING")
	_continuar.text = tr("CONTINUAR")
	_manuscritos.text = tr("MANUSCRITOS")
	_sair.text = tr("SAIR")
	# so ha o que continuar se o slot lembrado tiver Manuscrito. Slot ilegivel tambem
	# desabilita: mandar o jogador para uma partida que nao abre e pior que nao oferecer
	_continuar.disabled = not Config.manuscrito_do_slot(Config.slot()).cheio()


func _botao(pai: Node, nome_do_no: String) -> Button:
	var botao := Button.new()
	botao.name = nome_do_no
	botao.custom_minimum_size = Vector2(LARGURA_DO_BOTAO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.focus_mode = Control.FOCUS_NONE
	pai.add_child(botao)
	return botao


func _ao_continuar() -> void:
	Cenas.comecar_partida(Config.slot())


func _ao_sair() -> void:
	get_tree().quit(0)


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()
