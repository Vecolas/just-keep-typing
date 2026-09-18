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
	%Cortina.color = Tema.fundo()
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_TELA))
	%Titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	# o Titulo herda a expansao que era da Contagem, senao o Fechar cola no titulo em vez
	# de ir para a borda -- esconder um no de container nao redistribui o espaco dele
	%Contagem.visible = false
	%Titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%BotaoFechar.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)
	%Lista.add_theme_constant_override("separation", 6)

	EventBus.estatisticas_pedidas.connect(abrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)


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
		%Lista.add_child(_linha(linha["rotulo"], _numero(linha)))
	for linha in Estatisticas.tempos():
		%Lista.add_child(_linha(linha["rotulo"], linha["valor"]))

	%Lista.add_child(_secao("SEM GRANDE UTILIDADE"))
	for linha in Estatisticas.inuteis():
		%Lista.add_child(_linha(linha["rotulo"], _numero(linha)))

	_montar_o_registro()


## ⚠️ A GRANDEZA DIZ SE SE CONTA, e a tela obedece (issue #66). Campo ausente cai no
## continuo, que e o comportamento de sempre e o certo para a maioria.
func _numero(linha: Dictionary) -> String:
	if bool(linha.get("discreto", false)):
		return Formatador.formatar_discreto(linha["valor"])
	return Formatador.formatar(linha["valor"])


## O REGISTRO RECENTE (issue #69).
##
## ⚠️ ELE EXISTE PARA A MENSAGEM NAO SUMIR DO UNIVERSO. Antes desta issue, um aviso perdido
## era um aviso perdido para sempre -- e era isso que obrigava o aviso a ser grande e
## demorado, porque ele era a unica chance. Com o registro, ele pode ser discreto.
##
## ⚠️ E ELE MORA AQUI, e nao na partida. A issue pede que ele nao seja protagonista: quem
## perdeu um aviso vem procurar; quem nao perdeu nunca abre esta tela. Dar espaco
## permanente na HUD a uma lista que o jogador consulta uma vez por sessao seria gastar a
## area mais cara da tela com a informacao menos urgente.
##
## Vazio nao ganha secao: cabecalho com nada embaixo le como tela quebrada.
func _montar_o_registro() -> void:
	var registro := Avisos.registro()
	if registro.is_empty():
		return
	%Lista.add_child(_secao("REGISTRO RECENTE"))
	for aviso in registro:
		# o instante e tempo de JOGO e nao relogio de parede: "aos 12 min" diz mais que
		# "12:42" para quem quer saber em que ponto da partida aquilo aconteceu
		%Lista.add_child(_linha(
			str(aviso["texto"]), Relogio.duracao(float(aviso["instante"]))
		))


## Rotulo a esquerda, numero a direita. Duas colunas e nao uma frase montada: numero
## alinhado se compara com o olho, e comparar duas leituras da mesma estatistica e a unica
## coisa que se faz com esta tela.
func _linha(rotulo: String, valor: String) -> Control:
	var caixa := HBoxContainer.new()

	var esquerda := Label.new()
	esquerda.text = tr(rotulo)
	esquerda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esquerda.add_theme_font_size_override("font_size", Tema.fonte(ROTULO))
	esquerda.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))
	caixa.add_child(esquerda)

	var direita := Label.new()
	direita.text = valor
	direita.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	direita.add_theme_font_size_override("font_size", Tema.fonte(ROTULO))
	direita.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
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
	rotulo.add_theme_font_size_override("font_size", Tema.fonte(SECAO))
	rotulo.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.25)))
	caixa.add_child(rotulo)
	return caixa


## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	if visible:
		_montar()
