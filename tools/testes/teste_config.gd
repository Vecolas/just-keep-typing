## Suite das opcoes (issue #34).
##
## Duas afirmacoes valem mais que todas as outras juntas, e as duas sao sobre coisas que o
## jogador NAO consegue desfazer sozinho:
##
##   RESOLUCAO QUE NAO CABE NO MONITOR. Oferecer 2560x1440 a quem tem 1080p cria uma janela
##   maior que a tela, com a barra de titulo acima da area visivel. A pessoa nao consegue
##   arrastar a janela, nao consegue voltar as opcoes, e o jogo so volta ao normal apagando
##   o arquivo de configuracao na mao. Nao ha "cancelar" para isso -- por isso e portao.
##
##   TROCAR DE SLOT SEM GRAVAR. Perderia os minutos desde o ultimo autosave, num gesto que
##   o jogador entende como "dar uma olhada no outro save".
##
## A suite escreve num arquivo proprio (Config.caminho e Config.modelo_de_slot sao
## variaveis exatamente para isso) e devolve tudo no fim, senao rodar o teste mudaria a
## resolucao de quem esta desenvolvendo.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_opcoes.json"

## Os rotulos que a tela de opcoes usa, lidos do PROPRIO arquivo dela. Copiar a lista para
## ca criaria uma terceira fonte para a mesma coisa, e a terceira e sempre a que mente.
const _ROTULOS_DA_TELA: Dictionary = preload("res://src/ui/opcoes_tela.gd").ROTULOS
const SLOT_DE_TESTE := "user://teste_slot_%d.json"

var _caminho_original: String = ""
var _modelo_original: String = ""
var _save_original: String = ""


func _init() -> void:
	nome = "config"


func executar() -> void:
	_caminho_original = Config.caminho
	_modelo_original = Config.modelo_de_slot
	_save_original = Save.caminho
	Config.caminho = CAMINHO_DE_TESTE
	Config.modelo_de_slot = SLOT_DE_TESTE

	_campo_generico()
	_resolucao_cabe_no_monitor()
	_a_janela_inteira_cabe_na_tela()
	_tela_cheia_apaga_a_resolucao()
	_idioma_troca_as_convencoes_junto()
	_ida_e_volta_do_arquivo()
	_o_ritmo_do_quadro()
	_slots()

	_limpar()
	Config.caminho = _caminho_original
	Config.modelo_de_slot = _modelo_original
	Save.caminho = _save_original
	Config.carregar()


## A API generica responde por TODO campo declarado, e todo campo declarado PERTENCE A UMA
## ABA (issue #41). E o portao que faz a promessa da CONVENCOES.md valer: "opcao nova e uma
## linha na tabela, e nenhuma linha da tela muda". Campo declarado sem resposta apareceria
## na tela vazio; campo sem aba nao apareceria em lugar nenhum -- e sumir e pior que
## reprovar, porque ninguem procura o que nunca esteve la.
func _campo_generico() -> void:
	ok(not Config.CAMPOS.is_empty(), "existe campo de opcao")
	# ⚠️ contador proprio: um laco que caisse inteiro no `continue` imprimiria "tudo certo"
	# com ZERO campos medidos, e portao com zero verificacoes tem que reprovar
	var medidos := 0

	for nome in Config.nomes_de_campo():
		medidos += 1
		var linha := Config.campo(nome)
		ok(not linha.is_empty(), "%s -- esta na tabela" % nome)
		ok(
			Config.ABAS.has(str(linha.get("aba", ""))),
			"%s -- mora numa aba declarada (%s)" % [nome, linha.get("aba", "")],
		)
		# e o campo tem que estar em PADRAO, senao instalacao nova abre sem ele
		ok(Config.PADRAO.has(nome), "%s -- tem padrao de instalacao nova" % nome)
		# ⚠️ e ter rotulo na tela: as duas tabelas sao fontes separadas da MESMA lista de
		# campos, e sem este cruzamento um campo novo apareceria com o nome interno dele
		ok(
			_ROTULOS_DA_TELA.has(nome),
			"%s -- tem rotulo na tela de opcoes" % nome,
		)

		if Config.tipo_de(nome) == Config.Tipo.FAIXA:
			_campo_de_faixa(nome)
			continue
		_campo_de_lista(nome)

	igual(medidos, Config.CAMPOS.size(), "o portao mediu todos os campos, e nao um subconjunto")
	ok(medidos > 0, "⚠️ e mediu pelo menos um -- tabela vazia nao e aprovacao")

	# ⚠️ E O CAMPO "slot" NAO ESTA AQUI (issue #41). Trocar de Manuscrito por dentro das
	# opcoes, no meio da partida, e o gesto que apaga progresso sem querer -- quem escolhe
	# save e a tela de Arquivos. Esta linha e a metade que impede o campo de voltar calado.
	ok(
		not Config.nomes_de_campo().has("slot"),
		"o campo de slot NAO e uma opcao da tela",
	)

	# toda aba desenhada tem campo: aba vazia ensina o jogador a nao clicar nas outras
	var abas_com_campo := 0
	for aba in Config.ABAS:
		if not Config.campos_da_aba(aba).is_empty():
			abas_com_campo += 1
	ok(abas_com_campo > 0, "ha aba com campo para desenhar")


