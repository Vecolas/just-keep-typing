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

## O nome que a fumaca escreve no campo ao criar o Manuscrito. Nao passa por tr(): e texto
## do JOGADOR, e nao texto de jogo -- o que se prova e que ele chega ao cartao como foi
## escrito.
const NOME_DO_MANUSCRITO := "Fumaça"
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

	# ⚠️ ARQUIVOS PROPRIOS ANTES DE A CENA SUBIR. O caminho inteiro passa pelo Config desde
	# a issue #38: Cenas.comecar_partida aponta o Save pelo SLOT, entao redirecionar so na
	# hora da tela de opcoes deixaria a fumaca escrevendo nos arquivos de quem desenvolve
	# desde o primeiro passo dela.
	var caminho_de_opcoes := Config.caminho
	var modelo_de_slot := Config.modelo_de_slot
	var caminho_de_save := Save.caminho
	Config.caminho = "user://fumaca_opcoes.json"
	Config.modelo_de_slot = "user://fumaca_slot_%d.json"
	# ⚠️ E O ARQUIVO DE OPCOES COMECA DO ZERO. Sem apaga-lo, a run herda o
	# `ja_viu_abertura` da run ANTERIOR: a abertura seria pulada, o passo 0 dela nunca
	# rodaria, e a fumaca passaria dizendo que provou o que nao provou (issue #47).
	if FileAccess.file_exists(Config.caminho):
		DirAccess.remove_absolute(Config.caminho)
	Config.carregar()
	for numero in range(1, Config.SLOTS + 1):
		Save.caminho = Config.caminho_do_slot(numero)
		Save.apagar()
	Save.caminho = Config.caminho_do_slot(1)

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

	# 0. A ABERTURA (issue #47): instalacao nova ve; quem ja viu pula NA HORA.
	#
	#    ⚠️ Os dois lados sao afirmados. So provar que ela aparece deixaria passar uma
	#    abertura que aparece SEMPRE -- que e o pedagio que a issue existe para impedir.
	if Cenas.atual() != "abertura":
		_falhar("instalacao nova nao viu a abertura, e sim %s" % Cenas.atual())
		return
	var abertura := raiz.find_child("Abertura", true, false)
	if abertura == null:
		_falhar("o Cenas disse abertura mas nao montou a cena")
		return
	if abertura.call("duracao") < 2.0 or abertura.call("duracao") > 4.0:
		_falhar("a abertura dura %.1f s, e o plano pede de dois a quatro" % abertura.call("duracao"))
		return
	var escrito_no_comeco: String = (
		abertura.find_child("TituloDatilografado", true, false) as Label
	).text

	# pular e QUALQUER tecla, e nao so o ESC
	_apertar(&"ui_down")
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("apertar uma tecla nao pulou a abertura, e sim ficou em %s" % Cenas.atual())
		return
	if escrito_no_comeco.strip_edges().length() > 2:
		_falhar("a abertura ja comecou escrita: \"%s\"" % escrito_no_comeco)
		return

	# ⚠️ E A SEGUNDA ABERTURA PULA SEM ESPERAR -- sem montar cena nenhuma.
	Cenas.ir_para_abertura()
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("a segunda abertura nao pulou: o jogo foi para %s" % Cenas.atual())
		return
	if raiz.find_child("Abertura", true, false) != null:
		_falhar("a segunda abertura montou a cena so para desmonta-la")
		return

	# 0.05. o menu vivo: os gestos existem, sao sorteados, e reduzir movimento para TUDO
	#       (issue #48). O relogio e adiantado, e nao esperado.
	if GestosDoMenu.GESTOS.is_empty():
		_falhar("nao ha gesto declarado para o menu vivo")
		return
	var gestos := GestosDoMenu.new()
	if not gestos.ligado():
		_falhar("com reduzir movimento desligado, os gestos deviam estar ligados")
		return
	var pegou_algum := false
	for i in 400:
		var estado := gestos.tique(0.05)
		if estado["macaco"]["desloca"] != Vector2.ZERO or estado["macaco"]["gira"] != 0.0:
			pegou_algum = true
		if estado["maquina"]["desloca"] != Vector2.ZERO:
			pegou_algum = true
	if not pegou_algum:
		_falhar("vinte segundos de menu e nenhum gesto aconteceu")
		return

	# 0.1. e com reduzir movimento ligado ela continua levando ao menu (issue #43)
	var movimento_antes := Config.indice_de("reduzir_movimento")
	Config.escolher("reduzir_movimento", 1)
	Config._opcoes["ja_viu_abertura"] = false
	Cenas.ir_para_abertura()
	await get_tree().process_frame
	var sem_movimento := raiz.find_child("Abertura", true, false)
	if sem_movimento == null:
		_falhar("com reduzir movimento a abertura nem apareceu")
		return
	if sem_movimento.call("revelando"):
		_falhar("reduzir movimento nao desligou a revelacao de camera")
		return
	# ⚠️ E NADA SE MEXE NO MENU VIVO. O controle da afirmacao acima: sem esta linha, um
	# `ligado()` que devolvesse sempre verdadeiro passaria em tudo.
	var parados := GestosDoMenu.new()
	if parados.ligado():
		_falhar("reduzir movimento nao desligou os gestos do menu")
		return
	for i in 200:
		var quieto := parados.tique(0.05)
		if quieto["macaco"]["desloca"] != Vector2.ZERO or quieto["maquina"]["desloca"] != Vector2.ZERO:
			_falhar("com reduzir movimento ligado, um gesto ainda aconteceu")
			return
	_apertar(&"ui_down")
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("com reduzir movimento a abertura nao levou ao menu")
		return
	Config.escolher("reduzir_movimento", movimento_antes)

	# 1. o caminho da issue #38: o Boot chega no menu, e do menu se chega a uma partida.
	#
	#    Os botoes sao APERTADOS, e nao contornados chamando o Cenas por baixo: o que esta
	#    sob prova aqui e a ligacao entre a tela e o caminho, e chamar o autoload direto
	#    provaria o autoload de novo e a tela nunca.
	if Cenas.atual() != "menu":
		_falhar("o Boot nao chegou no menu, e sim em %s" % Cenas.atual())
		return
	var menu := raiz.find_child("MenuTela", true, false)
	if menu == null:
		_falhar("o menu nao foi montado pelo Cenas")
		return
	var continuar := menu.find_child("BotaoContinuar", true, false) as Button
	if continuar == null or not continuar.disabled:
		_falhar("sem Manuscrito nenhum, o menu ofereceu CONTINUAR")
		return
	# e o resumo embaixo dele diz POR QUE, em vez de ficar vazio (issue #39)
	var resumo := menu.find_child("ResumoDoContinuar", true, false) as Label
	if resumo == null or resumo.text.strip_edges().is_empty():
		_falhar("o CONTINUAR apagado nao explicou que nao ha Manuscrito")
		return

	# as cinco opcoes existem, e todas alcancaveis pelo teclado: menu que so anda no mouse
	# e menu quebrado para quem joga no controle (issue #39)
	for nome_do_botao in [
		"BotaoContinuar", "BotaoJogar", "BotaoConfiguracoes", "BotaoCreditos", "BotaoSair",
	]:
		var opcao := menu.find_child(nome_do_botao, true, false) as Button
		if opcao == null:
			_falhar("o menu nao tem %s" % nome_do_botao)
			return
		if opcao.focus_mode != Control.FOCUS_ALL:
			_falhar("%s nao pega foco: o menu nao anda sem mouse" % nome_do_botao)
			return

	# ⚠️ E A NAVEGACAO ANDA DE VERDADE. "Pega foco" nao e o mesmo que "da para chegar la":
	# uma cadeia de vizinhos quebrada deixa cada botao focavel e nenhum alcancavel, e a
	# unica forma de perceber isso sem mouse e apertar a seta e olhar onde o foco foi
	# parar. CONTINUAR esta apagado neste ponto, entao o foco comeca em JOGAR.
	await get_tree().process_frame
	var focado_antes := menu.get_viewport().gui_get_focus_owner()
	if focado_antes == null or focado_antes.name != "BotaoJogar":
		_falhar("o menu abriu com o foco em %s, e nao no primeiro botao util" % [
			focado_antes.name if focado_antes != null else "ninguem",
		])
		return
	_apertar(&"ui_down")
	await get_tree().process_frame
	var focado_depois := menu.get_viewport().gui_get_focus_owner()
	if focado_depois == focado_antes or focado_depois == null:
		_falhar("a seta para baixo nao moveu o foco: o menu nao anda sem mouse")
		return

	# 0.06. ⚠️ O EASTER EGG DA TECLA NAO ENCOSTA NO SAVE (issue #49). A brincadeira e
	#       visual: a letra aparece na folha e o total de caracteres do jogo NAO muda. Esta
	#       e a metade que importa -- um bug aqui nao pode custar progresso a ninguem.
	var cenario := menu.find_child("Cenario", true, false) as CenarioDoMenu
	if cenario == null:
		_falhar("o menu nao montou o cenario")
		return
	var total_antes_do_easter_egg := Jogo.total_caracteres
	var dinheiro_antes_do_easter_egg := Jogo.dinheiro
	_teclar("b")
	_teclar("o")
	_teclar("m")
	await get_tree().process_frame
	if cenario.escrito_no_papel() != "bom":
		_falhar("a tecla do jogador nao virou letra no papel: \"%s\"" % cenario.escrito_no_papel())
		return
	if not Jogo.total_caracteres.igual_a(total_antes_do_easter_egg):
		_falhar("⚠️ o easter egg da tecla MEXEU no total de caracteres")
		return
	if not Jogo.dinheiro.igual_a(dinheiro_antes_do_easter_egg):
		_falhar("⚠️ o easter egg da tecla MEXEU no dinheiro")
		return

	# e a folha nao cresce para sempre: ela mostra o FIM do que foi escrito
	for i in CenarioDoMenu.LIMITE_DO_PAPEL + 6:
		_teclar("x")
	await get_tree().process_frame
	if cenario.escrito_no_papel().length() > CenarioDoMenu.LIMITE_DO_PAPEL:
		_falhar("a folha aceitou %d caracteres, e o limite e %d" % [
			cenario.escrito_no_papel().length(), CenarioDoMenu.LIMITE_DO_PAPEL,
		])
		return

	# o acontecimento raro do plano §24, disparado em vez de esperado
	var frase_rara := tr(CenarioDoMenu.FRASES_RARAS[0])
	cenario.escrever_sozinho(frase_rara)
	# ⚠️ SO ATE A ULTIMA LETRA, e nao "um tempao". A folha e arrancada sozinha depois de
	# alguns segundos (e ela tem que ser), entao adiantar demais mede a folha JA LIMPA e
	# reprova o codigo certo -- foi o que esta linha fez na primeira versao.
	for i in frase_rara.length() + 1:
		cenario.adiantar_o_papel(0.2)
	if cenario.escrito_no_papel() != frase_rara:
		_falhar("o macaco nao escreveu %s sozinho: \"%s\"" % [
			CenarioDoMenu.FRASES_RARAS[0], cenario.escrito_no_papel(),
		])
		return
	if not Jogo.total_caracteres.igual_a(total_antes_do_easter_egg):
		_falhar("⚠️ o acontecimento raro MEXEU no total de caracteres")
		return

	# CONFIGURAÇÕES e CRÉDITOS abrem por cima do menu, e o ESC fecha os dois
	if not await _abre_e_fecha(menu, "BotaoConfiguracoes", "OpcoesTela"):
		return
	if not await _abre_e_fecha(menu, "BotaoCreditos", "CreditosTela"):
		return

	(menu.find_child("BotaoJogar", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	if Cenas.atual() != "arquivos":
		_falhar("MANUSCRITOS nao levou aos Arquivos, e sim a %s" % Cenas.atual())
		return

	var arquivos := raiz.find_child("ArquivosTela", true, false)
	if arquivos == null:
		_falhar("a tela de Arquivos nao foi montada")
		return

	# 0.1. criar um Manuscrito com nome (issue #40). O nome entra pelo CAMPO e nao por
	#      Jogo.nome: o que esta sob prova e o caminho inteiro -- campo, limpeza, gravacao
	#      e cartao --, e escrever no autoload provaria o autoload e a tela nunca.
	var criar := arquivos.find_child("BotaoNovo1", true, false) as Button
	if criar == null:
		_falhar("o cartao do slot vazio nao oferece CRIAR")
		return
	criar.pressed.emit()
	await get_tree().process_frame

	var campo := arquivos.find_child("CampoDeNome1", true, false) as LineEdit
	if campo == null:
		_falhar("CRIAR nao abriu o campo de nome")
		return
	if campo.text.strip_edges().is_empty():
		_falhar("o campo de nome abriu sem sugestao nenhuma")
		return
	if campo.max_length != NomesDeManuscrito.LIMITE:
		_falhar("o campo de nome aceita mais do que o cartao mostra")
		return
	campo.text = NOME_DO_MANUSCRITO
	(arquivos.find_child("BotaoCriar1", true, false) as Button).pressed.emit()
	await get_tree().process_frame

	# ⚠️ ENTRAR PELOS ARQUIVOS NAO TEM APROXIMACAO, e isso e de proposito (issue #48): nao
	# ha mesa na tela de onde a camera possa partir, e inventar uma maquina saindo do nada
	# seria uma transicao que nao costura coisa nenhuma.
	if Cenas.aproximando():
		_falhar("a tela de Arquivos disparou a aproximacao da maquina")
		return

	if Cenas.atual() != "partida":
		_falhar("criar o Manuscrito 1 nao abriu a partida, e sim %s" % Cenas.atual())
		return
	if Jogo.nome != NOME_DO_MANUSCRITO:
		_falhar("o Manuscrito nasceu chamado \"%s\"" % Jogo.nome)
		return
	# criar e um gesto em que o jogador espera que o arquivo passe a existir: ele nao pode
	# depender do autosave de trinta segundos
	if not FileAccess.file_exists(Config.caminho_do_slot(1)):
		_falhar("criar o Manuscrito nao gravou nada no disco")
		return
	if raiz.find_child("MenuTela", true, false) != null:
		_falhar("o menu continuou montado depois de a partida abrir")
		return

	# 1. o macaco ainda nao sabe digitar sozinho (GDD §3)
	if not Jogo.caracteres_por_segundo.e_zero():
		_falhar("a producao automatica ja estava ligada antes do Instinto Digitador")
		return
	if Economia.producao_automatica():
		_falhar("producao_automatica() e verdadeira sem nenhum upgrade comprado")
		return

	# 2. cada clique produz, e a tecla vale tanto quanto o mouse -- metade por cada
	# caminho, porque sao dois ramos diferentes do _unhandled_input e um deles pode
	# quebrar sozinho
	#
	# ⚠️ ATE A ISSUE #54 ESTE NUMERO ERA EXATO: 12 cliques, 12 caracteres. Com o combo de
	# digitacao, cliques EM SEQUENCIA rendem mais que cliques isolados -- entao a
	# afirmacao passa a ser sobre a REGRA ("digitar acelera") e nao sobre o numero, que
	# agora depende da cadencia. Cravar o numero aqui faria esta fumaca reprovar o codigo
	# certo no primeiro tuning do teto.
	for i in CLIQUES:
		if i % 2 == 0:
			_apertar(&"ui_accept")
		else:
			_clicar()
		await get_tree().process_frame

	var so_dos_cliques := Jogo.total_caracteres
	if not so_dos_cliques.maior_que(Grande.de_float(float(CLIQUES - 1))):
		_falhar("%d cliques deveriam dar pelo menos %d caracteres, deram %s" % [
			CLIQUES, CLIQUES, so_dos_cliques.para_texto(),
		])
		return
	if not so_dos_cliques.maior_que(Grande.de_float(float(CLIQUES))):
		_falhar("%d cliques seguidos nao acumularam combo nenhum: %s" % [
			CLIQUES, so_dos_cliques.para_texto(),
		])
		return
	if Combo.multiplicador() <= 1.0:
		_falhar("o combo nao subiu depois de %d cliques seguidos" % CLIQUES)
		return

	# ⚠️ E A OUTRA METADE DA REGRA, que e a que importa: PARAR NAO PUNE. Depois da pausa o
	# combo volta a 1,0 e o clique continua valendo exatamente um caractere -- e nao menos
	# do que valia antes de existir combo.
	#
	# A pausa e simulada por Economia.acumular(), que e o mesmo tique do jogo. Sem
	# producao automatica ligada ele nao credita nada; so faz o tempo andar, que e o que
	# esta fumaca precisa. Esperar em tempo real custaria cinco segundos de suite.
	Economia.acumular(30.0)
	if not is_equal_approx(Combo.multiplicador(), 1.0):
		_falhar("parado 30 s, o combo ficou em x%.3f em vez de voltar a 1,0" % Combo.multiplicador())
		return

	var antes_do_clique_frio := Jogo.total_caracteres
	_clicar()
	await get_tree().process_frame
	var ganho := Jogo.total_caracteres.menos(antes_do_clique_frio)
	if not ganho.igual_a(Grande.um()):
		_falhar("o clique depois da pausa deu %s caracteres em vez de 1" % ganho.para_texto())
		return

	# 3. a compra que vira o jogo do avesso
	var custo := Economia.upgrade_de(UPGRADE_INICIAL)
	if custo == null:
		_falhar("o upgrade %s nao esta em data/upgrades/" % UPGRADE_INICIAL)
		return

	# ⚠️ MESMO MOTIVO DO NUMERO DE CIMA (issue #54): o saldo antes da compra deixou de ser
	# igual ao numero de cliques, porque o combo acelera. O troco passa a ser conferido
	# contra o SALDO MEDIDO um instante antes -- que e a regra de verdade ("comprar debita
	# exatamente o custo") e nao uma aritmetica que so valia enquanto clique valia um.
	var saldo_antes := Jogo.dinheiro
	if not Economia.comprar_upgrade(UPGRADE_INICIAL):
		_falhar("nao deu para comprar %s com %s de saldo" % [
			UPGRADE_INICIAL, saldo_antes.para_texto(),
		])
		return
	if not Jogo.dinheiro.igual_a(saldo_antes.menos(Grande.de_float(custo.custo))):
		_falhar("o troco saiu errado: %s de %s menos %s" % [
			Jogo.dinheiro.para_texto(), saldo_antes.para_texto(), custo.custo,
		])
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
	var aviso := hud.find_child("Aviso", true, false) as Label
	if aviso == null:
		_falhar("a HUD nao tem o aviso discreto do rodape")
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

	var idioma_antes := Config.idioma()

	EventBus.opcoes_pedidas.emit()
	await get_tree().process_frame
	if not opcoes.visible:
		_falhar("a tela de opcoes nao abriu com o pedido do EventBus")
		return

	# ⚠️ UM BLOCO POR CAMPO DECLARADO, ESPALHADOS PELAS ABAS (issue #41). A conta e por
	#    NOME e nao por contagem de filhos de um container: com abas, contar filhos mediria
	#    uma aba so -- e uma tabela que perdesse metade dos campos passaria.
	for linha in Config.CAMPOS:
		var bloco := opcoes.find_child("Campo_%s" % linha["nome"], true, false)
		if bloco == null:
			_falhar("a tela de opcoes nao montou o campo %s" % linha["nome"])
			return
		if opcoes.find_child("Controle_%s" % linha["nome"], true, false) == null:
			_falhar("o campo %s foi montado sem controle nenhum" % linha["nome"])
			return

	# e cada aba com campo virou uma aba de verdade, na ordem declarada
	var abas := opcoes.find_child("Abas", true, false) as TabContainer
	var abas_esperadas := 0
	for aba in Config.ABAS:
		if not Config.campos_da_aba(aba).is_empty():
			abas_esperadas += 1
	if abas == null or abas.get_tab_count() != abas_esperadas:
		_falhar("a tela de opcoes montou %s abas em vez de %d" % [
			"nenhuma" if abas == null else str(abas.get_tab_count()), abas_esperadas,
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

	# 16.1. E A MESMA CONTA NA MAIOR ESCALA OFERECIDA (issue #43). Escala de interface e
	#       escala de texto no maximo, as duas ao mesmo tempo: e o caso que estoura, e o
	#       aviso da issue vira portao aqui em vez de virar captura que alguem olha uma vez.
	#
	#       ⚠️ Se um dia a lista oferecer uma escala que nao cabe, esta linha reprova -- e o
	#       conserto e tirar a escala da lista, como a lista de resolucoes ja faz com o que
	#       nao cabe no monitor (issue #34).
	var escala_antes := Config.indice_de("escala_da_interface")
	var texto_antes := Config.indice_de("escala_do_texto")

	# ⚠️ TODA COMBINACAO OFERECIDA, e nao so a maior de cada uma. A lista de escala de
	# texto ENCOLHE conforme a escala de interface sobe (Config.escalas_do_texto), entao
	# medir so o par (maior, maior) mediria um par que o jogo nunca oferece junto.
	for i_interface in Config.rotulos_de("escala_da_interface").size():
		Config.escolher("escala_da_interface", i_interface)
		for i_texto in Config.rotulos_de("escala_do_texto").size():
			Config.escolher("escala_do_texto", i_texto)
			for i in QUADROS_ATE_O_LAYOUT_ASSENTAR:
				await get_tree().process_frame
			var vazando_na_escala := _controles_fora_da_tela()
			if not vazando_na_escala.is_empty():
				_falhar("interface %s + texto %s: %d controles vazaram, a comecar por %s" % [
					Config.rotulos_de("escala_da_interface")[i_interface],
					Config.rotulos_de("escala_do_texto")[i_texto],
					vazando_na_escala.size(), ", ".join(vazando_na_escala.slice(0, 3)),
				])
				return

	Config.escolher("escala_da_interface", escala_antes)
	Config.escolher("escala_do_texto", texto_antes)
	for i in QUADROS_ATE_O_LAYOUT_ASSENTAR:
		await get_tree().process_frame

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

	# 18. e o caminho fecha: o botao MENU grava e sai, e o CONTINUAR traz a partida de
	#     volta. E o unico jeito de provar que a saida da issue #37 e a entrada da #38 sao
	#     a mesma porta -- sair sem gravar perderia a run inteira que a fumaca acabou de
	#     jogar, e o teste ainda passaria em tudo que vem antes desta linha.
	var total_ao_sair := Jogo.total_caracteres
	var hud_menu := hud.find_child("BotaoMenu", true, false) as Button
	if hud_menu == null:
		_falhar("a HUD nao tem o botao de voltar ao menu")
		return
	hud_menu.pressed.emit()
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("o botao MENU nao saiu da partida, e sim ficou em %s" % Cenas.atual())
		return
	if raiz.find_child("HUD", true, false) != null:
		_falhar("a partida continuou montada depois de voltar ao menu")
		return

	var menu_de_volta := raiz.find_child("MenuTela", true, false)
	var continuar_de_volta := menu_de_volta.find_child("BotaoContinuar", true, false) as Button
	if continuar_de_volta.disabled:
		_falhar("com Manuscrito gravado, o menu ainda nao oferece CONTINUAR")
		return

	# ⚠️ O RESUMO SAI DO METADADO, e e por ele que se ve que o menu esta falando do slot
	# certo. Um CONTINUAR habilitado apontando para outro Manuscrito passaria em tudo
	# acima desta linha -- e levaria o jogador para a partida de outra pessoa da casa.
	var resumo_de_volta := menu_de_volta.find_child("ResumoDoContinuar", true, false) as Label
	var total_escrito := Formatador.formatar(Jogo.total_caracteres)
	if resumo_de_volta == null or not resumo_de_volta.text.contains(total_escrito):
		_falhar("o resumo do CONTINUAR nao mostra %s, e sim \"%s\"" % [
			total_escrito, resumo_de_volta.text if resumo_de_volta != null else "",
		])
		return

	Jogo.total_caracteres = Grande.zero()
	continuar_de_volta.pressed.emit()

	# ⚠️ A TRANSICAO ROLA SEM A FUMACA ESPERAR POR ELA (issue #48). Ela e decoracao por cima
	# de uma partida que JA comecou: se ela exigisse await antes de montar, haveria uma
	# janela em que um segundo clique comecaria uma segunda partida -- que e exatamente a
	# janela que a issue #38 fechou escolhendo o clarao em vez da travessia.
	if not Cenas.aproximando():
		_falhar("vindo do menu, a aproximacao da maquina nao comecou")
		return

	# ⚠️ SEM await ANTES DE COMPARAR. Montar a partida e sincrono, mas o primeiro _process
	# dela ja produz: um quadro de espera aqui somaria producao ao total recem-carregado, e
	# a afirmacao viraria "voltou parecido" em vez de "voltou identico".
	if Cenas.atual() != "partida":
		_falhar("CONTINUAR nao abriu a partida, e sim %s" % Cenas.atual())
		return
	if not Jogo.total_caracteres.igual_a(total_ao_sair):
		_falhar("CONTINUAR trouxe %s no lugar de %s" % [
			Jogo.total_caracteres.para_texto(), total_ao_sair.para_texto(),
		])
		return
	await get_tree().process_frame

	# 19. o cartao de Arquivos conta a partida de volta, e excluir apaga o Manuscrito
	#     (issue #40). E o fecho do caminho: criar, jogar, voltar, ver, excluir.
	Cenas.voltar_ao_menu()
	await get_tree().process_frame
	var menu_final := raiz.find_child("MenuTela", true, false)
	(menu_final.find_child("BotaoJogar", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	for i in QUADROS_ATE_O_LAYOUT_ASSENTAR:
		await get_tree().process_frame

	var arquivos_final := raiz.find_child("ArquivosTela", true, false)
	if arquivos_final == null:
		_falhar("JOGAR nao levou de volta aos Arquivos")
		return
	var cartao := arquivos_final.find_child("CartaoSlot1", true, false)
	if cartao == null:
		_falhar("a tela de Arquivos nao desenhou o cartao do slot 1")
		return
	# o cartao se apresenta pelo nome que o jogador escreveu la atras, e pelo total dele
	var escrito := _texto_de(cartao)
	if not escrito.contains(NOME_DO_MANUSCRITO):
		_falhar("o cartao nao mostra o nome %s: \"%s\"" % [NOME_DO_MANUSCRITO, escrito])
		return
	if not escrito.contains(Formatador.formatar(Jogo.total_caracteres)):
		_falhar("o cartao nao mostra o total da partida: \"%s\"" % escrito)
		return

	# ⚠️ EXCLUIR EM DOIS PASSOS, E O SEGUNDO E UMA PRESSAO. O toque curto tem que NAO
	# apagar: sem esta metade, um botao que apagasse no primeiro clique passaria no teste.
	(arquivos_final.find_child("BotaoExcluir1", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	var segurar := arquivos_final.find_child("BotaoSegurarExcluir1", true, false) as BotaoDeSegurar
	if segurar == null:
		_falhar("EXCLUIR nao pediu a segunda confirmacao")
		return
	await _segurar(segurar, BotaoDeSegurar.SEGUNDOS * 0.25)
	if not FileAccess.file_exists(Config.caminho_do_slot(1)):
		_falhar("um toque curto ja apagou o Manuscrito")
		return

	segurar = arquivos_final.find_child("BotaoSegurarExcluir1", true, false) as BotaoDeSegurar
	if segurar == null:
		_falhar("o toque curto derrubou a confirmacao de exclusao")
		return
	await _segurar(segurar, BotaoDeSegurar.SEGUNDOS + 0.5)
	if FileAccess.file_exists(Config.caminho_do_slot(1)):
		_falhar("segurar o botao nao apagou o Manuscrito")
		return
	if FileAccess.file_exists(Manuscrito.caminho_do_meta(Config.caminho_do_slot(1))):
		_falhar("o .meta sobreviveu a exclusao -- o cartao continuaria na tela")
		return
	await get_tree().process_frame
	if arquivos_final.find_child("BotaoNovo1", true, false) == null:
		_falhar("depois de excluir, o cartao do slot 1 nao virou NOVO MANUSCRITO")
		return

	# 20. ⚠️ O CAMINHO DO §48, DE PONTA A PONTA. Este e o ACEITE DA VERSAO (issue #49), e
	#     por isso ele roda do zero, em ordem, depois de tudo -- e nao espalhado pelos
	#     passos acima. Um caminho provado em pedacos e um caminho que ninguem andou.
	if not await _o_caminho_do_48(raiz):
		return

	for numero in range(1, Config.SLOTS + 1):
		Save.caminho = Config.caminho_do_slot(numero)
		Save.apagar()
	if FileAccess.file_exists(Config.caminho):
		DirAccess.remove_absolute(Config.caminho)
	Config.caminho = caminho_de_opcoes
	Config.modelo_de_slot = modelo_de_slot
	Save.caminho = caminho_de_save
	TranslationServer.set_locale(locale_original)
	print("PASSOU (%d cliques, %s comprado, %d marcos, save ida e volta, %s de %.0f h offline)" % [
		CLIQUES, UPGRADE_INICIAL, Jogo.marcos_alcancados.size(),
		Formatador.formatar(creditado), HORAS_OFFLINE,
	])
	get_tree().quit(0)


## Aperta um botao do menu, confere que a tela sobreposta apareceu, fecha no ESC e confere
## que ela sumiu. Devolve se deu certo.
##
## O ESC entra por Input.parse_input_event e nao chamando fechar() por baixo: o que esta
## sob prova e que a tela COME a entrada enquanto esta aberta -- sem isso o espaco vazaria
## para o menu atras dela e apertaria o proprio botao que a abriu.
func _abre_e_fecha(menu: Node, nome_do_botao: String, nome_da_tela: String) -> bool:
	var botao := menu.find_child(nome_do_botao, true, false) as Button
	if botao == null:
		_falhar("o menu nao tem %s" % nome_do_botao)
		return false
	var tela := menu.find_child(nome_da_tela, true, false) as Control
	if tela == null:
		_falhar("o menu nao hospeda a %s" % nome_da_tela)
		return false
	if tela.visible:
		_falhar("a %s ja estava aberta antes de alguem pedir" % nome_da_tela)
		return false

	botao.pressed.emit()
	await get_tree().process_frame
	if not tela.visible:
		_falhar("%s nao abriu a %s" % [nome_do_botao, nome_da_tela])
		return false

	_apertar(&"ui_cancel")
	await get_tree().process_frame
	if tela.visible:
		_falhar("o ESC nao fechou a %s" % nome_da_tela)
		return false
	return true


## Segura um botao pelo tempo pedido e solta. O caminho e o do TECLADO: com o botao
## focado, ui_accept em baixo deixa button_pressed verdadeiro -- que e o que o
## BotaoDeSegurar conta. Press e release vem separados de proposito; _apertar() manda os
## dois juntos e nunca chegaria a segurar nada.
func _segurar(botao: Button, segundos: float) -> void:
	botao.grab_focus()
	await get_tree().process_frame

	var apertar := InputEventAction.new()
	apertar.action = &"ui_accept"
	apertar.pressed = true
	Input.parse_input_event(apertar)

	var ate := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < ate:
		await get_tree().process_frame

	var soltar := InputEventAction.new()
	soltar.action = &"ui_accept"
	soltar.pressed = false
	Input.parse_input_event(soltar)
	await get_tree().process_frame


## Todo texto visivel dentro de um no, junto. Existe para a fumaca poder afirmar o que um
## CARTAO diz sem saber em qual Label cada pedaco mora -- afirmar por caminho de no
## quebraria na primeira vez que alguem reorganizasse o cartao.
func _texto_de(no: Node) -> String:
	var pedacos := PackedStringArray()
	for rotulo in no.find_children("*", "Label", true, false):
		pedacos.append((rotulo as Label).text)
	return "
".join(pedacos)


## ⚠️ O ACEITE DA VERSAO v0.5, o caminho §48 do plano do menu (issue #49):
##
##   abrir -> abertura -> configurar -> criar Manuscrito -> jogar -> autosave
##   -> voltar ao menu -> ver o cartao -> fechar -> abrir -> CONTINUAR
##   -> estar exatamente onde parou
##
## Cada seta e um passo, e cada passo afirma alguma coisa. Ele comeca do ZERO: slots
## apagados, opcoes apagadas, "ja viu abertura" em falso -- senao ele herdaria o estado dos
## dezenove passos acima e provaria um caminho que ninguem percorre.
func _o_caminho_do_48(raiz: Node) -> bool:
	print("  §48: o caminho inteiro")

	# ABRIR -- do zero, como quem instalou o jogo agora
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))
	if FileAccess.file_exists(Config.caminho):
		DirAccess.remove_absolute(Config.caminho)
	Config.carregar()
	Config.aplicar()

	# ABERTURA
	Cenas.ir_para_abertura()
	await get_tree().process_frame
	if Cenas.atual() != "abertura":
		_falhar("§48: instalacao nova nao viu a abertura")
		return false
	_apertar(&"ui_cancel")
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("§48: a abertura nao levou ao menu")
		return false

	# CONFIGURAR -- e a escolha tem que sobreviver ao caminho inteiro
	var volume_escolhido := 0.35
	Config.definir("volume", volume_escolhido)
	Config.escolher("som_de_digitacao", 1)

	# CRIAR MANUSCRITO
	var menu := raiz.find_child("MenuTela", true, false)
	(menu.find_child("BotaoJogar", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	var arquivos := raiz.find_child("ArquivosTela", true, false)
	(arquivos.find_child("BotaoNovo1", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	var campo := arquivos.find_child("CampoDeNome1", true, false) as LineEdit
	campo.text = NOME_DO_MANUSCRITO
	(arquivos.find_child("BotaoCriar1", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	if Cenas.atual() != "partida":
		_falhar("§48: criar o Manuscrito nao abriu a partida")
		return false

	# JOGAR
	for i in CLIQUES:
		_apertar(&"ui_accept")
		await get_tree().process_frame
	if Jogo.total_caracteres.sinal() <= 0:
		_falhar("§48: jogar nao produziu caractere nenhum")
		return false

	# AUTOSAVE -- pelo gatilho de verdade, e nao chamando Save.gravar
	var gravou: Array[int] = []
	var ouvinte := func() -> void: gravou.append(1)
	EventBus.jogo_gravado.connect(ouvinte)
	Autosave.tique(Autosave.INTERVALO + 1.0)
	EventBus.jogo_gravado.disconnect(ouvinte)
	if gravou.is_empty():
		_falhar("§48: o cronometro do autosave nao gravou")
		return false

	# VOLTAR AO MENU
	var total_ao_sair := Jogo.total_caracteres
	var hud := raiz.find_child("HUD", true, false)
	(hud.find_child("BotaoMenu", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("§48: o botao MENU nao voltou ao menu")
		return false

	# VER O CARTAO -- o resumo do CONTINUAR conta a partida de volta
	var menu_de_volta := raiz.find_child("MenuTela", true, false)
	var resumo := menu_de_volta.find_child("ResumoDoContinuar", true, false) as Label
	if not resumo.text.contains(Formatador.formatar(total_ao_sair)):
		_falhar("§48: o cartao nao mostra %s" % Formatador.formatar(total_ao_sair))
		return false

	# FECHAR -> ABRIR. Fechar grava (Cenas.sair faz isso, mas ele encerra o processo),
	# entao o que se simula aqui e o ESTADO do jogo recem-aberto: memoria limpa e a
	# abertura ja vista. Se o disco nao tivesse a partida, o CONTINUAR abaixo reprovaria.
	Jogo.total_caracteres = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.nome = ""
	Cenas.ir_para_abertura()
	await get_tree().process_frame
	if Cenas.atual() != "menu":
		_falhar("§48: reabrir nao caiu direto no menu -- a abertura voltou")
		return false

	# CONTINUAR
	var menu_reaberto := raiz.find_child("MenuTela", true, false)
	var continuar := menu_reaberto.find_child("BotaoContinuar", true, false) as Button
	if continuar.disabled:
		_falhar("§48: depois de reabrir, o CONTINUAR nao esta disponivel")
		return false
	continuar.pressed.emit()

	# ESTAR EXATAMENTE ONDE PAROU -- sem await, para a producao do primeiro quadro nao
	# entrar na comparacao
	if Cenas.atual() != "partida":
		_falhar("§48: CONTINUAR nao abriu a partida")
		return false
	if not Jogo.total_caracteres.igual_a(total_ao_sair):
		_falhar("§48: voltou com %s no lugar de %s" % [
			Jogo.total_caracteres.para_texto(), total_ao_sair.para_texto(),
		])
		return false
	if Jogo.nome != NOME_DO_MANUSCRITO:
		_falhar("§48: o nome do Manuscrito nao voltou: \"%s\"" % Jogo.nome)
		return false
	if absf(Config.volume() - volume_escolhido) > 1e-6:
		_falhar("§48: a configuracao nao sobreviveu ao caminho")
		return false

	await get_tree().process_frame
	print("  §48: abrir, abertura, configurar, criar, jogar, autosave, menu, cartao, "
		+ "reabrir, CONTINUAR -- tudo no lugar")
	return true


## Aperta uma tecla de LETRA, e nao uma acao. O easter egg do menu le o `unicode` do
## evento, que acao nenhuma carrega.
func _teclar(letra: String) -> void:
	var evento := InputEventKey.new()
	evento.pressed = true
	evento.unicode = letra.unicode_at(0)
	evento.keycode = letra.to_upper().unicode_at(0)
	Input.parse_input_event(evento)


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
