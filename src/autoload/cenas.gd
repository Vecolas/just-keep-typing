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

const MENU := "res://src/ui/menu_tela.tscn"
const ARQUIVOS := "res://src/ui/arquivos_tela.tscn"
const PARTIDA := "res://src/cena/partida.tscn"

## Quanto tempo o clarao leva para sumir.
const CLARAO: float = 0.25

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


func _process(delta: float) -> void:
	if _ate_clarear <= 0.0:
		return
	_ate_clarear -= delta
	_fade.modulate.a = clampf(_ate_clarear / CLARAO, 0.0, 1.0)
	if _ate_clarear <= 0.0:
		_fade.visible = false


# --------------------------------------------------------------------------- o caminho

func ir_para_menu() -> bool:
	return _trocar("menu", MENU)


func ir_para_arquivos() -> bool:
	return _trocar("arquivos", ARQUIVOS)


## Abre um Manuscrito e entra nele.
##
## ⚠️ QUEM CARREGA O SAVE E AQUI, e nao mais a Partida no _ready dela. Com menu, o slot e
## escolhido antes de a cena existir; deixar a Partida carregar de novo creditaria a
## producao offline DUAS VEZES -- uma aqui e outra ao montar.
func comecar_partida(slot: int) -> bool:
	Config.abrir_slot(slot)
	if Save.existe():
		Save.carregar()
	else:
		Save.recomecar()
	_creditar_offline(slot)
	Marcos.verificar()
	return _trocar("partida", PARTIDA)


## Sai da partida pelo caminho que grava. Nao existe voltar ao menu sem gravar: e um dos
## momentos em que o jogador ESPERA que o jogo tenha guardado (issue #37).
func voltar_ao_menu() -> bool:
	if _atual == "partida":
		Autosave.gravar_agora()
	return ir_para_menu()


func atual() -> String:
	return _atual


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

	_fade.visible = true
	_fade.modulate.a = 1.0
	_ate_clarear = CLARAO
	return true