func _campo_de_lista(nome: String) -> void:
	var rotulos := Config.rotulos_de(nome)
	ok(not rotulos.is_empty(), "%s -- tem rotulos" % nome)
	for rotulo in rotulos:
		ok(not rotulo.strip_edges().is_empty(), "%s -- nenhum rotulo vazio" % nome)
	var indice := Config.indice_de(nome)
	ok(
		indice >= 0 and indice < rotulos.size(),
		"%s -- o indice escolhido existe na lista (%d de %d)" % [
			nome, indice, rotulos.size(),
		],
	)

	# indice fora da lista nao muda nada, e nao quebra
	var antes := Config.indice_de(nome)
	Config.escolher(nome, -1)
	Config.escolher(nome, 9999)
	igual(Config.indice_de(nome), antes, "%s -- indice invalido nao muda a escolha" % nome)

	# e o que se escolhe e o que fica: ida e volta por todos os indices do campo
	for i in rotulos.size():
		Config.escolher(nome, i)
		igual(Config.indice_de(nome), i, "%s -- escolher %d devolve %d" % [nome, i, i])
	Config.escolher(nome, antes)


func _campo_de_faixa(nome: String) -> void:
	var limites := Config.faixa_de(nome)
	ok(limites.has("minimo") and limites.has("maximo"), "%s -- declara a faixa" % nome)
	ok(float(limites["maximo"]) > float(limites["minimo"]), "%s -- a faixa nao e vazia" % nome)
	ok(float(limites.get("passo", 0.0)) > 0.0, "%s -- o passo nao e zero" % nome)

	var antes := Config.valor_de(nome)
	Config.definir(nome, float(limites["minimo"]))
	perto(Config.valor_de(nome), float(limites["minimo"]), 1e-6, "%s -- vai ao minimo" % nome)
	# ⚠️ valor fora da faixa e GRAMPEADO, e nao recusado: barra nao tem indice invalido, e
	# um volume de 5,0 escrito na mao no arquivo nao pode virar audio de 500%
	Config.definir(nome, float(limites["maximo"]) * 10.0)
	perto(
		Config.valor_de(nome), float(limites["maximo"]), 1e-6,
		"%s -- valor acima do maximo e grampeado" % nome,
	)
	Config.definir(nome, antes)


## ⚠️ O PORTAO. Resolucao maior que o monitor deixa a barra de titulo fora da area visivel,
## e a pessoa fica sem caminho de volta.
func _resolucao_cabe_no_monitor() -> void:
	var tela := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var lista := Config.resolucoes()
	ok(not lista.is_empty(), "sempre sobra alguma resolucao para escolher")
	if tela.x <= 0 or tela.y <= 0:
		# headless nao tem monitor. O que se afirma aqui e o RESGATE: monitor de tamanho
		# desconhecido cai no menor do catalogo, e nao no maior -- errar para o lado grande
		# e que deixa a barra de titulo fora da tela.
		igual(lista.size(), 1, "monitor desconhecido oferece uma resolucao so")
		igual(lista[0], Config.RESOLUCOES[0], "e ela e a MENOR do catalogo, nunca a maior")
	else:
		for tamanho in lista:
			ok(
				tamanho.x <= tela.x and tamanho.y <= tela.y,
				"%dx%d cabe no monitor de %dx%d" % [tamanho.x, tamanho.y, tela.x, tela.y],
			)

	# e a lista oferecida e exatamente a que os rotulos mostram: um descompasso aqui faria
	# escolher o indice 2 aplicar a resolucao do indice 3
	igual(
		Config.rotulos_de("resolucao").size(), lista.size(),
		"um rotulo por resolucao oferecida, sem sobra nem falta",
	)

	# escolher a maior que cabe e aplicar de verdade
	Config.escolher("tela_cheia", 0)
	Config.escolher("resolucao", lista.size() - 1)
	igual(
		Config.indice_de("resolucao"), lista.size() - 1,
		"a resolucao escolhida e a que fica",
	)


