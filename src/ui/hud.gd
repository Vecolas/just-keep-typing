## A interface principal: recursos a esquerda, cena no centro, loja a direita (GDD §25).
##
## ⚠️ ESCUTA EventBus.idioma_mudou, e tem que escutar: o Godot retraduz sozinho apenas o
## text que veio da CENA. Os rotulos montados em codigo nao se retraduzem, e sem isto o nome
## de uma sala ficaria em portugues no meio de uma interface ja em ingles -- sem quebrar nada,
## sem imprimir erro, sumindo sozinho na proxima vez que alguem mexesse naquele rotulo.
##
## ⚠️ A LOJA DE UPGRADES SAIU DAQUI, e virou tres pecas (plano §7 e §8): quem decide O QUE
## mostrar e a VitrineDeUpgrades, quem DESENHA cada upgrade e o CartaoDeUpgrade, e quem
## responde "isto esta ao alcance?" e o Alcance. Esta tela so compoe. O motivo nao e
## arrumacao: as tres perguntas passaram a ter mais de um consumidor, e regra copiada em cada
## consumidor e a familia "duas fontes para a mesma verdade" da CONVENCOES.
##
## ⚠️ E A LISTA SE REMONTA QUANDO UM REQUISITO E CRUZADO. Ate aqui ela era remontada apenas na
## COMPRA -- e um upgrade recem-desbloqueado nao aparecia ate o jogador comprar outra coisa.
## Numa coluna em que "o que vem depois" e o assunto, isso era o proprio assunto quebrado, sem
## erro nenhum no console. Quem confere e _conferir_desbloqueio(), por um Grande so, e nao
## varrendo os quarenta e quatro upgrades por quadro.
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

## O menor requisito ainda nao cruzado, ou nulo quando nao ha nenhum. E o gatilho de
## remontagem da loja: um Grande comparado por quadro, em vez de uma varredura.
var _proximo_requisito: Grande = null

## A sequencia de cada faixa de aviso JA DESENHADA nesta tela.
##
## ⚠️ ELAS CONSERTAM UM DEFEITO QUE PASSOU DESPERCEBIDO DESDE A ISSUE #69: a tela repintava o
## aviso quando `tique()` devolvia `true`, e `tique()` nao devolve `true` na PRIMEIRA troca --
## fila vazia mostra o aviso dentro do proprio `acrescentar()`, sem passar por tique nenhum.
## Resultado: todo aviso que chegava com a fila ociosa ficava a duracao inteira dele na fila,
## invisivel, e saia sem nunca ter sido desenhado. So apareciam os que chegavam ATRAS de outro.
##
## Quem acusou foi a CAPTURA do banner: a caixa apareceu na tela, com moldura, e vazia por
## dentro. Nenhuma suite pegava -- as suites afirmam a FILA, e a fila estava certa.
var _sequencia_do_rodape: int = -1
var _sequencia_do_destaque: int = -1

## Quantidades do GDD §32. Comprar Maximo e a entrada 0, resolvida na hora do clique.
const LOTES: Array[int] = [1, 10, 100]

## Quanto tempo um aviso fica na tela (issue #37). Curto porque ele e confirmacao e nao
## informacao: quem esta olhando ve, e quem nao esta nao perde nada.
## ⚠️ MANTIDO PARA A REGUA, e nao para a HUD. tools/observar.gd le esta constante para
## contar quantos avisos sumiram antes do tempo minimo de leitura -- era 20% antes da
## issue #69. A duracao de verdade agora vem de FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE, e
## este numero e o PISO contra o qual a regua mede.
const AVISO_VISIVEL: float = 1.6

## AS FASES DO BOTAO DIGITAR (issue #68).
##
## ⚠️ AOS TRINTA MINUTOS O MAIOR E MAIS BRILHANTE ELEMENTO DA TELA DAVA +1 CONTRA 37,7
## MILHOES POR SEGUNDO. Sete ordens de grandeza. O jogador comecou digitando, e a interface
## continuava dizendo que era isso que importava.
##
## ⚠️ O COMBO JA ENVELHECE DE PROPOSITO (issue #54): "quando a automacao cresce, o papel do
## jogador passa de operador para administrador". O botao nao acompanhou -- esta issue e o
## botao alcancando o combo.
##
## ⚠️ E ELE NUNCA SOME. Quem nao pode usar o mouse depende da tecla, e a acessibilidade da
## issue #54 vale aqui: acelera, nunca obriga -- mas tambem nunca desaparece. A fase mais
## tardia ainda e um botao clicavel e alcancavel por teclado.
##
## Altura em pixels por fase, e a fase e DERIVADA da razao entre o que o clique da e o que
## a producao automatica da -- nunca uma lista de minutos, nunca um estado guardado
## (regra 2 de arquitetura).
const ALTURAS_DO_DIGITAR: Array[float] = [96.0, 72.0, 52.0, 36.0]

