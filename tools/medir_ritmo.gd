## Regua: quanto tempo a partida leva ate cada marco do Panorama.
##
##   godot --headless --path . tools/medir_ritmo.tscn
##
## REGUA NAO APROVA NEM REPROVA -- ela MEDE. A saida sao numeros para voce decidir; a
## decisao e sua. Sem numero medido, ajustar balanceamento e chute com etapa extra.
## Ver TUNING.md.
##
## E a regua que sustenta a issue #20 (curva do Panorama) e todo tuning daqui para a
## frente: os requisitos dos marcos definem, na pratica, quanto tempo o jogador leva para
## atravessar cada faixa de escala (decisao 0003), e ate esta regua existir esse numero
## nunca tinha sido olhado.
##
## ⚠️ O JOGADOR SIMULADO NAO E O JOGADOR REAL. Ele faz a compra otima INGENUA: gasta em
## upgrade assim que da, e no resto compra o maximo de macacos que couber. Nenhum humano
## joga assim -- ninguem clica com cadencia constante nem compra no instante exato em que
## o saldo fecha. Isso e proposital: a regua precisa ser ESTAVEL, para que a diferenca
## entre duas medicoes seja a mudanca no .tres e nao o humor de quem jogou.
##
## Roda como cena, e nao com --script, porque toca autoload: avaliacao de GDScript solto
## nao passa pela lista de autoloads do project.godot (CONVENCOES.md).
extends Node

## Passo do relogio simulado. Meio segundo da resolucao de sobra para uma regua que mede
## minutos e horas, e deixa a simulacao de um dia inteiro terminar em segundos.
const PASSO: float = 0.5

## De quanto em quanto tempo o jogador simulado vai a loja. Comprar todo passo nao mudaria
## a curva e triplicaria o custo da medicao.
const INTERVALO_DE_COMPRA: float = 1.0

## Cliques por segundo enquanto o macaco ainda nao digita sozinho (GDD §3). Sem isto a
## partida nunca sai do zero: a producao automatica custa caracteres, e antes dela o
## clique e a unica fonte. Quatro por segundo e um dedilhado tranquilo, e ele para no
## instante em que o Instinto Digitador entra.
const CLIQUES_POR_SEGUNDO: float = 4.0

## Ate onde a medicao vai. Marco que nao cai em um dia de jogo aparece como NAO ALCANCADO,
## que e um resultado tao util quanto um tempo.
const LIMITE_SEGUNDOS: float = 24.0 * 3600.0


func _ready() -> void:
	_zerar_a_partida()

	var tempos := {}
	var producoes := {}
	var ouvinte := func(marco: DadosMarco) -> void:
		tempos[marco.id] = Jogo.tempo_jogado
		producoes[marco.id] = Jogo.caracteres_por_segundo
	EventBus.marco_alcancado.connect(ouvinte)

	var relogio := 0.0
	var ate_comprar := 0.0
	while relogio < LIMITE_SEGUNDOS and Marcos.proximo() != null:
		if not Economia.producao_automatica():
			Economia.digitar(int(CLIQUES_POR_SEGUNDO * PASSO))
		Economia.acumular(PASSO)
		Marcos.verificar()

		ate_comprar -= PASSO
		if ate_comprar <= 0.0:
			ate_comprar = INTERVALO_DE_COMPRA
			_comprar_o_que_der()
		relogio += PASSO

	EventBus.marco_alcancado.disconnect(ouvinte)
	_imprimir(tempos, producoes, relogio)
	get_tree().quit(0)


## A compra otima ingenua: upgrade primeiro, porque multiplicador vale para sempre e o
## macaco seguinte so vale por si; depois, o maximo de macacos que couber.
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


## Parte de partida nova. A regua nao le nem escreve save: ela mede a curva do zero, que e
## a unica medicao que da para comparar entre duas sessoes de tuning.
func _zerar_a_partida() -> void:
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.fragmentos = Grande.zero()
	Jogo.multiplicador_global = 1.0
	Jogo.tempo_jogado = 0.0
	Jogo.tempo_da_run = 0.0
	Jogo.recorde_por_segundo = Grande.zero()
	Jogo.macacos_comprados = Grande.zero()
	Jogo.total_offline = Grande.zero()
	Jogo.prestigios = 0
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]


## Texto, e nao CSV nem JSON, porque a saida de uma regua serve para dar DIFF entre duas
## sessoes de tuning -- e diff de texto alinhado se le a olho nu.
func _imprimir(tempos: Dictionary, producoes: Dictionary, relogio: float) -> void:
	print("medir_ritmo -- passo %.1fs, compra a cada %.1fs, %.0f cliques/s ate a automacao" % [
		PASSO, INTERVALO_DE_COMPRA, CLIQUES_POR_SEGUNDO,
	])
	print("jogador simulado: compra otima ingenua (upgrade assim que da, depois macaco maximo)")
	print("")
	print("%-22s %-12s %-14s %s" % ["marco", "tempo", "requisito", "cps no momento"])
	print("%-22s %-12s %-14s %s" % ["-".repeat(22), "-".repeat(12), "-".repeat(14), "-".repeat(14)])

	for marco in Marcos.todos():
		if tempos.has(marco.id):
			print("%-22s %-12s %-14s %s" % [
				marco.id,
				_relogio(tempos[marco.id]),
				Formatador.formatar(marco.requisito_grande()),
				Formatador.formatar(producoes[marco.id]),
			])
		else:
			print("%-22s %-12s %-14s %s" % [
				marco.id, "NAO ALCANCADO", Formatador.formatar(marco.requisito_grande()), "-",
			])

	print("")
	print("parou em %s com %s macacos, %s caracteres e %s/s" % [
		_relogio(relogio),
		Formatador.formatar(Jogo.macacos),
		Formatador.formatar(Jogo.total_caracteres),
		Formatador.formatar(Jogo.caracteres_por_segundo),
	])


static func _relogio(segundos: float) -> String:
	var inteiros := int(segundos)
	return "%02d:%02d:%02d" % [inteiros / 3600, (inteiros / 60) % 60, inteiros % 60]
