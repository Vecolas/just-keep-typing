## O caminho do jogo: Boot -> Menu -> Arquivos -> Partida -> Menu.
##
## Nome traduzido do SceneManager do plano do menu -- ver
## docs/decisoes/0002-codigo-em-portugues.md.
##
## Ate a v0.4 o main.tscn ERA a partida: abrir o jogo era estar jogando. Este autoload
## transforma isso num caminho, e passa a ser ele quem decide QUAL Manuscrito abre --
## papel que era do Config sozinho, no boot, sem ninguem escolher nada.
##
## ⚠️ MONTA NUM NO DE GRUPO, e nao com change_scene_to_packed. Trocar a cena da arvore
## libera a CENA ATUAL, e a cena atual, quando a fumaca roda, e a propria fumaca -- o teste
## se mataria no meio da run que ele existe para provar. Grupo e a unica excecao que a
## CONVENCOES.md abre a "nunca alcance ninguem por caminho de no", e e exatamente para isto.
##
## ⚠️ REMOVE DA ARVORE ANTES DE LIBERAR. queue_free() sozinho deixa a cena velha viva ate o
## fim do quadro: por um quadro haveria duas Partidas na arvore, as duas com _process, as
## duas mexendo no MESMO autoload Jogo. O tique dobrado nao imprime erro nenhum -- ele so
## faz a producao daquele quadro contar duas vezes. remove_child tira do ar na hora;
## queue_free apaga depois, que e o unico jeito seguro quando quem pediu a troca foi um
## botao de dentro da cena que esta saindo.
##
## O fade e um CLARAO e nao uma travessia: a tela ja aparece preta e clareia. Fade de saida
## exigiria await no meio da troca, e await no meio da troca e a janela em que um segundo
## clique comeca uma segunda partida. A transicao bonita e a issue #48.
extends Node

## Onde as cenas sao montadas. O Boot poe um no neste grupo; ninguem mais precisa saber
## onde ele fica.
const GRUPO_RAIZ := &"raiz_de_cena"

const ABERTURA := "res://src/ui/abertura.tscn"
const MENU := "res://src/ui/menu_tela.tscn"
const ARQUIVOS := "res://src/ui/arquivos_tela.tscn"
const PARTIDA := "res://src/cena/partida.tscn"

## Quanto tempo o clarao leva para sumir.
const CLARAO: float = 0.25

## Quanto dura a aproximacao da maquina ao entrar numa partida (issue #48).
const APROXIMACAO: float = 0.45

## Quantas vezes a maquina cresce durante a aproximacao. Seis: o bastante para ela sair da
## tela, que e o que faz o corte terminar DENTRO dela.
const ZOOM_DA_MAQUINA: float = 6.0

## Id da cena montada agora. Vazio antes do Boot montar a primeira.
var _atual: String = ""

## ⚠️ O INSTANTE EM QUE O JOGO ABRIU, e nao o instante em que a partida abre. E ele que
## mede a producao offline -- ver docs/decisoes/0005-o-relogio-do-offline.md.
var _abriu_em: float = 0.0

## Slots que ja foram abertos NESTA sessao. Voltar ao menu e entrar de novo nao credita
## offline outra vez: entre uma coisa e outra o jogo nao esteve fechado.
var _ja_creditados: Dictionary = {}

var _fade: ColorRect = null
var _ate_clarear: float = 0.0

## A maquina da transicao: ela existe no clarao, e nao na cena. Ver _aproximar_da_maquina.
var _maquina: TextureRect = null
var _ate_chegar: float = 0.0
var _de_onde := Rect2()


func _ready() -> void:
	_abriu_em = Time.get_unix_time_from_system()
	_montar_fade()