## As fronteiras entre as fases, em "quantos segundos de producao automatica um clique
## vale". Um clique que vale mais de um segundo de producao ainda e a acao principal.
##
## ⚠️ Limite de DESIGN. Ele responde "quando o clique deixa de ser o assunto", e nao
## "quanto o clique deve render".
const SEGUNDOS_QUE_O_CLIQUE_VALE: Array[float] = [1.0, 0.01, 0.0001]

## Respiro entre o banner e a borda da coluna do centro.
const FOLGA_DO_BANNER: float = 12.0

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
	_montar_a_loja()
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

	# ⚠️ A LARGURA DO BANNER E ACERTADA ANTES DE ELE APARECER, e nao no quadro em que aparece:
	# com a largura da cena, o autowrap do texto calcularia a altura errada e o primeiro quadro
	# do banner sairia com a caixa alta. `resized` cobre a troca de resolucao e a de escala de
	# interface; o adiado cobre a abertura, quando o pai ainda nao foi dimensionado.
	resized.connect(_assentar_o_banner)
	call_deferred("_assentar_o_banner")


func _process(delta: float) -> void:
	_conferir_desbloqueio()
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
	# ⚠️ CONTAVEL (issue #66): "48,99 macacos" apareceu numa captura, e le como defeito
	%ValorMacacos.text = Formatador.formatar_discreto(Jogo.macacos)
	_pintar_combo()
	_pintar_o_digitar()
	_pintar_objetivo()
	# a unidade vem da ERA, e nao esta escrita aqui: na era 14 a contagem de macacos
	# deixa de fazer sentido e o jogador passa a manipular possibilidades (GDD §6).
	# Trocar so o fundo contaria metade da historia.
	%TituloMacacos.text = tr(%Eras.unidade()).to_upper()

	%CustoMacaco.text = "%s %s" % [
		Formatador.formatar(Economia.custo_de_macacos(1)), tr("para o próximo"),
	]
	# ⚠️ QUANTO UM MACACO RENDE, e nao so quanto ele custa. A coluna inteira era de precos:
	# sem isto, "11,5 para o proximo" nao responde se vale a pena -- e a decisao de comprar
	# macaco ou upgrade e a unica decisao economica do early game.
	%ProducaoPorMacaco.text = tr("%s por segundo em cada macaco") % Formatador.formatar(
		Grande.de_float(Economia.producao_por_macaco())
	)
	# a barra mede o mesmo que a porcentagem no botao: quanto do proximo macaco o saldo ja
	# cobre. Duas leituras da mesma verdade, e nao duas verdades -- as duas saem do Alcance
	%BarraMacaco.value = Alcance.fracao(Economia.custo_de_macacos(1)) * 100.0

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

	# cada cartao le o proprio dado e o proprio saldo: a HUD nao sabe o preco de nada
	for filho in %ListaUpgrades.get_children():
		if filho is CartaoDeUpgrade:
			(filho as CartaoDeUpgrade).atualizar()
	for filho in %ListaFuturos.get_children():
		if filho is CartaoDeUpgrade:
			(filho as CartaoDeUpgrade).atualizar()

	for botao in %ListaAutomacao.get_children():
		var id: String = botao.get_meta("id")
		# a comprada nunca fica desabilitada: e o botao de desligar, e desligar tem que
		# funcionar mesmo sem um centavo no saldo
		if Automacao.comprada(id):
			botao.disabled = false
			# ⚠️ devolve o brilho: sem isto ela herda o apagado de quando ainda era cara, e
			# o interruptor de uma automacao LIGADA fica com cara de indisponivel
			botao.modulate.a = 1.0
			continue
		var dados := Automacao.de(id)
		if dados != null:
			_vestir_pelo_alcance(botao, Grande.de_float(dados.custo))


