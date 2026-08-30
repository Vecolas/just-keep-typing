## Regua: quando prestigiar passa a valer mais do que continuar (GDD §18).
##
##   godot --headless --path . tools/medir_economia.tscn
##
## Fecha a v0.3. Sem este numero o prestigio e um botao, e nao uma decisao.
##
## COMO ELA RESPONDE A PERGUNTA. Em cada ponto de amostragem ela BIFURCA a partida e
## simula os dois futuros a partir do mesmo estado:
##
##   continuar    quanto tempo ate a producao DOBRAR seguindo como esta
##   prestigiar   quanto tempo ate a run nova VOLTAR a producao de agora
##
## O menor dos dois e a resposta certa naquele ponto. Onde os dois se cruzam e onde o
## prestigio passa a valer; onde ficam a menos de 20% um do outro e a JANELA AMBIGUA -- e
## e ela que o GDD §18 quer criar, porque e ali que a pergunta tem dois lados de verdade.
##
## Bifurcar so e possivel porque o estado inteiro da partida mora no autoload Jogo: um
## dicionario copia tudo, e devolver e atribuir de volta. Se algum sistema guardasse
## estado proprio, esta regua nao existiria.
##
## ⚠️ O jogador simulado nao e o jogador real -- e a mesma compra otima ingenua da
## medir_ritmo, e pelo mesmo motivo: a regua precisa ser estavel para que a diferenca
## entre duas medicoes seja a mudanca no .tres. Ver TUNING.md.
##
## Roda como cena, e nao com --script, porque toca autoload (CONVENCOES.md).
extends Node

const PASSO: float = 2.0
const INTERVALO_DE_COMPRA: float = 2.0
const CLIQUES_POR_SEGUNDO: float = 4.0

## De quanto em quanto tempo a partida principal e amostrada.
const INTERVALO_DE_AMOSTRA: float = 300.0

## Ate onde a partida principal vai, e ate onde cada bifurcacao vai. Bifurcacao que nao
## termina vira "acima de", que e um resultado tao util quanto um tempo.
const LIMITE_PRINCIPAL: float = 4.0 * 3600.0
const LIMITE_DA_BIFURCACAO: float = 6.0 * 3600.0

## Abaixo desta diferenca relativa os dois caminhos empatam, e o ponto entra na janela
## ambigua. Vinte por cento porque abaixo disso nenhum jogador consegue perceber a
## diferenca -- e decisao que nao da para perceber nao e decisao.
const EMPATE: float = 0.20


func _ready() -> void:
	_zerar()
	print("medir_economia -- passo %.1fs, amostra a cada %.0f min, limite de %.0f h" % [
		PASSO, INTERVALO_DE_AMOSTRA / 60.0, LIMITE_PRINCIPAL / 3600.0,
	])
	print("jogador simulado: compra otima ingenua, sem prestigiar na partida principal")
	print("")
	print("%-10s %-14s %-10s %-12s %-12s %s" % [
		"tempo", "cps", "pontos", "continuar", "prestigiar", "veredito",
	])
	print("%-10s %-14s %-10s %-12s %-12s %s" % [
		"-".repeat(10), "-".repeat(14), "-".repeat(10), "-".repeat(12), "-".repeat(12),
		"-".repeat(20),
	])

	var relogio := 0.0
	var ate_amostrar := INTERVALO_DE_AMOSTRA
	var ambiguos := 0
	var linhas := 0
	while relogio < LIMITE_PRINCIPAL:
		_avancar(PASSO)
		relogio += PASSO
		ate_amostrar -= PASSO
		if ate_amostrar > 0.0:
			continue
		ate_amostrar = INTERVALO_DE_AMOSTRA
		if not Teoremas.pode_provar():
			continue

		var alvo := Jogo.caracteres_por_segundo
		var guardado := _guardar()
		var continuar := _tempo_ate_dobrar(alvo)
		_devolver(guardado)
		var prestigiar := _tempo_ate_voltar(alvo)
		_devolver(guardado)

		var veredito := _veredito(continuar, prestigiar)
		if veredito == "ambiguo":
			ambiguos += 1
		linhas += 1
		print("%-10s %-14s %-10s %-12s %-12s %s" % [
			_relogio(relogio),
			Formatador.formatar(alvo),
			Formatador.formatar(Teoremas.pontos_ao_provar()),
			_relogio(continuar) if continuar > 0.0 else "acima",
			_relogio(prestigiar) if prestigiar > 0.0 else "acima",
			veredito,
		])

	print("")
	print("%d amostras, %d na janela ambigua" % [linhas, ambiguos])
	if ambiguos == 0:
		print("SEM JANELA AMBIGUA: a resposta e sempre obvia, e o GDD §18 queria que nao fosse")
	_conferir_runs_seguintes()
	get_tree().quit(0)


