## Captura um quadro parado da cena principal, para olhar leitura visual.
##
##   godot --path . tools/capturar.tscn --resolution 1920x1080
##   godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=panorama
##
## SEM --headless de proposito: headless nao renderiza (DisplayServer.get_name()
## devolve "headless"), entao a imagem sairia vazia. Sai em user://capturas, que existe
## para olhar e nao para versionar -- o que e versionado e a galeria (tools/gerar_galeria),
## que entra quando houver tela suficiente para valer um diff de imagem.
extends Node

const PASTA := "user://capturas"
const FRAMES_ATE_ESTABILIZAR := 10

## Um cenario e um estado de jogo montado na mao para a foto sair util. Sem isso a unica
## imagem possivel e a partida vazia -- e o Panorama vazio nao mostra nem alcancado, nem
## atual, nem silhueta, que sao exatamente as tres coisas que ele precisa provar.
##
## Cada cenario vira um arquivo com o nome dele, para a galeria versionada (CONVENCOES.md)
## poder dar diff de um por vez.
const CENARIO_PADRAO := "principal"

## Lido de "-- cenario=<nome>" na linha de comando. Argumento depois de -- e o jeito do
## Godot passar coisa para o jogo sem a engine tentar interpretar.
func _cenario() -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("cenario="):
			return argumento.trim_prefix("cenario=")
	return CENARIO_PADRAO


## Argumento numerico da linha de comando, no mesmo formato do cenario.
func _argumento(chave: String, padrao: float) -> float:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with(chave + "="):
			return argumento.trim_prefix(chave + "=").to_float()
	return padrao


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

	var cenario := _cenario()
	if cenario.begins_with("letras"):
		# a producao entra pelo caminho de verdade: a Partida recalcula o cps todo quadro
		# e um valor cravado seria apagado antes de as letras lerem
		var alvo := _argumento("producao", 5.0)
		Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
		# dez macacos cabem na Sala Pequena; a escala entra pelo multiplicador global.
		# Macaco alem da capacidade e cortado pelo multiplicador de sala, e a primeira
		# versao desta captura saiu com 10/s nas tres escalas por causa disso.
		Jogo.macacos = Grande.de_float(10.0)
		Jogo.multiplicador_global = alvo / (10.0 * maxf(Economia.producao_por_macaco(), 1.0))
		# quadros suficientes para a piscina chegar no regime permanente
		for i in FRAMES_ATE_ESTABILIZAR * 8:
			await get_tree().process_frame
	elif cenario == "estatisticas":
		Descobertas.gerador.seed = 1
		Economia.digitar(500000)
		Economia.comprar_macacos(Economia.macacos_que_cabem())
		Marcos.verificar()
		Economia.acumular(1.0)
		EventBus.estatisticas_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "descobertas":
		# uma achada e o resto em silhueta: e a leitura inteira da tela numa foto so
		Descobertas.gerador.seed = 1
		Economia.digitar(20000)
		EventBus.descobertas_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "panorama":
		# caracteres suficientes para cruzar os dois primeiros marcos e deixar o terceiro
		# em silhueta -- e a leitura inteira da tela numa foto so
		Economia.digitar(2000)
		Marcos.verificar()
		EventBus.panorama_pedido.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(PASTA)
	var imagem := get_viewport().get_texture().get_image()
	var destino := PASTA.path_join(cenario + ".png")
	var erro := imagem.save_png(destino)
	if erro != OK:
		printerr("FALHA  nao salvou %s (erro %d)" % [destino, erro])
		get_tree().quit(1)
		return

	print("capturou %s (%dx%d)" % [
		ProjectSettings.globalize_path(destino), imagem.get_width(), imagem.get_height(),
	])
	get_tree().quit(0)
