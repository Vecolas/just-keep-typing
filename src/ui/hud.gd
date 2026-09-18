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

## id do evento -> o rotulo que mostra o relogio dele. Guardado na montagem para o quadro
## nao ter que procurar nada na arvore.
var _relogios: Dictionary = {}

## Quantidades do GDD §32. Comprar Maximo e a entrada 0, resolvida na hora do clique.
const LOTES: Array[int] = [1, 10, 100]

## Quanto tempo um aviso fica na tela (issue #37). Curto porque ele e confirmacao e nao
## informacao: quem esta olhando ve, e quem nao esta nao perde nada.
## ⚠️ MANTIDO PARA A REGUA, e nao para a HUD. tools/observar.gd le esta constante para
## contar quantos avisos sumiram antes do tempo minimo de leitura -- era 20% antes da
## issue #69. A duracao de verdade agora vem de FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE, e
## este numero e o PISO contra o qual a regua mede.
const AVISO_VISIVEL: float = 1.6

## Quanto tempo o icone de gravacao ainda fica aceso.
##
## ⚠️ O AUTOSAVE SAIU DA FILA DE AVISOS. Ele nao e um acontecimento do jogo -- e o jogo se
## explicando --, e disputava espaco com uma descoberta Lendaria em igualdade. Virou um
## icone discreto no canto, que e o que ele sempre foi: confirmacao, e nao informacao.
var _ate_apagar_o_icone: float = 0.0
const ICONE_DE_GRAVACAO_VISIVEL: float = 1.2


func _ready() -> void:
	theme = Tema.montar()
	%Fundo.color = Tema.fundo()

	# a cena das eras desenha sozinha e nao pode ser repintada como rotulo da HUD
	_liberar_clique(self)
	_estilizar()
	_ligar_botoes()
	_montar_upgrades()
	_montar_automacao()

	EventBus.automacao_comprada.connect(_ao_mudar_automacao)
	EventBus.automacao_alternada.connect(_ao_alternar_automacao)
	EventBus.evento_comecou.connect(_ao_mudar_eventos)
	EventBus.evento_terminou.connect(_ao_mudar_eventos)
	EventBus.voltou_do_offline.connect(_ao_voltar_do_offline)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	EventBus.upgrade_comprado.connect(_ao_comprar_upgrade)
	EventBus.jogo_gravado.connect(_ao_gravar)


func _process(delta: float) -> void:
	_pintar()
	_andar_a_fila(delta)


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
	_pintar_combo()
	# a unidade vem da ERA, e nao esta escrita aqui: na era 14 a contagem de macacos
	# deixa de fazer sentido e o jogador passa a manipular possibilidades (GDD §6).
	# Trocar so o fundo contaria metade da historia.
	%TituloMacacos.text = tr(%Eras.unidade()).to_upper()

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
	_pintar_relogio_dos_eventos()
	%BotaoTeoremas.visible = Teoremas.pode_provar() or Jogo.prestigios > 0

	for filho in %ListaUpgrades.get_children():
		# cabecalho de familia nao tem id e nao e botao: perguntar a meta dele derrubaria
		# o laco inteiro, e com ele o resto do quadro
		if not filho.has_meta("id"):
			continue
		var dados: DadosUpgrade = Economia.upgrade_de(filho.get_meta("id"))
		if dados != null:
			filho.disabled = Grande.de_float(dados.custo).maior_que(Jogo.dinheiro)

	for botao in %ListaAutomacao.get_children():
		var id: String = botao.get_meta("id")
		# a comprada nunca fica desabilitada: e o botao de desligar, e desligar tem que
		# funcionar mesmo sem um centavo no saldo
		if Automacao.comprada(id):
			botao.disabled = false
			continue
		var dados := Automacao.de(id)
		if dados != null:
			botao.disabled = Grande.de_float(dados.custo).maior_que(Jogo.dinheiro)


