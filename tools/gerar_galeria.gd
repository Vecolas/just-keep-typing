## Gera a galeria VERSIONADA de capturas, uma por era (issue #26).
##
##   godot --path . tools/gerar_galeria.tscn
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

## ⚠️ O TAMANHO E CRAVADO AQUI, e nao vem do --resolution. Estas imagens estao no git, e o
## diff delas so vale se duas geracoes do mesmo commit derem o mesmo arquivo -- galeria que
## muda de tamanho conforme quem rodou acusaria uma mudanca de arte que nunca houve.
##
## A primeira tentativa de conserto leu get_window().size, que o Config ja tinha reduzido
## para 1280x720 durante os autoloads. Ler o tamanho da janela e perguntar ao Config; o
## numero tem que ser dito.
const TAMANHO := Vector2i(1920, 1080)
const FRAMES_ATE_ESTABILIZAR := 40

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  a galeria precisa de janela; rode sem --headless")
		get_tree().quit(1)
		return

	Save.caminho = "user://galeria_save.json"
	Save.apagar()

	# a galeria nao usa as opcoes de quem desenvolve, e nem o tamanho que elas pedem
	Config.caminho = "user://galeria_opcoes.json"
	Config.modelo_de_slot = "user://galeria_save_%d.json"
	DisplayServer.window_set_size(TAMANHO)
	get_window().content_scale_size = TAMANHO
	var empacotada := load(ProjectSettings.get_setting("application/run/main_scene", "")) as PackedScene
	var raiz := empacotada.instantiate()
	add_child(raiz)
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(PASTA)

	# ⚠️ O main.tscn ABRE NO MENU desde a issue #38, e as duas telas do caminho entram na
	# galeria ANTES de a partida abrir -- e o unico momento em que elas estao no ar.
	#
	# Elas sao feias de proposito (issue #38 e a Fase 2 do plano: fluxo solido com interface
	# temporaria), e e exatamente por isso que valem uma imagem versionada: quando a arte
	# chegar na issue #46, o diff destes dois arquivos vai mostrar o antes e o depois.
	if not await _fotografar("menu_rascunho"):
		return
	Cenas.ir_para_arquivos()
	if not await _fotografar("arquivos_rascunho"):
		return

	Cenas.comecar_partida(1)
	await get_tree().process_frame

	var eras := raiz.find_child("Eras", true, false)
	if eras == null:
		printerr("FALHA  a cena principal nao tem o no Eras")
		get_tree().quit(1)
		return

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


## Espera assentar e salva. Devolve se deu certo -- a galeria para no primeiro erro em vez
## de terminar com um arquivo faltando e mesmo assim dizer que gerou.
func _fotografar(nome_do_arquivo: String) -> bool:
	for i in FRAMES_ATE_ESTABILIZAR:
		await get_tree().process_frame
	var destino := PASTA.path_join(nome_do_arquivo + ".png")
	if get_viewport().get_texture().get_image().save_png(destino) != OK:
		printerr("FALHA  nao salvou %s" % destino)
		get_tree().quit(1)
		return false
	print("%-30s %s" % [nome_do_arquivo, destino])
	return true


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
