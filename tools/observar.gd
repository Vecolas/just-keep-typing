## A SESSAO OBSERVADA (issue #64): o que esta NA TELA, minuto a minuto.
##
##   godot --path . tools/observar.tscn
##   godot --path . tools/observar.tscn -- perfil=passivo minutos=30
##
## ⚠️ ISTO NAO E O PLAYTEST, E NAO O SUBSTITUI. O playtest da issue #64 responde "o que
## confundiu", "quando parou de ler os textos", "quando ficou sem objetivo" -- e nenhuma
## maquina responde isso. O que ESTA ferramenta faz e a outra metade, a que nenhum humano
## consegue fazer bem: olhar a tela a cada minuto durante trinta minutos sem piscar, e
## anotar o que mudou nela.
##
## A diferenca para medir_ritmo importa:
##
##   medir_ritmo   QUANDO cada coisa acontece. Nao monta cena nenhuma.
##   observar      O QUE ESTA NA TELA enquanto acontece -- quantos botoes a loja oferece,
##                 se algum deles esta comprável, o que o jogador teria para fazer.
##
## A pergunta que ela responde, e que a regua nao responde: **em que minutos o jogador nao
## tem nada para fazer?** Um bloco de dez minutos pode estar "cheio" na tabela da regua --
## marcos caindo -- e mesmo assim nao oferecer NENHUMA decisao ao jogador.
##
## SEM --headless de proposito: ela monta a partida de verdade, com a HUD, e conta os
## botoes que a loja mostra. Headless nao monta layout.
extends Node

## De quanto em quanto tempo simulado ela olha para a tela.
const PASSO: float = 0.5
const INTERVALO_DE_COMPRA: float = 1.0

## ⚠️ O MESMO DA REGUA E DA SUITE. Semente diferente daria uma sessao que nao se compara
## com a tabela de medir_ritmo, e as duas existem para serem lidas lado a lado.
const SEMENTE_DO_SORTEIO: int = 1

const MINUTOS_PADRAO: int = 30

## Em que minutos ela guarda uma FOTO da tela.
##
## ⚠️ A TABELA DIZ QUANTOS BOTOES; A FOTO DIZ SE ELES SE LEEM. Um minuto com "4 na loja" e
## "3 compras" pode ser uma tela confusa, um texto cortado, um numero que nao cabe -- e
## nada disso aparece num contador. Os tres defeitos de leitura da v0.6 foram achados
## olhando captura, com a suite verde.
##
## Nao e todo minuto: trinta imagens de 1080p sao caras e a maior parte delas seria igual a
## anterior. Estes nove sao os instantes em que a campanha muda de fase.
const MINUTOS_FOTOGRAFADOS: PackedInt32Array = [1, 2, 3, 5, 10, 15, 20, 25, 30]

const PASTA_DAS_FOTOS := "user://playtest"

