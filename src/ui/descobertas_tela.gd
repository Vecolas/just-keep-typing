## O catalogo das descobertas -- e, principalmente, o BURACO do que falta (GDD §9 e §12).
##
## A tela mostra as sete categorias inteiras, encontradas e nao encontradas. O espaco
## vazio com formato reconhecivel e o que faz o jogador querer continuar: uma lista so com
## o que ele ja tem e um album fechado, e album fechado nao puxa ninguem.
##
## DESCOBERTA NAO REVELADA MOSTRA A RARIDADE, NUNCA O TEXTO. A raridade e a promessa; o
## texto e a recompensa. Adiantar o texto gasta a recompensa e deixa so a promessa.
##
## ⚠️ O jogo NAO GERA TEXTO (GDD §10). Tudo que aparece aqui foi escrito a mao num .tres.
##
## Paradoxal tem tratamento proprio: moldura em magenta cosmico, fundo com peso e a
## categoria marcada mesmo quando a descoberta ainda nao saiu. Ela quebra a quarta parede
## -- "o macaco descreveu exatamente o estado atual da sala" -- e a tela acompanha, senao
## a piada chega achatada no meio de uma lista de cards iguais. As descobertas paradoxais
## em si sao a issue #32; o tratamento entra antes delas de proposito, para a tela nao
## precisar mudar quando elas chegarem.
extends Control

const TITULO_ITEM: int = 22
const CATEGORIA_ITEM: int = 14
const TEXTO_ITEM: int = 18

## Marca de formato, nao texto: nao passa por traducao.
const SILHUETA := "? ? ?"

## Uma chave por valor do enum DadosDescoberta.Categoria, na mesma ordem.
const NOMES_DE_CATEGORIA: Array[String] = [
	"Comum", "Incomum", "Raro", "Épico", "Lendário", "Impossível", "Paradoxal",
]


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_ITEM)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%Contagem.add_theme_font_size_override("font_size", CATEGORIA_ITEM)
	%Contagem.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.2))
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)

	EventBus.descobertas_pedidas.connect(abrir)
	EventBus.descoberta_encontrada.connect(_ao_descobrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_montar()
	visible = true


func fechar() -> void:
	visible = false


## Esconde no ESC e come o espaco enquanto esta aberto: sem isto o jogador leria a tela
## digitando sem querer.
func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()


func _ao_descobrir(_descoberta: DadosDescoberta) -> void:
	if visible:
		_montar()


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


## Limpa antes de montar: repintar nao e reexecutar.
func _montar() -> void:
	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()

	var todas := Descobertas.todas()
	var achadas := Descobertas.quantas_encontradas()
	# molde no singular quando e uma so. Portugues pluraliza e ingles tambem, entao sao
	# dois moldes traduzidos e nao um "s" colado no fim -- colar sufixo em texto e o jeito
	# classico de a traducao sair errada em toda lingua que nao e a original
	var molde := "%s descoberta de %s" if achadas == 1 else "%s descobertas de %s"
	%Contagem.text = tr(molde) % [
		Formatador.formatar(Grande.de_float(float(achadas))),
		Formatador.formatar(Grande.de_float(float(todas.size()))),
	]
	for descoberta in todas:
		%Lista.add_child(_item(descoberta))


func _item(descoberta: DadosDescoberta) -> Control:
	var achada := Descobertas.encontrada(descoberta.id)
	var cor := _cor(descoberta.categoria)
	var paradoxal := descoberta.categoria == DadosDescoberta.Categoria.PARADOXAL

	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", _painel(cor, achada, paradoxal))

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 16 if achada else 12)
	moldura.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)

	# a raridade aparece SEMPRE, achada ou nao: e ela que da forma ao buraco
	var categoria := Label.new()
	categoria.text = tr(NOMES_DE_CATEGORIA[descoberta.categoria])
	categoria.add_theme_font_size_override("font_size", CATEGORIA_ITEM)
	categoria.add_theme_color_override("font_color", cor)
	coluna.add_child(categoria)

	var titulo := Label.new()
	titulo.text = tr(descoberta.nome) if achada else SILHUETA
	titulo.add_theme_font_size_override("font_size", TITULO_ITEM)
	titulo.add_theme_color_override(
		"font_color", cor if achada else Paleta.MONKEY_BROWN.lightened(0.1)
	)
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = tr(descoberta.texto) if achada else tr("Ainda não descoberto.")
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", TEXTO_ITEM)
	texto.add_theme_color_override(
		"font_color",
		Paleta.PAPER_CREAM if achada else Paleta.MONKEY_BROWN.lightened(0.1),
	)
	coluna.add_child(texto)

	if achada:
		var bonus := Label.new()
		# "x%s" e marca de formato, nao texto
		bonus.text = "x%s" % Formatador.formatar(Grande.de_float(descoberta.bonus))
		bonus.add_theme_font_size_override("font_size", CATEGORIA_ITEM)
		bonus.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
		coluna.add_child(bonus)
	return moldura


static func _cor(categoria: int) -> Color:
	if categoria < 0 or categoria >= Paleta.RARIDADES.size():
		return Paleta.PAPER_CREAM
	return Paleta.RARIDADES[categoria]


func _painel(cor: Color, achada: bool, paradoxal: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Paleta.INK_BROWN.lightened(0.06) if achada else Paleta.INK_BROWN
	estilo.border_color = cor if achada else cor.darkened(0.6)
	estilo.set_border_width_all(4 if paradoxal else 2)
	estilo.set_corner_radius_all(6)
	if paradoxal:
		# a unica categoria que ganha peso na propria moldura, achada ou nao
		estilo.bg_color = Paleta.VIOLETA_PROFUNDO.darkened(0.72)
	return estilo
