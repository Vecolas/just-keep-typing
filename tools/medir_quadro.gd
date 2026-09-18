## Regua: tempo de quadro com o efeito de letras ligado, em tres escalas de producao.
##
##   godot --path . tools/medir_quadro.tscn --resolution 1920x1080
##
## SEM --headless de proposito: headless nao renderiza, e medir tempo de quadro sem
## desenhar mede o nada. Ver CONVENCOES.md, "Headless nao renderiza".
##
## Regua nao aprova nem reprova -- ela MEDE. O que ela imprime e o tempo ENTRE QUADROS:
## media, p95, p99 e quantos passaram do orcamento de 16,67 ms. A decisao sobre o teto de
## rotulos e de quem le a tabela.
##
## ⚠️ ELA TIRA O TETO DE QUADROS E O VSYNC ANTES DE MEDIR. Com o limite em 60 a engine
## dorme o resto de cada quadro, e a tabela passaria a medir o relogio de parede em vez do
## custo do desenho: um sistema que dobrasse de preco nao mudaria uma linha enquanto
## coubesse no orcamento.
##
## E a regua que a issue #22 pede porque o efeito de letras e o primeiro sistema com muita
## coisa em tela. p95 e p99 e nao so media: quadro perdido nao aparece na media, e e
## justamente ele que o jogador enxerga.
extends Node

## A cena das eras, para a tabela dizer em qual era cada linha foi medida. A era mais
## pesada e a que interessa: e ela que define se o efeito cabe no orcamento (issue #26).
var _eras: Node = null

const ORCAMENTO_MS: float = 1000.0 / 60.0
## Quadros descartados antes de medir. Os primeiros carregam o custo de subir a cena, e
## media com o boot dentro nao mede quadro nenhum.
const AQUECIMENTO: int = 90
const QUADROS: int = 240

## Producao por segundo em cada escala. A primeira tem letra solta, a ultima tem numero
## grande em todo rotulo -- e o que testa os tres regimes do GDD §26.
const ESCALAS: Array[float] = [5.0, 5e5, 5e17]


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  medir_quadro precisa de janela; rode sem --headless")
		get_tree().quit(1)
		return

	var empacotada := load(ProjectSettings.get_setting("application/run/main_scene", "")) as PackedScene

	# ⚠️ ARQUIVOS PROPRIOS, E ENTRAR NA PARTIDA. Desde a issue #38 o main.tscn abre no MENU:
	# esta regua procurava Letras e Eras na cena principal e nao achava nenhum dos dois --
	# ela parou de rodar naquele merge e ninguem percebeu, porque regua que nao roda nao
	# reprova nada. Regua que ninguem roda apodrece.
	Config.caminho = "user://medir_quadro_opcoes.json"
	Config.modelo_de_slot = "user://medir_quadro_slot_%d.json"
	Save.caminho = Config.caminho_do_slot(1)
	Save.apagar()

	# ⚠️ SEM TETO DE QUADRO E SEM VSYNC, e isto e parte da medicao (issue #42). Com o
	# limite em 60 a engine DORME o resto de cada quadro: a regua passaria a medir o
	# relogio de parede em vez do custo do desenho, e um sistema que dobrasse de preco nao
	# mudaria uma linha da tabela enquanto coubesse no orcamento. Regua mede o custo; quem
	# escolhe o teto e o jogador, na tela de opcoes.
	_sem_teto_de_quadro()

	var raiz := empacotada.instantiate()
	add_child(raiz)
	await get_tree().process_frame

	# ⚠️ O MENU PARADO E MEDIDO PRIMEIRO (issue #48), e antes de qualquer partida existir.
	# Ele e a tela que fica aberta atras de outra coisa por mais tempo do que qualquer
	# outra, e e ali que "animacao a 60 fps num menu parado" vira bateria queimada a toa.
	await _medir_o_menu(raiz)

	Cenas.comecar_partida(1)
	await get_tree().process_frame

	var letras := raiz.find_child("Letras", true, false)
	var eras := raiz.find_child("Eras", true, false)
	if letras == null or eras == null:
		printerr("FALHA  a cena principal nao tem os nos Letras e Eras")
		get_tree().quit(1)
		return
	_eras = eras

	print("medir_quadro -- orcamento de %.2f ms por quadro, %d quadros por escala" % [
		ORCAMENTO_MS, QUADROS,
	])
	print("")
	print("%-16s %-8s %-8s %-9s %-9s %-9s %s" % [
		"producao/s", "rotulos", "maquinas", "quadro", "p95", "p99", "perdidos",
	])
	print("%-16s %-8s %-8s %-9s %-9s %-9s %s" % [
		"-".repeat(16), "-".repeat(8), "-".repeat(8), "-".repeat(9), "-".repeat(9),
		"-".repeat(9), "-".repeat(8),
	])

	for escala in ESCALAS:
		await _medir(letras, escala)
	await _medir(letras, ESCALAS[ESCALAS.size() - 1], true)
	# a era 14 nao e alcancada acumulando: 10^1000 nao cai em 240 quadros (issue #30).
	await _medir(letras, ESCALAS[ESCALAS.size() - 1], false, "1e1000")

	# ⚠️ E O AUDIO, ANTES E DEPOIS, NA MESMA ERA (issue #42). Som que aloca por evento
	# aparece aqui; som que reaproveita uma piscina fixa nao. As duas linhas abaixo medem a
	# MESMA producao com o CLACK desligado e ligado -- comparar contra a linha de outra
	# escala compararia duas coisas diferentes e nao mediria o audio.
	print("")
	print("audio na mesma era (%s por segundo):" % Formatador.formatar(
		Grande.de_float(ESCALAS[ESCALAS.size() - 1])
	))
	# ⚠️ DUAS VOLTAS, ALTERNANDO. A primeira medicao depois de uma troca carrega o que a
	# linha anterior deixou -- foi assim que a primeira versao desta comparacao imprimiu o
	# som DESLIGADO custando mais caro que o LIGADO. Medir nas duas ordens deixa o ruido
	# visivel na propria tabela, em vez de escondido numa linha so.
	for volta in 2:
		await _medir_som(letras, "desligado", volta + 1)
		await _medir_som(letras, "normal", volta + 1)
	get_tree().quit(0)


