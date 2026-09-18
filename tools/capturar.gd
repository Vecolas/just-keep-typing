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


## Poe um campo de lista no valor pedido pela linha de comando. Zero significa "nao
## pedido" -- nenhuma escala vale zero, entao ele serve de sentinela sem ambiguidade.
func _ajustar(campo: String, valor: float) -> void:
	if valor <= 0.0:
		return
	var valores: Array = Config.campo(campo)["valores"]
	var indice := -1
	for i in valores.size():
		if is_equal_approx(float(valores[i]), valor):
			indice = i
	if indice < 0:
		printerr("FALHA  %s nao oferece %s" % [campo, valor])
		get_tree().quit(1)
		return
	Config.escolher(campo, indice)


## Poe o jogo na lingua pedida pela linha de comando. A captura em outra lingua e o unico
## jeito de ver texto estourando botao: caractere nao e pixel, e "Comprar Maximo" e
## "Buy Max" nao ocupam a mesma largura.
func _falar(codigo: String) -> void:
	for i in Config.IDIOMAS.size():
		if Config.IDIOMAS[i]["codigo"] == codigo:
			Config.escolher("idioma", i)
			return
	printerr("FALHA  idioma %s nao esta em Config.IDIOMAS" % codigo)
	get_tree().quit(1)