## O PROXIMO OBJETIVO (plano §5.A). ⚠️ ELE EXISTE PORQUE A COLUNA DA ESQUERDA SO DIZIA
## "QUANTO", e nunca "para onde". Um incremental sem alvo visivel e um contador subindo: o
## Panorama ja guarda noventa e cinco significados, e nenhum deles aparecia antes de cair.
##
## ⚠️ A BARRA MEDE DO MARCO ANTERIOR AO PROXIMO, e nao de zero. Numa escala exponencial,
## medir de zero deixa a barra colada em 100% da segunda era em diante -- ela pareceria
## quebrada justamente onde a progressao fica mais interessante.
func _pintar_objetivo() -> void:
	var proximo := Marcos.proximo()
	%PainelObjetivo.visible = proximo != null
	if proximo == null:
		return
	%NomeObjetivo.text = tr(proximo.titulo)
	var teto := proximo.requisito_grande()
	var anterior := Marcos.atual()
	var piso := anterior.requisito_grande() if anterior != null else Grande.zero()
	%BarraObjetivo.value = _fracao_entre(piso, teto, Jogo.total_caracteres) * 100.0
	%FaltaObjetivo.text = tr("faltam %s caracteres") % Formatador.formatar(
		teto.menos(Jogo.total_caracteres) if teto.maior_que(Jogo.total_caracteres)
		else Grande.zero()
	)


## Onde `atual` esta entre `piso` e `teto`, de 0 a 1.
##
## ⚠️ Faixa de largura zero ou invertida devolve 1, e nao uma divisao por zero: barra em
## "inf%" nao quebra o jogo, ela desenha um numero impossivel e ninguem descobre de onde veio.
func _fracao_entre(piso: Grande, teto: Grande, atual: Grande) -> float:
	var largura := teto.menos(piso)
	if largura.sinal() <= 0:
		return 1.0
	return clampf(atual.menos(piso).dividido(largura).para_float(), 0.0, 1.0)


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


## O botao DIGITAR encolhe conforme o papel do jogador muda (issue #68).
##
## ⚠️ AS TRES PRODUCOES FICAM EM TRES ROTULOS, e nao num so (plano §B.3). Ate aqui a legenda
## do botao trocava de assunto no meio da partida: na fase 0 ela dizia o que o clique da, e
## depois passava a dizer o que a producao automatica da -- duas informacoes diferentes no
## mesmo lugar, e nunca as duas juntas. Agora:
##
##   DicaDigitar        o que o CLIQUE da -- a legenda do botao, sempre sobre o botao
##   LinhaDeProducao    o que a AUTOMACAO da -- e nao competindo com a legenda do botao
##   Combo              o MULTIPLICADOR, que aparece so quando existe
##
## O que o clique vale contra a producao continua decidindo a FASE (a altura do botao), que
## e onde aquela comparacao sempre pertenceu: ela e sobre importancia, e nao sobre numero.
func _pintar_o_digitar() -> void:
	var fase := _fase_do_digitar()
	%BotaoDigitar.custom_minimum_size.y = ALTURAS_DO_DIGITAR[fase]
	# ⚠️ reduzir_movimento nao desliga o encolhimento, e sim a ANIMACAO dele -- e nao ha
	# animacao: o tamanho segue a fase, e a fase muda uma vez por partida. Opcao de conforto
	# que escondesse a mudanca de papel esconderia conteudo.
	%BotaoDigitar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if fase == 0:
		%DicaDigitar.text = tr("+1 caractere por clique ou espaço")
	else:
		# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
		%DicaDigitar.text = tr("+%s por clique ou espaço") % Formatador.formatar(
			Grande.de_float(Combo.multiplicador())
		)

	# ⚠️ SO APARECE QUANDO EXISTE. O macaco comeca sem saber digitar sozinho (GDD §3), e uma
	# linha dizendo "automatico: 0 por segundo" nos primeiros trinta segundos ensina o jogador
	# a nao ler aquela linha pelo resto da partida.
	%LinhaDeProducao.visible = Jogo.caracteres_por_segundo.sinal() > 0
	if %LinhaDeProducao.visible:
		%LinhaDeProducao.text = tr("o macaco produz %s por segundo sozinho") % (
			Formatador.formatar(Jogo.caracteres_por_segundo)
		)