## ⚠️ O segundo portao da mesma familia, e o que faltava: nao basta a resolucao caber no
## monitor, a JANELA INTEIRA tem que caber -- e ela tem que ser colocada onde cabe.
##
## Dois defeitos medidos nesta maquina, num monitor de 1920x1080:
##
##   a moldura come 16x39, entao a janela de cliente 1920x1080 pedia 1936x1119 e nao cabia
##   em tela nenhuma, mesmo a resolucao sendo exatamente a do monitor;
##
##   e window_set_size cresce a partir do canto onde a janela estava: escolher 1920x1080
##   deixou o canto em (320, 180) e o jogo terminando em (2240, 1260) -- trezentos e vinte
##   pixels de interface fora da tela, sem rolagem nenhuma que alcance.
##
## E logica pura de proposito: headless nao tem monitor, e um portao que so roda com janela
## e um portao que nunca roda na suite.
func _a_janela_inteira_cabe_na_tela() -> void:
	var area := Rect2i(Vector2i.ZERO, Vector2i(1920, 1080))
	var moldura := Vector2i(16, 39)

	for tamanho in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1904, 1041)]:
		var canto := Config.posicao_centralizada(tamanho, area, moldura)
		var inteira := Rect2i(
			canto - Vector2i(moldura.x / 2, moldura.y), tamanho + moldura
		)
		ok(
			area.encloses(inteira),
			"%s: a janela INTEIRA (%s) cabe na area util" % [tamanho, inteira],
		)
		ok(canto.y >= moldura.y, "%s: a barra de titulo fica dentro da tela" % tamanho)
		ok(canto.x >= 0 and canto.y >= 0, "%s: e o canto nunca sai pela esquerda nem por cima" % tamanho)

	# centralizada mesmo, e nao encostada num canto
	var meio := Config.posicao_centralizada(Vector2i(1280, 720), area, moldura)
	igual(meio.x, (1920 - 1280 - 16) / 2 + 8, "sobra a mesma largura dos dois lados")

	# janela do tamanho da area, ou maior que ela: nao ha o que centralizar, e o que nao
	# pode acontecer e o canto ir para valor negativo
	var apertada := Config.posicao_centralizada(Vector2i(3840, 2160), area, moldura)
	ok(apertada.x >= 0 and apertada.y >= 0, "janela grande demais nao vai para fora da tela")

	# area que nao comeca na origem: monitor secundario, a direita do principal
	var segunda := Rect2i(Vector2i(1920, 0), Vector2i(1440, 900))
	var nela := Config.posicao_centralizada(Vector2i(1280, 720), segunda, moldura)
	ok(nela.x >= segunda.position.x, "no monitor secundario a janela fica NELE")

	# e a lista oferecida respeita a mesma conta: nada maior que a area util
	var util := Config.area_util()
	for tamanho in Config.resolucoes():
		ok(
			tamanho.x <= util.x and tamanho.y <= util.y or util.x <= 0,
			"%dx%d cabe na area util de %s" % [tamanho.x, tamanho.y, util],
		)


## Campo que nao faz nada tem que PARECER que nao faz nada.
func _tela_cheia_apaga_a_resolucao() -> void:
	Config.escolher("tela_cheia", 0)
	ok(not Config.tela_cheia(), "em janela")
	ok(not Config.apagado("resolucao"), "a resolucao esta viva")

	Config.escolher("tela_cheia", 1)
	ok(Config.tela_cheia(), "em tela cheia")
	ok(Config.apagado("resolucao"), "a resolucao fica apagada")

	# ⚠️ sem exclusividade: a exclusiva pisca a tela inteira a cada alt-tab.
	# headless nao tem janela para mudar de modo, entao la a afirmacao seria sobre nada
	if DisplayServer.get_name() != "headless":
		igual(
			DisplayServer.window_get_mode(), DisplayServer.WINDOW_MODE_FULLSCREEN,
			"e o modo e FULLSCREEN, nunca EXCLUSIVE_FULLSCREEN",
		)

	Config.escolher("tela_cheia", 0)
	ok(not Config.apagado("resolucao"), "voltando para janela, a resolucao volta a valer")


