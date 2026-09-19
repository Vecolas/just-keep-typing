## A tela de ARQUIVOS: criar, escolher e excluir Manuscrito (issue #40).
##
## Um cartao por slot. O vazio vira NOVO MANUSCRITO, o cheio se apresenta pelo que e, e o
## ilegivel avisa -- tres estados e nao dois, porque para quem esta na tela eles sao tres
## coisas diferentes: "comecar aqui", "continuar isto" e "alguma coisa aconteceu com este
## arquivo". Ilegivel tratado como vazio ofereceria comecar por cima de centenas de horas
## que so estao dificeis de ler.
##
## ⚠️ LE METADADO, NAO PARTIDA. Desenhar tres cartoes nao pode custar abrir tres saves --
## cada um creditaria producao offline por cima do outro (issue #35).
##
## ⚠️ TRES INFORMACOES EM DESTAQUE, E O RESTO PEQUENO. Era, caracteres e tempo jogado sao o
## que faz o jogador reconhecer a propria partida entre tres; criacao, ultima sessao,
## producao e prestigios sao contexto. Nove campos do mesmo tamanho nao sao nove
## informacoes, sao nenhuma.
##
## ⚠️ EXCLUIR E A UNICA ACAO DO JOGO QUE NAO TEM VOLTA, e por isso sao DOIS passos e um
## segundo de pressao. O primeiro passo tira o botao de onde a mao ja estava; o segundo
## exige um gesto que ninguem faz sem querer. Confirmacao de um clique vira reflexo na
## terceira vez.
##
## ⚠️ O NOME NUNCA ESCOLHE O CAMINHO DO ARQUIVO. Quem decide onde um slot mora e
## Config.caminho_do_slot; o que o jogador escreve vai para DENTRO do save. Ver o aviso em
## NomesDeManuscrito.
extends Control

const TITULO: int = 40
const LARGURA_DO_CARTAO: int = 880
const NOME: int = 24
const DESTAQUE_VALOR: int = 22
const DESTAQUE_ROTULO: int = 12
const SECUNDARIO: int = 13
const LARGURA_DA_ACAO: int = 200

## O que separa um campo secundario do proximo. Marca de formato, nao texto.
const SEPARADOR := "   ·   "

## Em que estado esta o cartao em acao. UM cartao por vez sai do normal: dois campos de
## nome abertos ao mesmo tempo seriam duas coisas pedindo Enter na mesma tela.
enum Modo { NORMAL, NOMEANDO, EXCLUINDO }

var _titulo: Label = null
var _cartoes: VBoxContainer = null
var _voltar: Button = null

var _modo: Modo = Modo.NORMAL
var _slot_em_acao: int = 0

## Nome do no que recebe o foco depois da proxima remontagem. Vazio deixa o foco no
## primeiro botao util -- remontar sem devolver o foco e a tela parando de responder ao
## teclado sem uma linha no console (CONVENCOES.md, "Foco, teclado e controle").
var _focar_depois: String = ""


func _ready() -> void:
	theme = Tema.montar()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Tema.fundo()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := VBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 12)
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO))
	_titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	centro.add_child(_titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 24)
	centro.add_child(espaco)

	_cartoes = VBoxContainer.new()
	_cartoes.name = "Cartoes"
	_cartoes.add_theme_constant_override("separation", 12)
	_cartoes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(_cartoes)

	var respiro := Control.new()
	respiro.custom_minimum_size = Vector2(0, 24)
	centro.add_child(respiro)

	_voltar = Button.new()
	_voltar.name = "BotaoVoltar"
	_voltar.custom_minimum_size = Vector2(LARGURA_DA_ACAO, 0)
	_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_voltar.focus_mode = Control.FOCUS_ALL
	Tema.vestir_de_placa(_voltar)
	_voltar.pressed.connect(_ao_voltar)
	centro.add_child(_voltar)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_pintar()


## ESC volta ao menu, e ESC dentro de uma acao cancela so a acao. Sem os dois niveis, quem
## abriu o campo de nome sem querer sai da tela inteira para cancela-lo.
func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _modo == Modo.NORMAL:
		_ao_voltar()
		return
	_cancelar()


# ------------------------------------------------------------------------------- desenho

func _pintar() -> void:
	_titulo.text = tr("ARQUIVOS")
	_voltar.text = tr("VOLTAR")

	for antigo in _cartoes.get_children():
		_cartoes.remove_child(antigo)
		antigo.queue_free()
	for numero in range(1, Config.SLOTS + 1):
		_cartoes.add_child(_cartao(numero, Config.manuscrito_do_slot(numero)))

	_dar_o_foco()