## O combo de digitacao (issue #54). ⚠️ ELE PRECISA SER VISIVEL: multiplicador que age
## sem aparecer e regra escondida, e o jogador atribuiria a variacao a outra coisa.
##
## ⚠️ SOME QUANDO ESTA EM 1,0, em vez de mostrar "COMBO x1,0" o tempo todo. Rotulo parado
## anunciando "nada esta acontecendo" e ruido permanente -- e o combo passa a maior parte
## da partida em 1,0, porque ele envelhece de proposito.
##
## ⚠️ E O QUE COMUNICA E O NUMERO, e nao a cor (issue #43). "x1,3" se le em qualquer
## monitor e em qualquer daltonismo; a cor so acompanha.
func _pintar_combo() -> void:
	var multiplicador := Combo.multiplicador()
	# 1,005 e meio por cento: abaixo disso o rotulo mostraria "x1,0" e piscaria a cada
	# arredondamento, que e pior que nao mostrar nada
	%Combo.visible = multiplicador > 1.005
	if not %Combo.visible:
		return
	# "%s ×%.2f" e marca de formato: o tr() vem ANTES da substituicao
	%Combo.text = "%s ×%.2f" % [tr("COMBO"), multiplicador]


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


## Um cartao por evento ativo (GDD §22). Remontado so quando um evento comeca ou acaba,
## nunca por quadro: o relogio de cada um e atualizado no cartao que ja existe.
##
## A saida pela acao do jogador vira BOTAO, e nao um clique escondido no cartao: punicao
## que exige o jogador adivinhar onde clicar e a mesma punicao, com um passo a mais.
func _montar_eventos() -> void:
	_relogios.clear()
	for antigo in %Eventos.get_children():
		%Eventos.remove_child(antigo)
		antigo.queue_free()

	for id in Eventos.ativos():
		var dados := Eventos.de(id)
		if dados == null:
			continue
		var moldura := PanelContainer.new()
		moldura.add_theme_stylebox_override("panel", Tema.painel(
			Paleta.MECHANICAL_GOLD if not dados.e_punicao() else Paleta.MAGENTA_COSMICO, true
		))
		var margem := MarginContainer.new()
		for lado in ["left", "top", "right", "bottom"]:
			margem.add_theme_constant_override("margin_" + lado, 10)
		moldura.add_child(margem)

		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		margem.add_child(linha)

		var rotulo := Label.new()
		rotulo.text = tr(dados.nome)
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotulo.add_theme_color_override(
			"font_color",
			Tema.cor(Paleta.MAGENTA_COSMICO if dados.e_punicao() else Paleta.BANANA_GOLD),
		)
		linha.add_child(rotulo)
		# guardado por id em vez de procurado na arvore: find_child devolve o primeiro
		# descendente com o nome pedido, e o primeiro aqui e o container, nao o rotulo --
		# foi assim que o relogio dos eventos nasceu invisivel
		_relogios[id] = rotulo

		if dados.resolve_com_clique:
			var botao := Button.new()
			botao.text = tr("Resolver")
			botao.focus_mode = Control.FOCUS_NONE
			botao.pressed.connect(_ao_resolver.bind(id))
			linha.add_child(botao)
		%Eventos.add_child(moldura)


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


## Um cartao por automacao ja disponivel (GDD §16). A comprada vira botao de LIGAR e
## DESLIGAR, e nao some da tela: automacao e sempre desligavel, e o botao que desliga
## precisa continuar existindo para isso ser verdade.
func _montar_automacao() -> void:
	for antigo in %ListaAutomacao.get_children():
		%ListaAutomacao.remove_child(antigo)
		antigo.queue_free()

	var alguma := false
	for dados in Automacao.todas():
		if not Automacao.comprada(dados.id) and not Automacao.disponivel(dados.id):
			continue
		alguma = true
		var botao := Button.new()
		botao.focus_mode = Control.FOCUS_NONE
		botao.tooltip_text = tr(dados.descricao)
		botao.set_meta("id", dados.id)
		if Automacao.comprada(dados.id):
			# "%s — %s" e marca de formato, nao texto
			botao.text = "%s — %s" % [
				tr(dados.nome), tr("Ligada") if Automacao.ligada(dados.id) else tr("Desligada"),
			]
			botao.pressed.connect(_ao_alternar.bind(dados.id))
		else:
			botao.text = "%s — %s" % [
				tr(dados.nome), Formatador.formatar(Grande.de_float(dados.custo)),
			]
			botao.pressed.connect(_ao_comprar_automacao.bind(dados.id))
		%ListaAutomacao.add_child(botao)
	%TituloAutomacao.visible = alguma


