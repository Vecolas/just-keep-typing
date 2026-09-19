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

## ⚠️ A SEMENTE DO SORTEIO DE DESCOBERTAS, FIXADA AQUI. A galeria esta no git para o DIFF
## mostrar o que mudou na tela: com o sorteio solto, duas geracoes do mesmo commit dao
## descobertas diferentes, e o diff acusa uma mudanca de arte que nunca houve.
##
## O numero e o mesmo do runner e das reguas: semente diferente por ferramenta daria imagens
## que nao se comparam entre si.
const SEMENTE_DO_SORTEIO: int = 1

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  a galeria precisa de janela; rode sem --headless")
		get_tree().quit(1)
		return

	Descobertas.gerador.seed = SEMENTE_DO_SORTEIO
	Save.caminho = "user://galeria_save.json"
	Save.apagar()

	# a galeria nao usa as opcoes de quem desenvolve, e nem o tamanho que elas pedem
	Config.caminho = "user://galeria_opcoes.json"
	Config.modelo_de_slot = "user://galeria_save_%d.json"
	# ⚠️ OS SLOTS SAO APAGADOS ANTES. comecar_partida(1) CARREGA o slot 1, e um slot deixado por
	# uma geracao anterior traz o dinheiro, as descobertas e os marcos de outra partida para
	# dentro da foto: a captura da era 1 saiu com 334 mil no saldo, sete descobertas e o
	# proximo marco em 10^3000. A galeria esta no git para o diff mostrar o que mudou na TELA,
	# e nao o que sobrou no disco de quem rodou.
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))
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
	# Elas entraram como `menu_rascunho` e `arquivos_rascunho` na issue #38, quando eram
	# feias de proposito. A issue #46 trouxe a mesa, e os arquivos mudaram de nome junto: o
	# "rascunho" era a descricao de um estado, e o estado passou. O antes continua no git.
	if not await _fotografar("menu"):
		return
	Cenas.ir_para_arquivos()
	if not await _fotografar("arquivos"):
		return

	Cenas.comecar_partida(1)
	await get_tree().process_frame

	# ⚠️ O BANNER ENTRA NA GALERIA VERSIONADA porque ele e a unica peca desta interface que
	# so existe por alguns SEGUNDOS: ele nao aparece em nenhuma captura de era, e sem uma foto
	# propria nenhum diff mostraria que ele parou de caber, de contrastar ou de quebrar linha
	# na hora em que alguem mexesse num texto de descoberta.
	#
	# ⚠️ E O ACONTECIMENTO ENTRA PELO BARRAMENTO, e nao preenchendo o banner na mao: o que a
	# foto prova e o CAMINHO inteiro -- Avisos classifica, escolhe a faixa e a duracao, e a HUD
	# desenha. Um banner preenchido na mao provaria so o desenho.
	Jogo.total_caracteres = Grande.de_float(500000.0)
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	var rara := _a_mais_rara()
	if rara == null:
		printerr("FALHA  nao ha descoberta no catalogo para fotografar o banner")
		get_tree().quit(1)
		return
	# a fila comeca limpa: sem isto a foto sairia com a primeira descoberta que o sorteio deu
	Avisos.limpar()
	EventBus.descoberta_encontrada.emit(rara)
	if not await _fotografar("banner_de_descoberta"):
		return

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

		# ⚠️ A FOTO DA ERA E SOBRE A ERA. O total escrito acima faz a producao correr de
		# verdade, e producao sorteia descoberta: sem isto, catorze fotos saem com um banner
		# por cima do cenario -- e cada regeracao com um banner diferente. O banner tem a foto
		# PROPRIA, logo acima, que e onde ele deve ser conferido.
		Avisos.limpar()
		for i in 2:
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


## A descoberta mais RARA do catalogo.
##
## ⚠️ ESCOLHIDA PELA CATEGORIA, e nao por um id cravado aqui. Id na ferramenta e uma segunda
## fonte: no dia em que aquela descoberta for renomeada ou sair do catalogo, a galeria deixaria
## de fotografar o banner em silencio -- e o arquivo antigo continuaria no git, parecendo atual.
## A mais rara e escolhida porque e o caso EXTREMO da caixa: o texto mais longo, a cor mais
## saturada e a duracao maior.
func _a_mais_rara() -> DadosDescoberta:
	var rara: DadosDescoberta = null
	for descoberta in Descobertas.todas():
		if rara == null or descoberta.categoria > rara.categoria:
			rara = descoberta
	return rara


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