## Quanto tempo ate a producao dobrar, seguindo sem prestigiar.
func _tempo_ate_dobrar(alvo: Grande) -> float:
	var dobro := alvo.vezes(Grande.de_float(2.0))
	var relogio := 0.0
	while relogio < LIMITE_DA_BIFURCACAO:
		_avancar(PASSO)
		relogio += PASSO
		if not Jogo.caracteres_por_segundo.menor_que(dobro):
			return relogio
	return 0.0


## Quanto tempo ate a run NOVA voltar a producao de agora, prestigiando neste ponto.
func _tempo_ate_voltar(alvo: Grande) -> float:
	if Teoremas.provar().sinal() <= 0:
		return 0.0
	_gastar_na_arvore()
	var relogio := 0.0
	while relogio < LIMITE_DA_BIFURCACAO:
		_avancar(PASSO)
		relogio += PASSO
		if not Jogo.caracteres_por_segundo.menor_que(alvo):
			return relogio
	return 0.0


## A run seguinte nunca pode ficar mais lenta que a anterior -- sintoma de arvore mal
## calibrada, e a terceira pergunta que a issue #29 faz.
func _conferir_runs_seguintes() -> void:
	print("")
	print("%-8s %-14s %s" % ["run", "cps em 30 min", "diferenca"])
	print("%-8s %-14s %s" % ["-".repeat(8), "-".repeat(14), "-".repeat(20)])

	_zerar()
	var anterior: Grande = Grande.zero()
	var regrediu := false
	for run in range(1, 6):
		var relogio := 0.0
		while relogio < 1800.0:
			_avancar(PASSO)
			relogio += PASSO
		var atual := Jogo.caracteres_por_segundo
		var diferenca := "primeira"
		if run > 1:
			if atual.menor_que(anterior):
				diferenca = "PIOR QUE A ANTERIOR"
				regrediu = true
			else:
				diferenca = "%sx" % Formatador.formatar(atual.dividido(anterior))
		print("%-8d %-14s %s" % [run, Formatador.formatar(atual), diferenca])
		anterior = atual

		if not Teoremas.pode_provar():
			print("(a run %d nao juntou ponto para prestigiar em 30 min)" % run)
			break
		Teoremas.provar()
		_gastar_na_arvore()

	if regrediu:
		print("")
		print("⚠️  ALGUMA RUN FICOU MAIS LENTA QUE A ANTERIOR -- a arvore esta mal calibrada")


func _veredito(continuar: float, prestigiar: float) -> String:
	if continuar <= 0.0 and prestigiar <= 0.0:
		return "nenhum dos dois"
	if continuar <= 0.0:
		return "prestigiar"
	if prestigiar <= 0.0:
		return "continuar"
	var diferenca := absf(continuar - prestigiar) / maxf(continuar, prestigiar)
	if diferenca <= EMPATE:
		return "ambiguo"
	return "prestigiar" if prestigiar < continuar else "continuar"


