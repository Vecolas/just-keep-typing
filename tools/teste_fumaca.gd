## Teste de fumaca: responde "a run inteira funciona?", nao "a conta esta certa?".
##
##   godot --headless --path . tools/teste_fumaca.tscn
##
## Sobe a cena principal de verdade e joga os primeiros trinta segundos do GDD §3: o
## macaco que nao digita sozinho, os cliques ate juntar o Instinto Digitador, a compra, e
## a producao automatica comecando. E o unico teste que prova a LIGACAO entre as pecas --
## a suite unitaria provaria as mesmas contas com a cena inteira desligada.
##
## O clique entra por Input.parse_input_event e nao chamando Economia.digitar direto, de
## proposito: assim ele passa pelo _unhandled_input da Partida, que e justamente o pedaco
## que nenhuma suite unitaria alcanca.
##
## Cresce a cada sistema (loja, marcos, save, prestigio). Escrever as etapas antes dos
## sistemas seria cerimonia.
extends Node

const FRAMES := 120
const CLIQUES := 12
const UPGRADE_INICIAL := "instinto_digitador"

func _ready() -> void:
	var caminho: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if caminho.is_empty():
		_falhar("nenhuma cena principal configurada em application/run/main_scene")
		return

	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		_falhar("cena principal %s nao carregou" % caminho)
		return

	var raiz := empacotada.instantiate()
	if raiz == null:
		_falhar("cena principal %s nao instanciou" % caminho)
		return

	add_child(raiz)
	await get_tree().process_frame

	# 1. o macaco ainda nao sabe digitar sozinho (GDD §3)
	if not Jogo.caracteres_por_segundo.e_zero():
		_falhar("a producao automatica ja estava ligada antes do Instinto Digitador")
		return
	if Economia.producao_automatica():
		_falhar("producao_automatica() e verdadeira sem nenhum upgrade comprado")
		return

	# 2. cada clique vale +1 caractere, e a tecla vale tanto quanto o mouse -- metade por
	# cada caminho, porque sao dois ramos diferentes do _unhandled_input e um deles pode
	# quebrar sozinho
	for i in CLIQUES:
		if i % 2 == 0:
			_apertar(&"ui_accept")
		else:
			_clicar()
		await get_tree().process_frame
	if not Jogo.total_caracteres.igual_a(Grande.de_float(float(CLIQUES))):
		_falhar("%d cliques deveriam dar %d caracteres, deram %s" % [
			CLIQUES, CLIQUES, Jogo.total_caracteres.para_texto(),
		])
		return

	# 3. a compra que vira o jogo do avesso
	var custo := Economia.upgrade_de(UPGRADE_INICIAL)
	if custo == null:
		_falhar("o upgrade %s nao esta em data/upgrades/" % UPGRADE_INICIAL)
		return
	if not Economia.comprar_upgrade(UPGRADE_INICIAL):
		_falhar("nao deu para comprar %s com %s de saldo" % [
			UPGRADE_INICIAL, Jogo.dinheiro.para_texto(),
		])
		return
	if not Jogo.dinheiro.igual_a(Grande.de_float(float(CLIQUES) - custo.custo)):
		_falhar("o troco saiu errado: %s" % Jogo.dinheiro.para_texto())
		return

	# 4. a partir daqui o jogo produz sozinho -- e o que a issue #6 pede para provar
	var antes := Jogo.total_caracteres
	for i in FRAMES:
		await get_tree().process_frame

	if not is_instance_valid(raiz):
		_falhar("cena principal morreu antes de %d frames" % FRAMES)
		return
	if Jogo.caracteres_por_segundo.sinal() <= 0:
		_falhar("o cps continuou zero depois do Instinto Digitador")
		return
	if not Jogo.total_caracteres.maior_que(antes):
		_falhar("o total nao cresceu em %d frames de producao automatica" % FRAMES)
		return

	print("PASSOU (%d cliques, %s comprado, cps %s)" % [
		CLIQUES, UPGRADE_INICIAL, Jogo.caracteres_por_segundo.para_texto(),
	])
	get_tree().quit(0)


func _apertar(acao: StringName) -> void:
	var apertar := InputEventAction.new()
	apertar.action = acao
	apertar.pressed = true
	Input.parse_input_event(apertar)

	var soltar := InputEventAction.new()
	soltar.action = acao
	soltar.pressed = false
	Input.parse_input_event(soltar)


func _clicar() -> void:
	var apertar := InputEventMouseButton.new()
	apertar.button_index = MOUSE_BUTTON_LEFT
	apertar.pressed = true
	Input.parse_input_event(apertar)

	var soltar := InputEventMouseButton.new()
	soltar.button_index = MOUSE_BUTTON_LEFT
	soltar.pressed = false
	Input.parse_input_event(soltar)


func _falhar(motivo: String) -> void:
	printerr("FALHA  %s" % motivo)
	print("FALHOU")
	get_tree().quit(1)
