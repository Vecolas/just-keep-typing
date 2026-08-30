## A tela de estatisticas, uteis e inuteis (GDD §23 e §24).
##
## As inuteis nao sao um apendice: elas sao metade da piada, e por isso ficam na mesma
## tela e no mesmo formato das uteis, separadas so por um titulo. Escondidas numa aba
## propria virariam conteudo opcional, e conteudo opcional ninguem abre.
##
## Toda linha aqui formata numero, entao a tela ESCUTA EventBus.idioma_mudou -- o Godot
## retraduz sozinho apenas o text que veio da cena, e aqui tudo e montado em codigo.
##
## Remonta so ao abrir e ao trocar de idioma. Numero que muda a cada quadro fica so no
## contador da HUD: uma tela de estatisticas que pisca inteira sessenta vezes por segundo
## e ilegivel, e ninguem le estatistica com pressa.
extends Control

const TITULO_TELA: int = 22
const SECAO: int = 15
const ROTULO: int = 17


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_TELA)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	# o Titulo herda a expansao que era da Contagem, senao o Fechar cola no titulo em vez
	# de ir para a borda -- esconder um no de container nao redistribui o espaco dele
	%Contagem.visible = false
	%Titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)
	%Lista.add_theme_constant_override("separation", 6)

	EventBus.estatisticas_pedidas.connect(abrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_montar()
	visible = true


func fechar() -> void:
	visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


## Limpa antes de montar: repintar nao e reexecutar.
func _montar() -> void:
	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()

	for linha in Estatisticas.uteis():
		%Lista.add_child(_linha(linha["rotulo"], Formatador.formatar(linha["valor"])))
	for linha in Estatisticas.tempos():
		%Lista.add_child(_linha(linha["rotulo"], linha["valor"]))

	%Lista.add_child(_secao("SEM GRANDE UTILIDADE"))
	for linha in Estatisticas.inuteis():
		%Lista.add_child(_linha(linha["rotulo"], Formatador.formatar(linha["valor"])))


## Rotulo a esquerda, numero a direita. Duas colunas e nao uma frase montada: numero
## alinhado se compara com o olho, e comparar duas leituras da mesma estatistica e a unica
## coisa que se faz com esta tela.
func _linha(rotulo: String, valor: String) -> Control:
	var caixa := HBoxContainer.new()

	var esquerda := Label.new()
	esquerda.text = tr(rotulo)
	esquerda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esquerda.add_theme_font_size_override("font_size", ROTULO)
	esquerda.add_theme_color_override("font_color", Paleta.PAPER_CREAM)
	caixa.add_child(esquerda)

	var direita := Label.new()
	direita.text = valor
	direita.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	direita.add_theme_font_size_override("font_size", ROTULO)
	direita.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	caixa.add_child(direita)
	return caixa


func _secao(titulo: String) -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 4)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 24)
	caixa.add_child(espaco)

	var rotulo := Label.new()
	rotulo.text = tr(titulo)
	rotulo.add_theme_font_size_override("font_size", SECAO)
	rotulo.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.25))
	caixa.add_child(rotulo)
	return caixa
