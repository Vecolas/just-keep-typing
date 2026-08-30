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
	_tela_cheia_apaga_a_resolucao()
	_idioma_troca_as_convencoes_junto()
	_ida_e_volta_do_arquivo()
	_slots()

	_limpar()
	Config.caminho = _caminho_original
	Config.modelo_de_slot = _modelo_original
	Save.caminho = _save_original
	Config.carregar()


## A API generica responde por TODO campo declarado. E o portao que faz a promessa da
## CONVENCOES.md valer: "opcao nova e um ramo em cada uma das tres, e nenhuma linha da tela
## de opcoes muda". Campo declarado sem os tres ramos apareceria na tela vazio.
func _campo_generico() -> void:
	ok(not Config.CAMPOS.is_empty(), "existe campo de opcao")
	for campo in Config.CAMPOS:
		var rotulos := Config.rotulos_de(campo)
		ok(not rotulos.is_empty(), "%s -- tem rotulos" % campo)
		for rotulo in rotulos:
			ok(not rotulo.strip_edges().is_empty(), "%s -- nenhum rotulo vazio" % campo)
		var indice := Config.indice_de(campo)
		ok(
			indice >= 0 and indice < rotulos.size(),
			"%s -- o indice escolhido existe na lista (%d de %d)" % [
				campo, indice, rotulos.size(),
			],
		)
		# e o campo tem que estar em PADRAO, senao instalacao nova abre sem ele
		ok(Config.PADRAO.has(campo), "%s -- tem padrao de instalacao nova" % campo)

	# indice fora da lista nao muda nada, e nao quebra
	for campo in Config.CAMPOS:
		var antes := Config.indice_de(campo)
		Config.escolher(campo, -1)
		Config.escolher(campo, 9999)
		igual(Config.indice_de(campo), antes, "%s -- indice invalido nao muda a escolha" % campo)


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
	Config.definir_volume(0.35)
	var idioma_gravado := Config.idioma()

	Config.carregar()
	igual(Config.idioma(), idioma_gravado, "o idioma sobrevive ao arquivo")
	ok(Config.tela_cheia(), "a tela cheia sobrevive")
	perto(Config.volume(), 0.35, 1e-6, "o volume sobrevive")

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


## Trocar de slot GRAVA O QUE ESTAVA ABERTO. E slot vazio comeca partida nova a partir do
## mesmo dicionario de padroes que a migracao de save usa.
func _slots() -> void:
	var guardado_total := Jogo.total_caracteres
	var guardado_macacos := Jogo.macacos

	for numero in range(1, Config.SLOTS + 1):
		var caminho := Config.caminho_do_slot(numero)
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)

	# vai ao slot 2 e volta, para que o Save.caminho passe a apontar para os arquivos DESTA
	# suite. Escolher o slot em que ja se esta nao faz nada -- de proposito, e afirmado
	# logo abaixo --, entao um escolher("slot", 0) sozinho aqui nao trocaria caminho nenhum
	Config.escolher("slot", 1)
	Config.escolher("slot", 0)
	igual(Config.slot(), 1, "comeca no slot 1")
	igual(Save.caminho, Config.caminho_do_slot(1), "e o Save aponta para o arquivo dele")
	for numero in range(1, Config.SLOTS + 1):
		var caminho := Config.caminho_do_slot(numero)
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)

	# uma partida qualquer no slot 1
	Jogo.total_caracteres = Grande.de_float(12345.0)
	Jogo.macacos = Grande.de_float(7.0)
	Config.escolher("slot", 1)

	igual(Config.slot(), 2, "trocou para o slot 2")
	igual(Save.caminho, Config.caminho_do_slot(2), "e o Save foi junto")
	ok(
		FileAccess.file_exists(Config.caminho_do_slot(1)),
		"⚠️ o slot que estava aberto foi GRAVADO antes de sair dele",
	)
	# slot vazio = partida nova, e nao o estado do slot anterior sobrando na memoria
	ok(Jogo.total_caracteres.e_zero(), "e o slot 2, vazio, comecou partida nova")
	ok(Jogo.macacos.igual_a(Grande.um()), "com o macaco do GDD §3")

	# e voltar traz a partida de volta inteira
	Config.escolher("slot", 0)
	igual(Config.slot(), 1, "voltou para o slot 1")
	perto(
		Jogo.total_caracteres.para_float(), 12345.0, 1e-6,
		"e a partida dele voltou como estava",
	)

	# escolher o slot em que ja se esta nao mexe em nada
	var antes := Jogo.total_caracteres
	Config.escolher("slot", 0)
	ok(Jogo.total_caracteres.igual_a(antes), "escolher o slot atual nao faz nada")

	Jogo.total_caracteres = guardado_total
	Jogo.macacos = guardado_macacos


func _limpar() -> void:
	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	for numero in range(1, Config.SLOTS + 1):
		var caminho := Config.caminho_do_slot(numero)
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)