## Em que fase o botao esta, lida na hora. Zero e a fase inicial.
func _fase_do_digitar() -> int:
	var por_segundo := Jogo.caracteres_por_segundo
	if por_segundo.sinal() <= 0:
		return 0
	# quantos segundos de producao automatica um clique vale
	var vale := Combo.multiplicador() / por_segundo.para_float()
	for i in SEGUNDOS_QUE_O_CLIQUE_VALE.size():
		if vale >= SEGUNDOS_QUE_O_CLIQUE_VALE[i]:
			return i
	return ALTURAS_DO_DIGITAR.size() - 1


## Veste um botao de compra conforme o quanto o jogador esta longe de poder paga-lo.
##
## ⚠️ O TEXTO BASE FICA NA META, e nao e relido do dado: ele ja passou por tr() na montagem,
## e refazer a traducao todo quadro seria trabalho por quadro para um texto que so muda
## quando o idioma muda -- e o idioma ja remonta a lista inteira.
##
## Quem responde em que estado o item esta e o Alcance, que e a fonte unica dos tres -- o
## cartao de upgrade pergunta ao mesmo lugar.
func _vestir_pelo_alcance(botao: Button, custo: Grande) -> void:
	var estado := Alcance.de(custo)
	botao.disabled = estado != Alcance.Estado.ALCANCAVEL
	botao.modulate.a = Alcance.brilho_de(estado)

	if not botao.has_meta("texto_base"):
		botao.set_meta("texto_base", botao.text)
	var base: String = botao.get_meta("texto_base")

	# ⚠️ E A PORCENTAGEM E TEXTO, e nao cor (issue #43). "72%" se le em qualquer monitor e em
	# qualquer daltonismo; o brilho so acompanha.
	if estado == Alcance.Estado.PERTO:
		# "%s  %d%%" e marca de formato, nao texto: nao passa por traducao
		botao.text = "%s  %d%%" % [base, int(Alcance.fracao(custo) * 100.0)]
		return
	botao.text = base


## A sala em uso, a ocupacao e a proxima da escada do GDD §15.
##
## A ocupacao fica ao lado do botao de comprar macaco, e nao escondida no card da sala: a
## issue #15 exige que comprar sem vaga seja impedido COM EXPLICACAO, e explicacao que o
## jogador precisa procurar em outro canto da tela nao explica nada.
func _pintar_sala() -> void:
	var atual := Economia.sala_atual()
	%NomeSala.text = "%s  %s" % [
		tr(atual.nome), tr("%s de %s macacos") % [
			Formatador.formatar_discreto(Jogo.macacos), Formatador.formatar_discreto(Economia.capacidade()),
		],
	] if atual != null else ""
	# a mesma ocupacao, em barra: quem le numero le o rotulo, quem le forma le a barra
	%BarraOcupacao.value = _fracao_entre(
		Grande.zero(), Economia.capacidade(), Jogo.macacos
	) * 100.0

	var proxima := Economia.proxima_sala()
	%BotaoSala.visible = proxima != null
	%BeneficioSala.visible = proxima != null
	if proxima != null:
		%BotaoSala.text = "%s — %s" % [
			tr(proxima.nome), Formatador.formatar(Grande.de_float(proxima.custo)),
		]
		# ⚠️ O BENEFICIO SAI DO TOOLTIP. A escada de salas e uma decisao economica -- trocar
		# de sala compete com comprar macaco e com comprar upgrade --, e ate aqui o que ela
		# entregava estava escondido no hover, que nao alcanca teclado nem toque.
		%BeneficioSala.text = tr("cabem %s macacos") % Formatador.formatar_discreto(
			Grande.de_float(proxima.capacidade)
		)
		# ⚠️ a meta e refeita aqui porque estes dois botoes reescrevem o proprio texto todo
		# quadro -- guardar o texto_base uma vez so deixaria a porcentagem grudada num nome
		# de sala que ja mudou
		%BotaoSala.set_meta("texto_base", %BotaoSala.text)
		_vestir_pelo_alcance(%BotaoSala, Grande.de_float(proxima.custo))

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
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moldura.add_theme_stylebox_override("panel", Tema.painel(
			Paleta.MECHANICAL_GOLD if not dados.e_punicao() else Paleta.MAGENTA_COSMICO, true
		))
		var margem := MarginContainer.new()
		margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for lado in ["left", "top", "right", "bottom"]:
			margem.add_theme_constant_override("margin_" + lado, 10)
		moldura.add_child(margem)

		var linha := HBoxContainer.new()
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_theme_constant_override("separation", 12)
		margem.add_child(linha)

		var rotulo := Label.new()
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	%BeneficioMaquina.visible = proxima != null
	if proxima == null:
		return
	# "%s — %s" e marca de formato, nao texto: nao passa por traducao
	%BotaoMaquina.text = "%s — %s" % [
		tr(proxima.nome), Formatador.formatar(Grande.de_float(proxima.custo)),
	]
	# ⚠️ IDEM A SALA: o multiplicador da proxima maquina saiu do tooltip. Trocar de maquina e
	# a compra mais cara da coluna, e o jogador decidia no escuro.
	%BeneficioMaquina.text = tr("×%s em toda a produção") % Formatador.formatar(
		Grande.de_float(proxima.multiplicador)
	)
	%BotaoMaquina.set_meta("texto_base", %BotaoMaquina.text)
	_vestir_pelo_alcance(%BotaoMaquina, Grande.de_float(proxima.custo))


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
	%EspacoAutomacao.visible = alguma


