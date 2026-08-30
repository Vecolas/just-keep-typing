## A tela do prestigio e da Arvore de Teoremas (GDD §17, §18 e §19).
##
## O BOTAO MOSTRA QUANTOS PONTOS VOCE LEVARIA AGORA, antes de qualquer confirmacao. E o
## que transforma o prestigio na pergunta que o GDD §18 quer -- sem o numero na frente, a
## unica forma de decidir seria adivinhar.
##
## CONFIRMACAO EXPLICITA, em dois passos. Provar o Teorema apaga macacos, maquina, sala,
## dinheiro e upgrades; reset acidental e o pior bug possivel aqui, e um clique so nunca e
## suficiente para uma acao que nao tem desfazer.
##
## Escuta EventBus.idioma_mudou porque monta numero em codigo -- o Godot retraduz sozinho
## apenas o text que veio da cena.
extends Control

const TITULO_TELA: int = 22
const GANHO: int = 26
const NO_TITULO: int = 19
const NO_TEXTO: int = 16


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Paleta.INK_BROWN.darkened(0.4)
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", TITULO_TELA)
	%Titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%Titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%Contagem.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	%Ganho.add_theme_font_size_override("font_size", GANHO)
	%Ganho.add_theme_color_override("font_color", Paleta.MAGENTA_COSMICO)
	%Aviso.add_theme_font_size_override("font_size", NO_TEXTO)
	%Aviso.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.25))

	for botao in [%BotaoFechar, %BotaoProvar, %BotaoConfirmar, %BotaoCancelar]:
		botao.focus_mode = Control.FOCUS_NONE
	%BotaoFechar.pressed.connect(fechar)
	%BotaoProvar.pressed.connect(_ao_pedir_prestigio)
	%BotaoConfirmar.pressed.connect(_ao_confirmar)
	%BotaoCancelar.pressed.connect(_ao_cancelar)

	EventBus.teoremas_pedidos.connect(abrir)
	EventBus.teorema_comprado.connect(_ao_mudar)
	EventBus.teorema_provado.connect(_ao_provar)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)


func abrir() -> void:
	_ao_cancelar()
	visible = true


func fechar() -> void:
	visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	get_viewport().set_input_as_handled()


func _ao_mudar(_id: String) -> void:
	if visible:
		_montar()


func _ao_provar(_pontos: Grande) -> void:
	_ao_cancelar()


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


## Primeiro clique: some com o botao e mostra confirmar e cancelar. O aviso do que vai ser
## apagado ja estava na tela desde antes -- ele nao aparece junto da confirmacao, porque
## aviso que aparece na hora de confirmar e aviso que ninguem le.
func _ao_pedir_prestigio() -> void:
	%BotaoProvar.visible = false
	%BotaoConfirmar.visible = true
	%BotaoCancelar.visible = true


func _ao_cancelar() -> void:
	%BotaoProvar.visible = true
	%BotaoConfirmar.visible = false
	%BotaoCancelar.visible = false
	_montar()


func _ao_confirmar() -> void:
	Teoremas.provar()


func _montar() -> void:
	%Ganho.text = tr("Você levaria %s Pontos de Teorema.") % Formatador.formatar(
		Teoremas.pontos_ao_provar()
	)
	%BotaoProvar.disabled = not Teoremas.pode_provar()
	# "%s: %s" e marca de formato, nao texto
	%Contagem.text = "%s: %s" % [
		tr("Pontos disponíveis"), Formatador.formatar(Jogo.pontos_de_teorema),
	]

	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()
	for no in Teoremas.nos():
		%Lista.add_child(_item(no))


func _item(no: DadosTeorema) -> Control:
	var nivel := Teoremas.nivel_de(no.id)
	var aberto := Teoremas.desbloqueado(no.id)
	var cheio := nivel >= no.niveis

	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", Tema.painel(
		Paleta.MAGENTA_COSMICO if nivel > 0 else Paleta.MONKEY_BROWN.darkened(0.3),
		nivel > 0,
	))

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 14)
	moldura.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)

	var titulo := Label.new()
	titulo.text = tr(no.nome)
	titulo.add_theme_font_size_override("font_size", NO_TITULO)
	titulo.add_theme_color_override(
		"font_color", Paleta.BANANA_GOLD if aberto else Paleta.MONKEY_BROWN.lightened(0.1)
	)
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = tr(no.descricao) if aberto else tr("Ainda não desbloqueado")
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", NO_TEXTO)
	texto.add_theme_color_override(
		"font_color", Paleta.PAPER_CREAM if aberto else Paleta.MONKEY_BROWN.lightened(0.1)
	)
	coluna.add_child(texto)

	var estado := Label.new()
	estado.text = tr("Nível %s de %s") % [str(nivel), str(no.niveis)]
	estado.add_theme_font_size_override("font_size", NO_TEXTO)
	estado.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.25))
	coluna.add_child(estado)

	if not cheio and aberto:
		var botao := Button.new()
		botao.text = "%s — %s" % [
			tr(no.nome), Formatador.formatar(Teoremas.custo_do_proximo(no.id)),
		]
		botao.focus_mode = Control.FOCUS_NONE
		botao.disabled = not Teoremas.pode_comprar(no.id)
		botao.pressed.connect(_ao_comprar.bind(no.id))
		coluna.add_child(botao)
	elif cheio:
		var maximo := Label.new()
		maximo.text = tr("Máximo")
		maximo.add_theme_font_size_override("font_size", NO_TEXTO)
		maximo.add_theme_color_override("font_color", Paleta.MAGENTA_COSMICO)
		coluna.add_child(maximo)
	return moldura


func _ao_comprar(id: String) -> void:
	Teoremas.comprar(id)
