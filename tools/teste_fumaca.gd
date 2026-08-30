## Teste de fumaca: responde "a run inteira funciona?", nao "a conta esta certa?".
##
##   godot --headless --path . tools/teste_fumaca.tscn
##
## Sobe a cena principal de verdade e joga a run da v0.1 inteira: o macaco que nao digita
## sozinho, os cliques ate juntar o Instinto Digitador, a compra, a producao automatica, a
## loja, o primeiro marco caindo, o Panorama, a ida e volta pelo save e quatro horas
## offline. E o unico teste que prova a LIGACAO entre as pecas -- a suite unitaria provaria
## as mesmas contas com a cena inteira desligada.
##
## O relogio e ACELERADO e nao esperado: as quatro horas offline entram como argumento.
## Esperar quatro horas para provar quatro horas e exatamente o motivo de essa conta nunca
## ser testada em lugar nenhum.
##
## Headless nao renderiza: nao ha afirmacao sobre pixel aqui. Isso e assunto de captura.
##
## O clique entra por Input.parse_input_event e nao chamando Economia.digitar direto, de
## proposito: assim ele passa pelo _unhandled_input da Partida, que e justamente o pedaco
## que nenhuma suite unitaria alcanca.
##
## Cresce a cada sistema (loja, marcos, save, prestigio). Escrever as etapas antes dos
## sistemas seria cerimonia.
extends Node

const FRAMES := 120
const CLIQUES := 12
const UPGRADE_INICIAL := "instinto_digitador"
const CAMINHO_DO_SAVE := "user://teste_fumaca_save.json"
const HORAS_OFFLINE := 4.0