## O menu, com o menu vivo ligado e desligado. As duas linhas medem a MESMA tela: a
## diferenca entre elas e o preco dos gestos, da poeira e das estrelas piscando.
func _medir_o_menu(raiz: Node) -> void:
	# o Boot pode ter pulado a abertura ou nao; o que se mede e o menu, entao vai-se a ele
	Config._opcoes["ja_viu_abertura"] = true
	Cenas.ir_para_menu()
	await get_tree().process_frame

	print("")
	print("menu parado:")
	var movimento_antes := Config.indice_de("reduzir_movimento")
	for ligado in [1, 0]:
		Config.escolher("reduzir_movimento", ligado)
		await get_tree().process_frame
		await _medir_tela("MENU %s" % ("PARADO" if ligado == 1 else "VIVO"))
	Config.escolher("reduzir_movimento", movimento_antes)
	print("")


## Mede a tela que estiver montada agora, sem mexer em producao nenhuma. Serve para o menu,
## onde nao ha Letras nem Eras para contar.
func _medir_tela(rotulo: String) -> void:
	for i in AQUECIMENTO:
		await get_tree().process_frame

	var amostras: PackedFloat64Array = PackedFloat64Array()
	var anterior := Time.get_ticks_usec()
	for i in QUADROS:
		await get_tree().process_frame
		var agora := Time.get_ticks_usec()
		amostras.append(float(agora - anterior) / 1000.0)
		anterior = agora

	var ordenadas := amostras.duplicate()
	ordenadas.sort()
	var soma := 0.0
	var perdidos := 0
	for valor in amostras:
		soma += valor
		if valor > ORCAMENTO_MS:
			perdidos += 1
	print("%-16s %-8s %-8s %-9s %-9s %-9s %d de %d" % [
		rotulo, "-", "-",
		"%.3f ms" % (soma / float(amostras.size())),
		"%.3f ms" % ordenadas[int(float(ordenadas.size()) * 0.95)],
		"%.3f ms" % ordenadas[mini(int(float(ordenadas.size()) * 0.99), ordenadas.size() - 1)],
		perdidos, QUADROS,
	])


## Tira o teto de quadros e o vsync desta medicao, pelos dois caminhos que os controlam.
func _sem_teto_de_quadro() -> void:
	var fps: Array = Config.campo("limite_de_fps")["valores"]
	Config.escolher("limite_de_fps", maxi(fps.find(0), 0))
	var vsync: Array = Config.campo("vsync")["valores"]
	Config.escolher("vsync", maxi(vsync.find(DisplayServer.VSYNC_DISABLED), 0))
	# e o modo economico tambem: a janela da regua pode perder o foco durante a corrida, e
	# ai metade da tabela sairia medida a dez quadros por segundo
	var economico: Array = Config.campo("modo_economico")["valores"]
	Config.escolher("modo_economico", maxi(economico.find(false), 0))


