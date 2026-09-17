## A tela de CONFIGURAÇÕES, em abas (issue #41).
##
## ⚠️ ESTA TELA NAO SABE O QUE E IDIOMA, RESOLUCAO NEM VSYNC. Ela percorre Config.ABAS,
## pergunta quais campos moram em cada uma, e para cada campo monta o controle do TIPO que
## a tabela declara. Opcao nova e uma linha em Config.CAMPOS mais um rotulo aqui embaixo --
## nenhuma linha de logica DAQUI muda.
##
## E por isso que _campo() nao tem `match` por nome: no dia em que alguem precisar de um
## `if campo == "resolucao"` aqui dentro, a generalizacao ja quebrou e o lugar certo do
## conserto e o Config.
##
## ⚠️ A ABA E UMA COLUNA DA TABELA, e nao um bloco de codigo por aba. Aba sem campo nenhum
## simplesmente nao e desenhada: enquanto INTERFACE e ACESSIBILIDADE nao tiverem campo
## (issue #43), elas nao aparecem -- aba vazia ensina o jogador a nao clicar nas outras.
##
## ⚠️ O CAMPO "slot" SAIU DAQUI. Escolher Manuscrito e a tela de Arquivos (issue #40);
## trocar de save por dentro das opcoes, no meio da partida, e o gesto que apaga progresso
## sem querer.
##
## Herda de TelaSobreposta: ESC fecha, a tela come o resto da entrada enquanto esta aberta,
## e ela TOMA o foco de quem a abriu -- sem isso, apertar espaco com o painel na frente
## aperta o botao CONFIGURAÇÕES do menu que esta atras dele (issue #39).
##
## ESCUTA idioma_mudou e se remonta. Os rotulos sao montados em codigo com tr(), e o Godot
## so retraduz sozinho o que veio da cena -- sem isto eles ficariam em portugues numa
## interface ja em ingles (CONVENCOES.md).
extends TelaSobreposta

const TITULO_TELA: int = 22
const ROTULO_CAMPO: int = 18
const DICA: int = 14

## Largura dos controles. Fixa, e nao esticada ate a borda: um OptionButton de mil e
## duzentos pixels para escrever "1280x720" e o tipo de campo que a pessoa nao sabe onde
## clicar.
const LARGURA_DO_CAMPO: int = 360

## Um rotulo por campo de Config.CAMPOS. Mora aqui e nao no Config porque e texto de tela,
## e o Config nao fala com o jogador.
##
## ⚠️ O rotulo do campo e a PERGUNTA, nunca uma das respostas. A primeira versao chamava o
## campo de "Janela" e a primeira opcao dele tambem era "Janela" -- em ingles a captura
## saiu com "Windowed" escrito duas vezes, uma em cima da outra.
##
## ⚠️ E SAO DUAS TABELAS PARA A MESMA LISTA DE CAMPOS. Campo declarado no Config sem linha
## aqui apareceria na tela com o nome interno dele; e por isso que o teste_config cruza as
## duas e reprova quando uma anda sem a outra.
const ROTULOS: Dictionary = {
	"idioma": "Idioma",
	"autosave": "Salvamento automático",
	"confirmacoes": "Confirmações",
	"aviso_de_marco": "Avisar ao alcançar um marco",
	"aviso_de_descoberta": "Avisar ao encontrar uma descoberta",
	"volume": "Volume",
	"resolucao": "Resolução",
	"tela_cheia": "Modo de janela",
	"vsync": "Sincronização vertical",
	"limite_de_fps": "Limite de quadros por segundo",
	"modo_economico": "Modo econômico",
}