func _ready() -> void:
	# arquivo proprio e apagado ANTES de a cena subir: a Partida carrega o save no _ready,
	# e sem isto a run de fumaca leria -- e sobrescreveria -- a partida de quem desenvolve
	Save.caminho = CAMINHO_DO_SAVE
	Save.apagar()

	var caminho: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if caminho.is_empty():
		_falhar("nenhuma cena principal configurada em application/run/main_scene")
		return

	var empacotada := load(caminho) as PackedScene
	if empacotada == null:
		_falhar("cena principal %s nao carregou" % caminho)
		return

	var raiz := empacotada.instantiate()
	if raiz == null:
		_falhar("cena principal %s nao instanciou" % caminho)
		return

	add_child(raiz)
	await get_tree().process_frame

	# 1. o macaco ainda nao sabe digitar sozinho (GDD §3)
	if not Jogo.caracteres_por_segundo.e_zero():
		_falhar("a producao automatica ja estava ligada antes do Instinto Digitador")
		return
	if Economia.producao_automatica():
		_falhar("producao_automatica() e verdadeira sem nenhum upgrade comprado")
		return

	# 2. cada clique vale +1 caractere, e a tecla vale tanto quanto o mouse -- metade por
	# cada caminho, porque sao dois ramos diferentes do _unhandled_input e um deles pode
	# quebrar sozinho
	for i in CLIQUES:
		if i % 2 == 0:
			_apertar(&"ui_accept")
		else:
			_clicar()
		await get_tree().process_frame
	if not Jogo.total_caracteres.igual_a(Grande.de_float(float(CLIQUES))):
		_falhar("%d cliques deveriam dar %d caracteres, deram %s" % [
			CLIQUES, CLIQUES, Jogo.total_caracteres.para_texto(),
		])
		return

	# 3. a compra que vira o jogo do avesso
	var custo := Economia.upgrade_de(UPGRADE_INICIAL)
	if custo == null:
		_falhar("o upgrade %s nao esta em data/upgrades/" % UPGRADE_INICIAL)
		return
	if not Economia.comprar_upgrade(UPGRADE_INICIAL):
		_falhar("nao deu para comprar %s com %s de saldo" % [
			UPGRADE_INICIAL, Jogo.dinheiro.para_texto(),
		])
		return
	if not Jogo.dinheiro.igual_a(Grande.de_float(float(CLIQUES) - custo.custo)):
		_falhar("o troco saiu errado: %s" % Jogo.dinheiro.para_texto())
		return

	# 4. a partir daqui o jogo produz sozinho -- e o que a issue #6 pede para provar
	var antes := Jogo.total_caracteres
	for i in FRAMES:
		await get_tree().process_frame

	if not is_instance_valid(raiz):
		_falhar("cena principal morreu antes de %d frames" % FRAMES)
		return
	if Jogo.caracteres_por_segundo.sinal() <= 0:
		_falhar("o cps continuou zero depois do Instinto Digitador")
		return
	if not Jogo.total_caracteres.maior_que(antes):
		_falhar("o total nao cresceu em %d frames de producao automatica" % FRAMES)
		return

	# 5. a HUD subiu junto e os botoes dela mexem no jogo de verdade (issue #7)
	var hud := raiz.find_child("HUD", true, false)
	if hud == null:
		_falhar("a HUD nao subiu junto da cena principal")
		return

	var digitar := hud.find_child("BotaoDigitar", true, false) as Button
	if digitar == null:
		_falhar("a HUD nao tem BotaoDigitar")
		return
	var antes_do_botao := Jogo.total_caracteres
	digitar.pressed.emit()
	if not Jogo.total_caracteres.maior_que(antes_do_botao):
		_falhar("o botao DIGITAR nao produziu nada")
		return

	var comprar := hud.find_child("Comprar1", true, false) as Button
	if comprar == null:
		_falhar("a loja nao tem o botao Comprar 1")
		return
	# saldo suficiente para o macaco, sem depender de quanto a producao ja rendeu
	Economia.digitar(1000)
	var macacos_antes := Jogo.macacos
	var dinheiro_antes := Jogo.dinheiro
	comprar.pressed.emit()
	if not Jogo.macacos.maior_que(macacos_antes):
		_falhar("comprar 1 macaco na loja nao aumentou a contagem")
		return
	if not dinheiro_antes.maior_que(Jogo.dinheiro):
		_falhar("comprar 1 macaco na loja nao cobrou nada")
		return

	await get_tree().process_frame
	if not Jogo.caracteres_por_segundo.maior_que(Grande.um()):
		_falhar("o macaco comprado nao apareceu na producao")
		return

	# 6. o Panorama abre, e abre com os tres estados montados (issue #11)
	var panorama := raiz.find_child("Panorama", true, false) as Control
	if panorama == null:
		_falhar("o Panorama nao subiu junto da cena principal")
		return
	if panorama.visible:
		_falhar("o Panorama comecou aberto")
		return

	# os primeiros marcos ja podem ter caido com os cliques e a compra la atras, entao o
	# que se conta aqui e o SALTO: todo cruzamento emite exatamente um sinal, nem mais
	var ja_alcancados := Jogo.marcos_alcancados.size()
	var cruzados: Array[String] = []
	var ouvinte := func(marco: DadosMarco) -> void: cruzados.append(marco.id)
	EventBus.marco_alcancado.connect(ouvinte)
	Economia.digitar(2000)
	Marcos.verificar()
	EventBus.marco_alcancado.disconnect(ouvinte)
	if cruzados.is_empty():
		_falhar("dois mil caracteres nao dispararam marco nenhum no EventBus")
		return
	if cruzados.size() != Jogo.marcos_alcancados.size() - ja_alcancados:
		_falhar("o EventBus emitiu %d sinais para %d marcos novos na lista" % [
			cruzados.size(), Jogo.marcos_alcancados.size() - ja_alcancados,
		])
		return

	EventBus.panorama_pedido.emit()
	await get_tree().process_frame
	if not panorama.visible:
		_falhar("o Panorama nao abriu com o pedido do EventBus")
		return

	var lista := panorama.find_child("Lista", true, false) as Control
	if lista == null or lista.get_child_count() < Jogo.marcos_alcancados.size() + 1:
		_falhar("o Panorama abriu sem os alcancados mais a silhueta do proximo")
		return

	panorama.call("fechar")
	await get_tree().process_frame
	if panorama.visible:
		_falhar("o Panorama nao fechou")
		return

	# 7. a tela de Descobertas abre com o catalogo inteiro -- achadas e buracos (issue #17)
	var tela := raiz.find_child("DescobertasTela", true, false) as Control
	if tela == null:
		_falhar("a tela de Descobertas nao subiu junto da cena principal")
		return
	if tela.visible:
		_falhar("a tela de Descobertas comecou aberta")
		return
	EventBus.descobertas_pedidas.emit()
	await get_tree().process_frame
	if not tela.visible:
		_falhar("a tela de Descobertas nao abriu com o pedido do EventBus")
		return
	var catalogo := tela.find_child("Lista", true, false) as Control
	if catalogo == null or catalogo.get_child_count() != Descobertas.todas().size():
		_falhar("a tela nao listou o catalogo inteiro, com achadas e buracos")
		return
	tela.call("fechar")
	await get_tree().process_frame

	# 8. a tela de Estatisticas abre com as uteis e as inuteis (issue #21)
	var estatisticas := raiz.find_child("EstatisticasTela", true, false) as Control
	if estatisticas == null:
		_falhar("a tela de Estatisticas nao subiu junto da cena principal")
		return
	EventBus.estatisticas_pedidas.emit()
	await get_tree().process_frame
	if not estatisticas.visible:
		_falhar("a tela de Estatisticas nao abriu com o pedido do EventBus")
		return
	var linhas := estatisticas.find_child("Lista", true, false) as Control
	var esperadas := (
		Estatisticas.uteis().size() + Estatisticas.tempos().size()
		+ Estatisticas.inuteis().size() + 1
	)
	if linhas == null or linhas.get_child_count() != esperadas:
		_falhar("a tela de Estatisticas listou %d linhas em vez de %d" % [
			linhas.get_child_count() if linhas != null else -1, esperadas,
		])
		return
	estatisticas.call("fechar")
	await get_tree().process_frame

	# 9. a sala enche e a expansao libera vaga (issue #15)
	var sala := Economia.sala_atual()
	Economia.digitar(100000)
	Economia.comprar_macacos(Economia.macacos_que_cabem())
	if not Economia.vagas_livres().e_zero():
		_falhar("comprar o maximo nao encheu a sala")
		return
	if Economia.comprar_macacos(1) != 0:
		_falhar("com a sala cheia ainda deu para comprar mais um macaco")
		return

	var proxima_sala := Economia.proxima_sala()
	if proxima_sala == null:
		_falhar("nao ha proxima sala para expandir")
		return
	if not Economia.expandir_sala(proxima_sala.id):
		_falhar("nao deu para expandir a sala com %s de saldo" % Jogo.dinheiro.para_texto())
		return
	var liberou := Economia.vagas_livres().para_float()
	var diferenca := proxima_sala.capacidade - sala.capacidade
	if absf(liberou - diferenca) > 0.5:
		_falhar("expandir liberou %s vagas em vez de %s" % [liberou, diferenca])
		return

	# 10. gravar, sujar tudo e carregar: o estado tem que voltar identico
	var total_antes := Jogo.total_caracteres
	var macacos_no_save := Jogo.macacos
	var upgrades_antes := Jogo.upgrades_comprados.size()
	var marcos_antes := Jogo.marcos_alcancados.size()
	if not Save.gravar():
		_falhar("nao gravou o save")
		return

	Jogo.total_caracteres = Grande.zero()
	Jogo.macacos = Grande.zero()
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]

	if Save.carregar() <= 0.0:
		_falhar("carregar nao devolveu o timestamp da gravacao")
		return
	if not Jogo.total_caracteres.igual_a(total_antes):
		_falhar("o total voltou diferente: %s em vez de %s" % [
			Jogo.total_caracteres.para_texto(), total_antes.para_texto(),
		])
		return
	if not Jogo.macacos.igual_a(macacos_no_save):
		_falhar("a contagem de macacos voltou diferente")
		return
	if Jogo.upgrades_comprados.size() != upgrades_antes:
		_falhar("os upgrades comprados nao voltaram")
		return
	if Jogo.marcos_alcancados.size() != marcos_antes:
		_falhar("os marcos alcancados nao voltaram")
		return

	# 11. quatro horas offline. O relogio e ARGUMENTO, entao o teste acelera em vez de
	# esperar -- esperar 4 h para provar 4 h e o motivo de essa conta nunca ser testada
	var antes_do_offline := Jogo.total_caracteres
	var creditado := Economia.creditar_offline(HORAS_OFFLINE * 3600.0)
	if creditado.sinal() <= 0:
		_falhar("quatro horas fora nao creditaram nada")
		return
	if not Jogo.total_caracteres.igual_a(antes_do_offline.mais(creditado)):
		_falhar("o credito offline nao bateu com o total")
		return

	Save.apagar()
	print("PASSOU (%d cliques, %s comprado, %d marcos, save ida e volta, %s de %.0f h offline)" % [
		CLIQUES, UPGRADE_INICIAL, Jogo.marcos_alcancados.size(),
		Formatador.formatar(creditado), HORAS_OFFLINE,
	])
	get_tree().quit(0)


func _apertar(acao: StringName) -> void:
	var apertar := InputEventAction.new()
	apertar.action = acao
	apertar.pressed = true
	Input.parse_input_event(apertar)

	var soltar := InputEventAction.new()
	soltar.action = acao
	soltar.pressed = false
	Input.parse_input_event(soltar)


func _clicar() -> void:
	var apertar := InputEventMouseButton.new()
	apertar.button_index = MOUSE_BUTTON_LEFT
	apertar.pressed = true
	Input.parse_input_event(apertar)

	var soltar := InputEventMouseButton.new()
	soltar.button_index = MOUSE_BUTTON_LEFT
	soltar.pressed = false
	Input.parse_input_event(soltar)


func _falhar(motivo: String) -> void:
	printerr("FALHA  %s" % motivo)
	print("FALHOU")
	get_tree().quit(1)
