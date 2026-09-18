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
## ⚠️ O QUE ESTA REGUA NAO MEDE, declarado para ninguem supor que ela mede:
##
##   EVENTOS. Ela nunca chama Eventos.tique -- so a cena da partida chama. A campanha
##   medida aqui nao tem nenhum acontecimento aleatorio, nem os bons nem os ruins.
##
##   AUTOMACAO. Mesma coisa: Automacao.tique nao roda. Gerente Macaco e os outros nao
##   compram macaco sozinhos durante a medicao, e o jogador simulado faz esse trabalho na
##   mao a cada INTERVALO_DE_COMPRA.
##
## Os dois sao ponto cego DECLARADO e nao esquecimento: liga-los mudaria o instrumento mais
## uma vez, e tabela medida com instrumento diferente nao se compara. Entram na issue que
## for rebalancear a curva, junto com a medicao nova que ela vai precisar de qualquer jeito.
##
## ⚠️ E O SORTEIO DE DESCOBERTAS E SEMEADO -- ver SEMENTE_DO_SORTEIO. Sem isso a promessa
## do paragrafo abaixo e falsa, e foi falsa ate a issue #56.
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


## ⚠️ O CONTROLE DA ISSUE #54. `-- sem_combo=1` zera o combo depois de cada clique, o que
## simula um jogador que digita sem nenhuma cadencia -- e da a MESMA medicao sem o efeito.
##
## Piso escrito a mao inventa a propria escala: "o combo acelera" so quer dizer alguma
## coisa contra a mesma corrida sem ele.
##
## E ele nao precisa de porta de tras no Combo: zerar e a operacao que ja existe para o
## prestigio, e o que muda aqui e o JOGADOR simulado, nao o sistema medido.
var _sem_combo: bool = false


## ⚠️ A SEMENTE DO SORTEIO DE DESCOBERTAS. SEM ELA A REGUA NAO E REGUA.
##
## Descobertas.gerador chama randomize() no _ready, e descoberta DA BONUS DE PRODUCAO:
## duas corridas do mesmo commit sorteavam em instantes diferentes, a producao divergia, e
## a curva inteira andava junto. Medido: 35 segundos de diferenca no primeiro Teorema entre
## duas corridas identicas.
##
## Isso valia desde que a regua existe, e o cabecalho dela AFIRMAVA O CONTRARIO -- "a regua
## precisa ser ESTAVEL, para que a diferenca entre duas medicoes seja a mudanca no .tres e
## nao o humor de quem jogou". A suite e a ferramenta de captura ja semeavam; as reguas,
## nao. Uma verdade por assunto, e este assunto tinha duas.
##
## ⚠️ E O NUMERO E UM SO, COMPARTILHADO. Semente diferente por ferramenta daria tabelas que
## nao se comparam entre si, que e metade do problema de volta.
const SEMENTE_DO_SORTEIO: int = 1


func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento == "sem_combo=1":
			_sem_combo = true
	Descobertas.gerador.seed = SEMENTE_DO_SORTEIO
	_zerar_a_partida()

	var tempos := {}
	var producoes := {}
	var ouvinte := func(marco: DadosMarco) -> void:
		tempos[marco.id] = Jogo.tempo_jogado
		producoes[marco.id] = Jogo.caracteres_por_segundo
	EventBus.marco_alcancado.connect(ouvinte)

	# ⚠️ OS TRES OUVINTES DA ISSUE #56. A regua media SO marco ate aqui, e a versao se
	# chama "A primeira hora": sem saber quando o jogador compra e quando ele DESCOBRE,
	# metade do que acontece na primeira hora era invisivel para quem ajusta os numeros.
	var upgrades := {}
	var ouvinte_upgrade := func(id: String) -> void:
		upgrades[id] = Jogo.tempo_jogado
	EventBus.upgrade_comprado.connect(ouvinte_upgrade)

	# a PRIMEIRA de cada categoria, e nao todas: o que conta e quando a faixa comeca a
	# sair, que e a pergunta que a issue #52 deixou aberta
	var primeira_da_categoria := {}
	var ouvinte_descoberta := func(descoberta: DadosDescoberta) -> void:
		if not primeira_da_categoria.has(descoberta.categoria):
			primeira_da_categoria[descoberta.categoria] = [
				Jogo.tempo_jogado, descoberta.id,
			]
	EventBus.descoberta_encontrada.connect(ouvinte_descoberta)

	var teorema_disponivel := -1.0
	var teorema_vale := -1.0

	var relogio := 0.0
	var ate_comprar := 0.0
	while relogio < LIMITE_SEGUNDOS and Marcos.proximo() != null:
		if _vale_a_pena_digitar():
			Economia.digitar(int(CLIQUES_POR_SEGUNDO * PASSO))
			if _sem_combo:
				Combo._zerar()
		Economia.acumular(PASSO)
		Marcos.verificar()

		# ⚠️ CURTO-CIRCUITO, e nao uma amostragem mais rala. pode_provar() faz um log10
		# sobre Grande, e a versao ingenua o chamava DUAS vezes por passo, 172 mil vezes --
		# a regua ficou duas vezes mais lenta antes de alguem ligar as duas coisas.
		#
		# A conta e feita uma vez por passo e para de vez assim que a resposta e conhecida,
		# o que acontece aos 3 min de 24 h: 99,7% do laco nem entra aqui. O RESULTADO e
		# identico ao da versao ingenua -- medir mais raro mudaria os numeros, e isso nao
		# seria otimizar, seria medir outra coisa.
		if teorema_vale < 0.0:
			var pode := Teoremas.pode_provar()
			if pode and teorema_disponivel < 0.0:
				teorema_disponivel = Jogo.tempo_jogado
			if pode and _o_teorema_dobra_a_producao():
				teorema_vale = Jogo.tempo_jogado

		ate_comprar -= PASSO
		if ate_comprar <= 0.0:
			ate_comprar = INTERVALO_DE_COMPRA
			_comprar_o_que_der()
		relogio += PASSO

	EventBus.marco_alcancado.disconnect(ouvinte)
	EventBus.upgrade_comprado.disconnect(ouvinte_upgrade)
	EventBus.descoberta_encontrada.disconnect(ouvinte_descoberta)
	_imprimir(tempos, producoes, relogio)
	_imprimir_a_primeira_hora(tempos, upgrades, primeira_da_categoria,
		teorema_disponivel, teorema_vale)
	get_tree().quit(0)


