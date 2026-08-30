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

## A tela logica do jogo: display/window/size/viewport_* do project.godot.
const _TELA_DE_PROJETO := Vector2i(1920, 1080)

## Quadros ate um container terminar de ordenar os filhos dele.
const QUADROS_ATE_O_LAYOUT_ASSENTAR := 8

func _ready() -> void:
	# fixa a lingua como o runner faz, e pelo mesmo motivo: as opcoes moram em
	# user://opcoes.json, que e da INSTALACAO. Sem isto a fumaca roda no idioma em que o
	# jogo foi deixado, e uma volta na tela de opcoes quebraria a run sem nada ter mudado
	# no codigo. Portugues porque a chave da tabela de traducao E o texto em portugues.
	var locale_original := TranslationServer.get_locale()
	TranslationServer.set_locale("pt_BR")

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

	# e o outro extremo da mesma tela: o FIM. Cruzado O Macaco Infinito nao entra silhueta
	# nenhuma abaixo dele -- e a ausencia dessa linha que fecha o jogo (issue #33)
	var total_antes_do_fim := Jogo.total_caracteres
	var alcancados_antes_do_fim := Jogo.marcos_alcancados.duplicate()
	Jogo.total_caracteres = Marcos.todos()[-1].requisito_grande()
	Marcos.verificar()
	panorama.call("abrir")
	await get_tree().process_frame
	if Marcos.proximo() != null:
		_falhar("cruzado o ultimo marco ainda sobrou um proximo")
		return
	if lista.get_child_count() != Marcos.todos().size():
		_falhar("o Panorama do fim tem %d linhas para %d marcos -- sobrou silhueta" % [
			lista.get_child_count(), Marcos.todos().size(),
		])
		return
	if Marcos.atual().id != "o_macaco_infinito":
		_falhar("o marco do fim nao e O Macaco Infinito, e sim %s" % Marcos.atual().id)
		return

	# e volta ao estado de antes: a fumaca continua jogando dali
	Jogo.total_caracteres = total_antes_do_fim
	Jogo.marcos_alcancados = alcancados_antes_do_fim
	panorama.call("abrir")
	await get_tree().process_frame

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

	# 9. um evento dispara, mexe na producao e a producao volta ao normal (issue #27)
	#
	# ⚠️ SEM await ENTRE LIMPAR E MEDIR. A Partida sorteia evento todo quadro, e a
	# primeira versao deste bloco mediu a producao com uma Tecla Presa que tinha nascido
	# sozinha no meio -- razao 25 onde se esperava 1. Evento aleatorio dentro de uma
	# medicao e a mesma armadilha da semente da descoberta, com outro nome.
	# o total vai a ZERO de proposito durante este bloco: abaixo do requisito de eventos o
	# sorteio nao roda, e a run controla quais eventos existem. Sem isso, tique() com um
	# delta grande expira o evento E sorteia outro no mesmo passo -- inclusive o mesmo que
	# acabou de expirar -- e a afirmacao vira cara ou coroa.
	var total_antes_dos_eventos := Jogo.total_caracteres
	Jogo.total_caracteres = Grande.zero()
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	Eventos.limpar()
	var producao_normal := Economia.producao_por_segundo()

	var inspirado := Eventos.de("macaco_inspirado")
	if inspirado == null or not Eventos.comecar(inspirado.id):
		_falhar("nao deu para disparar o Macaco Inspirado")
		return
	if not Economia.producao_por_segundo().maior_que(producao_normal):
		_falhar("o evento nao mexeu na producao")
		return

	Eventos.tique(inspirado.duracao + 1.0)
	if Eventos.ativo(inspirado.id):
		_falhar("o evento nao expirou depois da duracao dele")
		return
	if not Economia.producao_por_segundo().igual_a(producao_normal):
		_falhar("a producao nao voltou ao normal: %s contra %s" % [
			Economia.producao_por_segundo().para_texto(), producao_normal.para_texto(),
		])
		return

	# e a saida pela acao do jogador funciona
	var banana := Eventos.de("banana_na_maquina")
	if banana == null or not Eventos.comecar(banana.id):
		_falhar("nao deu para disparar a Banana na Maquina")
		return
	if not Eventos.resolver(banana.id):
		_falhar("clicar na banana nao resolveu o problema")
		return
	Eventos.limpar()
	if not Economia.producao_por_segundo().igual_a(producao_normal):
		_falhar("resolver o evento nao devolveu a producao")
		return
	Jogo.total_caracteres = total_antes_dos_eventos

	# 10. uma run com TUDO automatizado, sem travar (issue #28)
	Jogo.total_caracteres = Grande.new(1.0, 20)
	Jogo.dinheiro = Grande.new(1.0, 20)
	for dados in Automacao.todas():
		if not Automacao.comprar(dados.id):
			_falhar("nao deu para comprar a automacao %s" % dados.id)
			return
		if not Automacao.ligada(dados.id):
			_falhar("a automacao %s nao nasceu ligada" % dados.id)
			return
	Eventos.comecar("banana_na_maquina")
	var macacos_antes_da_automacao := Jogo.macacos
	for i in FRAMES:
		Automacao.tique(1.0)
		await get_tree().process_frame
	if not Jogo.macacos.maior_que(macacos_antes_da_automacao):
		_falhar("a run automatizada nao comprou macaco nenhum")
		return
	if Eventos.ativo("banana_na_maquina"):
		_falhar("o Diretor nao resolveu a punicao")
		return
	for dados in Automacao.todas():
		Automacao.alternar(dados.id)
		if Automacao.ligada(dados.id):
			_falhar("a automacao %s nao desligou" % dados.id)
			return

	# 11. o prestigio: o Teorema e provado e um no da Arvore muda a run seguinte
	#    (issues #24 e #25)
	var teoremas := raiz.find_child("TeoremasTela", true, false) as Control
	if teoremas == null:
		_falhar("a tela de Teoremas nao subiu junto da cena principal")
		return
	EventBus.teoremas_pedidos.emit()
	await get_tree().process_frame
	if not teoremas.visible:
		_falhar("a tela de Teoremas nao abriu com o pedido do EventBus")
		return
	teoremas.call("fechar")

	Economia.digitar(1000000000)
	if not Teoremas.pode_provar():
		_falhar("um bilhao de caracteres nao chegou para provar o Teorema")
		return
	# ⚠️ o prestigio GRAVA (issue #37). Perder um prestigio por um desligamento trinta
	# segundos depois dele nao e perder trinta segundos: e desfazer a decisao mais cara da
	# run. E grava UMA vez -- o cronometro reinicia junto com o gatilho.
	var aviso := hud.find_child("AvisoDeGravacao", true, false) as Label
	if aviso == null:
		_falhar("a HUD nao tem o aviso discreto de gravacao")
		return
	# a run ja atravessou era ate aqui, e trocar de era e gatilho de gravacao: espera o
	# aviso anterior sumir para que o que se mede a seguir seja o do prestigio. Que ele
	# suma sozinho tambem e afirmacao -- aviso que fica e popup sem moldura.
	if not await _esperar_o_aviso_sumir(aviso):
		return
	# ⚠️ conta numa lista, e nao num int: lambda de GDScript captura por VALOR, e um
	# contador inteiro voltaria zero com o sinal tendo chegado. Array e referencia.
	var gravacoes: Array[int] = []
	var contador := func() -> void: gravacoes.append(1)
	EventBus.jogo_gravado.connect(contador)

	var macacos_antes_do_reset := Jogo.macacos
	var ganhos := Teoremas.provar()
	EventBus.jogo_gravado.disconnect(contador)
	if ganhos.sinal() <= 0:
		_falhar("provar o Teorema nao rendeu ponto nenhum")
		return
	if not macacos_antes_do_reset.maior_que(Jogo.macacos):
		_falhar("provar o Teorema nao reiniciou a contagem de macacos")
		return
	if gravacoes.size() != 1:
		_falhar("provar o Teorema gravou %d vezes em vez de uma" % gravacoes.size())
		return
	if not Save.existe():
		_falhar("o prestigio gravou, mas nao ha arquivo em disco")
		return

	# e o aviso e AVISO: aparece, nao rouba foco, nao e popup, e some sozinho
	if not aviso.visible:
		_falhar("gravar nao mostrou o aviso na HUD")
		return
	if get_viewport().gui_get_focus_owner() != null:
		_falhar("o aviso de gravacao roubou o foco de alguem")
		return
	if not await _esperar_o_aviso_sumir(aviso):
		return

	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	var sem_arvore := Economia.producao_por_segundo()
	if not Teoremas.comprar("memoria_genetica"):
		_falhar("nao deu para comprar o no da Arvore com %s pontos" % [
			Jogo.pontos_de_teorema.para_texto(),
		])
		return
	if not Economia.producao_por_segundo().maior_que(sem_arvore):
		_falhar("o no da Arvore nao mudou a producao da run seguinte")
		return

	# 12. o segundo prestigio: Reescrever o Universo apaga a Arvore e devolve Fragmentos
	#     (issue #31)
	Jogo.pontos_totais = Grande.de_float(1e6)
	Jogo.pontos_de_teorema = Grande.de_float(1e6)
	if not Teoremas.comprar("memoria_genetica"):
		_falhar("nao deu para comprar um no da Arvore antes de reescrever")
		return
	var total_antes_da_reescrita := Jogo.total_caracteres
	var marcos_antes_da_reescrita := Jogo.marcos_alcancados.size()
	if not Fragmentos.pode_reescrever():
		_falhar("um milhao de pontos nao chegou para reescrever o Universo")
		return
	if Fragmentos.reescrever().sinal() <= 0:
		_falhar("reescrever o Universo nao rendeu Fragmento nenhum")
		return
	if not Jogo.teoremas.is_empty() or not Jogo.pontos_totais.e_zero():
		_falhar("reescrever nao apagou a Arvore e os pontos")
		return
	if not Jogo.total_caracteres.igual_a(total_antes_da_reescrita):
		_falhar("reescrever apagou o total do Panorama, que devia sobreviver")
		return
	if Jogo.marcos_alcancados.size() != marcos_antes_da_reescrita:
		_falhar("reescrever apagou os marcos alcancados")
		return

	# a run recomeca do zero depois da reescrita, e a fumaca segue jogando dali -- que e
	# exatamente o que o jogador faz
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)

	# 13. a sala enche e a expansao libera vaga (issue #15)
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

	# 14. gravar, sujar tudo e carregar: o estado tem que voltar identico
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

	# 15. a tela de opcoes troca idioma e resolucao SEM ERRO (issue #34)
	#
	#     A suite ja prova as regras do Config. O que so a fumaca prova e que a tela existe,
	#     abre, e que mexer nela mexe no jogo -- e que a HUD atras dela sobrevive a troca de
	#     idioma, que e o momento em que rotulo montado em codigo fica para tras.
	var opcoes := raiz.find_child("OpcoesTela", true, false) as Control
	if opcoes == null:
		_falhar("a tela de opcoes nao subiu junto da cena principal")
		return
	if opcoes.visible:
		_falhar("a tela de opcoes comecou aberta")
		return

	var caminho_de_opcoes := Config.caminho
	var modelo_de_slot := Config.modelo_de_slot
	var caminho_de_save := Save.caminho
	var idioma_antes := Config.idioma()
	Config.caminho = "user://fumaca_opcoes.json"
	Config.modelo_de_slot = "user://fumaca_slot_%d.json"

	EventBus.opcoes_pedidas.emit()
	await get_tree().process_frame
	if not opcoes.visible:
		_falhar("a tela de opcoes nao abriu com o pedido do EventBus")
		return

	var campos := opcoes.find_child("Lista", true, false) as Control
	# um bloco por campo de lista, mais o volume
	if campos == null or campos.get_child_count() != Config.CAMPOS.size() + 1:
		_falhar("a tela de opcoes montou %s blocos para %d campos" % [
			"nenhum" if campos == null else str(campos.get_child_count()),
			Config.CAMPOS.size() + 1,
		])
		return

	# trocar de idioma pelos botoes da tela, e a HUD atras tem que acompanhar
	var destino := 1 if Config.idioma() == "pt_BR" else 0
	Config.escolher("idioma", destino)
	await get_tree().process_frame
	if TranslationServer.get_locale() == idioma_antes:
		_falhar("escolher outro idioma nao mudou o locale")
		return
	if hud.find_child("BotaoOpcoes", true, false) == null:
		_falhar("a HUD perdeu o botao de opcoes depois da troca de idioma")
		return

	# e trocar de resolucao nao pode oferecer nada maior que o monitor
	var monitor := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	for tamanho in Config.resolucoes():
		if monitor.x > 0 and (tamanho.x > monitor.x or tamanho.y > monitor.y):
			_falhar("a tela ofereceu %dx%d num monitor de %dx%d" % [
				tamanho.x, tamanho.y, monitor.x, monitor.y,
			])
			return
	Config.escolher("resolucao", 0)
	Config.escolher("idioma", 0 if idioma_antes == "pt_BR" else 1)
	await get_tree().process_frame

	opcoes.call("fechar")
	await get_tree().process_frame
	if opcoes.visible:
		_falhar("a tela de opcoes nao fechou")
		return

	for numero in range(1, Config.SLOTS + 1):
		var caminho_do_slot := Config.caminho_do_slot(numero)
		if FileAccess.file_exists(caminho_do_slot):
			DirAccess.remove_absolute(caminho_do_slot)
	if FileAccess.file_exists(Config.caminho):
		DirAccess.remove_absolute(Config.caminho)
	Config.caminho = caminho_de_opcoes
	Config.modelo_de_slot = modelo_de_slot
	Save.caminho = caminho_de_save

	# 16. ⚠️ NADA VAZA PARA FORA DA TELA, com a loja no pior caso que o jogo produz.
	#
	#     Depois de um prestigio o jogador tem total alto e NENHUM upgrade comprado: os
	#     vinte aparecem de uma vez na coluna da loja. Sem rolagem, a altura minima da
	#     coluna passava da tela inteira, e MarginContainer cresce para os dois lados --
	#     medido em 1617 px de conteudo numa tela de 1080, com a lista comecando em
	#     y = -268. Os botoes do topo saiam por cima, a loja saia por baixo, e as bordas
	#     dos tres paineis ficavam fora da imagem.
	#
	#     Vale em qualquer resolucao porque a tela logica e sempre a mesma (1920x1080,
	#     canvas_items): o que quebrava nao era a resolucao, era a altura do conteudo.
	var total_antes_do_layout := Jogo.total_caracteres
	var dinheiro_antes_do_layout := Jogo.dinheiro
	var upgrades_antes_do_layout := Jogo.upgrades_comprados.duplicate()
	Jogo.total_caracteres = Grande.new(1.0, 60)
	Jogo.dinheiro = Grande.new(1.0, 60)
	Jogo.upgrades_comprados = [] as Array[String]
	EventBus.idioma_mudou.emit(Config.idioma())

	# ⚠️ A TELA LOGICA E FIXADA NA DO PROJETO ANTES DE MEDIR. Headless nao tem janela e cai
	# no window_*_override de 1280x720; com aspect=expand isso vira uma area logica de
	# 1920x1920 -- meio ecra a mais de altura, exatamente na direcao em que o defeito
	# acontece. A primeira versao deste portao passou com a cena quebrada na frente dele
	# por causa disso, que e a unica coisa pior do que nao ter portao.
	get_window().size = _TELA_DE_PROJETO
	get_window().content_scale_size = _TELA_DE_PROJETO

	# ⚠️ E MAIS DE UM QUADRO. Container ordena filho de forma diferida: medir no quadro
	# seguinte ao remontar a loja mede o layout ANTERIOR.
	for i in QUADROS_ATE_O_LAYOUT_ASSENTAR:
		await get_tree().process_frame

	var vazando := _controles_fora_da_tela()
	if not vazando.is_empty():
		_falhar("%d controles vazaram para fora da tela, a comecar por %s" % [
			vazando.size(), ", ".join(vazando.slice(0, 4)),
		])
		return

	# a run continua de onde estava: a producao offline logo abaixo precisa do Instinto
	# Digitador, e a loja cheia foi um cenario montado, nao o estado da partida
	Jogo.total_caracteres = total_antes_do_layout
	Jogo.dinheiro = dinheiro_antes_do_layout
	Jogo.upgrades_comprados = upgrades_antes_do_layout
	EventBus.idioma_mudou.emit(Config.idioma())
	await get_tree().process_frame

	# 17. quatro horas offline. O relogio e ARGUMENTO, entao o teste acelera em vez de
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
	TranslationServer.set_locale(locale_original)
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


