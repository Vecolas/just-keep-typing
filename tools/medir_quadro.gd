## Regua: tempo de quadro com o efeito de letras ligado, em tres escalas de producao.
##
##   godot --path . tools/medir_quadro.tscn --resolution 1920x1080
##
## SEM --headless de proposito: headless nao renderiza, e medir tempo de quadro sem
## desenhar mede o nada. Ver CONVENCOES.md, "Headless nao renderiza".
##
## Regua nao aprova nem reprova -- ela MEDE. O que ela imprime e media, p95, p99 e quadros
## perdidos, contra o orcamento de 16,67 ms de 60 quadros por segundo. A decisao sobre o
## teto de rotulos e de quem le a tabela.
##
## E a regua que a issue #22 pede porque o efeito de letras e o primeiro sistema com muita
## coisa em tela. p95 e p99 e nao so media: quadro perdido nao aparece na media, e e
## justamente ele que o jogador enxerga.
extends Node

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
	Save.caminho = "user://medir_quadro_save.json"
	Save.apagar()
	var raiz := empacotada.instantiate()
	add_child(raiz)
	await get_tree().process_frame

	var letras := raiz.find_child("Letras", true, false)
	if letras == null:
		printerr("FALHA  a cena principal nao tem o no Letras")
		get_tree().quit(1)
		return

	print("medir_quadro -- orcamento de %.2f ms por quadro, %d quadros por escala" % [
		ORCAMENTO_MS, QUADROS,
	])
	print("")
	print("%-16s %-8s %-9s %-9s %-9s %s" % [
		"producao/s", "rotulos", "media", "p95", "p99", "perdidos",
	])
	print("%-16s %-8s %-9s %-9s %-9s %s" % [
		"-".repeat(16), "-".repeat(8), "-".repeat(9), "-".repeat(9), "-".repeat(9), "-".repeat(8),
	])

	for escala in ESCALAS:
		await _medir(letras, escala)
	await _medir(letras, ESCALAS[ESCALAS.size() - 1], true)
	get_tree().quit(0)


func _medir(letras: Node, producao: float, saturar: bool = false) -> void:
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
	for i in AQUECIMENTO:
		await get_tree().process_frame

	var amostras: PackedFloat64Array = PackedFloat64Array()
	for i in QUADROS:
		await get_tree().process_frame
		if saturar:
			# enche a piscina a cada quadro: e o unico jeito de o teto ser medido em vez
			# de suposto, ja que o regime permanente do jogo nem chega perto dele
			for j in 8:
				letras.call("nascer", Jogo.caracteres_por_segundo)
		amostras.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)

	var ordenadas := amostras.duplicate()
	ordenadas.sort()
	var soma := 0.0
	var perdidos := 0
	for valor in amostras:
		soma += valor
		if valor > ORCAMENTO_MS:
			perdidos += 1

	print("%-16s %-8d %-9s %-9s %-9s %d de %d" % [
		("SATURADO" if saturar else Formatador.formatar(Grande.de_float(producao))),
		letras.call("vivos"),
		"%.3f ms" % (soma / float(amostras.size())),
		"%.3f ms" % ordenadas[int(float(ordenadas.size()) * 0.95)],
		"%.3f ms" % ordenadas[mini(int(float(ordenadas.size()) * 0.99), ordenadas.size() - 1)],
		perdidos, QUADROS,
	])