## ⚠️ O CONSERTO DO MODELO QUE A ISSUE #54 ACHOU.
##
## Ate aqui o jogador simulado parava de digitar no INSTANTE em que a producao automatica
## acendia -- e nos primeiros minutos clicar a 4/s rende MUITO mais que a automacao
## recem-ligada. O efeito media a ingenuidade do modelo e nao o jogo: o combo, por fazer a
## primeira compra chegar um segundo antes, aparecia como 37 segundos de ATRASO na
## campanha inteira.
##
## A regra nova nao tem numero magico e nao precisa de nenhum: ele digita enquanto digitar
## render mais do que esperar. E o mesmo criterio de "compra otima ingenua" aplicado a mao,
## e ele se desliga sozinho quando o jogador vira administrador -- que e exatamente o arco
## que o plano da v0.6 descreve.
##
## ⚠️ TABELA MEDIDA ANTES DESTA MUDANCA NAO SE COMPARA COM AS NOVAS. Ver TUNING.md.
func _vale_a_pena_digitar() -> bool:
	if not Economia.producao_automatica():
		return true
	var da_mao := Grande.de_float(CLIQUES_POR_SEGUNDO * Combo.multiplicador())
	return da_mao.maior_que(Economia.producao_por_segundo())


## O primeiro Teorema "vale a pena" quando provar multiplica a producao por pelo menos o
## DOBRO. Disponivel e vale a pena sao coisas diferentes: pode_provar() abre com um ponto
## so, e um ponto so nao compensa perder a run.
##
## O numero mora aqui e nao num .tres de proposito: e um criterio de LEITURA da regua, e
## nao um botao do jogo. Regua nao aprova nem reprova -- ela mede, e este e o limiar a
## partir do qual ela conta a historia.
const DOBRO: float = 2.0


## Chamado so quando pode_provar() ja deu verdadeiro -- por isso nao repete a pergunta.
func _o_teorema_dobra_a_producao() -> bool:
	var agora := Teoremas.multiplicador()
	if agora <= 0.0:
		return false
	return Teoremas.multiplicador_se_provar() / agora >= DOBRO


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
	Jogo.pontos_totais = Grande.zero()
	Jogo.recorde_de_total = Grande.zero()
	Jogo.teoremas = {}
	Jogo.automacoes = {}
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]