## O clarao vive num CanvasLayer do proprio autoload, acima de qualquer coisa que a cena
## montada desenhe: cena que carrega junto com o fade por baixo dela e cena que aparece
## antes da hora.
func _montar_fade() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 128
	add_child(camada)
	_fade = ColorRect.new()
	_fade.color = Paleta.INK_BROWN.darkened(0.4)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	camada.add_child(_fade)

	# ⚠️ A MAQUINA DA TRANSICAO MORA AQUI, e nao na cena que esta saindo. Ela precisa
	# sobreviver a troca -- e a cena do menu e liberada no mesmo quadro em que a partida
	# monta. Uma copia da textura no CanvasLayer do clarao atravessa a troca sem depender de
	# ninguem (issue #48).
	_maquina = TextureRect.new()
	_maquina.texture = AssetsDoMenu.textura_ampliada("maquina")
	_maquina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maquina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_maquina.stretch_mode = TextureRect.STRETCH_SCALE
	_maquina.visible = false
	AssetsDoMenu.aplicar_filtro(_maquina)
	camada.add_child(_maquina)


func _process(delta: float) -> void:
	_andar_a_aproximacao(delta)
	if _ate_clarear <= 0.0:
		return
	_ate_clarear -= delta
	_fade.modulate.a = clampf(_ate_clarear / CLARAO, 0.0, 1.0)
	if _ate_clarear <= 0.0:
		_fade.visible = false


## A camera "entra" na maquina de escrever: ela cresce a partir de onde estava no menu e
## some, deixando a partida atras dela.
##
## ⚠️ A PARTIDA JA ESTA MONTADA QUANDO ISTO RODA. Esta e a razao inteira do desenho: uma
## transicao que EXIGISSE await antes de montar abriria a janela em que um segundo clique
## comeca uma segunda partida -- e foi para fechar essa janela que a issue #38 escolheu o
## clarao em vez da travessia. Aqui a transicao e decoracao por cima de um jogo que ja
## comecou, e por isso a fumaca a atravessa sem esperar tempo real nenhum.
func _andar_a_aproximacao(delta: float) -> void:
	if _ate_chegar <= 0.0:
		return
	_ate_chegar -= delta
	var quanto := 1.0 - clampf(_ate_chegar / APROXIMACAO, 0.0, 1.0)
	var perto := lerpf(1.0, ZOOM_DA_MAQUINA, quanto * quanto)
	var tamanho := _de_onde.size * perto
	_maquina.size = tamanho
	_maquina.position = _de_onde.get_center() - tamanho * 0.5
	_maquina.modulate.a = 1.0 - quanto
	if _ate_chegar <= 0.0:
		_maquina.visible = false


## Comeca a aproximacao a partir do retangulo onde a maquina estava no menu.
##
## ⚠️ SEM RETANGULO NAO HA TRANSICAO, e isso e legitimo: entrar numa partida pela tela de
## Arquivos nao vem de uma mesa na tela, e inventar uma maquina saindo do nada seria uma
## transicao que nao costura coisa nenhuma.
func _aproximar_da_maquina(de_onde: Rect2) -> void:
	if de_onde.size.x <= 0.0 or _maquina.texture == null:
		return
	# reduzir movimento e reduzir flashes desligam os dois: a transicao e movimento, e ela
	# termina num clarao (issue #43)
	if Config.ligado("reduzir_movimento"):
		return
	_de_onde = de_onde
	_ate_chegar = APROXIMACAO
	_maquina.visible = true
	_maquina.modulate.a = 1.0
	_maquina.size = de_onde.size
	_maquina.position = de_onde.position
	Audio.tocar_clack()


## Onde a maquina esta na tela agora, se houver um menu montado. Vazio quando nao houver --
## e o caso de entrar numa partida pela tela de Arquivos.
##
## ⚠️ PERGUNTA POR NOME DE NO, e isso e uma excecao consciente a "nunca alcance ninguem por
## caminho de no": a alternativa era o menu ANUNCIAR a posicao da maquina num sinal que so
## esta funcao escutaria, o que e uma chamada de metodo disfarcada de evento. O acoplamento
## e de um nome, e ele esta escrito aqui.
func _retangulo_da_maquina_no_menu() -> Rect2:
	var raiz := get_tree().get_first_node_in_group(GRUPO_RAIZ)
	if raiz == null:
		return Rect2()
	var cenario := raiz.find_child("Cenario", true, false) as CenarioDoMenu
	if cenario == null:
		return Rect2()
	return cenario.retangulo_da_maquina()


