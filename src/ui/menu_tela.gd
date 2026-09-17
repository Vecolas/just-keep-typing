## O menu principal: as cinco opcoes e o CONTINUAR (issue #39).
##
## ⚠️ AINDA SEM ARTE. O cenario, o logo e os botoes de placa sao a issue #46, e a abertura
## datilografada e a #47. O que esta resolvido aqui e o COMPORTAMENTO: cinco opcoes, o
## resumo de onde o jogador esta voltando, e a tela inteira andavel sem tocar no mouse.
##
## CONTINUAR nao carrega nada por conta propria: ele so diz ao Cenas qual Manuscrito abrir,
## que e o mesmo que a tela de Arquivos faz. Dois caminhos ate uma partida seriam dois
## lugares para esquecer de creditar o offline.
##
## ⚠️ LE O METADADO DO SLOT, E NAO A PARTIDA DELE (issue #35). Saber se ha o que continuar
## -- e escrever era, total e data embaixo do botao -- nao pode custar abrir um save:
## carregar para desenhar o menu creditaria producao offline antes de o jogador escolher
## qualquer coisa.
##
## ⚠️ CONTINUAR SEM SAVE PARECE DESABILITADO, e nao so recusa o clique. E a mesma regra da
## resolucao apagada em tela cheia (issue #34): campo que nao faz nada e parece que faz e
## campo que a pessoa conclui que o jogo ignorou. E o resumo embaixo dele diz o PORQUE --
## sem Manuscrito, ilegivel -- em vez de ficar vazio.
##
## ⚠️ AQUI OS BOTOES PEGAM FOCO, e na HUD nao. Sao a mesma acao (`ui_accept` e espaco) com
## dois significados: dentro da partida o espaco DIGITA um caractere (issue #6), e por isso
## os botoes da HUD usam FOCUS_NONE -- apertar espaco para comprar macaco seria comprar
## macaco a cada caractere. No menu nao ha o que digitar, e sem foco nao ha navegacao por
## teclado nem por controle.
extends Control

const TITULO: int = 64
const LARGURA_DO_BOTAO: int = 420
const RESUMO: int = 16

## Uma opcao do menu: o nome do no (que a fumaca aperta), a chave de texto e o que ela faz.
## Lista e nao cinco blocos soltos porque a ORDEM e o que a navegacao por teclado segue --
## e ordem escrita em cinco lugares e ordem que vai divergir.
const OPCOES: Array[Dictionary] = [
	{"no": "BotaoContinuar", "texto": "CONTINUAR", "acao": "_ao_continuar"},
	{"no": "BotaoJogar", "texto": "JOGAR", "acao": "_ao_jogar"},
	{"no": "BotaoConfiguracoes", "texto": "CONFIGURAÇÕES", "acao": "_ao_configurar"},
	{"no": "BotaoCreditos", "texto": "CRÉDITOS", "acao": "_ao_creditar"},
	{"no": "BotaoSair", "texto": "SAIR", "acao": "_ao_sair"},
]

var _titulo: Label = null
var _resumo: Label = null
var _botoes: Dictionary = {}


func _ready() -> void:
	theme = Tema.montar()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Paleta.INK_BROWN.darkened(0.4)
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
	_titulo.add_theme_font_size_override("font_size", TITULO)
	_titulo.add_theme_color_override("font_color", Paleta.BANANA_GOLD)
	centro.add_child(_titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 40)
	centro.add_child(espaco)

	# os nos ganham nome porque a fumaca aperta ESTES botoes, e nao chama o Cenas por
	# baixo: o que se prova la e a ligacao, e find_child por indice quebraria na primeira
	# vez que alguem acrescentasse uma opcao no meio
	for opcao in OPCOES:
		var botao := _botao(centro, str(opcao["no"]))
		botao.pressed.connect(Callable(self, str(opcao["acao"])))
		_botoes[opcao["no"]] = botao
		# o resumo mora colado no CONTINUAR, e nao no rodape: ele e a legenda daquele botao
		if opcao["no"] == "BotaoContinuar":
			_resumo = _montar_resumo(centro)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	_pintar()
	_dar_o_foco_inicial()


## Repintar nao e remontar: os botoes ja existem, e so o texto deles muda de lingua
## (CONVENCOES.md). Chamar isto de novo nao pode empilhar botao nenhum.
func _pintar() -> void:
	# o titulo do jogo nao se traduz, mas passa por tr() do mesmo jeito: a linha existe no
	# CSV nas duas colunas, e assim o dia em que ele mudar de nome numa lingua so nao exige
	# tocar em codigo
	_titulo.text = tr("JUST KEEP TYPING")
	for opcao in OPCOES:
		(_botoes[opcao["no"]] as Button).text = tr(str(opcao["texto"]))

	var manuscrito := Config.manuscrito_do_slot(Config.slot())
	# so ha o que continuar se o slot lembrado tiver Manuscrito. Slot ilegivel tambem
	# desabilita: mandar o jogador para uma partida que nao abre e pior que nao oferecer
	(_botoes["BotaoContinuar"] as Button).disabled = not manuscrito.cheio()
	_resumo.text = _texto_do_resumo(manuscrito)


## De onde o jogador esta voltando -- era, total e ultima sessao -- ou POR QUE nao ha para
## onde voltar. Resumo vazio ao lado de um botao apagado deixa a pessoa sem saber se o
## jogo perdeu o save dela ou se ela nunca teve um.
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


## O primeiro botao que o jogador consegue apertar. CONTINUAR desabilitado nao recebe foco:
## abrir o menu com o cursor de teclado parado num botao morto e a versao de teclado do
## mesmo defeito que a issue #34 consertou no mouse.
func _dar_o_foco_inicial() -> void:
	for opcao in OPCOES:
		var botao := _botoes[opcao["no"]] as Button
		if not botao.disabled:
			botao.call_deferred("grab_focus")
			return


func _montar_resumo(pai: Node) -> Label:
	var rotulo := Label.new()
	rotulo.name = "ResumoDoContinuar"
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", RESUMO)
	rotulo.add_theme_color_override("font_color", Paleta.MONKEY_BROWN.lightened(0.35))
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(rotulo)
	return rotulo


func _botao(pai: Node, nome_do_no: String) -> Button:
	var botao := Button.new()
	botao.name = nome_do_no
	botao.custom_minimum_size = Vector2(LARGURA_DO_BOTAO, 0)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# ⚠️ FOCUS_ALL, ao contrario da HUD: ver o aviso no topo do arquivo
	botao.focus_mode = Control.FOCUS_ALL
	pai.add_child(botao)
	return botao


func _ao_continuar() -> void:
	Cenas.comecar_partida(Config.slot())


func _ao_jogar() -> void:
	Cenas.ir_para_arquivos()


func _ao_configurar() -> void:
	EventBus.opcoes_pedidas.emit()


func _ao_creditar() -> void:
	EventBus.creditos_pedidos.emit()


## ⚠️ SAIR GRAVA ANTES DE FECHAR, e quem sabe se ha o que gravar e o Cenas. Chamar
## get_tree().quit() daqui e o jeito de perder os minutos desde o ultimo autosave no gesto
## em que o jogador MAIS espera que o jogo tenha guardado.
func _ao_sair() -> void:
	Cenas.sair()


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()
	# repintar pode ter acabado de apagar o botao que estava com o foco -- e foco em botao
	# desabilitado e navegacao por teclado que trava sem dizer nada
	var focado := get_viewport().gui_get_focus_owner() as Button
	if focado == null or focado.disabled:
		_dar_o_foco_inicial()
