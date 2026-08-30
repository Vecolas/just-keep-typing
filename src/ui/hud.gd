## A interface principal: recursos a esquerda, cena no centro, loja a direita (GDD §25).
##
## Versao minima de proposito -- so os botoes que existem. Panorama, Descobertas e
## Prestigio entram com os sistemas deles, e botao que abre tela vazia ensina o jogador a
## ignorar a barra de cima.
##
## ⚠️ ESCUTA EventBus.idioma_mudou, e tem que escutar: o Godot retraduz sozinho apenas o
## text que veio da CENA. Os botoes de upgrade sao montados em codigo, com tr(), e sem
## isto o nome do upgrade ficaria em portugues no meio de uma interface ja em ingles --
## sem quebrar nada, sem imprimir erro, sumindo sozinho na proxima vez que alguem mexesse
## naquele rotulo. Ver CONVENCOES.md.
##
## _montar_upgrades() limpa antes de montar: repintar nao e reexecutar, e chamar de novo
## nao pode empilhar dez copias do mesmo botao so porque a pessoa mexeu nas opcoes.
##
## Nao guarda numero nenhum. Le Jogo e Economia no quadro em que desenha, que e a regra 2
## de arquitetura -- assim um bonus novo aparece na tela sem ninguem avisar a HUD.
##
## As cores vem de Paleta e o tema e montado em codigo, nao num .tres: cor de identidade
## nao e numero de balanceamento (docs/ARTE.md, secao 6).
extends Control

## Quantidades do GDD §32. Comprar Maximo e a entrada 0, resolvida na hora do clique.
const LOTES: Array[int] = [1, 10, 100]


func _ready() -> void:
	theme = Tema.montar()
	%Fundo.color = Paleta.INK_BROWN.darkened(0.4)

	# a cena das eras desenha sozinha e nao pode ser repintada como rotulo da HUD
	_liberar_clique(self)
	_estilizar()
	_ligar_botoes()
	_montar_upgrades()

	EventBus.voltou_do_offline.connect(_ao_voltar_do_offline)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.upgrade_comprado.connect(_ao_comprar_upgrade)


func _process(_delta: float) -> void:
	_pintar()


# --- pintura --------------------------------------------------------------------------

## Numeros e estado dos botoes, todo quadro. E barato e evita a familia inteira de bug em
## que a tela mostra um valor que o jogo ja mudou.
func _pintar() -> void:
	%ValorCaracteres.text = Formatador.formatar(Jogo.total_caracteres)
	%ValorPorSegundo.text = Formatador.formatar(Jogo.caracteres_por_segundo)
	%ValorDinheiro.text = Formatador.formatar(Jogo.dinheiro)
	%ValorDescobertas.text = Formatador.formatar(
		Grande.de_float(float(Descobertas.quantas_encontradas()))
	)
	%ValorMacacos.text = Formatador.formatar(Jogo.macacos)

	%CustoMacaco.text = "%s %s" % [
		Formatador.formatar(Economia.custo_de_macacos(1)), tr("para o próximo"),
	]

	for lote in LOTES:
		var botao: Button = get_node("%Comprar" + str(lote))
		botao.disabled = (
			Economia.custo_de_macacos(lote).maior_que(Jogo.dinheiro)
			or not Economia.cabe_na_sala(lote)
		)
	%ComprarMaximo.disabled = Economia.macacos_que_cabem() <= 0
	_pintar_maquina()
	_pintar_sala()
	%BotaoTeoremas.visible = Teoremas.pode_provar() or Jogo.prestigios > 0

	for botao in %ListaUpgrades.get_children():
		var dados: DadosUpgrade = Economia.upgrade_de(botao.get_meta("id"))
		if dados != null:
			botao.disabled = Grande.de_float(dados.custo).maior_que(Jogo.dinheiro)