# --------------------------------------------------------------------------- o caminho

## O primeiro passo do caminho (issue #47), e o unico que as vezes nao acontece.
##
## ⚠️ QUEM JA VIU PULA AQUI, e nao dentro da cena. A abertura nem chega a ser montada: sem
## isso, quem abre o jogo todo dia pagaria o custo de montar uma cena inteira para ela se
## desmontar sozinha no quadro seguinte -- e um quadro de tela preta e uma piscada que a
## pessoa ve.
func ir_para_abertura() -> bool:
	if Config.ligado("ja_viu_abertura"):
		return ir_para_menu()
	return _trocar("abertura", ABERTURA)


func ir_para_menu() -> bool:
	return _trocar("menu", MENU)


func ir_para_arquivos() -> bool:
	return _trocar("arquivos", ARQUIVOS)


## Abre um Manuscrito e entra nele.
##
## ⚠️ QUEM CARREGA O SAVE E AQUI, e nao mais a Partida no _ready dela. Com menu, o slot e
## escolhido antes de a cena existir; deixar a Partida carregar de novo creditaria a
## producao offline DUAS VEZES -- uma aqui e outra ao montar.
## `nome` so vale para slot VAZIO (issue #40): e o que o jogador escreveu no cartao antes
## de apertar CRIAR. Chamar com nome no caminho de ABRIR nao renomeia nada -- renomear a
## partida de alguem por engano nao imprime erro, so troca o rotulo que a pessoa escolheu.
##
## O Manuscrito novo e GRAVADO na hora, e nao no proximo autosave: criar e o gesto em que o
## jogador espera que o arquivo passe a existir. Sem isto, fechar o jogo nos primeiros
## trinta segundos apagaria um Manuscrito que a tela ja mostrava.
func comecar_partida(slot: int, nome: String = "") -> bool:
	# ⚠️ QUEM DIZ SE HA PARTIDA AQUI E O MESMO CARTAO QUE A TELA DESENHOU. A versao
	# anterior perguntava Save.existe(), que olha so o arquivo principal -- e desde o
	# backup (issue #36) um slot com o principal perdido e o .backup intacto E uma partida:
	# o cartao dizia CHEIO e abrir comecava do zero por cima dele. Duas fontes para a mesma
	# verdade, e a que valia era a errada.
	var manuscrito := Config.manuscrito_do_slot(slot)
	Config.abrir_slot(slot)
	if manuscrito.cheio():
		Save.carregar()
	else:
		Save.recomecar()

	if manuscrito.vazio() and not nome.is_empty():
		Jogo.nome = nome

	# ⚠️ MEDIDO ANTES DA TROCA. Depois dela o menu ja foi liberado, e a pergunta devolveria
	# um retangulo vazio -- a transicao simplesmente nao aconteceria, sem erro nenhum.
	var de_onde := _retangulo_da_maquina_no_menu()

	_creditar_offline(slot)
	Marcos.verificar()

	# ⚠️ SO SLOT VAZIO GRAVA NA ENTRADA. Manuscrito ILEGIVEL tambem caiu no recomecar acima
	# -- ele precisa de um Jogo em estado valido para a cena abrir --, mas gravar por cima
	# dele apagaria o arquivo que o jogador ainda pode querer recuperar na mao.
	if manuscrito.vazio():
		Autosave.gravar_agora()
	var trocou := _trocar("partida", PARTIDA)
	if trocou:
		_aproximar_da_maquina(de_onde)
	return trocou


## Sai da partida pelo caminho que grava. Nao existe voltar ao menu sem gravar: e um dos
## momentos em que o jogador ESPERA que o jogo tenha guardado (issue #37).
func voltar_ao_menu() -> bool:
	if _atual == "partida":
		Autosave.gravar_agora()
	return ir_para_menu()