func _ao_mudar_automacao(_id: String) -> void:
	_montar_automacao()


func _ao_alternar_automacao(_id: String, _ligada: bool) -> void:
	_montar_automacao()


func _ao_alternar(id: String) -> void:
	Automacao.alternar(id)


func _ao_comprar_automacao(id: String) -> void:
	Automacao.comprar(id)


# --- a loja de upgrades ---------------------------------------------------------------

## As duas listas e o gatilho de remontagem, sempre juntos: elas particionam a MESMA
## pergunta -- o que ja apareceu e o que ainda vem --, e montar uma sem a outra deixaria um
## upgrade em nenhuma das duas ou nas duas.
func _montar_a_loja() -> void:
	_montar_upgrades()
	_montar_futuros()
	_proximo_requisito = _menor_requisito_pendente()


## ⚠️ UM Grande COMPARADO POR QUADRO, e nao uma varredura dos quarenta e quatro upgrades. A
## lista so muda quando o total cruza o proximo requisito -- e esse numero e conhecido no
## momento da montagem.
func _conferir_desbloqueio() -> void:
	if _proximo_requisito == null:
		return
	if _proximo_requisito.maior_que(Jogo.total_caracteres):
		return
	_montar_a_loja()


## O menor requisito ainda nao cruzado entre os upgrades nao comprados, ou nulo quando todos
## ja apareceram. Nulo desliga a conferencia: comparar contra um numero que nao existe seria
## remontar a loja toda vez, para sempre.
func _menor_requisito_pendente() -> Grande:
	# ⚠️ UM SO, e nao a lista da tela: a vitrine devolve os futuros ORDENADOS por requisito,
	# entao o primeiro E o menor. Pedir quatro e procurar o minimo entre eles daria o mesmo
	# numero por um caminho mais longo -- e um caminho mais longo que depende de a ordenacao
	# continuar sendo por requisito.
	var proximos := VitrineDeUpgrades.futuros(1)
	if proximos.is_empty():
		return null
	return Grande.de_float(proximos[0].requisito)


## Um cartao por upgrade ainda nao comprado e ja desbloqueado, AGRUPADO POR FAMILIA
## (issue #53). Limpa antes de montar: repintar nao e reexecutar, e chamar de novo nao pode
## empilhar dez copias do mesmo cartao.
##
## ⚠️ O CABECALHO SO SAI SE A FAMILIA TIVER ALGUEM EMBAIXO DELE. Emitir o titulo antes de
## saber se sobrou upgrade produziria "A MAQUINA" seguido de nada assim que o jogador
## comprasse o ultimo da familia -- uma secao vazia le como tela quebrada, e nao como
## "voce ja comprou tudo daqui".
##
## ⚠️ A FAMILIA NAO ESCOLHE COMPORTAMENTO NENHUM AQUI -- so o cabecalho embaixo do qual o
## cartao cai. O que o clique faz continua vindo do tipo de efeito, la na Economia.
func _montar_upgrades() -> void:
	for antigo in %ListaUpgrades.get_children():
		%ListaUpgrades.remove_child(antigo)
		antigo.queue_free()

	var por_familia := VitrineDeUpgrades.por_familia(VitrineDeUpgrades.disponiveis())
	# a ordem das secoes e a do enum, e nao a de quem apareceu primeiro: assim a loja nao
	# se reorganiza sozinha a cada compra
	for familia in DadosUpgrade.Familia.values():
		var disponiveis: Array = por_familia.get(familia, [])
		if disponiveis.is_empty():
			continue
		%ListaUpgrades.add_child(_cabecalho_de_familia(familia))
		for dados in disponiveis:
			%ListaUpgrades.add_child(CartaoDeUpgrade.disponivel(dados, _ao_comprar))