## Dica por campo, ou nenhuma. Cada uma existe porque o campo, sozinho, seria lido errado.
const DICAS: Dictionary = {
	"resolucao": "Só aparecem as resoluções que cabem no seu monitor.",
	"autosave": "Desligado, o jogo ainda grava ao sair e ao prestigiar.",
	"confirmacoes": "Excluir Manuscrito confirma sempre — essa não tem volta.",
	"modo_economico": "Com o jogo em segundo plano, desenha menos quadros.",
}


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_TELA)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%BotaoFechar.focus_mode = Control.FOCUS_ALL
	%BotaoFechar.pressed.connect(fechar)

	EventBus.opcoes_pedidas.connect(abrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_montar()
	super()


func _primeiro_foco() -> Control:
	return %BotaoFechar


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


func _montar() -> void:
	%Titulo.text = tr("CONFIGURAÇÕES")
	%BotaoFechar.text = tr("Fechar")

	# a aba escolhida sobrevive a remontagem: trocar o volume e ser jogado de volta para a
	# primeira aba e o tipo de detalhe que faz a pessoa desistir de mexer nas opcoes
	var escolhida: int = %Abas.current_tab
	for antiga in %Abas.get_children():
		%Abas.remove_child(antiga)
		antiga.queue_free()

	for aba in Config.ABAS:
		var campos := Config.campos_da_aba(aba)
		if campos.is_empty():
			continue
		%Abas.add_child(_aba(aba, campos))
	%Abas.current_tab = clampi(escolhida, 0, maxi(%Abas.get_tab_count() - 1, 0))


## Uma aba: o nome dela no cabecalho e os campos dela dentro, rolaveis. A rolagem e por
## aba e nao da tela inteira -- rolar a tela levaria o cabecalho das abas junto.
func _aba(nome: String, campos: Array[Dictionary]) -> Control:
	var rolagem := ScrollContainer.new()
	# o nome do no VIRA o titulo da aba no TabContainer, entao ele e texto de tela: sem o
	# tr() aqui a aba ficaria em portugues numa interface em ingles
	rolagem.name = tr(nome)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var lista := VBoxContainer.new()
	lista.name = "Lista%s" % nome
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 24)
	rolagem.add_child(lista)

	for linha in campos:
		lista.add_child(_campo(linha))
	return rolagem


## Um campo qualquer. Repare que nada aqui menciona idioma, resolucao ou volume: o que
## muda entre um campo e outro e o TIPO declarado na tabela.
func _campo(linha: Dictionary) -> Control:
	var nome := str(linha["nome"])
	var coluna := VBoxContainer.new()
	coluna.name = "Campo_%s" % nome
	coluna.add_theme_constant_override("separation", 4)

	var rotulo := Label.new()
	rotulo.text = tr(str(ROTULOS.get(nome, nome)))
	rotulo.add_theme_font_size_override("font_size", ROTULO_CAMPO)
	rotulo.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	coluna.add_child(rotulo)

	if Config.tipo_de(nome) == Config.Tipo.FAIXA:
		coluna.add_child(_faixa(nome))
	else:
		coluna.add_child(_lista(nome))

	if DICAS.has(nome):
		var dica := Label.new()
		dica.text = tr(str(DICAS[nome]))
		dica.add_theme_font_size_override("font_size", DICA)
		dica.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.2))
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		coluna.add_child(dica)

	return coluna


func _lista(nome: String) -> Control:
	var botao := OptionButton.new()
	botao.name = "Controle_%s" % nome
	# ⚠️ FOCO LIGADO, ao contrario da HUD: aqui o espaco nao digita caractere nenhum -- a
	# tela e modal e come a entrada solta --, e sem foco nao ha como mexer nas opcoes por
	# teclado ou por controle (issue #39)
	botao.focus_mode = Control.FOCUS_ALL
	botao.custom_minimum_size = Vector2(LARGURA_DO_CAMPO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# o rotulo do OptionButton vem dos itens que ele mesmo recebeu, e nao de uma chave do
	# CSV -- traduzir de novo procuraria "1920x1080" na tabela e acharia nada
	botao.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for texto in Config.rotulos_de(nome):
		botao.add_item(texto)
	botao.selected = Config.indice_de(nome)
	# ⚠️ campo que nao faz nada tem que PARECER que nao faz nada: em tela cheia a resolucao
	# fica apagada, senao a pessoa mexe nela e conclui que o jogo ignorou a escolha
	botao.disabled = Config.apagado(nome)
	botao.item_selected.connect(func(indice: int) -> void: _escolher(nome, indice))
	return botao


func _faixa(nome: String) -> Control:
	var limites := Config.faixa_de(nome)
	var barra := HSlider.new()
	barra.name = "Controle_%s" % nome
	barra.focus_mode = Control.FOCUS_ALL
	barra.min_value = limites["minimo"]
	barra.max_value = limites["maximo"]
	barra.step = limites["passo"]
	barra.value = Config.valor_de(nome)
	barra.custom_minimum_size = Vector2(LARGURA_DO_CAMPO, 0)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# a barra NAO remonta a tela a cada arrastada: remontar no meio do arrasto tira a
	# barra de baixo do cursor, e o volume fica preso no primeiro valor tocado
	barra.value_changed.connect(func(valor: float) -> void: Config.definir(nome, valor))
	return barra


## Remonta a tela inteira depois de escolher numa lista. Custa alguns OptionButtons e
## resolve o unico acoplamento que sobraria: tela cheia apaga a resolucao, e a resolucao
## nao sabe disso.
func _escolher(nome: String, indice: int) -> void:
	Config.escolher(nome, indice)
	_montar()