func _avancar(passo: float) -> void:
	if not Economia.producao_automatica():
		Economia.digitar(int(CLIQUES_POR_SEGUNDO * passo))
	Economia.acumular(passo)
	Marcos.verificar()
	_comprar_o_que_der()


func _comprar_o_que_der() -> void:
	for dados in Economia.upgrades():
		Economia.comprar_upgrade(dados.id)
	var proxima := Economia.proxima_maquina()
	if proxima != null:
		Economia.comprar_maquina(proxima.id)
	var sala := Economia.proxima_sala()
	if sala != null:
		Economia.expandir_sala(sala.id)
	var cabem := Economia.macacos_que_cabem()
	if cabem > 0:
		Economia.comprar_macacos(cabem)


## O jogador simulado gasta os pontos na arvore, do mais barato para o mais caro. Nao
## gastar seria medir um prestigio que ninguem faz.
func _gastar_na_arvore() -> void:
	for volta in 20:
		var comprou := false
		for no in Teoremas.nos():
			if Teoremas.comprar(no.id):
				comprou = true
		if not comprou:
			return


func _zerar() -> void:
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.multiplicador_global = 1.0
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.pontos_totais = Grande.zero()
	Jogo.recorde_de_total = Grande.zero()
	Jogo.recorde_por_segundo = Grande.zero()
	Jogo.macacos_comprados = Grande.zero()
	Jogo.total_offline = Grande.zero()
	Jogo.prestigios = 0
	Jogo.tempo_jogado = 0.0
	Jogo.tempo_da_run = 0.0
	Jogo.teoremas = {}
	Jogo.automacoes = {}
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]
	Eventos.limpar()


## O estado inteiro da partida cabe num dicionario porque ele inteiro mora no Jogo. E o
## que permite bifurcar.
func _guardar() -> Dictionary:
	return {
		"total": Jogo.total_caracteres, "run": Jogo.caracteres_da_run,
		"cps": Jogo.caracteres_por_segundo, "dinheiro": Jogo.dinheiro,
		"macacos": Jogo.macacos, "maquina": Jogo.maquina_atual, "sala": Jogo.sala_atual,
		"global": Jogo.multiplicador_global, "pontos": Jogo.pontos_de_teorema,
		"totais": Jogo.pontos_totais, "recorde": Jogo.recorde_de_total,
		"prestigios": Jogo.prestigios, "tempo": Jogo.tempo_jogado,
		"tempo_run": Jogo.tempo_da_run, "teoremas": Jogo.teoremas.duplicate(),
		"upgrades": Jogo.upgrades_comprados.duplicate(),
		"descobertas": Jogo.descobertas.duplicate(),
		"marcos": Jogo.marcos_alcancados.duplicate(),
	}


func _devolver(g: Dictionary) -> void:
	Jogo.total_caracteres = g["total"]
	Jogo.caracteres_da_run = g["run"]
	Jogo.caracteres_por_segundo = g["cps"]
	Jogo.dinheiro = g["dinheiro"]
	Jogo.macacos = g["macacos"]
	Jogo.maquina_atual = g["maquina"]
	Jogo.sala_atual = g["sala"]
	Jogo.multiplicador_global = g["global"]
	Jogo.pontos_de_teorema = g["pontos"]
	Jogo.pontos_totais = g["totais"]
	Jogo.recorde_de_total = g["recorde"]
	Jogo.prestigios = g["prestigios"]
	Jogo.tempo_jogado = g["tempo"]
	Jogo.tempo_da_run = g["tempo_run"]
	Jogo.teoremas = g["teoremas"]
	Jogo.upgrades_comprados = g["upgrades"]
	Jogo.descobertas = g["descobertas"]
	Jogo.marcos_alcancados = g["marcos"]
	Eventos.limpar()


static func _relogio(segundos: float) -> String:
	var inteiros := int(segundos)
	return "%02d:%02d:%02d" % [inteiros / 3600, (inteiros / 60) % 60, inteiros % 60]
