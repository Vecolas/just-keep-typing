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
##   e nenhum    depois do ultimo marco nao entra linha nenhuma (ver _montar)
##
## A silhueta e o motor da tela. O jogador tem que querer chegar la so para descobrir a
## comparacao; mostrar o texto antes da hora gasta a unica recompensa que o Panorama tem.
## Nada depois do proximo aparece, pelo mesmo motivo.
##
## Monta a lista so quando abre e quando um marco e cruzado, nunca por quadro: sao ate
## cem itens na v0.2 (issue #19), e remontar cem nos sessenta vezes por segundo seria
## queimar quadro para desenhar exatamente a mesma coisa.
##
## Tem class_name para a suite poder perguntar a MARCA de cada tipo de marco sem subir cena
## nenhuma -- copiar a lista para dentro do teste criaria uma segunda tabela.
class_name Panorama
extends Control

const TITULO_ITEM: int = 26
const REQUISITO_ITEM: int = 14
const TEXTO_ITEM: int = 19

## Marca de formato, nao texto: nao passa por traducao.
const SILHUETA := "? ? ?"

## A MARCA DE CADA TIPO DE MARCO (issue #51), na ordem do enum DadosMarco.Tipo.
##
## ⚠️ FORMA + NOME, e nunca cor sozinha. E a mesma regra da raridade das descobertas
## (issue #43): quem nao distingue matiz tem que ler o tipo do mesmo jeito. A marca se le
## de relance; o nome ao lado dela e quem diz o que ela quer dizer.
##
## ⚠️ E SO GLIFOS QUE A FONTE MONOESPACADA TEM. Os tres sao ASCII, e o teste_acessibilidade
## confere isso na fonte de verdade -- glifo ausente nao aparece como erro, ele faz o Godot
## percorrer a cadeia de fallback a cada desenho (TUNING.md, a era 14).
##
## Eles escalam em abstracao, e a escada se le sem legenda:
##
##   =  quantitativo   uma igualdade: isto tem o tamanho daquilo
##   §  humano         o sinal de paragrafo, que e um artefato escrito por gente
##   ∞  conceitual     o glifo do proprio jogo, que e onde essa escada termina
const MARCAS_DE_TIPO: PackedStringArray = ["=", "§", "∞"]

## O nome de cada tipo, na mesma ordem. Texto de jogo: entra no CSV nas duas colunas.
const NOMES_DE_TIPO: PackedStringArray = ["Tamanho", "Humano", "Conceito"]


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Tema.fundo()
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_ITEM))
	%Titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)

	EventBus.panorama_pedido.connect(abrir)
	EventBus.marco_alcancado.connect(_ao_alcancar)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)


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

	# ⚠️ O FIM DO JOGO E A AUSENCIA DE UMA LINHA, E ISSO E DE PROPOSITO (issue #33).
	#
	# Cruzado O Macaco Infinito, Marcos.proximo() devolve nulo e nada entra abaixo dele.
	# Nenhum "? ? ?", nenhum "voce terminou", nenhum selo. O Panorama passou o jogo inteiro
	# dizendo que sempre ha um proximo; o fecho e ele parar de dizer isso.
	#
	# Uma linha de parabens aqui responderia a frase do ultimo marco, e a frase nao e uma
	# pergunta. A tela tem que saber terminar em silencio.
	var proximo := Marcos.proximo()
	if proximo != null:
		%Lista.add_child(_item(proximo, false, true))


## A marca de um tipo. Publica porque a suite le daqui: copiar a lista para dentro do teste
## criaria uma segunda tabela, e a segunda e a que mente.
static func marca_de(tipo: int) -> String:
	if tipo < 0 or tipo >= MARCAS_DE_TIPO.size():
		return "?"
	return MARCAS_DE_TIPO[tipo]


static func nome_do_tipo(tipo: int) -> String:
	if tipo < 0 or tipo >= NOMES_DE_TIPO.size():
		return "? ? ?"
	return NOMES_DE_TIPO[tipo]


## A cor e o TERCEIRO canal, e nunca o unico. Conceitual puxa para o ciano porque e ele que
## prepara a transicao para o endgame, e o ciano e a cor do infinito no docs/ARTE.md §6.
static func _cor_do_tipo(tipo: int) -> Color:
	match tipo:
		DadosMarco.Tipo.HUMANO:
			return Paleta.PAPER_CREAM.darkened(0.25)
		DadosMarco.Tipo.CONCEITUAL:
			return Paleta.INFINITY_CYAN.darkened(0.2)
	return Paleta.MONKEY_BROWN.lightened(0.2)


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
	# ⚠️ O TIPO ENTRA NA MESMA LINHA DO REQUISITO, e nao numa linha propria: o Panorama ja
	# tem numero, titulo e frase por item, e uma quarta linha por marco transformaria uma
	# lista de noventa e um numa parede. "%s %s  %s" e marca de formato, nao texto.
	requisito.text = "%s %s  %s" % [
		marca_de(marco.tipo),
		tr(nome_do_tipo(marco.tipo)),
		Formatador.formatar(marco.requisito_grande()),
	]
	requisito.add_theme_font_size_override("font_size", Tema.fonte(REQUISITO_ITEM))
	requisito.add_theme_color_override("font_color", Tema.cor(_cor_do_tipo(marco.tipo)))
	coluna.add_child(requisito)

	var titulo := Label.new()
	titulo.text = SILHUETA if silhueta else tr(marco.titulo)
	titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_ITEM))
	titulo.add_theme_color_override(
		"font_color",
		Tema.cor(Paleta.MONKEY_BROWN.lightened(0.1) if silhueta else Paleta.BANANA_GOLD),
	)
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = tr("O próximo marco ainda é um mistério.") if silhueta else tr(marco.texto)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", Tema.fonte(TEXTO_ITEM))
	texto.add_theme_color_override(
		"font_color",
		Tema.cor(Paleta.MONKEY_BROWN.lightened(0.1) if silhueta else Paleta.PAPER_CREAM),
	)
	coluna.add_child(texto)
	return moldura



## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	if visible:
		_montar()