var _perfil: Dictionary = {}
var _nome_do_perfil: String = "normal"
var _minutos: int = MINUTOS_PADRAO


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FALHA  a sessao observada monta a HUD; rode sem --headless")
		get_tree().quit(1)
		return

	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("perfil="):
			_nome_do_perfil = argumento.trim_prefix("perfil=")
		elif argumento.begins_with("minutos="):
			_minutos = maxi(1, int(argumento.trim_prefix("minutos=").to_int()))

	var perfis: Dictionary = preload("res://tools/medir_ritmo.gd").PERFIS
	if not perfis.has(_nome_do_perfil):
		printerr("FALHA  perfil desconhecido: %s" % _nome_do_perfil)
		get_tree().quit(1)
		return
	_perfil = perfis[_nome_do_perfil]

	# nunca encosta no save de quem joga
	#
	# ⚠️ A PASTA TEM QUE EXISTIR ANTES. Sem isto o autosave falha a cada gravacao e enche a
	# saida de backtrace -- e pior, a sessao roda mesmo assim, entao o erro passa por ruido
	# em vez de por defeito.
	DirAccess.make_dir_recursive_absolute("user://observar")
	Save.caminho = "user://observar/save.json"
	Config.caminho = "user://observar/opcoes.json"
	Config.modelo_de_slot = "user://observar/slot_%d.json"

	# ⚠️ APAGA A PASTA INTEIRA, e nao so Save.caminho. comecar_partida(1) troca o caminho do
	# save para o do SLOT, e o arquivo do slot sobrevive entre execucoes da ferramenta --
	# entao a segunda sessao em diante RETOMAVA a partida da anterior.
	#
	# O sintoma nao parecia defeito: a tabela saia coerente, so comecando com producao de
	# 13,9 milhoes no minuto 1. Uma sessao observada que comeca no meio da campanha mede
	# outro jogo, e a leitura dela vale zero.
	_limpar_a_pasta("user://observar")
	DirAccess.make_dir_recursive_absolute(PASTA_DAS_FOTOS)
	_limpar_a_pasta(PASTA_DAS_FOTOS)

	Descobertas.gerador.seed = SEMENTE_DO_SORTEIO
	Eventos.gerador.seed = SEMENTE_DO_SORTEIO
	Eventos.limpar()

	var caminho: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		printerr("FALHA  cena principal %s nao carregou" % caminho)
		get_tree().quit(1)
		return
	add_child(empacotada.instantiate())
	await get_tree().process_frame
	Cenas.comecar_partida(1)
	Cenas.concluir_transicao()
	for i in 10:
		await get_tree().process_frame

	# ⚠️ UM RELOGIO SO. partida.gd::_process tica Eventos, Automacao, Economia.acumular E
	# Marcos.verificar -- exatamente as quatro coisas que o laco abaixo tica. Com a cena
	# ligada, o tempo andava DUAS vezes.
	#
	# O sintoma foi os dois instrumentos discordarem em oito ordens de grandeza: a regua
	# dizia total 750 aos 60 minutos e esta sessao dizia 35 bilhoes aos 30, com o mesmo
	# perfil e a mesma semente. Numero de medidor que discorda do outro medidor nao e
	# "ruido": e um dos dois mentindo, e tuning feito em cima de qualquer um dos dois nao
	# vale nada ate a discordancia ser explicada.
	var partida := get_tree().root.find_child("Partida", true, false)
	if partida == null:
		printerr("FALHA  a cena da partida nao foi encontrada para desligar o _process")
		get_tree().quit(1)
		return
	partida.set_process(false)

	await _observar()
	get_tree().quit(0)