## A SEGUNDA TABELA: o que acontece na PRIMEIRA HORA, que e o nome da versao.
##
## Ela e separada da primeira de proposito. A tabela de marcos e a curva inteira, de 24
## horas; esta responde outra pergunta -- "a primeira hora tem acontecimento denso?" --, e
## misturar as duas daria uma so que nao responde nenhuma direito.
##
## ⚠️ REGUA NAO APROVA NEM REPROVA. Nada aqui diz "bom" ou "ruim": ela conta QUANTOS
## acontecimentos caem em cada faixa de dez minutos e QUANDO cada coisa comeca. A decisao
## sobre os numeros e de quem le.
func _imprimir_a_primeira_hora(
	marcos: Dictionary, upgrades: Dictionary, descobertas: Dictionary,
	teorema_disponivel: float, teorema_vale: float
) -> void:
	print("")
	print("──── a primeira hora ────")
	print("")

	# quantos acontecimentos por faixa de dez minutos. E a medida mais direta de
	# "densidade", que e a palavra que o plano da v0.6 usa.
	var faixas := [600.0, 1200.0, 1800.0, 2400.0, 3000.0, 3600.0]
	print("%-14s %8s %10s %12s" % ["ate", "marcos", "upgrades", "descobertas"])
	print("%-14s %8s %10s %12s" % ["-".repeat(14), "-".repeat(8), "-".repeat(10), "-".repeat(12)])
	var anterior := 0.0
	for limite in faixas:
		print("%-14s %8d %10d %12d" % [
			_como_tempo(limite),
			_quantos_entre(marcos.values(), anterior, limite),
			_quantos_entre(upgrades.values(), anterior, limite),
			_quantos_primeiros_entre(descobertas, anterior, limite),
		])
		anterior = limite

	print("")
	print("upgrades da primeira hora, por familia:")
	var por_familia := {}
	for id in upgrades:
		if float(upgrades[id]) > 3600.0:
			continue
		var dados := Economia.upgrade_de(id)
		if dados == null:
			continue
		var familia: int = dados.familia
		if not por_familia.has(familia):
			por_familia[familia] = []
		por_familia[familia].append([float(upgrades[id]), id])
	for familia in DadosUpgrade.Familia.values():
		if not por_familia.has(familia):
			continue
		var lista: Array = por_familia[familia]
		lista.sort()
		var nomes := PackedStringArray()
		for item in lista:
			nomes.append("%s %s" % [_como_tempo(float(item[0])), item[1]])
		print("  %-16s %d: %s" % [
			DadosUpgrade.NOMES_DE_FAMILIA[familia], lista.size(), ", ".join(nomes),
		])
	# ⚠️ familia sem NENHUM upgrade na primeira hora e um resultado, e nao um vazio: sem
	# esta linha, a familia ausente simplesmente nao apareceria e ninguem repararia
	for familia in DadosUpgrade.Familia.values():
		if familia == DadosUpgrade.Familia.SEM_FAMILIA or por_familia.has(familia):
			continue
		print("  %-16s 0: NENHUM na primeira hora" % DadosUpgrade.NOMES_DE_FAMILIA[familia])

	print("")
	print("a primeira descoberta de cada categoria:")
	for categoria in DadosDescoberta.Categoria.values():
		if descobertas.has(categoria):
			var dado: Array = descobertas[categoria]
			print("  %-14s %s  %s" % [
				DescobertasTela.NOMES_DE_CATEGORIA[categoria],
				_como_tempo(float(dado[0])), dado[1],
			])
		else:
			print("  %-14s NAO SAIU em 24 h" % DescobertasTela.NOMES_DE_CATEGORIA[categoria])

	print("")
	print("o primeiro Teorema:")
	print("  disponivel      %s" % (
		"NUNCA" if teorema_disponivel < 0.0 else _como_tempo(teorema_disponivel)))
	print("  vale a pena     %s  (dobrar a producao)" % (
		"NUNCA" if teorema_vale < 0.0 else _como_tempo(teorema_vale)))


## Quantos instantes de uma lista caem em (de, ate].
func _quantos_entre(instantes: Array, de: float, ate: float) -> int:
	var quantos := 0
	for instante in instantes:
		var t := float(instante)
		if t > de and t <= ate:
			quantos += 1
	return quantos


func _quantos_primeiros_entre(primeiras: Dictionary, de: float, ate: float) -> int:
	var quantos := 0
	for categoria in primeiras:
		var t := float((primeiras[categoria] as Array)[0])
		if t > de and t <= ate:
			quantos += 1
	return quantos


func _como_tempo(segundos: float) -> String:
	return "%02d:%02d:%02d" % [
		int(segundos) / 3600, (int(segundos) / 60) % 60, int(segundos) % 60,
	]


## Texto, e nao CSV nem JSON, porque a saida de uma regua serve para dar DIFF entre duas
## sessoes de tuning -- e diff de texto alinhado se le a olho nu.
func _imprimir(tempos: Dictionary, producoes: Dictionary, relogio: float) -> void:
	print("medir_ritmo -- passo %.1fs, compra a cada %.1fs, %.0f cliques/s ate a automacao" % [
		PASSO, INTERVALO_DE_COMPRA, CLIQUES_POR_SEGUNDO,
	])
	print("jogador simulado: compra otima ingenua (upgrade assim que da, depois macaco maximo)")
	print("combo de digitacao: %s" % ("DESLIGADO (sem_combo=1)" if _sem_combo else "ligado"))
	# ⚠️ E ELE PARA DE DIGITAR quando a producao automatica acende, que sao os primeiros
	# dez caracteres. O resto da campanha inteira roda sem um clique -- o que e, por si
	# so, a prova de que a progressao nao depende do combo.
	print("⚠️ o jogador simulado nao digita depois do Instinto Digitador")
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
