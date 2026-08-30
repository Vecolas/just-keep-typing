## A tela que da significado ao numero (GDD §7 e §45).
##
## O GDD e explicito: o diferencial do jogo nao e o numero subindo, e o jogador descobrir
## o que aquele numero SIGNIFICA -- e por isso o Panorama recebe tanta atencao quanto os
## upgrades. Aqui isso vira uma regra de leitura: o TEXTO do marco e a estrela da tela, e
## ele nao divide linha com numero grande. O requisito fica acima, pequeno e apagado.
##
## Tres estados, e os tres importam:
##
##   alcancado   texto completo, e o jogador rele quando quiser
##   atual       o ultimo cruzado, em destaque, porque e onde ele esta
##   proximo     EM SILHUETA -- o requisito aparece, a comparacao nao
##
## A silhueta e o motor da tela. O jogador tem que querer chegar la so para descobrir a
## comparacao; mostrar o texto antes da hora gasta a unica recompensa que o Panorama tem.
## Nada depois do proximo aparece, pelo mesmo motivo.
##
## Monta a lista so quando abre e quando um marco e cruzado, nunca por quadro: sao ate
## cem itens na v0.2 (issue #19), e remontar cem nos sessenta vezes por segundo seria
## queimar quadro para desenhar exatamente a mesma coisa.
extends Control

const TITULO_ITEM: int = 26
const REQUISITO_ITEM: int = 14
const TEXTO_ITEM: int = 19

## Marca de formato, nao texto: nao passa por traducao.
const SILHUETA := "? ? ?"


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_ITEM)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)

	EventBus.panorama_pedido.connect(abrir)
	EventBus.marco_alcancado.connect(_ao_alcancar)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_montar()
	visible = true


func fechar() -> void:
	visible = false


## Esconde no ESC e come o espaco enquanto esta aberto: sem isto o jogador leria o
## Panorama digitando sem querer, e sairia dele com um contador diferente do que entrou.
func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()


func _ao_alcancar(_marco: DadosMarco) -> void:
	if visible:
		_montar()


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


## Limpa antes de montar: repintar nao e reexecutar, e chamar de novo nao pode empilhar
## uma segunda copia do Panorama inteiro so porque a pessoa cruzou um marco com a tela
## aberta.
func _montar() -> void:
	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()

	var atual := Marcos.atual()
	for marco in Marcos.todos():
		if not Marcos.alcancado(marco.id):
			break
		%Lista.add_child(_item(marco, marco == atual, false))

	var proximo := Marcos.proximo()
	if proximo != null:
		%Lista.add_child(_item(proximo, false, true))


func _item(marco: DadosMarco, destaque: bool, silhueta: bool) -> Control:
	var moldura := PanelContainer.new()
	var borda := Paleta.BANANA_GOLD if destaque else Color(0, 0, 0, 0)
	moldura.add_theme_stylebox_override("panel", Tema.painel(borda, destaque))

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 20 if destaque else 12)
	moldura.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 6)
	margem.add_child(coluna)

	# o requisito fica aqui em cima, pequeno e apagado. Ele nao divide linha com o texto:
	# numero grande ao lado da frase rouba a frase, e a frase e a razao da tela existir
	var requisito := Label.new()
	requisito.text = Formatador.formatar(marco.requisito_grande())
	requisito.add_theme_font_size_override("font_size", REQUISITO_ITEM)
	requisito.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.2))
	coluna.add_child(requisito)

	var titulo := Label.new()
	titulo.text = SILHUETA if silhueta else tr(marco.titulo)
	titulo.add_theme_font_size_override("font_size", TITULO_ITEM)
	titulo.add_theme_color_override(
		"font_color",
		Paleta.MONKEY_BROWN.lightened(0.1) if silhueta else Paleta.BANANA_GOLD,
	)
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = tr("O próximo marco ainda é um mistério.") if silhueta else tr(marco.texto)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", TEXTO_ITEM)
	texto.add_theme_color_override(
		"font_color",
		Paleta.MONKEY_BROWN.lightened(0.1) if silhueta else Paleta.PAPER_CREAM,
	)
	coluna.add_child(texto)
	return moldura

