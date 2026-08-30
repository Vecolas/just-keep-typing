## Gera a galeria VERSIONADA de capturas, uma por era (issue #26).
##
##   godot --path . tools/gerar_galeria.tscn --resolution 1920x1080
##
## SEM --headless: headless nao renderiza. Ver CONVENCOES.md.
##
## Sai em docs/capturas/ e as imagens SAO versionadas, ao contrario do capturar.tscn que
## sai em user://. O motivo esta na CONVENCOES.md: como as imagens estao no git, o diff
## mostra exatamente o que mudou na tela -- e o jeito mais barato de perceber que um
## ajuste de escala estragou a leitura de uma era que ninguem estava olhando.
##
## Cada era e montada com a producao do requisito dela, e nao esperando o jogo chegar la.
extends Node

const PASTA := "res://docs/capturas"
const FRAMES_ATE_ESTABILIZAR := 40

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  a galeria precisa de janela; rode sem --headless")
		get_tree().quit(1)
		return

	Save.caminho = "user://galeria_save.json"
	Save.apagar()
	var empacotada := load(ProjectSettings.get_setting("application/run/main_scene", "")) as PackedScene
	var raiz := empacotada.instantiate()
	add_child(raiz)
	await get_tree().process_frame

	var eras := raiz.find_child("Eras", true, false)
	if eras == null:
		printerr("FALHA  a cena principal nao tem o no Eras")
		get_tree().quit(1)
		return

	DirAccess.make_dir_recursive_absolute(PASTA)
	var quantas := 0
	for era in _eras_ordenadas():
		# entra na era pelo caminho de verdade -- escrevendo o total, que e o que a cena le
		Jogo.total_caracteres = era.requisito_grande().vezes(Grande.de_float(1.5))
		Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
		Jogo.macacos = Grande.de_float(10.0)
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame

		var imagem := get_viewport().get_texture().get_image()
		var destino := PASTA.path_join("era_%d_%s.png" % [era.numero, era.id])
		if imagem.save_png(destino) != OK:
			printerr("FALHA  nao salvou %s" % destino)
			get_tree().quit(1)
			return
		print("era %d  %-24s %s" % [era.numero, era.id, destino])
		quantas += 1

	print("galeria com %d eras em %s" % [quantas, ProjectSettings.globalize_path(PASTA)])
	get_tree().quit(0)


func _eras_ordenadas() -> Array[DadosEra]:
	var eras: Array[DadosEra] = []
	var dir := DirAccess.open("res://data/eras")
	if dir == null:
		return eras
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			var era := ResourceLoader.load("res://data/eras".path_join(item)) as DadosEra
			if era != null:
				eras.append(era)
		item = dir.get_next()
	dir.list_dir_end()
	eras.sort_custom(func(a: DadosEra, b: DadosEra) -> bool: return a.numero < b.numero)
	return eras