## Uma medicao com o som de digitacao num timbre dado. O timbre entra pelo Config, que e o
## caminho de verdade: cravar o campo por baixo mediria um jogo que nao existe.
func _medir_som(letras: Node, timbre: String, volta: int) -> void:
	var valores: Array = Config.campo("som_de_digitacao")["valores"]
	Config.escolher("som_de_digitacao", maxi(valores.find(timbre), 0))
	await _medir(
		letras, ESCALAS[ESCALAS.size() - 1], false, "",
		"SOM %s %d" % [timbre.to_upper(), volta],
	)


func _medir(
	letras: Node, producao: float, saturar: bool = false, era_forcada: String = "",
	rotulo: String = ""
) -> void:
	# monta a producao pelo caminho de verdade, e nao escrevendo o cps na mao: a Partida
	# recalcula caracteres_por_segundo todo quadro, e um valor cravado seria apagado antes
	# de as letras lerem -- foi assim que a primeira medicao saiu com zero rotulos
	# a escala entra pelo multiplicador global e nao pela contagem de macacos: macaco
	# alem da capacidade da sala e cortado pelo multiplicador de sala, e a primeira versao
	# desta regua mediu as tres escalas rodando todas a 10 caracteres por segundo sem
	# ninguem perceber. Dez macacos cabem na Sala Pequena, e ai o multiplicador de sala
	# vale 1.
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.descobertas = [] as Array[String]
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.macacos = Grande.de_float(10.0)
	Jogo.multiplicador_global = producao / (10.0 * maxf(Economia.producao_por_macaco(), 1.0))
	# CADA LINHA COMECA DO ZERO. Sem isto a medicao herda o que a anterior deixou: os
	# rotulos ainda vivos morrendo dentro da amostra, e o total de caracteres que ja tinha
	# levado a cena para outra era. As duas coisas ja fizeram esta regua mentir -- a era 14
	# reportou 23 ms que eram da linha anterior, e as linhas depois dela mediram a era 14
	# achando que mediam a propria.
	letras.call("limpar")
	Jogo.total_caracteres = (
		Grande.de_texto(era_forcada) if not era_forcada.is_empty() else Grande.zero()
	)
	for i in AQUECIMENTO:
		if not era_forcada.is_empty():
			Jogo.total_caracteres = Grande.de_texto(era_forcada)
		await get_tree().process_frame

	# ⚠️ O RELOGIO E O INSTRUMENTO, e nao o monitor de desempenho. Performance.TIME_PROCESS
	# nao muda a cada quadro: com a engine solta, 240 amostras seguidas saiam IDENTICAS, e
	# media, p95 e p99 imprimiam o mesmo numero -- a regua estava medindo o periodo de
	# atualizacao do proprio monitor. O tempo entre dois quadros e o que o jogador sente, e
	# e o que o orcamento de 16,67 ms quer dizer.
	#
	# ⚠️ E O MONITOR NAO VOLTA NEM COMO COLUNA DE APOIO. Medido: com o quadro em 1,7 ms ele
	# imprimia 57 ms na mesma linha. Numero que nao pode ser verdade ao lado de um que
	# pode e pior que numero nenhum -- alguem vai ler os dois.
	var amostras: PackedFloat64Array = PackedFloat64Array()
	var anterior := Time.get_ticks_usec()
	for i in QUADROS:
		await get_tree().process_frame
		if not era_forcada.is_empty():
			Jogo.total_caracteres = Grande.de_texto(era_forcada)
		if saturar:
			# enche a piscina a cada quadro: e o unico jeito de o teto ser medido em vez
			# de suposto, ja que o regime permanente do jogo nem chega perto dele
			for j in 8:
				letras.call("nascer", Jogo.caracteres_por_segundo)
		var agora := Time.get_ticks_usec()
		amostras.append(float(agora - anterior) / 1000.0)
		anterior = agora

	var ordenadas := amostras.duplicate()
	ordenadas.sort()
	var soma := 0.0
	var perdidos := 0
	for valor in amostras:
		soma += valor
		if valor > ORCAMENTO_MS:
			perdidos += 1
	print("%-16s %-8d %-8d %-9s %-9s %-9s %d de %d" % [
		(rotulo if not rotulo.is_empty()
			else ("SATURADO" if saturar else ("ERA 14" if not era_forcada.is_empty()
			else Formatador.formatar(Grande.de_float(producao))))),
		letras.call("vivos"),
		_eras.call("visiveis"),
		"%.3f ms" % (soma / float(amostras.size())),
		"%.3f ms" % ordenadas[int(float(ordenadas.size()) * 0.95)],
		"%.3f ms" % ordenadas[mini(int(float(ordenadas.size()) * 0.99), ordenadas.size() - 1)],
		perdidos, QUADROS,
	])