func _ao_mudar_automacao(_id: String) -> void:
	_montar_automacao()


func _ao_alternar_automacao(_id: String, _ligada: bool) -> void:
	_montar_automacao()


func _ao_alternar(id: String) -> void:
	Automacao.alternar(id)


func _ao_comprar_automacao(id: String) -> void:
	Automacao.comprar(id)


## Um botao por upgrade ainda nao comprado e ja desbloqueado, AGRUPADO POR FAMILIA
## (issue #53). Limpa antes de montar.
##
## ⚠️ O CABECALHO SO SAI SE A FAMILIA TIVER ALGUEM EMBAIXO DELE. Emitir o titulo antes de
## saber se sobrou upgrade produziria "A MAQUINA" seguido de nada assim que o jogador
## comprasse o ultimo da familia -- uma secao vazia le como tela quebrada, e nao como
## "voce ja comprou tudo daqui".
##
## Economia.upgrades() ja vem do mais barato para o mais caro, entao percorrer uma vez e
## separar por familia preserva a escada dentro de cada secao sem ordenar de novo.
##
## ⚠️ A FAMILIA NAO ESCOLHE COMPORTAMENTO NENHUM AQUI -- so o cabecalho embaixo do qual o
## botao cai. O que o clique faz continua vindo do tipo de efeito, la na Economia.
func _montar_upgrades() -> void:
	for antigo in %ListaUpgrades.get_children():
		%ListaUpgrades.remove_child(antigo)
		antigo.queue_free()

	var por_familia := {}
	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue
		if not por_familia.has(dados.familia):
			por_familia[dados.familia] = []
		por_familia[dados.familia].append(dados)

	# a ordem das secoes e a do enum, e nao a de quem apareceu primeiro: assim a loja nao
	# se reorganiza sozinha a cada compra
	for familia in DadosUpgrade.Familia.values():
		var disponiveis: Array = por_familia.get(familia, [])
		if disponiveis.is_empty():
			continue

		%ListaUpgrades.add_child(_cabecalho_de_familia(familia))
		for dados in disponiveis:
			var botao := Button.new()
			# "%s — %s" e marca de formato, nao texto: nao passa por traducao. O que
			# traduz e o nome, e o tr() vem ANTES da substituicao (CONVENCOES.md, idioma)
			botao.text = "%s — %s" % [
				tr(dados.nome), Formatador.formatar(Grande.de_float(dados.custo)),
			]
			botao.tooltip_text = tr(dados.descricao)
			botao.focus_mode = Control.FOCUS_NONE
			botao.set_meta("id", dados.id)
			botao.pressed.connect(_ao_comprar.bind(dados.id))
			%ListaUpgrades.add_child(botao)