func _observar() -> void:
	print("sessao observada -- perfil %s, %d minutos" % [_nome_do_perfil, _minutos])
	print("⚠️ isto NAO e o playtest da issue #64: ele responde o que confundiu e quando o")
	print("   jogador parou de ler. Isto responde o que estava na tela.")
	print("")
	print("%-6s %-12s %-12s %7s %7s %9s" % [
		"min", "producao/s", "total", "na loja", "perto", "compras",
	])
	print("%-6s %-12s %-12s %7s %7s %9s" % [
		"-".repeat(6), "-".repeat(12), "-".repeat(12), "-".repeat(7), "-".repeat(7),
		"-".repeat(9),
	])

	var relogio := 0.0
	var ate_comprar := 0.0
	var proximo_minuto := 60.0
	var mudou_no_minuto := 0
	var marcos_antes := Jogo.marcos_alcancados.size()
	var descobertas_antes := Jogo.descobertas.size()
	# ⚠️ minutos sem NADA para fazer, que e a pergunta desta ferramenta
	var minutos_sem_escolha := 0
	var minutos_sem_acontecimento := 0
	var minutos_sem_oferta := 0
	# ⚠️ a pergunta que a coluna "na loja" nao respondia: o jogador tem algum alvo ALCANCAVEL
	# a vista, ou so uma vitrine de precos que ele nao encosta?
	var minutos_sem_alvo := 0

	# ⚠️ "QUANDO O JOGADOR PAROU DE LER OS TEXTOS" TEM UMA METADE MEDIVEL, e e esta.
	#
	# A HUD tem UM slot de aviso (hud.gd::_avisar): cada marco, cada descoberta e cada
	# autosave escreve por cima do anterior e reinicia o relogio de AVISO_VISIVEL. Dois
	# avisos dentro dessa janela querem dizer que o primeiro SUMIU antes de dar tempo de
	# ler -- e isso nao e opiniao, e aritmetica.
	#
	# A outra metade -- se o jogador QUIS ler -- continua sendo dele.
	# ⚠️ GUARDA O INSTANTE E A PRIORIDADE. A primeira versao guardava so o instante e
	# contava quantos pares caiam a menos de 1,6 s um do outro -- e isso mede QUANDO OS
	# EVENTOS CAEM, que a issue #69 nao muda. O que ela muda e o que a fila FAZ com eles.
	#
	# E o terceiro defeito desta familia nesta sessao: medir a entrada em vez do resultado.
	var avisos: Array[Dictionary] = []
	var anotar := func(prioridade: int) -> void:
		avisos.append({"instante": Jogo.tempo_jogado, "prioridade": prioridade})
	var anotar_marco := func(m: DadosMarco) -> void:
		anotar.call(
			FilaDeAvisos.Prioridade.ALTA
			if m.tipo == DadosMarco.Tipo.CONCEITUAL
			else FilaDeAvisos.Prioridade.NORMAL
		)
	var anotar_descoberta := func(d: DadosDescoberta) -> void:
		anotar.call(
			FilaDeAvisos.Prioridade.CRITICA
			if d.categoria >= DadosDescoberta.Categoria.LENDARIO
			else FilaDeAvisos.Prioridade.ALTA
		)
	EventBus.marco_alcancado.connect(anotar_marco)
	EventBus.descoberta_encontrada.connect(anotar_descoberta)

	var compras := [0]
	var ouvinte_upgrade := func(_id: String) -> void: compras[0] += 1
	var ouvinte_macaco := func(_quantos: int) -> void: compras[0] += 1
	EventBus.upgrade_comprado.connect(ouvinte_upgrade)
	EventBus.macacos_comprados.connect(ouvinte_macaco)

	while relogio < float(_minutos) * 60.0:
		if _vale_a_pena_digitar():
			var quantos := int(float(_perfil["cliques_por_segundo"]) * PASSO)
			if quantos > 0:
				Economia.digitar(quantos)
		Economia.acumular(PASSO)
		Eventos.tique(PASSO)
		Automacao.tique(PASSO)
		Marcos.verificar()

		ate_comprar -= PASSO
		if ate_comprar <= 0.0:
			ate_comprar = INTERVALO_DE_COMPRA + float(_perfil["atraso_de_compra"])
			_comprar_o_que_der()

		relogio += PASSO
		if relogio >= proximo_minuto:
			var na_loja := _quantos_na_loja()
			var compraveis: int = compras[0]
			compras[0] = 0
			var acontecimentos := (
				(Jogo.marcos_alcancados.size() - marcos_antes)
				+ (Jogo.descobertas.size() - descobertas_antes)
			)
			if compraveis == 0:
				minutos_sem_escolha += 1
			if na_loja == 0:
				minutos_sem_oferta += 1
			if _quantos_perto() == 0 and compraveis == 0:
				minutos_sem_alvo += 1
			if acontecimentos == 0:
				minutos_sem_acontecimento += 1
			print("%-6d %-12s %-12s %7d %7d %9d" % [
				int(proximo_minuto / 60.0),
				Formatador.formatar(Jogo.caracteres_por_segundo),
				Formatador.formatar(Jogo.total_caracteres),
				na_loja, _quantos_perto(), compraveis,
			])
			var minuto := int(proximo_minuto / 60.0)
			if minuto in MINUTOS_FOTOGRAFADOS:
				await _fotografar(minuto)
			marcos_antes = Jogo.marcos_alcancados.size()
			descobertas_antes = Jogo.descobertas.size()
			proximo_minuto += 60.0
			mudou_no_minuto += 1
			await get_tree().process_frame

	print("")
	EventBus.upgrade_comprado.disconnect(ouvinte_upgrade)
	EventBus.macacos_comprados.disconnect(ouvinte_macaco)
	print("⚠️ minutos SEM NENHUMA COMPRA:               %d de %d" % [
		minutos_sem_escolha, _minutos,
	])
	print("⚠️ minutos com a LOJA VAZIA (nada a mirar):  %d de %d" % [
		minutos_sem_oferta, _minutos,
	])
	print("⚠️ minutos so com VITRINE (nada perto):      %d de %d" % [
		minutos_sem_alvo, _minutos,
	])
	print("⚠️ minutos SEM MARCO NEM DESCOBERTA:         %d de %d" % [
		minutos_sem_acontecimento, _minutos,
	])
	EventBus.marco_alcancado.disconnect(anotar_marco)
	EventBus.descoberta_encontrada.disconnect(anotar_descoberta)
	_contar_o_que_nao_deu_para_ler(avisos)

	print("")
	print("um minuto sem compra possivel E sem acontecimento e um minuto em que a tela nao")
	print("muda e o jogador nao tem o que decidir. A regua nao ve isso.")


