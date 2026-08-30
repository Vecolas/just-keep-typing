## Captura um quadro parado da cena principal, para olhar leitura visual.
##
##   godot --path . tools/capturar.tscn
##   godot --path . tools/capturar.tscn -- cenario=panorama
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
## ⚠️ O TAMANHO SAI DAQUI, e nao do --resolution. O Config aplica a resolucao guardada
## durante os autoloads, que rodam DEPOIS do que a linha de comando pediu -- e a tentativa
## de ler o --resolution de volta em OS.get_cmdline_args() saiu vazia. Numero que a
## ferramenta precisa e numero que a ferramenta diz.
##
## "largura=" e "altura=" depois do -- mudam isto quando fizer falta.
const TAMANHO := Vector2i(1920, 1080)


func _cenario() -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("cenario="):
			return argumento.trim_prefix("cenario=")
	return CENARIO_PADRAO


## Argumento numerico da linha de comando, no mesmo formato do cenario.
func _texto_do_argumento(chave: String, padrao: String) -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with(chave + "="):
			return argumento.trim_prefix(chave + "=")
	return padrao


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

	# ⚠️ E NEM NAS OPCOES DELE. O Config aplica a resolucao guardada durante os autoloads,
	# que rodam DEPOIS do --resolution da linha de comando -- a primeira captura desta
	# ferramenta com o Config no jogo saiu em 1280x720 pedindo 1920x1080. Aqui a linha de
	# comando volta a mandar, que e o unico jeito de a galeria versionada ter sempre o
	# mesmo tamanho.
	Config.caminho = "user://capturas/opcoes_da_captura.json"
	Config.modelo_de_slot = "user://capturas/save_da_captura_%d.json"
	var pedida := Vector2i(
		int(_argumento("largura", TAMANHO.x)), int(_argumento("altura", TAMANHO.y))
	)
	DisplayServer.window_set_size(pedida)
	get_window().content_scale_size = pedida

	var caminho: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		printerr("FALHA  cena principal %s nao carregou" % caminho)
		get_tree().quit(1)
		return

	add_child(empacotada.instantiate())
	for i in FRAMES_ATE_ESTABILIZAR:
		await get_tree().process_frame

	# ⚠️ O main.tscn ABRE NO MENU desde a issue #38. Os cenarios de menu param aqui; todos
	# os outros sao fotos de dentro da partida, e sem entrar nela sairiam com o menu na
	# frente -- inclusive os catorze da galeria.
	var cenario := _cenario()
	if cenario == "arquivos":
		Cenas.ir_para_arquivos()
	elif cenario != "menu":
		Cenas.comecar_partida(1)
	for i in FRAMES_ATE_ESTABILIZAR:
		await get_tree().process_frame

	# a captura em outra lingua e o unico jeito de ver texto estourando botao: caractere
	# nao e pixel, e "Comprar Maximo" e "Buy Max" nao ocupam a mesma largura
	var idioma := _texto_do_argumento("idioma", "")
	if not idioma.is_empty():
		TranslationServer.set_locale(idioma)

	if cenario == "eventos":
		Economia.digitar(50000)
		Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
		Jogo.macacos = Grande.de_float(10.0)
		# um de cada lado: a punicao com botao de saida, e a troca sem botao
		Eventos.comecar("banana_na_maquina")
		Eventos.comecar("tecla_presa")
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "teoremas":
		Economia.digitar(1000000000000)
		Jogo.pontos_de_teorema = Grande.de_float(30.0)
		Jogo.pontos_totais = Grande.de_float(30.0)
		Teoremas.comprar("memoria_genetica")
		Teoremas.comprar("producao_offline")
		EventBus.teoremas_pedidos.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "reescrever":
		# a mesma tela dos Teoremas, mas no ponto em que o segundo prestigio ja abriu:
		# a Arvore com nos comprados EM CIMA do bloco que propoe apaga-la (issue #31)
		Economia.digitar(1000000000000)
		Jogo.pontos_de_teorema = Grande.de_float(50000.0)
		Jogo.pontos_totais = Grande.de_float(50000.0)
		Teoremas.comprar("memoria_genetica")
		Teoremas.comprar("producao_offline")
		Jogo.reescritas = 2
		Jogo.fragmentos = Grande.de_float(2.0)
		EventBus.teoremas_pedidos.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario.begins_with("letras"):
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
	elif cenario == "opcoes":
		# a captura que a issue #34 pede: em ingles, para conferir que nenhum rotulo estoura
		# o botao. "Fullscreen" e "Save slot" sao mais longos que os originais.
		Economia.digitar(20000)
		EventBus.opcoes_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "fim":
		# o fecho do jogo (issue #33): O Macaco Infinito em destaque e, abaixo dele, NADA.
		# A foto existe justamente para mostrar o que nao esta la -- se um dia aparecer uma
		# silhueta "? ? ?" no rodape, e nesta captura que se ve.
		Jogo.total_caracteres = Marcos.todos()[-1].requisito_grande()
		Marcos.verificar()
		EventBus.panorama_pedido.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
		var fundo: ScrollContainer = null
		for candidata in get_tree().root.find_children("Rolagem", "ScrollContainer", true, false):
			if candidata.is_visible_in_tree():
				fundo = candidata
		if fundo != null:
			fundo.scroll_vertical = int(fundo.get_v_scroll_bar().max_value)
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "lendarias":
		# as seis do GDD §11 abertas, para a revisao de texto das DUAS colunas do CSV
		# (issue #32): a piada e o produto aqui, e traduzir e onde ela mais se perde
		Economia.digitar(20000)
		for id in [
			"hamlet", "romance_inedito", "minha_biografia",
			"o_jogo", "essa_mensagem", "o_proximo_texto",
		]:
			if not Jogo.descobertas.has(id):
				Jogo.descobertas.append(id)
		EventBus.descobertas_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
		# as raras ficam no fim de uma lista de dezesseis: sem rolar ate o fundo a foto
		# mostra as comuns, que nao sao o que esta em revisao.
		#
		# ⚠️ Quatro telas tem um no chamado "Rolagem", e find_child a partir da raiz achava
		# a primeira -- que estava escondida. Tem que ser a rolagem VISIVEL.
		var rolagem: ScrollContainer = null
		for candidata in get_tree().root.find_children("Rolagem", "ScrollContainer", true, false):
			if candidata.is_visible_in_tree():
				rolagem = candidata
		if rolagem != null:
			rolagem.scroll_vertical = int(rolagem.get_v_scroll_bar().max_value)
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
	var destino := PASTA.path_join(cenario + ("_" + idioma if not idioma.is_empty() else "") + ".png")
	var erro := imagem.save_png(destino)
	if erro != OK:
		printerr("FALHA  nao salvou %s (erro %d)" % [destino, erro])
		get_tree().quit(1)
		return

	print("capturou %s (%dx%d)" % [
		ProjectSettings.globalize_path(destino), imagem.get_width(), imagem.get_height(),
	])
	get_tree().quit(0)
