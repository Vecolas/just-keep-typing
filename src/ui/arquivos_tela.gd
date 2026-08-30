## A tela de Arquivos, em rascunho (issue #38): um botao por Manuscrito e o caminho de
## volta.
##
## ⚠️ FEIA DE PROPOSITO, como o menu. Criar com nome, excluir com confirmacao e a leitura
## completa de cada Manuscrito sao a issue #40; o que existe aqui e escolher qual slot
## abrir, que e o pedaco que o fluxo precisa.
##
## ⚠️ LE METADADO, NAO PARTIDA. Desenhar tres linhas nao pode custar abrir tres saves --
## cada um creditaria producao offline por cima do outro (issue #35). Config.
## manuscrito_do_slot responde sem tocar no Jogo.
##
## Os tres estados aparecem como tres coisas diferentes, e nao como duas: vazio convida,
## cheio continua, e ILEGIVEL avisa. Slot ilegivel tratado como vazio ofereceria comecar
## por cima de centenas de horas que so estao dificeis de ler.
extends Control

const TITULO: int = 40
const LARGURA_DO_BOTAO: int = 720

var _titulo: Label = null
var _voltar: Button = null
var _slots: Array[Button] = []


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
	centro.add_theme_constant_override("separation", 12)
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", TITULO)
	_titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	centro.add_child(_titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 32)
	centro.add_child(espaco)

	for numero in range(1, Config.SLOTS + 1):
		var botao := _botao(centro, "BotaoSlot%d" % numero)
		botao.pressed.connect(_ao_escolher.bind(numero))
		_slots.append(botao)

	var respiro := Control.new()
	respiro.custom_minimum_size = Vector2(0, 32)
	centro.add_child(respiro)

	_voltar = _botao(centro, "BotaoVoltar")
	_voltar.pressed.connect(Cenas.ir_para_menu)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	_pintar()


func _pintar() -> void:
	_titulo.text = tr("MANUSCRITOS")
	_voltar.text = tr("VOLTAR")
	for i in _slots.size():
		var manuscrito := Config.manuscrito_do_slot(i + 1)
		_slots[i].text = _rotulo_de(manuscrito)
		# ilegivel nao e escolha: abrir levaria o jogador a uma partida que nao carrega.
		# Recuperar isso e assunto do backup (issue #36), e apagar e da issue #40.
		_slots[i].disabled = manuscrito.ilegivel()


## O que cada linha diz. Um Manuscrito cheio se apresenta pelo que ele e -- nome, era e
## total --, que e a unica coisa que faz o jogador reconhecer a propria partida entre tres.
func _rotulo_de(manuscrito: Manuscrito) -> String:
	if manuscrito.ilegivel():
		return "%d — %s" % [manuscrito.slot, tr("Manuscrito ilegível")]
	if manuscrito.vazio():
		return "%d — %s" % [manuscrito.slot, tr("Manuscrito vazio")]

	var nome := manuscrito.nome
	if nome.strip_edges().is_empty():
		# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
		nome = tr("Manuscrito %d") % manuscrito.slot
	var era := ErasCatalogo.por_id(manuscrito.era)
	return "%d — %s  %s  %s" % [
		manuscrito.slot, nome,
		tr(era.nome) if era != null else "",
		Formatador.formatar(manuscrito.total_caracteres),
	]


func _botao(pai: Node, nome_do_no: String) -> Button:
	var botao := Button.new()
	botao.name = nome_do_no
	botao.custom_minimum_size = Vector2(LARGURA_DO_BOTAO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.focus_mode = Control.FOCUS_NONE
	pai.add_child(botao)
	return botao


func _ao_escolher(numero: int) -> void:
	Cenas.comecar_partida(numero)


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()