## Quantos avisos foram apagados antes de completarem AVISO_VISIVEL na tela.
##
## ⚠️ O NUMERO SAI DA CONSTANTE DA HUD, e nao de um 1,6 digitado aqui. Ela e um limite de
## design e pode mudar; copia-la criaria a segunda fonte, e a copia e sempre a que
## envelhece.
## Quantos avisos NAO chegaram a ficar o tempo minimo na tela.
##
## ⚠️ RODA A FILA DE VERDADE, com os instantes e as prioridades reais da partida. Medir
## "quantos eventos caem a menos de 1,6 s um do outro" mediria a ENTRADA -- e a entrada nao
## muda com a issue #69. O que muda e o que a fila faz com eles.
##
## O piso e AVISO_VISIVEL, e nao a duracao de cada prioridade: interessa quantos nao
## alcancaram nem o minimo. Medir cada um contra a propria duracao daria um numero melhor e
## menos honesto.
func _contar_o_que_nao_deu_para_ler(avisos: Array[Dictionary]) -> void:
	var piso: float = preload("res://src/ui/hud.gd").AVISO_VISIVEL
	avisos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["instante"]) < float(b["instante"]))

	var fila := FilaDeAvisos.new()
	var relogio := 0.0
	var visto := {}
	var curtos := 0
	var mostrados := 0

	for aviso in avisos:
		# anda o relogio da fila ate o instante deste aviso, contando quanto tempo o que
		# estava na tela ficou la
		var ate: float = float(aviso["instante"])
		while relogio < ate:
			var passo := minf(0.05, ate - relogio)
			var antes := fila.texto_atual()
			# ⚠️ ACUMULA ANTES DE TICAR. Somando depois, o ultimo passo do aviso se perde:
			# um aviso de exatamente 1,6 s contava 1,55 e entrava como curto. Isso sozinho
			# inflava o resultado de 15% para 40% -- erro DA MEDICAO, e o quarto desta
			# familia nesta sessao.
			if not antes.is_empty():
				visto[antes] = float(visto.get(antes, 0.0)) + passo
			if fila.tique(passo) and not antes.is_empty():
				mostrados += 1
				# a tolerancia e do float, e nao folga de design: 1,6 acumulado em passos
				# de 0,05 nao da exatamente 1,6
				if float(visto[antes]) < piso - 0.001:
					curtos += 1
			relogio += passo
		fila.acrescentar("aviso %d" % mostrados, int(aviso["prioridade"]), ate)

	print("")
	print("⚠️ avisos que a fila entregou:               %d de %d" % [mostrados, avisos.size()])
	print("⚠️ que nao ficaram os %.1f s minimos:         %d  (%.0f%%)" % [
		piso, curtos, 0.0 if mostrados == 0 else 100.0 * float(curtos) / float(mostrados),
	])
	print("   medido rodando FilaDeAvisos com os instantes e prioridades reais da partida.")
	print("   o autosave nao entra: desde a issue #69 ele e um icone, e nao apaga texto.")