func _cartao(numero: int, manuscrito: Manuscrito) -> Control:
	var cartao := PanelContainer.new()
	cartao.name = "CartaoSlot%d" % numero
	# o cartao em acao se destaca dos outros dois: sem isso, o campo de nome aberto num
	# cartao parece um campo solto no meio da tela
	var em_acao := numero == _slot_em_acao and _modo != Modo.NORMAL
	# a moldura de Manuscrito da issue #45, quando ela existe. Ela e a MESMA familia de
	# componentes do menu -- meia familia de pixel art e meia de StyleBox le como defeito,
	# e nao como incompleto (docs/ASSETS.md)
	var moldura := Tema.moldura("moldura_manuscrito", Tema.BRILHO_HOVER if em_acao else Tema.BRILHO_NORMAL)
	if moldura != null:
		AssetsDoMenu.aplicar_filtro(cartao)
		cartao.add_theme_stylebox_override("panel", moldura)
	else:
		cartao.add_theme_stylebox_override("panel", Tema.painel(
			Paleta.BANANA_GOLD if em_acao else Paleta.MECHANICAL_GOLD.darkened(0.35), em_acao
		))
	cartao.custom_minimum_size = Vector2(LARGURA_DO_CARTAO, 0)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_top", 14)
	margem.add_theme_constant_override("margin_bottom", 14)
	cartao.add_child(margem)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 24)
	margem.add_child(linha)

	var dados := VBoxContainer.new()
	dados.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dados.add_theme_constant_override("separation", 6)
	linha.add_child(dados)

	var acoes := VBoxContainer.new()
	acoes.alignment = BoxContainer.ALIGNMENT_CENTER
	acoes.add_theme_constant_override("separation", 6)
	linha.add_child(acoes)

	if em_acao and _modo == Modo.NOMEANDO:
		_montar_nomeando(numero, dados, acoes)
	elif em_acao and _modo == Modo.EXCLUINDO:
		_montar_excluindo(numero, manuscrito, dados, acoes)
	else:
		_montar_normal(numero, manuscrito, dados, acoes)
	return cartao


func _montar_normal(
	numero: int, manuscrito: Manuscrito, dados: VBoxContainer, acoes: VBoxContainer
) -> void:
	if manuscrito.vazio():
		dados.add_child(_rotulo(tr("NOVO MANUSCRITO"), NOME, Paleta.BANANA_GOLD))
		dados.add_child(_rotulo(
			tr("Nada escrito ainda."), SECUNDARIO, Paleta.MONKEY_BROWN.lightened(0.2)
		))
		var criar := _acao(acoes, "BotaoNovo%d" % numero, tr("CRIAR"))
		criar.pressed.connect(_ao_criar.bind(numero))
		return

	if manuscrito.ilegivel():
		dados.add_child(_rotulo(
			tr("Manuscrito ilegível"), NOME, Paleta.MONKEY_BROWN.lightened(0.3)
		))
		dados.add_child(_rotulo(
			tr("O arquivo deste slot não abre. Excluir libera o slot."),
			SECUNDARIO, Paleta.MONKEY_BROWN.lightened(0.2),
		))
		# ⚠️ ABRIR fica APAGADO, e nao ausente: botao que some muda o cartao de forma e faz
		# o jogador procurar o que ele fez de errado. Apagado diz "aqui nao da"
		var abrir_morto := _acao(acoes, "BotaoAbrir%d" % numero, tr("ABRIR"))
		abrir_morto.disabled = true
		var apagar_ilegivel := _acao(acoes, "BotaoExcluir%d" % numero, tr("EXCLUIR"))
		apagar_ilegivel.pressed.connect(_ao_pedir_exclusao.bind(numero))
		return

	dados.add_child(_rotulo(_nome_de(numero, manuscrito), NOME, Paleta.PAPER_CREAM))
	dados.add_child(_destaques(manuscrito))
	dados.add_child(_rotulo(
		_secundario(manuscrito), SECUNDARIO, Paleta.MONKEY_BROWN.lightened(0.2)
	))

	var abrir := _acao(acoes, "BotaoAbrir%d" % numero, tr("ABRIR"))
	abrir.pressed.connect(_ao_abrir.bind(numero))
	var excluir := _acao(acoes, "BotaoExcluir%d" % numero, tr("EXCLUIR"))
	excluir.pressed.connect(_ao_pedir_exclusao.bind(numero))


