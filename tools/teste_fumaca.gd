## Teste de fumaca: responde "a run inteira funciona?", nao "a conta esta certa?".
##
##   godot --headless --path . tools/teste_fumaca.tscn
##
## Sobe a cena principal de verdade e deixa rodar. Hoje prova pouco -- a cena principal
## e um Node2D vazio -- e isso e proposital: o teste nasce junto do projeto e cresce com
## ele, ganhando etapa a cada sistema (gerar andar, spawnar inimigo, limpar sala, chegar
## no chefe). Escrever as etapas antes dos sistemas seria cerimonia.
extends Node

const FRAMES := 120

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
	for i in FRAMES:
		await get_tree().process_frame

	if not is_instance_valid(raiz):
		_falhar("cena principal morreu antes de %d frames" % FRAMES)
		return

	print("PASSOU (%s sobreviveu a %d frames)" % [caminho, FRAMES])
	get_tree().quit(0)


func _falhar(motivo: String) -> void:
	printerr("FALHA  %s" % motivo)
	print("FALHOU")
	get_tree().quit(1)