## ⚠️ O cabecalho NAO pode entrar no laco que pinta os botoes: _pintar() percorre os
## filhos de %ListaUpgrades chamando Economia.upgrade_de(get_meta("id")). Um Label sem a
## meta "id" derrubaria aquele laco, entao o filtro la embaixo pergunta por `has_meta`.
## ⚠️ ELE E SUBTITULO, E NAO TITULO. Na primeira captura o cabecalho saiu com a mesma cor
## e o mesmo corpo de "UPGRADES", logo abaixo dele -- e "UPGRADES / O MACACO" empilhados,
## iguais, leem como dois titulos e nao como secao e subsecao. O dourado fica com a secao;
## a familia usa o marrom apagado que ja e o papel de legenda nesta tela (%NomeMaquina,
## %NomeSala), em vez de inventar um terceiro nivel.
##
## Nenhum portao pega isto: a hierarquia visual nao tem regua, e a suite estava verde. Foi
## a captura do CI que mostrou -- que e o que ela existe para fazer.
func _cabecalho_de_familia(familia: int) -> Label:
	var titulo := Label.new()
	titulo.text = tr(DadosUpgrade.NOMES_DE_FAMILIA[familia]).to_upper()
	titulo.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	titulo.add_theme_color_override(
		"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.3)))
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return titulo


# --- reacoes --------------------------------------------------------------------------

## Tudo que nao e botao deixa o clique passar adiante. A HUD cobre a tela inteira e o
## mouse_filter padrao de Control e STOP, entao sem isto ela comeria todo clique que nao
## caisse num botao -- e clicar no meio da tela, que e o gesto natural do genero, nao
## digitaria nada. Botao continua STOP: clicar em "Comprar" compra e nao digita.
##
## O teste de fumaca pegou este bug com o contador em 6 de 12: metade dos cliques dele e
## por mouse.
##
## ⚠️ ROLAGEM E BARRA FICAM DE FORA. IGNORE nao e "deixa passar", e "nem me pergunte": um
## ScrollContainer ignorado nao recebe a roda do mouse, e a coluna que acabou de ganhar
## rolagem nao rolaria. PASS resolve os dois lados -- a roda e consumida por quem rola, e o
## clique esquerdo, que ela nao usa, segue adiante e vira caractere.
func _liberar_clique(no: Node) -> void:
	if no is ScrollContainer:
		(no as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	elif no is ScrollBar:
		# arrastar a barra e clique, e clique que passa adiante arrastaria e digitaria junto
		(no as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	elif no is Control and not (no is Button):
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
	%BotaoOpcoes.pressed.connect(EventBus.opcoes_pedidas.emit)
	# ⚠️ SAI PELO Cenas, e nao emitindo sinal: voltar ao menu GRAVA antes de sair
	# (issue #37), e um sinal que qualquer um pode escutar seria um segundo caminho
	# de saida -- um deles sem gravar.
	%BotaoMenu.pressed.connect(Cenas.voltar_ao_menu)
	%BotaoMaquina.pressed.connect(_ao_comprar_maquina)
	%BotaoSala.pressed.connect(_ao_expandir_sala)

	# nenhum botao pega foco: com foco, a barra de espaco aciona o botao focado em vez de
	# digitar, e um "Comprar Maximo" clicado uma vez transformaria toda tecla de digitar
	# em compra de macaco pelo resto da partida
	for botao in [
		%BotaoDigitar, %Comprar1, %Comprar10, %Comprar100, %ComprarMaximo, %BotaoOpcoes,
		%BotaoMenu,
		%BotaoPanorama, %BotaoDescobertas, %BotaoEstatisticas, %BotaoTeoremas,
		%BotaoMaquina, %BotaoSala,
	]:
		botao.focus_mode = Control.FOCUS_NONE


func _ao_comprar_maximo() -> void:
	Economia.comprar_macacos(Economia.macacos_que_cabem())


func _ao_comprar(id: String) -> void:
	Economia.comprar_upgrade(id)


## So o relogio, todo quadro. O cartao inteiro so e remontado quando a lista muda.
func _pintar_relogio_dos_eventos() -> void:
	for id in _relogios:
		var dados := Eventos.de(id)
		var rotulo: Label = _relogios[id]
		if dados != null and is_instance_valid(rotulo):
			# "%s  %ds" e marca de formato, nao texto
			rotulo.text = "%s  %ds" % [tr(dados.nome), int(ceil(Eventos.restante(id)))]


func _ao_mudar_eventos(_qualquer: Variant) -> void:
	_montar_eventos()


func _ao_resolver(id: String) -> void:
	Eventos.resolver(id)


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


## ⚠️ AVISO, E NAO POPUP. Um Label no rodape que aparece e some sozinho: nao rouba foco,
## nao para o jogo e nao pede clique nenhum. Este e um jogo que fica aberto atras de outra
## coisa -- o mesmo motivo pelo qual a tela cheia nao e exclusiva (issue #34) --, e uma
## janelinha modal a cada trinta segundos seria motivo para fechar o jogo.
##
## ⚠️ E E UM SO PARA TODOS OS AVISOS. Um Label por assunto seria dois avisos empilhados no
## quadro em que um marco cai junto de uma gravacao -- e o de baixo aparece por cima da
## loja. O ultimo a chegar manda, e o anterior ja tinha sido lido ou nao seria lido nunca.
## ⚠️ O AUTOSAVE NAO ENTRA NA FILA. Ele acendia o mesmo rotulo que uma descoberta Lendaria,
## com a mesma prioridade -- e e o unico dos tres que o jogador nao estava esperando.
## Virou icone, e o icone nao apaga texto nenhum.
func _ao_gravar() -> void:
	%IconeGravando.visible = true
	%IconeGravando.modulate.a = 1.0
	_ate_apagar_o_icone = ICONE_DE_GRAVACAO_VISIVEL




## Anda a fila e o icone de gravacao. Os dois vivem em cantos diferentes da tela de
## proposito: um e conteudo, o outro e sistema.
func _andar_a_fila(delta: float) -> void:
	if Avisos.tique(delta):
		_pintar_o_aviso()
	if Avisos.tem_aviso():
		# desaparece nos ultimos segundos em vez de sumir num quadro: aviso que pisca vira
		# ruido, e o jogador passa a nao ler nenhum deles
		%Aviso.modulate.a = Avisos.quanto_resta()

	if _ate_apagar_o_icone > 0.0:
		_ate_apagar_o_icone -= delta
		%IconeGravando.modulate.a = clampf(_ate_apagar_o_icone, 0.0, 1.0)
		if _ate_apagar_o_icone <= 0.0:
			%IconeGravando.visible = false


func _pintar_o_aviso() -> void:
	%Aviso.visible = Avisos.tem_aviso()
	if not Avisos.tem_aviso():
		return
	%Aviso.text = Avisos.texto_atual()
	%Aviso.modulate.a = 1.0
	# ⚠️ COR + o proprio TEXTO (issue #43). A cor separa critica de comum para quem a
	# distingue; o texto do aviso ja diz "Descoberta:" ou "Marco:" para quem nao distingue.
	%Aviso.add_theme_color_override("font_color", Tema.cor(_cor_da_prioridade()))


func _cor_da_prioridade() -> Color:
	match Avisos.prioridade_atual():
		FilaDeAvisos.Prioridade.CRITICA:
			return Paleta.BANANA_GOLD
		FilaDeAvisos.Prioridade.ALTA:
			return Paleta.MECHANICAL_GOLD
		_:
			return Paleta.MONKEY_BROWN.lightened(0.25)


func _ao_mudar_idioma(_codigo: String) -> void:
	_montar_upgrades()


# --- aparencia ------------------------------------------------------------------------

## O contador e a coisa mais importante da tela e nao compete com nada: e o maior corpo,
## na cor de producao, e todo o resto fica pequeno e creme.
func _estilizar() -> void:
	%ValorCaracteres.add_theme_font_size_override("font_size", Tema.fonte(Tema.CONTADOR))
	%ValorCaracteres.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))

	for grande in [%ValorPorSegundo, %ValorDinheiro, %ValorMacacos, %ValorDescobertas]:
		grande.add_theme_font_size_override("font_size", Tema.fonte(Tema.DESTAQUE))
		grande.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))

	%AvisoOffline.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
	# discreto de proposito: marrom apagado, corpo de legenda. O aviso confirma, e nao
	# disputa atencao com o contador.
	%Aviso.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.25)))
	%Aviso.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	%Combo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
	%Combo.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	# sala cheia e o unico aviso da loja: cor de alerta, e nao mais um creme apagado
	%VagasMacaco.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	%VagasMacaco.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))

	for legenda in [
		%NomeCaracteres, %NomePorSegundo, %NomeDinheiro, %DicaDigitar, %CustoMacaco,
		%NomeMaquina, %NomeSala, %NomeDescobertas,
	]:
		legenda.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
		legenda.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.25)))

	for titulo in [
		%TituloMacacos, %TituloUpgrades, %TituloMaquina, %TituloSala, %TituloAutomacao,
	]:
		titulo.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
		titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))

	# o botao principal do docs/ARTE.md, secao 9: dourado, borda grossa, texto escuro
	%BotaoDigitar.add_theme_font_size_override("font_size", Tema.fonte(Tema.BOTAO_GRANDE))
	%BotaoDigitar.add_theme_color_override("font_color", Tema.cor(Paleta.INK_BROWN))
	%BotaoDigitar.add_theme_color_override("font_hover_color", Tema.cor(Paleta.INK_BROWN))
	%BotaoDigitar.add_theme_color_override("font_pressed_color", Tema.cor(Paleta.INK_BROWN))
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


## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	_estilizar()
	_montar_upgrades()
	_montar_automacao()