func _montar_nomeando(numero: int, dados: VBoxContainer, acoes: VBoxContainer) -> void:
	dados.add_child(_rotulo(
		tr("Nome do Manuscrito"), DESTAQUE_ROTULO, Paleta.MONKEY_BROWN.lightened(0.3)
	))

	var campo := LineEdit.new()
	campo.name = "CampoDeNome%d" % numero
	# o limite e do CAMPO tambem, e nao so da validacao: recusar depois de a pessoa ter
	# digitado trinta caracteres e faze-la apagar o que o jogo deixou escrever
	campo.max_length = NomesDeManuscrito.LIMITE
	campo.text = NomesDeManuscrito.sugerir(numero, _nomes_em_uso())
	campo.focus_mode = Control.FOCUS_ALL
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo.text_submitted.connect(func(_texto: String) -> void: _ao_confirmar_criacao(numero))
	dados.add_child(campo)

	var aviso := _rotulo("", SECUNDARIO, Paleta.MONKEY_BROWN.lightened(0.2))
	aviso.name = "AvisoDoNome%d" % numero
	dados.add_child(aviso)

	var criar := _acao(acoes, "BotaoCriar%d" % numero, tr("CRIAR"))
	criar.pressed.connect(_ao_confirmar_criacao.bind(numero))
	var cancelar := _acao(acoes, "BotaoCancelar%d" % numero, tr("CANCELAR"))
	cancelar.pressed.connect(_cancelar)

	# ⚠️ RECUSA, E NAO CORTA CALADO. max_length ja impede digitar alem do limite, mas nao
	# alcanca o que chega COLADO -- quebra de linha, tabulacao, texto de outro lugar. Nome
	# cortado em silencio e o jogador achando que escreveu uma coisa e lendo outra no
	# cartao; aqui o botao apaga e a linha embaixo do campo diz o porque.
	campo.text_changed.connect(func(_texto: String) -> void: _conferir_o_nome(numero))
	_conferir_o_nome(numero)


## O que a linha embaixo do campo diz, e se CRIAR pode ser apertado. Nome em branco e
## legitimo -- o Manuscrito fica com o numero do slot --, entao ele nao apaga o botao.
func _conferir_o_nome(numero: int) -> void:
	var campo := _cartoes.find_child("CampoDeNome%d" % numero, true, false) as LineEdit
	var aviso := _cartoes.find_child("AvisoDoNome%d" % numero, true, false) as Label
	var criar := _cartoes.find_child("BotaoCriar%d" % numero, true, false) as Button
	if campo == null or aviso == null or criar == null:
		return

	var escrito := campo.text
	if escrito.strip_edges().is_empty():
		aviso.text = tr("Em branco, o Manuscrito fica com o número do slot.")
		aviso.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.2)))
		criar.disabled = false
		return
	if NomesDeManuscrito.cabe(escrito):
		aviso.text = tr("Até %d caracteres.") % NomesDeManuscrito.LIMITE
		aviso.add_theme_color_override("font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.2)))
		criar.disabled = false
		return
	aviso.text = (
		tr("Este nome não cabe no cartão: até %d caracteres, e sem quebra de linha.")
		% NomesDeManuscrito.LIMITE
	)
	aviso.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
	criar.disabled = true


func _montar_excluindo(
	numero: int, manuscrito: Manuscrito, dados: VBoxContainer, acoes: VBoxContainer
) -> void:
	dados.add_child(_rotulo(_nome_de(numero, manuscrito), NOME, Paleta.PAPER_CREAM))
	dados.add_child(_rotulo(
		tr("Isto não tem volta: o Manuscrito, o metadado e a cópia de segurança somem."),
		SECUNDARIO, Paleta.BANANA_GOLD,
	))

	var segurar := BotaoDeSegurar.new()
	segurar.name = "BotaoSegurarExcluir%d" % numero
	segurar.text = tr("SEGURE PARA EXCLUIR")
	segurar.custom_minimum_size = Vector2(LARGURA_DA_ACAO, 0)
	segurar.focus_mode = Control.FOCUS_ALL
	Tema.vestir_de_placa(segurar)
	segurar.segurado.connect(_ao_excluir.bind(numero))
	acoes.add_child(segurar)

	var cancelar := _acao(acoes, "BotaoCancelar%d" % numero, tr("CANCELAR"))
	cancelar.pressed.connect(_cancelar)


## As tres que importam, grandes e lado a lado. O rotulo fica embaixo e pequeno: quem olha
## o cartao procura o NUMERO, e descobre o que ele e depois.
func _destaques(manuscrito: Manuscrito) -> Control:
	var era := ErasCatalogo.por_id(manuscrito.era)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 40)
	linha.add_child(_destaque(tr("Era"), tr(era.nome) if era != null else tr("? ? ?")))
	linha.add_child(_destaque(
		tr("Caracteres"), Formatador.formatar(manuscrito.total_caracteres)
	))
	linha.add_child(_destaque(tr("Tempo jogado"), Relogio.duracao(manuscrito.tempo_jogado)))
	return linha