## A sala em uso, a ocupacao e a proxima da escada do GDD §15.
##
## A ocupacao fica ao lado do botao de comprar macaco, e nao escondida no card da sala: a
## issue #15 exige que comprar sem vaga seja impedido COM EXPLICACAO, e explicacao que o
## jogador precisa procurar em outro canto da tela nao explica nada.
func _pintar_sala() -> void:
	var atual := Economia.sala_atual()
	%NomeSala.text = "%s  %s" % [
		tr(atual.nome), tr("%s de %s macacos") % [
			Formatador.formatar(Jogo.macacos), Formatador.formatar(Economia.capacidade()),
		],
	] if atual != null else ""

	var proxima := Economia.proxima_sala()
	%BotaoSala.visible = proxima != null
	if proxima != null:
		%BotaoSala.text = "%s \u2014 %s" % [
			tr(proxima.nome), Formatador.formatar(Grande.de_float(proxima.custo)),
		]
		%BotaoSala.tooltip_text = tr(proxima.descricao)
		%BotaoSala.disabled = Grande.de_float(proxima.custo).maior_que(Jogo.dinheiro)

	var vagas := Economia.vagas_livres()
	%VagasMacaco.text = tr("Sala cheia") if vagas.e_zero() else ""
	%VagasMacaco.visible = vagas.e_zero()


## A maquina em uso e a proxima da escada do GDD §13. No topo o botao some, em vez de
## ficar la desabilitado para sempre dizendo que nao ha nada -- botao morto na tela e
## ruido que o jogador aprende a nao ler.
func _pintar_maquina() -> void:
	var atual := Economia.maquina_atual()
	%NomeMaquina.text = "%s  x%s" % [
		tr(atual.nome), Formatador.formatar(Grande.de_float(atual.multiplicador)),
	] if atual != null else ""

	var proxima := Economia.proxima_maquina()
	%BotaoMaquina.visible = proxima != null
	if proxima == null:
		return
	# "%s — %s" e marca de formato, nao texto: nao passa por traducao
	%BotaoMaquina.text = "%s — %s" % [
		tr(proxima.nome), Formatador.formatar(Grande.de_float(proxima.custo)),
	]
	%BotaoMaquina.tooltip_text = tr(proxima.descricao)
	%BotaoMaquina.disabled = Grande.de_float(proxima.custo).maior_que(Jogo.dinheiro)


## Um botao por upgrade ainda nao comprado e ja desbloqueado. Limpa antes de montar.
func _montar_upgrades() -> void:
	for antigo in %ListaUpgrades.get_children():
		%ListaUpgrades.remove_child(antigo)
		antigo.queue_free()

	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue

		var botao := Button.new()
		# "%s — %s" e marca de formato, nao texto: nao passa por traducao. O que traduz e
		# o nome, e o tr() vem ANTES da substituicao (CONVENCOES.md, regra 2 de idioma)
		botao.text = "%s — %s" % [tr(dados.nome), Formatador.formatar(Grande.de_float(dados.custo))]
		botao.tooltip_text = tr(dados.descricao)
		botao.focus_mode = Control.FOCUS_NONE
		botao.set_meta("id", dados.id)
		botao.pressed.connect(_ao_comprar.bind(dados.id))
		%ListaUpgrades.add_child(botao)


# --- reacoes --------------------------------------------------------------------------