## Todo Control visivel que passa da area da tela, pelo nome.
##
## Conteudo dentro de um ScrollContainer nao conta: ele passar da area e o motivo de a
## rolagem existir, e o proprio ScrollContainer recorta o que sobra. O que nao pode e a
## MOLDURA vazar -- painel, coluna e barra de botoes tem que caber.
##
## Layout nao e desenho: headless calcula retangulo de Control normalmente, entao este
## portao roda na fumaca sem precisar de janela.
func _controles_fora_da_tela() -> PackedStringArray:
	var tela := get_viewport().get_visible_rect()
	var vazando := PackedStringArray()
	for no in get_tree().root.find_children("*", "Control", true, false):
		var controle := no as Control
		if not controle.is_visible_in_tree() or _dentro_de_rolagem(controle):
			continue
		var area := controle.get_global_rect()
		if area.size.x <= 0.0 or area.size.y <= 0.0:
			continue
		# uma folga de um pixel: arredondamento de layout nao e vazamento
		if not tela.grow(1.0).encloses(area):
			vazando.append("%s %s" % [controle.name, area])
	return vazando


func _dentro_de_rolagem(controle: Control) -> bool:
	var pai := controle.get_parent()
	while pai != null:
		if pai is ScrollContainer:
			return true
		pai = pai.get_parent()
	return false


## Espera o aviso de gravacao sumir sozinho. Devolve se ele sumiu -- aviso que fica na tela
## para sempre e popup sem moldura, e o teto existe para a fumaca falhar em vez de travar.
func _esperar_o_aviso_sumir(aviso: Label) -> bool:
	var ate := Time.get_ticks_msec() + 8000
	while aviso.visible and Time.get_ticks_msec() < ate:
		await get_tree().process_frame
	if aviso.visible:
		_falhar("o aviso de gravacao nao sumiu sozinho")
		return false
	return true


func _falhar(motivo: String) -> void:
	printerr("FALHA  %s" % motivo)
	print("FALHOU")
	get_tree().quit(1)