func _destaque(rotulo: String, valor: String) -> Control:
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	coluna.add_child(_rotulo(valor, DESTAQUE_VALOR, Paleta.BANANA_GOLD))
	coluna.add_child(_rotulo(rotulo, DESTAQUE_ROTULO, Paleta.MONKEY_BROWN.lightened(0.3)))
	return coluna


## O contexto, numa linha so e pequeno. Ele tem que PARECER secundario: o cartao tem tres
## informacoes, e estas quatro sao o rodape delas.
func _secundario(manuscrito: Manuscrito) -> String:
	var agora := Time.get_unix_time_from_system()
	return SEPARADOR.join([
		tr("Criado em %s") % Relogio.data(manuscrito.criado_em),
		tr("Última sessão: %s") % Relogio.quando(manuscrito.ultima_sessao, agora),
		tr("%s por segundo") % Formatador.formatar(manuscrito.por_segundo),
		tr("Prestígios: %d") % manuscrito.prestigios,
	])


## Como um Manuscrito se chama na tela. Sem nome ele se apresenta pelo numero do slot -- e
## o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado.
func _nome_de(numero: int, manuscrito: Manuscrito) -> String:
	var nome := manuscrito.nome.strip_edges()
	return nome if not nome.is_empty() else tr("Manuscrito %d") % numero


func _nomes_em_uso() -> PackedStringArray:
	var usados := PackedStringArray()
	for numero in range(1, Config.SLOTS + 1):
		var manuscrito := Config.manuscrito_do_slot(numero)
		if manuscrito.cheio() and not manuscrito.nome.strip_edges().is_empty():
			usados.append(manuscrito.nome.strip_edges())
	return usados


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", Tema.fonte(tamanho))
	rotulo.add_theme_color_override("font_color", Tema.cor(cor))
	return rotulo


func _acao(pai: Node, nome_do_no: String, texto: String) -> Button:
	var botao := Button.new()
	botao.name = nome_do_no
	botao.text = texto
	botao.custom_minimum_size = Vector2(LARGURA_DA_ACAO, 0)
	botao.focus_mode = Control.FOCUS_ALL
	Tema.vestir_de_placa(botao)
	pai.add_child(botao)
	return botao


## Devolve o foco depois de remontar. Sem isto, cada acao deixaria o teclado parado: a tela
## e remontada inteira a cada mudanca de modo, e o controle focado morre junto.
func _dar_o_foco() -> void:
	var alvo: Control = null
	if not _focar_depois.is_empty():
		alvo = _cartoes.find_child(_focar_depois, true, false) as Control
	_focar_depois = ""
	if alvo == null:
		for candidato in _cartoes.find_children("Botao*", "Button", true, false):
			if not (candidato as Button).disabled:
				alvo = candidato as Control
				break
	if alvo == null:
		alvo = _voltar
	Foco.pedir(alvo)


# --------------------------------------------------------------------------------- acoes

func _ao_abrir(numero: int) -> void:
	Cenas.comecar_partida(numero)


func _ao_criar(numero: int) -> void:
	_modo = Modo.NOMEANDO
	_slot_em_acao = numero
	_focar_depois = "CampoDeNome%d" % numero
	_pintar()


func _ao_confirmar_criacao(numero: int) -> void:
	var campo := _cartoes.find_child("CampoDeNome%d" % numero, true, false) as LineEdit
	var nome := NomesDeManuscrito.limpar(campo.text if campo != null else "")
	_modo = Modo.NORMAL
	_slot_em_acao = 0
	Cenas.comecar_partida(numero, nome)


func _ao_pedir_exclusao(numero: int) -> void:
	_modo = Modo.EXCLUINDO
	_slot_em_acao = numero
	_focar_depois = "BotaoSegurarExcluir%d" % numero
	_pintar()


## ⚠️ APAGA OS TRES ARQUIVOS DO SLOT, E SO OS DELE. Deixar o .meta para tras faria o cartao
## continuar aparecendo; deixar o .backup ressuscitaria a partida que o jogador acabou de
## mandar apagar. Quem sabe disso e o Save, e por isso a conta nao e refeita aqui.
func _ao_excluir(numero: int) -> void:
	Save.apagar_arquivos(Config.caminho_do_slot(numero))
	_modo = Modo.NORMAL
	_slot_em_acao = 0
	_focar_depois = "BotaoNovo%d" % numero
	_pintar()


func _cancelar() -> void:
	if _modo == Modo.NORMAL:
		return
	_focar_depois = "BotaoAbrir%d" % _slot_em_acao
	_modo = Modo.NORMAL
	_slot_em_acao = 0
	_pintar()


func _ao_voltar() -> void:
	Cenas.ir_para_menu()


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()


## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	_pintar()
