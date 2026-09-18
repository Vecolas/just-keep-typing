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
##
## A TELA VIRA COLECAO NA ISSUE #55. Com sessenta e duas descobertas, a lista plana deixou
## de funcionar: ela passa a ser agrupada por FAIXA, com contagem por faixa.
##
## ⚠️ A FAIXA VEM DE DadosDescoberta.FAIXAS, e nao de uma tabela aqui. Ela ja existia
## dentro da suite desde a issue #52; copia-la para ca faria a segunda tabela, e a segunda
## e sempre a que mente.
##
## ⚠️ `0/?` NAO E ENFEITE. A faixa paradoxal esconde o total de proposito: saber quantas
## faltam mata a ultima faixa, porque o `?` E a promessa e a contagem exata a desmonta.
##
## ⚠️ "A ENTRADA ABERTA MOSTRA O RESTO" -- e ABERTA aqui quer dizer REVELADA, e nao
## expandida por clique. A issue nao pede interacao nenhuma, e inventar uma so para o
## Arquivo custaria caro: esta tela nao navega por foco (o proprio botao Fechar e
## FOCUS_NONE), entao entrada clicavel seria conteudo que so existe para quem usa o mouse.
## Nao encontrada mostra a raridade e mais nada; encontrada mostra tudo.
##
## ⚠️ E DESCOBERTA ANTIGA NAO MOSTRA ZERO QUE MENTE. Quem achou uma descoberta antes desta
## versao nao tem data nem ordem de grandeza carimbadas -- as duas linhas simplesmente nao
## aparecem, em vez de dizerem "1 de janeiro de 1970, com 1 caractere".
##
## Tem class_name para a suite poder perguntar o SIMBOLO de cada raridade sem subir cena
## nenhuma -- ver simbolo_de().
class_name DescobertasTela
extends Control

const TITULO_ITEM: int = 22
const CATEGORIA_ITEM: int = 14
const TEXTO_ITEM: int = 18

## Marca de formato, nao texto: nao passa por traducao.
const SILHUETA := "? ? ?"

## O total escondido da faixa paradoxal. Marca de formato: "?" se le igual em toda lingua.
const OCULTO := "?"

## Uma chave por valor do enum DadosDescoberta.Categoria, na mesma ordem.
const NOMES_DE_CATEGORIA: Array[String] = [
	"Comum", "Incomum", "Raro", "Épico", "Lendário", "Impossível", "Paradoxal",
]


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Tema.fundo()
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_ITEM))
	%Titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	%Contagem.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
	%Contagem.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.2)))
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)

	EventBus.descobertas_pedidas.connect(abrir)
	EventBus.descoberta_encontrada.connect(_ao_descobrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)


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
	for faixa in DadosDescoberta.FAIXAS.size():
		var desta_faixa: Array[DadosDescoberta] = []
		for descoberta in todas:
			if DadosDescoberta.faixa_de(descoberta.categoria) == faixa:
				desta_faixa.append(descoberta)
		# faixa sem nenhuma descoberta nao ganha cabecalho: secao vazia le como tela
		# quebrada, e nao como "ainda nao ha nada aqui"
		if desta_faixa.is_empty():
			continue
		%Lista.add_child(_cabecalho_da_faixa(faixa))
		for descoberta in desta_faixa:
			%Lista.add_child(_item(descoberta))


## O nome da faixa e a contagem dela. ⚠️ A CONTAGEM VEM DO CATALOGO (Descobertas), e nao de
## um numero somado aqui: descoberta nova entra na conta sozinha.
func _cabecalho_da_faixa(faixa: int) -> Control:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)

	var dados: Dictionary = DadosDescoberta.FAIXAS[faixa]
	var nome := Label.new()
	nome.text = tr(str(dados["nome"]))
	nome.add_theme_font_size_override("font_size", Tema.fonte(TITULO_ITEM))
	nome.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(nome)

	var contagem: Array = Descobertas.contagem_da_faixa(faixa)
	var achadas: int = contagem[0]
	# "%d/%s" e marca de formato, nao texto: nao passa por traducao
	var direita := Label.new()
	direita.text = "%d/%s" % [
		achadas, OCULTO if bool(dados["oculta"]) else str(contagem[1]),
	]
	direita.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
	direita.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.3)))
	linha.add_child(direita)
	return linha