## O QUE VEM DEPOIS (plano §8). ⚠️ SEM ELA, A COLUNA RESPONDIA "o que posso comprar" e nunca
## "por que continuar". Num incremental, o que sustenta a sessao e a proxima coisa -- e ate
## aqui a proxima coisa simplesmente nao existia na tela: ela aparecia do nada quando o
## requisito caia.
##
## ⚠️ E ELA REVELA POUCO DE PROPOSITO. Mostrar a arvore inteira nao cria antecipacao, cria
## uma lista que ninguem le -- o numero esta em VitrineDeUpgrades.FUTUROS_NA_TELA, e e limite
## de design.
##
## O titulo e o espaco somem junto quando nao ha futuro nenhum: secao vazia le como tela
## quebrada, e o fim da escada de upgrades e um estado legitimo.
func _montar_futuros() -> void:
	for antigo in %ListaFuturos.get_children():
		%ListaFuturos.remove_child(antigo)
		antigo.queue_free()

	var futuros := VitrineDeUpgrades.futuros()
	%TituloFuturos.visible = not futuros.is_empty()
	%EspacoFuturos.visible = not futuros.is_empty()
	for dados in futuros:
		%ListaFuturos.add_child(CartaoDeUpgrade.futuro(dados))


## ⚠️ ELE E SUBTITULO, E NAO TITULO. Na primeira captura o cabecalho saiu com a mesma cor
## e o mesmo corpo de "UPGRADES", logo abaixo dele -- e "UPGRADES / O MACACO" empilhados,
## iguais, leem como dois titulos e nao como secao e subsecao. O dourado fica com a secao;
## a familia usa o marrom apagado que ja e o papel de legenda nesta tela.
##
## Nenhum portao pega isto: a hierarquia visual nao tem regua, e a suite estava verde. Foi
## a captura do CI que mostrou -- que e o que ela existe para fazer.
##
## ⚠️ O ICONE VEM DA FAMILIA DE ASSETS QUE JA EXISTE, e ele e DECORACAO: quem carrega a
## leitura e o nome escrito ao lado. Por isso ele nao cresce com a escala do texto -- e por
## isso a peca ausente nao e erro, e sim um cabecalho sem icone (decisao 0011).
func _cabecalho_de_familia(familia: int) -> Control:
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 8)
	# a meta e o que permite repintar o cabecalho na troca de lingua sem remontar a lista
	linha.set_meta("familia", familia)

	var icone := VitrineDeUpgrades.icone_de_familia(familia)
	var textura := AssetsDoMenu.textura_de(icone) if not icone.is_empty() else null
	if textura != null:
		var imagem := TextureRect.new()
		imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		imagem.texture = textura
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagem.custom_minimum_size = Vector2(
			VitrineDeUpgrades.LADO_DO_ICONE, VitrineDeUpgrades.LADO_DO_ICONE
		)
		# ⚠️ pixel art sem nearest e um icone borrado no meio de uma tela nitida, e nada no
		# console diz isso
		AssetsDoMenu.aplicar_filtro(imagem)
		linha.add_child(imagem)

	var titulo := Label.new()
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.text = tr(DadosUpgrade.NOMES_DE_FAMILIA[familia]).to_upper()
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	titulo.add_theme_color_override(
		"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.3)))
	linha.add_child(titulo)
	return linha


## Repinta o texto e o corpo dos cabecalhos de familia.
##
## ⚠️ REPINTA EM VEZ DE REMONTAR, e a diferenca importa: a lista de upgrades nao muda de
## COMPOSICAO quando a lingua muda, e remonta-la faria os cartoes -- que repintam a si mesmos
## -- serem destruidos e recriados a cada toque numa opcao de interface.
func _repintar_cabecalhos() -> void:
	for filho in %ListaUpgrades.get_children():
		if not filho.has_meta("familia"):
			continue
		var familia: int = filho.get_meta("familia")
		for neto in filho.get_children():
			if neto is Label:
				(neto as Label).text = tr(
					DadosUpgrade.NOMES_DE_FAMILIA[familia]
				).to_upper()
				(neto as Label).add_theme_font_size_override(
					"font_size", Tema.fonte(Tema.TITULO)
				)


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
##
## ⚠️ ELE ALCANCA SO QUEM JA ESTA NA ARVORE. Cartao, cabecalho e cartao de evento sao
## montados depois, e cada um deles poe o proprio mouse_filter -- quem monta e que precisa
## lembrar. Varrer a arvore de novo a cada montagem custaria mais e esqueceria o mesmo.
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
	_montar_a_loja()


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
## ⚠️ O AUTOSAVE NAO ENTRA NA FILA. Ele acendia o mesmo rotulo que uma descoberta Lendaria,
## com a mesma prioridade -- e e o unico dos tres que o jogador nao estava esperando.
## Virou icone, e o icone nao apaga texto nenhum.
func _ao_gravar() -> void:
	%IconeGravando.visible = true
	%IconeGravando.modulate.a = 1.0
	_ate_apagar_o_icone = ICONE_DE_GRAVACAO_VISIVEL


## Anda as DUAS faixas de aviso e o icone de gravacao.
##
## ⚠️ AS TRES VIVEM EM LUGARES DIFERENTES DA TELA DE PROPOSITO (plano §9.4): o banner e
## acontecimento, a linha do rodape e confirmacao, o icone e sistema. Ate aqui os tres
## disputavam o mesmo rotulo -- e o unico dos tres que o jogador nao estava esperando, o
## autosave, apagava os outros dois.
##
## ⚠️ E QUEM TICA E SO ESTA FUNCAO. Duas telas ticando a mesma fila andariam o relogio duas
## vezes por quadro, e cada aviso duraria metade do que a tabela promete -- sem erro nenhum.
func _andar_a_fila(delta: float) -> void:
	Avisos.tique(delta)

	# ⚠️ COMPARA A SEQUENCIA, e nao o retorno do tique: o tique nao acusa a PRIMEIRA troca,
	# porque fila vazia mostra o aviso dentro do proprio acrescentar(). Ver o comentario de
	# _sequencia_do_rodape.
	if Avisos.rodape_sequencia() != _sequencia_do_rodape:
		_sequencia_do_rodape = Avisos.rodape_sequencia()
		_pintar_o_aviso()
	if Avisos.tem_aviso():
		# desaparece nos ultimos segundos em vez de sumir num quadro: aviso que pisca vira
		# ruido, e o jogador passa a nao ler nenhum deles
		%Aviso.modulate.a = Avisos.quanto_resta()

	if Avisos.destaque_sequencia() != _sequencia_do_destaque:
		_sequencia_do_destaque = Avisos.destaque_sequencia()
		%Banner.trocar()
	%Banner.andar()
	if %Banner.visible:
		_assentar_o_banner()

	if _ate_apagar_o_icone > 0.0:
		_ate_apagar_o_icone -= delta
		%IconeGravando.modulate.a = clampf(_ate_apagar_o_icone, 0.0, 1.0)
		if _ate_apagar_o_icone <= 0.0:
			%IconeGravando.visible = false


## Poe o banner exatamente sobre a coluna do centro.
##
## ⚠️ ELE SEGUE A COLUNA, E NAO UMA FRACAO DA TELA, e isso foi visto numa captura: com ancoras
## de 22% a 78% o banner cobria o topo da coluna da direita em 1920x1080 -- e em 1280x720, que
## e a area logica com a escala de interface em 150%, ele cobriria a da esquerda. As colunas
## tem largura FIXA em pixels (360 e 440), e fracao de tela nao acompanha largura fixa: a
## proporcao entre elas muda a cada resolucao.
##
## ⚠️ E ELE NAO EMPURRA NADA. Entrar na coluna como mais uma linha do VBox moveria o botao
## DIGITAR para baixo toda vez que uma descoberta saisse -- um alvo de clique que foge do
## cursor, a cada poucos segundos, no unico botao que o jogador usa o tempo todo.
## ⚠️ E A ALTURA E REPOSTA EM ZERO, e nunca preservada. `size.x = ...` no Godot le o Vector2
## inteiro, troca o x e devolve os dois -- ou seja, ele PRESERVA o y. E o y da primeira vez e o
## minimo calculado com a largura que o no tinha na cena (quarenta pixels): com autowrap, uma
## frase de descoberta em quarenta pixels de largura vira quarenta linhas, e o banner nasceu com
## mil pixels de altura cobrindo a coluna inteira. Zero obriga o Godot a reclampar para o minimo
## da largura que vale AGORA -- Control cresce sozinho ate o minimo, mas nunca encolhe sozinho.
##
## Foi a captura que mostrou: a caixa do banner era a coluna do centro inteira, e o macaco tinha
## sumido atras dela. Nenhuma suite pega isso -- layout nao tem regua.
func _assentar_o_banner() -> void:
	var caixa: Rect2 = %Centro.get_global_rect()
	%Banner.position = (
		caixa.position + Vector2(FOLGA_DO_BANNER, FOLGA_DO_BANNER) - global_position
	)
	%Banner.size = Vector2(maxf(caixa.size.x - FOLGA_DO_BANNER * 2.0, 1.0), 0.0)


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


## ⚠️ NAO REMONTA A LISTA DE UPGRADES. Os cartoes repintam a si mesmos, escutando os mesmos
## dois sinais -- e a COMPOSICAO da lista nao muda com a lingua. Remontar aqui destruiria e
## recriaria oito cartoes a cada toque numa opcao.
func _ao_mudar_idioma(_codigo: String) -> void:
	_repintar_cabecalhos()
	_montar_automacao()


# --- aparencia ------------------------------------------------------------------------

## O contador e a coisa mais importante da tela e nao compete com nada: e o maior corpo,
## na cor de producao, e todo o resto fica pequeno e creme.
func _estilizar() -> void:
	%ValorCaracteres.add_theme_font_size_override("font_size", Tema.fonte(Tema.CONTADOR))
	%ValorCaracteres.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))

	for grande in [%ValorPorSegundo, %ValorDinheiro, %ValorMacacos, %ValorDescobertas]:
		grande.add_theme_font_size_override("font_size", Tema.fonte(Tema.DESTAQUE))
		grande.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))

	# ⚠️ OS TRES BLOCOS DA ESQUERDA GANHARAM MOLDURA (plano §5.A). Ate aqui producao, saldo e
	# colecao eram seis rotulos empilhados com o mesmo peso, separados so por um espaco: o
	# jogador nao tinha como saber que "37,7 M" e "12,4 K" respondem perguntas diferentes --
	# uma e velocidade, a outra e quanto da para gastar agora.
	for painel in [%PainelObjetivo, %PainelProducao, %PainelSaldo, %PainelColecao]:
		painel.add_theme_stylebox_override("panel", Tema.painel(
			Paleta.MONKEY_BROWN.darkened(0.2), true
		))

	# a barra do objetivo e dourada porque objetivo e progresso, e progresso e a cor de
	# producao do docs/ARTE.md §6
	Tema.vestir_de_barra(%BarraObjetivo, Paleta.BANANA_GOLD)
	Tema.vestir_de_barra(%BarraMacaco, Paleta.MECHANICAL_GOLD)
	Tema.vestir_de_barra(%BarraOcupacao, Paleta.MONKEY_BROWN.lightened(0.25))

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
		%NomeMaquina, %NomeSala, %NomeDescobertas, %LinhaDeProducao, %FaltaObjetivo,
		%ProducaoPorMacaco,
	]:
		legenda.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
		legenda.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.25)))

	# ⚠️ O BENEFICIO E DOURADO E O NOME E CREME, e a diferenca e proposital: o beneficio e a
	# razao da compra, e o codigo de cores do docs/ARTE.md §6 diz que dourado e producao.
	for beneficio in [%BeneficioSala, %BeneficioMaquina]:
		beneficio.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
		beneficio.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))

	# o nome do proximo marco e conteudo, e nao legenda: ele e a unica frase da coluna da
	# esquerda que diz para onde o jogo esta indo
	%NomeObjetivo.add_theme_font_size_override("font_size", Tema.fonte(Tema.CORPO))
	%NomeObjetivo.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))

	for titulo in [
		%TituloMacacos, %TituloUpgrades, %TituloMaquina, %TituloSala, %TituloAutomacao,
		%TituloFuturos, %TituloObjetivo, %TituloProducao, %TituloSaldo, %TituloColecao,
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
	_repintar_cabecalhos()
	_montar_automacao()
