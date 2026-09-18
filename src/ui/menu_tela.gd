## O menu principal: a mesa, o logo e as cinco opções (issues #39 e #46).
##
## Esta é a primeira cena narrativa do jogo. Até a #38 ela era um rascunho feio de
## propósito; a #39 deu a ela o comportamento — cinco opções, o resumo do CONTINUAR,
## navegação sem mouse — e a #46 deu a mesa.
##
## ⚠️ HÍBRIDO, E NÃO O MENU DESENHADO NA FOLHA DA MÁQUINA. O menu escrito na folha é bonito
## e é armadilha de usabilidade: o texto fica preso ao ângulo do papel, o alvo de clique
## fica torto e a tradução estoura a folha. O plano §6 recomenda o híbrido — cenário físico
## com UI estilizada por cima —, e é ele que entra.
##
## ⚠️ O CENÁRIO NÃO COME O CLIQUE DE QUEM ESTÁ ATRÁS. Todo nó dele é `MOUSE_FILTER_IGNORE`:
## foi exatamente com `mouse_filter` em STOP por padrão que a fumaça da issue #7 pegou um
## painel comendo o clique da loja.
##
## ⚠️ DUAS TIPOGRAFIAS, E NUNCA TRÊS (`ARTE.md` §8). Título serifado pesado, interface
## monoespaçada. O logo usa a serifada do `Tema` — ele não inventa uma terceira fonte.
##
## CONTINUAR não carrega nada por conta própria: ele só diz ao `Cenas` qual Manuscrito
## abrir, que é o mesmo que a tela de Arquivos faz. Dois caminhos até uma partida seriam
## dois lugares para esquecer de creditar o offline.
##
## ⚠️ LÊ O METADADO DO SLOT, E NÃO A PARTIDA DELE (issue #35). Saber se há o que continuar
## não pode custar abrir um save.
##
## ⚠️ CONTINUAR SEM SAVE PARECE DESABILITADO, e não só recusa o clique — e o resumo embaixo
## dele diz o porquê em vez de ficar vazio.
##
## ⚠️ AQUI OS BOTÕES PEGAM FOCO, e na HUD não. São a mesma ação (`ui_accept` e espaço) com
## dois significados: dentro da partida o espaço DIGITA um caractere (issue #6). No menu não
## há o que digitar, e sem foco não há navegação por teclado nem por controle.
extends Control

const TITULO: int = 58
const RESUMO: int = 16

## A largura do painel de menu, em pixels lógicos. Ele mora na metade DIREITA porque é lá
## que o cenário deixou espaço negativo de propósito (docs/ASSETS.md).
const LARGURA_DO_PAINEL: int = 660
const MARGEM_DO_PAINEL: int = 40
const LARGURA_DO_BOTAO: int = 500
const LADO_DO_EMBLEMA: int = 128

## Uma opção do menu: o nome do nó (que a fumaça aperta), a chave de texto e o que ela faz.
## Lista e não cinco blocos soltos porque a ORDEM é o que a navegação por teclado segue — e
## ordem escrita em cinco lugares é ordem que vai divergir.
const OPCOES: Array[Dictionary] = [
	{"no": "BotaoContinuar", "texto": "CONTINUAR", "acao": "_ao_continuar"},
	{"no": "BotaoJogar", "texto": "JOGAR", "acao": "_ao_jogar"},
	{"no": "BotaoConfiguracoes", "texto": "CONFIGURAÇÕES", "acao": "_ao_configurar"},
	{"no": "BotaoCreditos", "texto": "CRÉDITOS", "acao": "_ao_creditar"},
	{"no": "BotaoSair", "texto": "SAIR", "acao": "_ao_sair"},
]

var _cenario: CenarioDoMenu = null
var _titulo: Label = null
var _resumo: Label = null
var _painel: Control = null
var _botoes: Dictionary = {}


func _ready() -> void:
	theme = Tema.montar()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_cenario = CenarioDoMenu.new()
	_cenario.name = "Cenario"
	add_child(_cenario)

	_montar_painel()

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_pintar()
	_dar_o_foco_inicial()


# ------------------------------------------------------------------------------ montagem