## ⚠️ AS DUAS FORMAS DE ENTRADA TEM ALTURAS MUITO DIFERENTES, e e nisso que a issue #55
## consiste. Ate aqui uma descoberta nao encontrada ocupava o mesmo card de 120 px que uma
## encontrada, com "? ? ?" e "Ainda nao descoberto." ocupando tres linhas para dizer nada.
## Com sessenta e duas, a tela virava uma rolagem de silhuetas onde nao se acha coisa
## nenhuma -- agrupar por faixa nao resolve isso sozinho, porque o problema e altura.
##
## Nao encontrada vira UMA LINHA: simbolo, raridade e a silhueta. O buraco continua tendo
## forma reconhecivel, que e o que faz o jogador querer continuar, e cabe uma faixa inteira
## na tela. Encontrada mantem o card, porque ela E a recompensa.
##
## A frase "Ainda nao descoberto." sai: ao lado de "? ? ?" ela repete em palavras o que o
## simbolo ja disse, e repeticao e o que enche a tela.
func _item(descoberta: DadosDescoberta) -> Control:
	var achada := Descobertas.encontrada(descoberta.id)
	var cor := _cor(descoberta.categoria)
	var paradoxal := descoberta.categoria == DadosDescoberta.Categoria.PARADOXAL

	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", _painel(cor, achada, paradoxal))

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 16 if achada else 6)
	moldura.add_child(margem)

	# ⚠️ COR + SIMBOLO + NOME (issue #43), nas duas formas. A cor sozinha nao serve para
	# quem nao distingue as sete -- e sao sete, com dois roxos e dois azuis entre elas.
	# "%s %s" e marca de formato: o simbolo na frente do nome se le igual em qualquer
	# lingua.
	var etiqueta := "%s %s" % [
		simbolo_de(descoberta.categoria), tr(NOMES_DE_CATEGORIA[descoberta.categoria]),
	]

	if not achada:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		margem.add_child(linha)

		var categoria_so := Label.new()
		categoria_so.text = etiqueta
		categoria_so.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		categoria_so.add_theme_color_override("font_color", Tema.cor(cor.darkened(0.25)))
		linha.add_child(categoria_so)

		var silhueta := Label.new()
		silhueta.text = SILHUETA
		silhueta.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		silhueta.add_theme_color_override(
			"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.1)))
		linha.add_child(silhueta)
		return moldura

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)

	var categoria := Label.new()
	categoria.text = etiqueta
	categoria.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
	categoria.add_theme_color_override("font_color", Tema.cor(cor))
	coluna.add_child(categoria)

	var titulo := Label.new()
	titulo.text = tr(descoberta.nome)
	titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_ITEM))
	titulo.add_theme_color_override("font_color", Tema.cor(cor))
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = tr(descoberta.texto)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", Tema.fonte(TEXTO_ITEM))
	texto.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))
	coluna.add_child(texto)

	_acrescentar_o_resto(coluna, descoberta)
	return moldura


## O que so a entrada revelada mostra: a curiosidade, quando ela saiu, com que ordem de
## grandeza, e o bonus quando ha bonus.
func _acrescentar_o_resto(coluna: VBoxContainer, descoberta: DadosDescoberta) -> void:
	if not descoberta.curiosidade.strip_edges().is_empty():
		var curiosidade := Label.new()
		curiosidade.text = tr(descoberta.curiosidade)
		curiosidade.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		curiosidade.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		curiosidade.add_theme_color_override(
			"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.35)))
		coluna.add_child(curiosidade)

	# ⚠️ AS DUAS LINHAS ABAIXO SO SAEM SE HOUVER O QUE DIZER. Descoberta achada antes da
	# issue #55 nao tem carimbo, e o dicionario vazio e a sentinela -- zero nao serve,
	# porque ordem de grandeza zero e legitima (de 1 a 9 caracteres).
	var detalhe := Descobertas.detalhe_de(descoberta.id)
	if not detalhe.is_empty():
		var quando := Label.new()
		quando.text = tr("Encontrada em %s") % Relogio.data(float(detalhe["quando"]))
		quando.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		quando.add_theme_color_override(
			"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.3)))
		coluna.add_child(quando)

		var grandeza := Label.new()
		# "10^%d" e marca de formato. ORDEM DE GRANDEZA e nao o numero exato de proposito:
		# o que conta a historia e "isto saiu quando voce tinha 10^12", e nao a virgula.
		grandeza.text = tr("Com 10^%d caracteres produzidos") % int(detalhe["grandeza"])
		grandeza.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		grandeza.add_theme_color_override(
			"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.3)))
		coluna.add_child(grandeza)

	# so quem TEM bonus mostra bonus: "x1" numa descoberta de humor anuncia um ganho que
	# nao existe, e o jogador procuraria a diferenca na producao
	if descoberta.papel == DadosDescoberta.Papel.BONUS:
		var bonus := Label.new()
		# "x%s" e marca de formato, nao texto
		bonus.text = "x%s" % Formatador.formatar(Grande.de_float(descoberta.bonus))
		bonus.add_theme_font_size_override("font_size", Tema.fonte(CATEGORIA_ITEM))
		bonus.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
		coluna.add_child(bonus)


## O simbolo de uma raridade. Publico porque a suite le daqui: afirmar o simbolo copiando
## a lista para dentro do teste criaria uma segunda tabela, e a segunda e a que mente.
static func simbolo_de(categoria: int) -> String:
	if categoria < 0 or categoria >= Paleta.SIMBOLOS_DE_RARIDADE.size():
		return "?"
	return Paleta.SIMBOLOS_DE_RARIDADE[categoria]


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


## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	if visible:
		_montar()