## "Idioma traz as convencoes junto, e nao so as palavras": nem o relogio nem o Formatador
## tem ramo por lingua, os dois perguntam a tabela.
func _idioma_troca_as_convencoes_junto() -> void:
	var locale_original := TranslationServer.get_locale()

	for i in Config.IDIOMAS.size():
		Config.escolher("idioma", i)
		var tabela := Config.convencoes()
		igual(
			str(tabela["codigo"]), Config.idioma(),
			"a tabela de convencoes acompanha o idioma escolhido",
		)
		ok(tabela.has("relogio_12h"), "%s -- diz como escreve hora" % Config.idioma())
		ok(tabela.has("moeda"), "%s -- diz qual e a moeda" % Config.idioma())
		igual(
			TranslationServer.get_locale(), Config.idioma(),
			"e o TranslationServer foi junto",
		)

	# o sinal existe porque tela que monta texto em codigo nao e retraduzida sozinha
	var avisos: Array[String] = []
	var ouvinte := func(codigo: String) -> void: avisos.append(codigo)
	EventBus.idioma_mudou.connect(ouvinte)
	Config.escolher("idioma", 0)
	EventBus.idioma_mudou.disconnect(ouvinte)
	igual(avisos.size(), 1, "trocar de idioma avisa o EventBus exatamente uma vez")

	TranslationServer.set_locale(locale_original)


func _ida_e_volta_do_arquivo() -> void:
	Config.escolher("idioma", 1)
	Config.escolher("tela_cheia", 1)
	Config.definir("volume", 0.35)
	var idioma_gravado := Config.idioma()

	Config.carregar()
	igual(Config.idioma(), idioma_gravado, "o idioma sobrevive ao arquivo")
	ok(Config.tela_cheia(), "a tela cheia sobrevive")
	perto(Config.volume(), 0.35, 1e-6, "o volume sobrevive")

	# ⚠️ E TODO CAMPO SOBREVIVE A IDA E VOLTA PELO DISCO, um indice de cada vez. Este
	# portao existe por um bug medido: o JSON devolve numero como FLOAT, a comparacao de
	# Variant do Godot confere o TIPO antes do valor, e [0, 1, 2].find(1.0) e -1. Todo
	# campo numerico voltava do arquivo mostrando a primeira opcao -- a configuracao da
	# pessoa sumindo a cada abertura, sem um erro sequer. Afirmar so em memoria nao pegava:
	# em memoria o valor ainda e int.
	for linha in Config.CAMPOS:
		var nome := str(linha["nome"])
		if Config.tipo_de(nome) == Config.Tipo.FAIXA:
			continue
		for i in Config.rotulos_de(nome).size():
			Config.escolher(nome, i)
			Config.carregar()
			igual(
				Config.indice_de(nome), i,
				"%s -- o indice %d sobrevive a ida e volta pelo arquivo" % [nome, i],
			)
		Config.escolher(nome, 0)

	# arquivo com campo desconhecido nao vira estado, e nao quebra
	var arquivo := FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string('{"idioma": "en", "campo_do_futuro": 7}')
	arquivo.close()
	Config.carregar()
	igual(Config.idioma(), "en", "o que o jogo conhece entra")
	ok(not Config._opcoes.has("campo_do_futuro"), "e o que ele nao conhece fica de fora")
	# e o resto volta ao padrao, e nao a lixo
	perto(Config.volume(), float(Config.PADRAO["volume"]), 1e-6, "campo ausente vira o padrao")

	Config.escolher("tela_cheia", 0)
	Config.escolher("idioma", 0)