func _montar_painel() -> void:
	var margem := MarginContainer.new()
	margem.name = "MargemDoPainel"
	margem.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	margem.offset_left = float(-LARGURA_DO_PAINEL - MARGEM_DO_PAINEL)
	margem.offset_right = float(-MARGEM_DO_PAINEL)
	margem.offset_top = float(MARGEM_DO_PAINEL)
	margem.offset_bottom = float(-MARGEM_DO_PAINEL)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)

	# o painel de papel é a moldura; quando o asset não existe, o StyleBox do tema assume e
	# o menu continua utilizável -- menu que não abre porque um PNG não veio é pior
	_painel = _moldura_de_papel()
	margem.add_child(_painel)

	var dentro := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		dentro.add_theme_constant_override("margin_" + lado, 56)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(dentro)

	var coluna := VBoxContainer.new()
	coluna.name = "Coluna"
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 14)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(coluna)

	coluna.add_child(_emblema())

	_titulo = Label.new()
	_titulo.name = "Titulo"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 28)
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(espaco)

	# os nós ganham nome porque a fumaça aperta ESTES botões, e não chama o Cenas por
	# baixo: o que se prova lá é a ligação, e find_child por índice quebraria na primeira
	# vez que alguém acrescentasse uma opção no meio
	for opcao in OPCOES:
		var botao := _botao(coluna, str(opcao["no"]))
		botao.pressed.connect(Callable(self, str(opcao["acao"])))
		_botoes[opcao["no"]] = botao
		# o resumo mora colado no CONTINUAR, e não no rodapé: ele é a legenda daquele botão
		if opcao["no"] == "BotaoContinuar":
			_resumo = _montar_resumo(coluna)


func _moldura_de_papel() -> Control:
	var textura := AssetsDoMenu.textura_ampliada("painel")
	if textura == null:
		var painel := PanelContainer.new()
		painel.name = "PainelDoMenu"
		painel.add_theme_stylebox_override("panel", Tema.painel())
		painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return painel

	var papel := NinePatchRect.new()
	papel.name = "PainelDoMenu"
	papel.texture = textura
	var borda := AssetsDoMenu.borda_ampliada("painel")
	papel.patch_margin_left = borda
	papel.patch_margin_top = borda
	papel.patch_margin_right = borda
	papel.patch_margin_bottom = borda
	# ⚠️ ESTICA, e nao repete. O modo padrao LADRILHA a borda: numa peca de papel com
	# rasgo, o rasgo aparece de novo a cada 48 pixels e a moldura vira uma serrilha
	papel.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	papel.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AssetsDoMenu.aplicar_filtro(papel)
	return papel


func _emblema() -> Control:
	var textura := AssetsDoMenu.textura_ampliada("emblema")
	var marca := TextureRect.new()
	marca.name = "Emblema"
	marca.texture = textura
	marca.visible = textura != null
	marca.custom_minimum_size = Vector2(LADO_DO_EMBLEMA, LADO_DO_EMBLEMA)
	marca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marca.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AssetsDoMenu.aplicar_filtro(marca)
	return marca


func _montar_resumo(pai: Node) -> Label:
	var rotulo := Label.new()
	rotulo.name = "ResumoDoContinuar"
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", Tema.fonte(RESUMO))
	rotulo.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM.darkened(0.35)))
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(rotulo)
	return rotulo


func _botao(pai: Node, nome_do_no: String) -> Button:
	var botao := Button.new()
	botao.name = nome_do_no
	botao.custom_minimum_size = Vector2(LARGURA_DO_BOTAO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# ⚠️ FOCUS_ALL, ao contrário da HUD: ver o aviso no topo do arquivo
	botao.focus_mode = Control.FOCUS_ALL
	# os quatro estados de placa, distinguíveis sem cor (Tema.vestir_de_placa)
	Tema.vestir_de_placa(botao)
	pai.add_child(botao)
	return botao


# ------------------------------------------------------------------------------- pintura

## Repintar não é remontar: os botões já existem, e só o texto deles muda de língua
## (CONVENCOES.md). Chamar isto de novo não pode empilhar botão nenhum.
func _pintar() -> void:
	# o título do jogo não se traduz, mas passa por tr() do mesmo jeito: a linha existe no
	# CSV nas duas colunas, e assim o dia em que ele mudar de nome numa língua só não exige
	# tocar em código
	_titulo.text = tr("JUST KEEP TYPING")
	_titulo.add_theme_font_override("font", Tema.fonte_de_titulo())
	_titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO))
	_titulo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))

	for opcao in OPCOES:
		(_botoes[opcao["no"]] as Button).text = tr(str(opcao["texto"]))

	var manuscrito := Config.manuscrito_do_slot(Config.slot())
	# só há o que continuar se o slot lembrado tiver Manuscrito. Slot ilegível também
	# desabilita: mandar o jogador para uma partida que não abre é pior que não oferecer
	(_botoes["BotaoContinuar"] as Button).disabled = not manuscrito.cheio()
	_resumo.text = _texto_do_resumo(manuscrito)