## Guarda a tela do minuto. ⚠️ ESPERA DOIS QUADROS ANTES: a HUD repinta no _process, e
## fotografar no mesmo quadro em que o laco creditou pega a tela com os numeros do minuto
## ANTERIOR -- uma foto que parece certa e esta um minuto atrasada.
func _fotografar(minuto: int) -> void:
	for i in 2:
		await get_tree().process_frame
	var imagem := get_viewport().get_texture().get_image()
	var caminho := "%s/min_%02d.png" % [PASTA_DAS_FOTOS, minuto]
	if imagem.save_png(caminho) != OK:
		printerr("FALHA  nao consegui guardar %s" % caminho)
		return
	print("        [foto do minuto %d]" % minuto)


## Apaga tudo que sobrou de uma execucao anterior. Partida nova quer dizer partida nova.
func _limpar_a_pasta(pasta: String) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir():
			DirAccess.remove_absolute(pasta + "/" + item)
		item = dir.get_next()
	dir.list_dir_end()


## Quantos upgrades a loja esta mostrando -- ja desbloqueados e ainda nao comprados.
func _quantos_na_loja() -> int:
	var quantos := 0
	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue
		quantos += 1
	return quantos


## ⚠️ QUANTOS DELES SAO "PROXIMO OBJETIVO" (issue #67). Esta e a coluna que faltava: "3 na
## loja" e "3 botoes apagados" eram o mesmo numero, e foi por isso que a tabela registrou
## como saudavel um minuto em que o jogador nao tinha o que fazer.
##
## Vitrine e oferta sao coisas diferentes: um item a 5% do custo e uma promessa distante;
## um a 70% e um alvo. O limiar sai da HUD, e nao de um numero digitado aqui.
func _quantos_perto() -> int:
	var perto: float = preload("res://src/ui/hud.gd").PERTO_O_BASTANTE
	var quantos := 0
	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue
		var custo := Grande.de_float(dados.custo)
		if custo.sinal() <= 0 or not custo.maior_que(Jogo.dinheiro):
			continue
		if Jogo.dinheiro.dividido(custo).para_float() >= perto:
			quantos += 1
	return quantos


## ⚠️ A PRIMEIRA VERSAO DESTA FERRAMENTA MEDIA A COISA ERRADA, e vale registrar porque o
## numero era convincente.
##
## Ela contava quantos upgrades estavam COMPRAVEIS no instante da medicao, e reportava "27
## de 30 minutos sem nenhuma compra possivel". O numero era real e a leitura era falsa: o
## jogador simulado varre a loja a cada ciclo de compra, entao no instante em que a medicao
## acontece tudo que dava para comprar ACABOU DE SER COMPRADO. Ela media a politica do
## jogador, e nao a oferta do jogo.
##
## O que substituiu: quantas compras de fato ACONTECERAM no minuto. Compra que aconteceu e
## um fato sobre o jogo; saldo no instante errado e um fato sobre o medidor.


func _vale_a_pena_digitar() -> bool:
	if not Economia.producao_automatica():
		return true
	if not bool(_perfil["digita_depois_da_automacao"]):
		return false
	var da_mao := Grande.de_float(
		float(_perfil["cliques_por_segundo"]) * Combo.multiplicador()
	)
	return da_mao.maior_que(Economia.producao_por_segundo())


func _comprar_o_que_der() -> void:
	for dados in Economia.upgrades():
		Economia.comprar_upgrade(dados.id)
	for automacao in Automacao.todas():
		Automacao.comprar(automacao.id)
	var proxima := Economia.proxima_maquina()
	if proxima != null:
		Economia.comprar_maquina(proxima.id)
	var sala := Economia.proxima_sala()
	if sala != null:
		Economia.expandir_sala(sala.id)
	var cabem := Economia.macacos_que_cabem()
	if cabem > 0:
		Economia.comprar_macacos(cabem)