## Entra no Manuscrito 1, produz um tanto e volta ao menu pelo caminho que grava. Deixa o
## jogo NO MENU, que e onde a foto e tirada.
func _uma_partida_gravada() -> void:
	Cenas.comecar_partida(1)
	await get_tree().process_frame
	Jogo.nome = "Hamlet Talvez"
	Economia.digitar(180000000000000)
	Marcos.verificar()
	Jogo.tempo_jogado = 9142.0
	Cenas.voltar_ao_menu()
	await get_tree().process_frame


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
	# ⚠️ O IDIOMA ENTRA PELA PORTA DO JOGADOR, E ANTES DE A CENA SUBIR. Ele ja foi aplicado
	# aqui com TranslationServer.set_locale depois de montar, e a foto saia em portugues
	# pedindo ingles: o Godot so retraduz sozinho o text que veio da CENA, e todo rotulo
	# deste jogo e montado em codigo -- quem repinta e EventBus.idioma_mudou, que
	# set_locale nao emite. Config.escolher e o unico caminho que faz as duas coisas.
	var idioma := _texto_do_argumento("idioma", "")
	if not idioma.is_empty():
		_falar(idioma)

	# ⚠️ A CAPTURA QUE A ISSUE #43 PEDE: escala acima de 100% na MENOR resolucao da lista e
	# o caso que estoura tudo, e caractere nao e pixel -- so a foto mostra rotulo saindo do
	# botao. Entra pelo Config, que e a porta do jogador.
	_ajustar("escala_da_interface", _argumento("escala", 0.0))
	_ajustar("escala_do_texto", _argumento("escala_do_texto", 0.0))
	if _texto_do_argumento("contraste", "").begins_with("1"):
		Config.escolher("alto_contraste", 1)

	var pedida := Vector2i(
		int(_argumento("largura", TAMANHO.x)), int(_argumento("altura", TAMANHO.y))
	)
	DisplayServer.window_set_size(pedida)
	# ⚠️ A AREA LOGICA NAO ENCOLHE JUNTO COM A JANELA, e isso e o jogo e nao a ferramenta.
	# O modo de estiramento e canvas_items: a interface e SEMPRE montada em 1920x1080 e
	# depois desenhada no tamanho da janela. Cravar a area logica em 1280x720 aqui mediria
	# um layout que nenhum jogador ve -- e foi assim que a primeira captura em escala 125%
	# saiu com a loja pela metade, acusando um defeito que era da captura.
	get_window().content_scale_size = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", pedida.x)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", pedida.y)),
	)

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
	if cenario.begins_with("abertura"):
		# ⚠️ A ABERTURA E TEMPO, e a foto precisa dizer QUANDO. "instante=" em segundos
		# escolhe o quadro: 0,6 pega as primeiras letras saindo, 2,4 pega a mesa entrando.
		# Sem isso a unica foto possivel e a do quadro em que a ferramenta acordou.
		#
		# O relogio e ADIANTADO, e nao esperado: a captura empurra o _process da cena com
		# um delta escolhido, como a fumaca faz com as quatro horas de offline.
		Config._opcoes["ja_viu_abertura"] = false
		Cenas.ir_para_abertura()
		await get_tree().process_frame
		var cena := get_tree().root.find_child("Abertura", true, false)
		if cena == null:
			printerr("FALHA  a abertura nao foi montada")
			get_tree().quit(1)
			return
		cena.set_process(false)
		cena.call("adiantar", _argumento("instante", 0.6))
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario.begins_with("menu") or cenario.begins_with("arquivos"):
		# ⚠️ O MENU SO TEM O QUE MOSTRAR COM UM MANUSCRITO NO DISCO. Sem save, o CONTINUAR
		# sai apagado e o resumo embaixo dele nao existe -- e o resumo e justamente o que a
		# issue #39 pede para olhar. Entao o cenario "cheio" JOGA um pouco e volta, em vez
		# de escrever um .meta na mao: metadado inventado provaria a foto, e nao o jogo.
		if cenario.ends_with("_cheio"):
			await _uma_partida_gravada()
		if cenario.begins_with("arquivos"):
			Cenas.ir_para_arquivos()
	else:
		Cenas.comecar_partida(1)
	for i in FRAMES_ATE_ESTABILIZAR:
		await get_tree().process_frame

	# ⚠️ QUADRO NAO E TEMPO. A transicao do menu para a partida dura 0,45 s; dez quadros
	# numa maquina rapida sao 0,17 s, e a foto de `principal` saia com a maquina de
	# escrever em pleno voo por cima do botao DIGITAR. No runner do CI, mais lento, os
	# mesmos dez quadros passavam de 0,45 s e a foto saia limpa -- a MESMA ferramenta, no
	# MESMO commit, dando imagens diferentes conforme a velocidade de quem roda.
	#
	# Esperar mais quadros so moveria a fronteira. O que resolve e cortar a transicao para
	# o fim, que e o unico estado que nao depende de relogio nenhum.
	Cenas.concluir_transicao()
	await get_tree().process_frame

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
	elif cenario == "menu_estados":
		# ⚠️ OS QUATRO ESTADOS DE BOTAO NUMA CAPTURA SO (issue #46). Hover e pressionado nao
		# se forcam por fora -- o Godot os desenha a partir do mouse e do clique --, entao a
		# foto troca o estilo NORMAL de cada botao pelo estilo do estado que se quer ver. E
		# uma vitrine dos quatro desenhos, e nao uma simulacao de interacao.
		#
		# O que ela existe para provar: os quatro sao distinguiveis SEM COR. Tres degraus de
		# luminancia mais a placa afundada, que difere por FORMA.
		var menu := get_tree().root.find_child("MenuTela", true, false)
		if menu != null:
			var vitrine := {
				"BotaoJogar": Tema.placa("placa", Tema.BRILHO_NORMAL),
				"BotaoConfiguracoes": Tema.placa("placa", Tema.BRILHO_HOVER),
				"BotaoCreditos": Tema.placa(
					"placa_afundada", Tema.BRILHO_NORMAL, Tema.DESLOCAMENTO_AO_APERTAR
				),
				"BotaoSair": Tema.placa("placa", Tema.BRILHO_DESABILITADO),
			}
			for nome_do_botao in vitrine:
				var botao := menu.find_child(nome_do_botao, true, false) as Button
				if botao != null and vitrine[nome_do_botao] != null:
					botao.add_theme_stylebox_override("normal", vitrine[nome_do_botao])
					botao.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
	elif cenario == "opcoes":
		# a captura que as issues #34 e #41 pedem: em ingles, para conferir que nenhum
		# rotulo estoura o campo. "Frame rate limit" e "Power saving mode" sao bem mais
		# longos que os originais.
		#
		# ⚠️ UMA FOTO POR ABA. Fotografar so a primeira mediria um quinto da tela, e o
		# rotulo que estoura costuma estar justamente na aba que ninguem olhou.
		Economia.digitar(20000)
		EventBus.opcoes_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
		var abas := get_tree().root.find_children("Abas", "TabContainer", true, false)
		for painel in abas:
			var tabulado := painel as TabContainer
			if not tabulado.is_visible_in_tree():
				continue
			tabulado.current_tab = clampi(
				int(_argumento("aba", 0.0)), 0, maxi(tabulado.get_tab_count() - 1, 0)
			)
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
	elif cenario == "descobertas_fim":
		# ⚠️ A FOTO DO `0/?` (issue #55). Com sessenta e duas descobertas, a primeira tela
		# so mostra a primeira faixa -- e o que esta issue precisa provar mora no FIM:
		# faixas vazias e a paradoxal escondendo o proprio total. Foto que nao chega la nao
		# prova a marca registrada da tela.
		Descobertas.gerador.seed = 1
		Economia.digitar(20000)
		EventBus.descobertas_pedidas.emit()
		for i in FRAMES_ATE_ESTABILIZAR:
			await get_tree().process_frame
		var tela := get_tree().root.find_child("DescobertasTela", true, false)
		if tela == null:
			printerr("FALHA  a tela de Descobertas nao foi montada")
			get_tree().quit(1)
			return
		var rolagem := tela.find_child("Rolagem", true, false) as ScrollContainer
		if rolagem == null:
			printerr("FALHA  a rolagem das Descobertas nao foi encontrada")
			get_tree().quit(1)
			return
		# o fim de verdade, e nao um numero grande chutado: o maximo da barra muda com a
		# escala do texto e com o idioma
		rolagem.scroll_vertical = int(rolagem.get_v_scroll_bar().max_value)
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
	# a aba entra no nome do arquivo: cinco fotos com o mesmo nome seriam uma foto so
	var sufixo := ""
	if cenario == "opcoes":
		sufixo += "_aba%d" % int(_argumento("aba", 0.0))
	if _argumento("escala", 0.0) > 0.0:
		sufixo += "_escala%d" % int(_argumento("escala", 0.0) * 100.0)
	if cenario.begins_with("abertura"):
		sufixo += "_%dms" % int(_argumento("instante", 0.6) * 1000.0)
	if not idioma.is_empty():
		sufixo += "_" + idioma
	var destino := PASTA.path_join(cenario + sufixo + ".png")
	var erro := imagem.save_png(destino)
	if erro != OK:
		printerr("FALHA  nao salvou %s (erro %d)" % [destino, erro])
		get_tree().quit(1)
		return

	print("capturou %s (%dx%d)" % [
		ProjectSettings.globalize_path(destino), imagem.get_width(), imagem.get_height(),
	])
	get_tree().quit(0)