## De onde o jogador está voltando — era, total e última sessão — ou POR QUE não há para
## onde voltar. Resumo vazio ao lado de um botão apagado deixa a pessoa sem saber se o jogo
## perdeu o save dela ou se ela nunca teve um.
func _texto_do_resumo(manuscrito: Manuscrito) -> String:
	if manuscrito.ilegivel():
		return tr("Manuscrito ilegível")
	if manuscrito.vazio():
		return tr("Nenhum Manuscrito para continuar.")

	var era := ErasCatalogo.por_id(manuscrito.era)
	return "\n".join([
		tr("Era: %s") % (tr(era.nome) if era != null else tr("? ? ?")),
		tr("%s caracteres") % Formatador.formatar(manuscrito.total_caracteres),
		tr("Última sessão: %s") % Relogio.quando(
			manuscrito.ultima_sessao, Time.get_unix_time_from_system()
		),
	])


## O primeiro botão que o jogador consegue apertar. CONTINUAR desabilitado não recebe foco:
## abrir o menu com o cursor de teclado parado num botão morto é a versão de teclado do
## mesmo defeito que a issue #34 consertou no mouse.
func _dar_o_foco_inicial() -> void:
	for opcao in OPCOES:
		var botao := _botoes[opcao["no"]] as Button
		if not botao.disabled:
			botao.call_deferred("grab_focus")
			return


## ⚠️ A TECLA DO JOGADOR VIRA A TECLA DO MACACO, e mais nada (issue #49, plano §37). Esta
## é a única brincadeira do projeto sem consequência nenhuma — e ela só pode existir porque
## não tem: um bug aqui não custa progresso a ninguém.
##
## ⚠️ `_unhandled_input` E NÃO `_input`: assim o botão focado consome `ui_accept` antes, e
## apertar espaço no menu continua sendo "selecionar" em vez de escrever um espaço na folha.
##
## Só caractere imprimível entra. `unicode` vem zero em tecla de função, seta e modificador,
## e escrever o caractere zero na folha é escrever um retângulo vazio.
func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.is_pressed() or tecla.is_echo():
		return
	if tecla.unicode < 32:
		return
	_cenario.datilografar(String.chr(tecla.unicode))
	get_viewport().set_input_as_handled()


# --------------------------------------------------------------------------------- ações

func _ao_continuar() -> void:
	Cenas.comecar_partida(Config.slot())


func _ao_jogar() -> void:
	Cenas.ir_para_arquivos()


func _ao_configurar() -> void:
	EventBus.opcoes_pedidas.emit()


func _ao_creditar() -> void:
	EventBus.creditos_pedidos.emit()


## ⚠️ SAIR GRAVA ANTES DE FECHAR, e quem sabe se há o que gravar é o Cenas. Chamar
## get_tree().quit() daqui é o jeito de perder os minutos desde o último autosave no gesto
## em que o jogador MAIS espera que o jogo tenha guardado.
func _ao_sair() -> void:
	Cenas.sair()


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()
	# repintar pode ter acabado de apagar o botão que estava com o foco -- e foco em botão
	# desabilitado é navegação por teclado que trava sem dizer nada
	var focado := get_viewport().gui_get_focus_owner() as Button
	if focado == null or focado.disabled:
		_dar_o_foco_inicial()


## ⚠️ REMONTA O TEMA, e não só repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme é um objeto CONSTRUÍDO: ele não se atualiza sozinho
## quando a opção muda.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	for opcao in OPCOES:
		Tema.vestir_de_placa(_botoes[opcao["no"]] as Button)
	_pintar()
