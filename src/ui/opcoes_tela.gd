## A tela de opcoes (CONVENCOES.md, "Idioma" e "Video e opcoes").
##
## ⚠️ ESTA TELA NAO SABE O QUE E IDIOMA, RESOLUCAO NEM SLOT. Ela percorre Config.CAMPOS e,
## para cada nome, pergunta rotulos_de / indice_de e devolve escolher. Opcao nova e uma
## entrada em PADRAO, uma em CAMPOS e um ramo em cada uma das tres funcoes do Config --
## nenhuma linha DAQUI muda.
##
## E por isso que _campo() nao tem `match`: no dia em que alguem precisar de um `if campo
## == "resolucao"` aqui dentro, a generalizacao ja quebrou e o lugar certo do conserto e o
## Config.
##
## O volume e o unico que nao e lista, e por isso tem controle proprio. Lista de volumes
## seria uma lista de numeros arbitrarios onde o mundo inteiro usa uma barra.
##
## ESCUTA idioma_mudou e se remonta. Os rotulos "Janela" e "Tela cheia" sao montados em
## codigo com tr(), e o Godot so retraduz sozinho o que veio da cena -- sem isto eles
## ficariam em portugues numa interface ja em ingles (CONVENCOES.md).
extends Control

const TITULO_TELA: int = 22
const ROTULO_CAMPO: int = 18
const DICA: int = 14

## Largura dos controles. Fixa, e nao esticada ate a borda: um OptionButton de mil e
## duzentos pixels para escrever "1280x720" e o tipo de campo que a pessoa nao sabe onde
## clicar.
const LARGURA_DO_CAMPO: int = 360

## Um rotulo por nome de Config.CAMPOS, na mesma ordem. Mora aqui e nao no Config porque e
## texto de tela, e o Config nao fala com o jogador.
## ⚠️ O rotulo do campo e a PERGUNTA, nunca uma das respostas. A primeira versao chamava o
## campo de "Janela" e a primeira opcao dele tambem era "Janela" -- em ingles a captura
## saiu com "Windowed" escrito duas vezes, uma em cima da outra.
const ROTULOS: Dictionary = {
	"idioma": "Idioma",
	"resolucao": "Resolução",
	"tela_cheia": "Modo de janela",
	"slot": "Slot de save",
}

## Dica por campo, ou vazio. A da resolucao existe porque a lista curta parece defeito:
## quem tem 1080p nao ve 1440p e conclui que o jogo esqueceu.
const DICAS: Dictionary = {
	"resolucao": "Só aparecem as resoluções que cabem no seu monitor.",
	"slot": "Trocar de slot grava a partida aberta antes de sair dela.",
}


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_TELA)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)

	EventBus.opcoes_pedidas.connect(abrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_montar()
	visible = true


func fechar() -> void:
	visible = false


## Esconde no ESC e come o espaco enquanto esta aberta: sem isto o jogador mexeria nas
## opcoes digitando sem querer.
func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


func _montar() -> void:
	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()
	for campo in Config.CAMPOS:
		%Lista.add_child(_campo(campo))
	%Lista.add_child(_volume())


## Um campo de lista qualquer. Repare que nada aqui menciona idioma, resolucao ou slot.
func _campo(campo: String) -> Control:
	var linha := VBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)

	var rotulo := Label.new()
	rotulo.text = tr(str(ROTULOS.get(campo, campo)))
	rotulo.add_theme_font_size_override("font_size", ROTULO_CAMPO)
	rotulo.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	linha.add_child(rotulo)

	var botao := OptionButton.new()
	botao.focus_mode = Control.FOCUS_NONE
	botao.custom_minimum_size = Vector2(LARGURA_DO_CAMPO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# o rotulo do OptionButton vem dos itens que ele mesmo recebeu, e nao de uma chave do
	# CSV -- traduzir de novo procuraria "1920x1080" na tabela e acharia nada
	botao.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for texto in Config.rotulos_de(campo):
		botao.add_item(texto)
	botao.selected = Config.indice_de(campo)
	# ⚠️ campo que nao faz nada tem que PARECER que nao faz nada: em tela cheia a resolucao
	# fica apagada, senao a pessoa mexe nela e conclui que o jogo ignorou a escolha
	botao.disabled = Config.apagado(campo)
	botao.item_selected.connect(func(indice: int) -> void: _escolher(campo, indice))
	linha.add_child(botao)

	if DICAS.has(campo):
		var dica := Label.new()
		dica.text = tr(str(DICAS[campo]))
		dica.add_theme_font_size_override("font_size", DICA)
		dica.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.2))
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		linha.add_child(dica)

	return linha


## Remonta a tela inteira depois de escolher. Custa quatro OptionButtons e resolve o unico
## acoplamento que sobraria: tela cheia apaga a resolucao, e a resolucao nao sabe disso.
func _escolher(campo: String, indice: int) -> void:
	Config.escolher(campo, indice)
	_montar()


func _volume() -> Control:
	var linha := VBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)

	var rotulo := Label.new()
	rotulo.text = tr("Volume")
	rotulo.add_theme_font_size_override("font_size", ROTULO_CAMPO)
	rotulo.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	linha.add_child(rotulo)

	var barra := HSlider.new()
	barra.focus_mode = Control.FOCUS_NONE
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.step = 0.05
	barra.value = Config.volume()
	barra.custom_minimum_size = Vector2(LARGURA_DO_CAMPO, 0)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	barra.value_changed.connect(func(valor: float) -> void: Config.definir_volume(valor))
	linha.add_child(barra)

	return linha