## Tudo que nao e botao deixa o clique passar adiante. A HUD cobre a tela inteira e o
## mouse_filter padrao de Control e STOP, entao sem isto ela comeria todo clique que nao
## caisse num botao -- e clicar no meio da tela, que e o gesto natural do genero, nao
## digitaria nada. Botao continua STOP: clicar em "Comprar" compra e nao digita.
##
## O teste de fumaca pegou este bug com o contador em 6 de 12: metade dos cliques dele e
## por mouse.
func _liberar_clique(no: Node) -> void:
	if no is Control and not (no is Button):
		(no as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for filho in no.get_children():
		_liberar_clique(filho)


func _ligar_botoes() -> void:
	%BotaoDigitar.pressed.connect(Economia.digitar.bind(1))
	for lote in LOTES:
		var botao: Button = get_node("%Comprar" + str(lote))
		botao.pressed.connect(Economia.comprar_macacos.bind(lote))
	%ComprarMaximo.pressed.connect(_ao_comprar_maximo)
	%BotaoPanorama.pressed.connect(EventBus.panorama_pedido.emit)
	%BotaoDescobertas.pressed.connect(EventBus.descobertas_pedidas.emit)
	%BotaoEstatisticas.pressed.connect(EventBus.estatisticas_pedidas.emit)
	%BotaoTeoremas.pressed.connect(EventBus.teoremas_pedidos.emit)
	%BotaoMaquina.pressed.connect(_ao_comprar_maquina)
	%BotaoSala.pressed.connect(_ao_expandir_sala)

	# nenhum botao pega foco: com foco, a barra de espaco aciona o botao focado em vez de
	# digitar, e um "Comprar Maximo" clicado uma vez transformaria toda tecla de digitar
	# em compra de macaco pelo resto da partida
	for botao in [
		%BotaoDigitar, %Comprar1, %Comprar10, %Comprar100, %ComprarMaximo,
		%BotaoPanorama, %BotaoDescobertas, %BotaoEstatisticas, %BotaoTeoremas,
		%BotaoMaquina, %BotaoSala,
	]:
		botao.focus_mode = Control.FOCUS_NONE


func _ao_comprar_maximo() -> void:
	Economia.comprar_macacos(Economia.macacos_que_cabem())


func _ao_comprar(id: String) -> void:
	Economia.comprar_upgrade(id)


func _ao_comprar_maquina() -> void:
	var proxima := Economia.proxima_maquina()
	if proxima != null:
		Economia.comprar_maquina(proxima.id)


func _ao_expandir_sala() -> void:
	var proxima := Economia.proxima_sala()
	if proxima != null:
		Economia.expandir_sala(proxima.id)


## O upgrade comprado sai da lista, e um requisito recem-atingido pode ter trazido outro.
func _ao_comprar_upgrade(_id: String) -> void:
	_montar_upgrades()


## Metade da recompensa de reabrir o jogo e ver o quanto rendeu enquanto estava fechado
## (GDD §38). Volta sem producao nao mostra nada -- aviso de zero e ruido.
func _ao_voltar_do_offline(produzido: Grande, _segundos: float) -> void:
	%AvisoOffline.visible = produzido.sinal() > 0
	if %AvisoOffline.visible:
		# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
		%AvisoOffline.text = tr("Enquanto você esteve fora: %s") % Formatador.formatar(produzido)


func _ao_mudar_idioma(_codigo: String) -> void:
	_montar_upgrades()


# --- aparencia ------------------------------------------------------------------------

## O contador e a coisa mais importante da tela e nao compete com nada: e o maior corpo,
## na cor de producao, e todo o resto fica pequeno e creme.
func _estilizar() -> void:
	%ValorCaracteres.add_theme_font_size_override("font_size", Tema.CONTADOR)
	%ValorCaracteres.add_theme_color_override("font_color", Paleta.BANANA_GOLD)

	for grande in [%ValorPorSegundo, %ValorDinheiro, %ValorMacacos, %ValorDescobertas]:
		grande.add_theme_font_size_override("font_size", Tema.DESTAQUE)
		grande.add_theme_color_override("font_color", Paleta.PAPER_CREAM)

	%AvisoOffline.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	# sala cheia e o unico aviso da loja: cor de alerta, e nao mais um creme apagado
	%VagasMacaco.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)
	%VagasMacaco.add_theme_font_size_override("font_size", Tema.TITULO)

	for legenda in [
		%NomeCaracteres, %NomePorSegundo, %NomeDinheiro, %DicaDigitar, %CustoMacaco,
		%NomeMaquina, %NomeSala, %NomeDescobertas,
	]:
		legenda.add_theme_font_size_override("font_size", Tema.TITULO)
		legenda.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.25))

	for titulo in [%TituloMacacos, %TituloUpgrades, %TituloMaquina, %TituloSala]:
		titulo.add_theme_font_size_override("font_size", Tema.TITULO)
		titulo.add_theme_color_override("font_color", Paleta.MECHANICAL_GOLD)

	# o botao principal do docs/ARTE.md, secao 9: dourado, borda grossa, texto escuro
	%BotaoDigitar.add_theme_font_size_override("font_size", Tema.BOTAO_GRANDE)
	%BotaoDigitar.add_theme_color_override("font_color", Paleta.INK_BROWN)
	%BotaoDigitar.add_theme_color_override("font_hover_color", Paleta.INK_BROWN)
	%BotaoDigitar.add_theme_color_override("font_pressed_color", Paleta.INK_BROWN)
	%BotaoDigitar.add_theme_stylebox_override("normal", _digitar(Paleta.BANANA_GOLD))
	%BotaoDigitar.add_theme_stylebox_override("hover", _digitar(Paleta.BANANA_GOLD.lightened(0.15)))
	%BotaoDigitar.add_theme_stylebox_override("pressed", _digitar(Paleta.MECHANICAL_GOLD))


## Borda grossa e escura porque dourado brilhante sem area escura para contrastar esta na
## lista do que evitar (docs/ARTE.md, secao 13).
func _digitar(fundo: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = Paleta.INK_BROWN
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 56
	estilo.content_margin_right = 56
	estilo.content_margin_top = 16
	estilo.content_margin_bottom = 16
	return estilo
