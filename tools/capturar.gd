## Captura um quadro parado da cena principal, para olhar leitura visual.
##
##   godot --path . tools/capturar.tscn --resolution 1920x1080
##
## SEM --headless de proposito: headless nao renderiza (DisplayServer.get_name()
## devolve "headless"), entao a imagem sairia vazia. Sai em user://capturas, que existe
## para olhar e nao para versionar -- o que e versionado e a galeria (tools/gerar_galeria),
## que entra quando houver tela suficiente para valer um diff de imagem.
extends Node

const PASTA := "user://capturas"
const FRAMES_ATE_ESTABILIZAR := 10

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  captura precisa de janela; rode sem --headless")
		get_tree().quit(1)
		return

	# a captura nunca encosta no save de quem joga, e parte sempre de partida nova: assim
	# duas capturas do mesmo commit dao a mesma imagem, que e o que faz o diff valer
	Save.caminho = "user://capturas/save_da_captura.json"
	Save.apagar()

	var caminho: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		printerr("FALHA  cena principal %s nao carregou" % caminho)
		get_tree().quit(1)
		return

	add_child(empacotada.instantiate())
	for i in FRAMES_ATE_ESTABILIZAR:
		await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(PASTA)
	var imagem := get_viewport().get_texture().get_image()
	var destino := PASTA.path_join("principal.png")
	var erro := imagem.save_png(destino)
	if erro != OK:
		printerr("FALHA  nao salvou %s (erro %d)" % [destino, erro])
		get_tree().quit(1)
		return

	print("capturou %s (%dx%d)" % [
		ProjectSettings.globalize_path(destino), imagem.get_width(), imagem.get_height(),
	])
	get_tree().quit(0)