## Fecha o jogo pelo caminho que grava.
##
## ⚠️ get_tree().quit() NAO DISPARA NOTIFICATION_WM_CLOSE_REQUEST. O fechar-pelo-X da
## janela grava porque a Partida escuta aquela notificacao; o botao SAIR do menu nao
## passaria por ela, e sairia comendo os minutos desde o ultimo autosave -- calado, e no
## gesto em que o jogador mais espera que o jogo tenha guardado. Os dois caminhos de saida
## precisam gravar, e o par mora aqui, que e quem sabe se ha partida aberta.
func sair() -> void:
	if _atual == "partida":
		Autosave.gravar_agora()
	# as opcoes ja gravam a cada escolha; isto e o cinto de seguranca de um campo que tenha
	# mudado sem passar por escolher()
	Config.gravar()
	get_tree().quit(0)


func atual() -> String:
	return _atual


## Se a aproximacao da maquina esta acontecendo agora. A fumaca le isto para afirmar que a
## transicao ROLA sem que ela precise esperar por ela.
func aproximando() -> bool:
	return _ate_chegar > 0.0


## Quantos Manuscritos ja foram abertos nesta sessao. A suite le isto para provar que
## reentrar nao credita offline de novo.
func creditados_nesta_sessao() -> int:
	return _ja_creditados.size()


# ------------------------------------------------------------------------------ offline

## Credita a producao das horas em que o jogo esteve FECHADO, e so dela.
##
## Duas regras, e as duas vem da decisao 0005:
##
##   o relogio para no instante em que o jogo abriu, e nao no instante em que a partida
##   abre -- senao o tempo que a pessoa passa lendo o menu vira producao;
##
##   e um Manuscrito so recebe offline UMA vez por sessao. Voltar ao menu grava, e entrar
##   de novo veria o proprio gravado_em de ha um minuto como "um minuto fora".
func _creditar_offline(slot: int) -> void:
	if _ja_creditados.has(slot):
		return
	_ja_creditados[slot] = true
	var gravado_em := _gravado_em_do_save()
	if gravado_em <= 0.0:
		return
	Economia.creditar_offline(_abriu_em - gravado_em)


func _gravado_em_do_save() -> float:
	if not Save.existe():
		return 0.0
	var arquivo := FileAccess.open(Save.caminho, FileAccess.READ)
	if arquivo == null:
		return 0.0
	var cru = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	if typeof(cru) != TYPE_DICTIONARY:
		return 0.0
	return float((cru as Dictionary).get("gravado_em", 0.0))


# -------------------------------------------------------------------------------- troca

func _trocar(id: String, caminho: String) -> bool:
	var raiz := get_tree().get_first_node_in_group(GRUPO_RAIZ)
	if raiz == null:
		push_error("Cenas: nao ha no no grupo %s para montar a cena" % GRUPO_RAIZ)
		return false

	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		push_error("Cenas: %s nao carregou" % caminho)
		return false

	# fora da arvore ANTES de montar a proxima: duas cenas montadas, mesmo que por um
	# quadro so, sao dois _process mexendo no mesmo Jogo
	for filho in raiz.get_children():
		raiz.remove_child(filho)
		filho.queue_free()

	raiz.add_child(empacotada.instantiate())
	_atual = id

	# ⚠️ REDUZIR FLASHES APAGA O CLARAO (issue #43). Ele e literalmente uma tela inteira
	# indo de opaca a transparente em um quarto de segundo, que e a definicao do que aquela
	# opcao existe para evitar. Sem ele a cena simplesmente aparece -- o caminho continua o
	# mesmo, e o que some e o piscar.
	if Config.ligado("reduzir_flashes"):
		_fade.visible = false
		_ate_clarear = 0.0
		return true
	_fade.visible = true
	_fade.modulate.a = 1.0
	_ate_clarear = CLARAO
	return true