## O modo economico e o limite de quadros escrevem NO MESMO lugar, e por isso ha uma conta
## so: fps_efetivo(). Duas fontes para Engine.max_fps seriam a janela voltando do segundo
## plano presa em dez quadros por segundo, sem uma linha no console.
##
## ⚠️ E ela e afirmada aqui, e nao onde e aplicada, de proposito: sem janela o jogo nao
## aplica ritmo nenhum (Engine.max_fps em headless ritmaria a fumaca inteira), entao um
## portao que dependesse da aplicacao nunca rodaria na suite.
func _o_ritmo_do_quadro() -> void:
	var fps_antes := Config.indice_de("limite_de_fps")
	var economico_antes := Config.indice_de("modo_economico")
	var valores: Array = Config.campo("limite_de_fps")["valores"]

	Config.escolher("modo_economico", 0)
	for i in valores.size():
		Config.escolher("limite_de_fps", i)
		igual(
			Config.fps_efetivo(), int(valores[i]),
			"sem modo economico, o limite efetivo e o escolhido",
		)

	# com a janela na frente o modo economico nao muda nada: ele e sobre segundo plano
	Config.escolher("modo_economico", 1)
	Config.escolher("limite_de_fps", valores.find(60))
	Config._em_primeiro_plano = true
	igual(Config.fps_efetivo(), 60, "modo economico com a janela na frente nao baixa nada")

	Config._em_primeiro_plano = false
	igual(
		Config.fps_efetivo(), Config.FPS_EM_SEGUNDO_PLANO,
		"⚠️ e em segundo plano ele baixa -- e este e o botao inteiro",
	)

	# o controle: desligado, o segundo plano nao muda nada. Sem ele, um fps_efetivo que
	# baixasse SEMPRE passaria na afirmacao acima
	Config.escolher("modo_economico", 0)
	igual(Config.fps_efetivo(), 60, "desligado, o segundo plano nao baixa quadro nenhum")

	# e "sem limite" continua sendo zero, e nao um sentinela inventado ao lado dele
	Config.escolher("limite_de_fps", valores.find(0))
	igual(Config.fps_efetivo(), 0, "sem limite e zero, que e o que o Engine entende")

	Config._em_primeiro_plano = true
	Config.escolher("limite_de_fps", fps_antes)
	Config.escolher("modo_economico", economico_antes)


## ⚠️ O QUE MUDOU DE CASA NA ISSUE #41, e o que NAO mudou.
##
## "Trocar de slot grava o que estava aberto" saiu daqui junto com o campo de slot da tela
## de opcoes: o unico caminho ate outro Manuscrito agora passa por Cenas.voltar_ao_menu,
## que grava antes de sair -- e quem afirma isso e o teste_cenas. A regra nao foi
## afrouxada, ela mudou de porta, e o portao foi junto.
##
## O que continua sendo deste arquivo e a outra metade, que nunca teve a ver com a tela:
## abrir_slot RECUSA o que nao existe. A primeira versao grampeava, e um numero invalido
## levava o jogador para o ULTIMO Manuscrito -- trocando a partida dele por outra sem
## ninguem ter pedido, e isso nao tem desfazer.
func _slots() -> void:
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))

	Config.abrir_slot(1)
	igual(Config.slot(), 1, "abrir_slot aponta para o slot pedido")
	igual(Save.caminho, Config.caminho_do_slot(1), "e o Save vai junto")

	Config.abrir_slot(2)
	igual(Config.slot(), 2, "e para o seguinte")
	igual(Save.caminho, Config.caminho_do_slot(2), "com o Save atras")

	# ⚠️ O PORTAO. Fora da faixa nao muda NADA -- nem o slot, nem o caminho do Save.
	print("    (as duas linhas ERROR abaixo sao de proposito -- slot invalido sob teste)")
	Config.abrir_slot(0)
	igual(Config.slot(), 2, "slot zero e recusado, e o aberto continua o mesmo")
	Config.abrir_slot(Config.SLOTS + 1)
	igual(Config.slot(), 2, "slot alem do ultimo tambem")
	igual(
		Save.caminho, Config.caminho_do_slot(2),
		"e o Save nao foi reapontado por um slot que nao existe",
	)

	# arquivo de opcoes adulterado na mao nao pode virar indice invalido na leitura: aqui
	# grampear e o certo, porque nao ha jogador escolhendo nada
	Config._opcoes["slot"] = 99
	igual(Config.slot(), Config.SLOTS, "slot fora da faixa NO ARQUIVO e grampeado na leitura")
	Config._opcoes["slot"] = -5
	igual(Config.slot(), 1, "e pelo outro lado tambem")

	Config.abrir_slot(1)
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))


## Apaga os arquivos DESTA suite. Save.apagar_arquivos leva o .meta e o .backup junto --
## deixar qualquer um dos tres faria a suite seguinte achar um Manuscrito que ela nao
## gravou.
func _limpar() -> void:
	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))
