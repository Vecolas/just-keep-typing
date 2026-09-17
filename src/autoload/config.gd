## As opcoes da INSTALACAO: idioma, video, audio e qual slot de save esta aberto.
##
## ⚠️ NAO ENTRAM NO SAVE. Elas moram em user://opcoes.json porque sao da instalacao e nao
## da partida: trocar de slot nao pode mudar a resolucao de quem joga. Ver CONVENCOES.md,
## "Video e opcoes".
##
## CAMPO E GENERICO, E A ABA E SO MAIS UMA COLUNA DA TABELA (issue #41). rotulos_de /
## indice_de / escolher sao a API dos campos de LISTA; faixa_de / valor_de / definir, a dos
## de FAIXA. A tela percorre a tabela e nao sabe o que campo nenhum contem -- no dia em que
## aparecer um `if campo == "resolucao"` la dentro, a generalizacao ja quebrou e o conserto
## e aqui.
##
## Opcao nova e UMA LINHA em CAMPOS mais uma entrada em PADRAO. As enumeradas trazem os
## proprios valores e rotulos na linha; so as que o jogo calcula em runtime -- idioma e
## resolucao -- tem ramo em codigo.
##
## ⚠️ O CAMPO "slot" SAIU DAQUI. Escolher Manuscrito e a tela de Arquivos (issue #40);
## trocar de save por dentro das opcoes, no meio da partida, e o gesto que apaga progresso
## sem querer. O slot continua GUARDADO aqui -- e onde mora "qual foi o ultimo" --, mas
## quem o troca e Cenas.comecar_partida, e o unico caminho ate la passa por
## Cenas.voltar_ao_menu, que grava antes de sair.
##
## O que a tela nao consegue quebrar, porque nao esta na mao dela:
##
##   ⚠️ A LISTA DE RESOLUCOES E FILTRADA PELA JANELA INTEIRA, e nao pelo monitor. Oferecer
##   2560x1440 a quem tem 1080p cria uma janela maior que a tela, com a barra de titulo
##   acima da area visivel -- e a pessoa nao tem como voltar as opcoes para desfazer. Nao ha
##   "cancelar" para isso. Filtrar pelo tamanho do monitor nao bastava: a moldura do sistema
##   come 16x39 pixels, entao a maior da lista tambem nao cabia (ver area_util).
##
##   ⚠️ TELA CHEIA SEM EXCLUSIVIDADE. WINDOW_MODE_FULLSCREEN, nunca EXCLUSIVE: no Windows a
##   exclusiva pisca a tela inteira a cada alt-tab, e este e um jogo que fica aberto atras
##   de outra coisa.
extends Node

const CAMINHO_PADRAO := "user://opcoes.json"

## Variavel e nao constante, pelo mesmo motivo do Save.caminho: sem isto a suite
## sobrescreveria as opcoes de quem esta desenvolvendo toda vez que rodasse.
var caminho: String = CAMINHO_PADRAO

## O modelo do caminho de cada slot -- tambem variavel, e tambem para a suite.
var modelo_de_slot: String = "user://save_%d.json"

## O que um campo e para a tela. LISTA vira um OptionButton; FAIXA, uma barra.
##
## Volume nao e lista de proposito: uma lista de numeros arbitrarios onde o mundo inteiro
## usa uma barra e interface que faz a pessoa procurar o valor dela.
enum Tipo { LISTA, FAIXA }

## As abas, na ordem em que a tela as desenha. Aba sem campo nenhum NAO e desenhada -- aba
## vazia ensina o jogador a nao clicar nas outras.
const ABAS: PackedStringArray = ["GERAL", "ÁUDIO", "VÍDEO", "INTERFACE", "ACESSIBILIDADE"]

## A tabela de campos, na ordem em que a tela os desenha dentro de cada aba.
##
## Colunas:
##   nome     a chave em PADRAO e no arquivo
##   aba      uma de ABAS
##   tipo     LISTA ou FAIXA
##   valores  LISTA enumerada: os valores crus, na ordem dos indices
##   rotulos  LISTA enumerada: o que o jogador le, um por valor (passa por tr())
##   faixa    FAIXA: minimo, maximo e passo
##   aplicar  o que chamar depois de escolher. Vazio = nada a aplicar: o valor e lido na
##            hora de usar por quem se importa, que e a regra 2 da CONVENCOES.md
##
## ⚠️ Campo sem `valores` tem ramo em codigo porque a lista DELE muda em runtime: os
## idiomas vem da tabela IDIOMAS e as resolucoes sao filtradas pelo monitor. Os outros nao
## tem, e nao devem ganhar.
const CAMPOS: Array[Dictionary] = [
	{"nome": "idioma", "aba": "GERAL", "tipo": Tipo.LISTA, "aplicar": "_aplicar_idioma"},
	{
		"nome": "autosave", "aba": "GERAL", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Desligado", "Ligado"], "aplicar": "",
	},
	{
		"nome": "confirmacoes", "aba": "GERAL", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Desligado", "Ligado"], "aplicar": "",
	},
	{
		"nome": "aviso_de_marco", "aba": "GERAL", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Desligado", "Ligado"], "aplicar": "",
	},
	{
		"nome": "aviso_de_descoberta", "aba": "GERAL", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Desligado", "Ligado"], "aplicar": "",
	},
	{
		"nome": "volume", "aba": "ÁUDIO", "tipo": Tipo.FAIXA,
		"faixa": {"minimo": 0.0, "maximo": 1.0, "passo": 0.05},
		"aplicar": "_aplicar_audio",
	},
	{"nome": "resolucao", "aba": "VÍDEO", "tipo": Tipo.LISTA, "aplicar": "_aplicar_video"},
	{
		"nome": "tela_cheia", "aba": "VÍDEO", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Janela", "Tela cheia"],
		"aplicar": "_aplicar_video",
	},
	{
		"nome": "vsync", "aba": "VÍDEO", "tipo": Tipo.LISTA,
		# os valores sao os do DisplayServer.VSyncMode, e nao uma numeracao propria: dois
		# jeitos de numerar a mesma coisa divergem na primeira versao da engine
		"valores": [
			DisplayServer.VSYNC_DISABLED,
			DisplayServer.VSYNC_ENABLED,
			DisplayServer.VSYNC_ADAPTIVE,
		],
		"rotulos": ["Desligado", "Ligado", "Adaptativo"],
		"aplicar": "_aplicar_video",
	},
	{
		"nome": "limite_de_fps", "aba": "VÍDEO", "tipo": Tipo.LISTA,
		# ⚠️ ZERO E "SEM LIMITE", e nao "nao configurado". E o valor que o Godot entende
		# por ilimitado em Engine.max_fps, e inventar um sentinela proprio ao lado dele
		# seria uma segunda numeracao para a mesma coisa
		"valores": [0, 30, 60, 120, 144],
		"rotulos": ["Sem limite", "30", "60", "120", "144"],
		"aplicar": "_aplicar_video",
	},
	{
		"nome": "modo_economico", "aba": "VÍDEO", "tipo": Tipo.LISTA,
		"valores": [false, true], "rotulos": ["Desligado", "Ligado"],
		"aplicar": "_aplicar_video",
	},
]

## Quantos quadros por segundo o jogo desenha com a janela em segundo plano e o modo
## economico ligado. Limite de DESIGN e nao botao de tuning: este e um jogo que fica aberto
## atras de outra coisa, e dez quadros por segundo ainda e uma animacao.
const FPS_EM_SEGUNDO_PLANO: int = 10

## Instalacao nova. Tambem e o que preenche opcao que falta num arquivo antigo -- o mesmo
## cuidado do save: campo novo ganha padrao, nunca zero em cima do que a pessoa ja tinha
## escolhido.
##
## ⚠️ "slot" CONTINUA AQUI e nao esta em CAMPOS: e estado da instalacao (qual Manuscrito
## foi o ultimo), e nao uma opcao que a tela ofereca.
const PADRAO := {
	"idioma": "pt_BR",
	"autosave": true,
	"confirmacoes": true,
	"aviso_de_marco": true,
	"aviso_de_descoberta": true,
	"volume": 0.8,
	"resolucao": "1280x720",
	"tela_cheia": false,
	"vsync": DisplayServer.VSYNC_ENABLED,
	"limite_de_fps": 60,
	"modo_economico": true,
	"slot": 1,
}

## Idioma traz as convencoes junto, e nao so as palavras (CONVENCOES.md, "Idioma"). Nem o
## relogio nem o Formatador tem ramo por lingua: os dois perguntam a esta tabela.
##
## Idioma novo e uma linha aqui mais uma coluna no CSV.
const IDIOMAS: Array[Dictionary] = [
	{
		"codigo": "pt_BR", "nome": "Português",
		"relogio_12h": false, "data_dia_primeiro": true, "moeda": &"BRL",
	},
	{
		"codigo": "en", "nome": "English",
		"relogio_12h": true, "data_dia_primeiro": false, "moeda": &"USD",
	},
]

## O catalogo inteiro. O que a tela ve e o resultado de resolucoes(), que corta o que nao
## cabe no monitor.
const RESOLUCOES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const SLOTS: int = 3

var _opcoes: Dictionary = PADRAO.duplicate(true)

## Se a janela do jogo esta na frente. Comeca verdadeiro: o jogo abre com foco, e comecar
## em falso deixaria a primeira sessao presa no limite de segundo plano ate o primeiro
## alt-tab de ida e volta.
var _em_primeiro_plano: bool = true


func _ready() -> void:
	_trazer_o_save_antigo()
	carregar()
	aplicar()


## Antes dos slots o jogo gravava em user://save.json. Quem jogou a v0.3 tem a partida la,
## e ela vira o slot 1 -- renomeada uma vez, na primeira abertura da v0.4.
##
## Sem isto o jogador abriria a v0.4 num slot 1 vazio com o progresso dele intacto num
## arquivo que o jogo nunca mais olha, o que e pior que perder: e perder em silencio.
func _trazer_o_save_antigo() -> void:
	var slot_um := caminho_do_slot(1)
	if not FileAccess.file_exists(Save.CAMINHO_PADRAO) or FileAccess.file_exists(slot_um):
		return
	if DirAccess.rename_absolute(Save.CAMINHO_PADRAO, slot_um) != OK:
		push_error("Config: nao consegui mover o save antigo para %s" % slot_um)
		return
	print("Config: o save de antes dos slots virou o slot 1")


# --------------------------------------------------------------------------- persistencia

func carregar() -> void:
	_opcoes = PADRAO.duplicate(true)
	if not FileAccess.file_exists(caminho):
		return
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Config: nao abriu %s para leitura" % caminho)
		return
	var cru = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	if typeof(cru) != TYPE_DICTIONARY:
		push_error("Config: %s nao contem um objeto JSON" % caminho)
		return
	# so o que o jogo conhece entra: opcao de uma versao futura nao vira estado aqui
	for nome in PADRAO:
		if cru.has(nome):
			_opcoes[nome] = _do_tipo_de(PADRAO[nome], cru[nome])


## O valor lido, convertido para o TIPO que o padrao declara.
##
## ⚠️ ISTO NAO E ZELO, E CONSERTO DE UM BUG MEDIDO. O JSON devolve todo numero como FLOAT:
## um vsync gravado como 1 volta 1.0. E a comparacao de Variant do Godot confere o TIPO
## antes do valor -- [0, 1, 2].find(1.0) devolve -1, nao 1. O efeito foi uma tela de
## opcoes em que TODO campo numerico voltava do arquivo mostrando a primeira opcao, como
## se a escolha da pessoa nunca tivesse sido gravada. Nenhum erro, nenhum aviso: so a
## configuracao dela desaparecendo a cada abertura do jogo.
static func _do_tipo_de(modelo: Variant, lido: Variant) -> Variant:
	match typeof(modelo):
		TYPE_INT:
			return int(lido)
		TYPE_FLOAT:
			return float(lido)
		TYPE_BOOL:
			return bool(lido)
		TYPE_STRING:
			return str(lido)
	return lido


func gravar() -> bool:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		push_error("Config: nao abriu %s para escrita" % caminho)
		return false
	arquivo.store_string(JSON.stringify(_opcoes, "\t"))
	arquivo.close()
	return true


## Poe no mundo o que esta guardado. Chamada uma vez na abertura; depois disso cada
## escolher() aplica so o campo que mudou.
func aplicar() -> void:
	_aplicar_idioma()
	_aplicar_video()
	_aplicar_audio()
	Save.caminho = caminho_do_slot(slot())


# -------------------------------------------------------------------------- API generica

## A linha da tabela de um campo, ou vazia quando ele nao existe.
func campo(nome: String) -> Dictionary:
	for linha in CAMPOS:
		if linha["nome"] == nome:
			return linha
	return {}


## Os nomes de todos os campos declarados. E o que a suite percorre para exigir que cada um
## responda a API inteira: campo declarado sem resposta apareceria na tela vazio.
func nomes_de_campo() -> PackedStringArray:
	var nomes := PackedStringArray()
	for linha in CAMPOS:
		nomes.append(str(linha["nome"]))
	return nomes


## Os campos de uma aba, na ordem da tabela. Aba sem campo devolve lista vazia, e a tela
## nao a desenha.
func campos_da_aba(aba: String) -> Array[Dictionary]:
	var desta: Array[Dictionary] = []
	for linha in CAMPOS:
		if linha["aba"] == aba:
			desta.append(linha)
	return desta


func tipo_de(nome: String) -> Tipo:
	var linha := campo(nome)
	return linha["tipo"] if linha.has("tipo") else Tipo.LISTA


## Os rotulos de um campo de lista, na ordem dos indices. A tela nao sabe o que sao.
func rotulos_de(nome: String) -> PackedStringArray:
	var rotulos := PackedStringArray()
	match nome:
		"idioma":
			# cada idioma escrito NO PROPRIO idioma, e por isso nao passa por tr(): quem
			# abriu a tela sem querer numa lingua que nao le precisa reconhecer a dele
			for tabela in IDIOMAS:
				rotulos.append(str(tabela["nome"]))
			return rotulos
		"resolucao":
			for tamanho in resolucoes():
				rotulos.append(_rotulo_de(tamanho))
			return rotulos

	var linha := campo(nome)
	if not linha.has("rotulos"):
		push_error("Config: campo %s nao tem rotulos" % nome)
		return rotulos
	for texto in linha["rotulos"]:
		# numero cru continua numero: "30" nao muda de idioma, e a tabela de traducao nao
		# tem linha para ele. tr() de chave ausente devolve a propria chave, entao isto e
		# seguro para os dois casos.
		rotulos.append(tr(str(texto)))
	return rotulos


## O indice escolhido agora. Sempre valido: opcao que saiu do catalogo -- resolucao que nao
## cabe mais porque a pessoa trocou de monitor -- cai no primeiro.
func indice_de(nome: String) -> int:
	match nome:
		"idioma":
			for i in IDIOMAS.size():
				if IDIOMAS[i]["codigo"] == _opcoes["idioma"]:
					return i
			return 0
		"resolucao":
			var lista := resolucoes()
			for i in lista.size():
				if _rotulo_de(lista[i]) == str(_opcoes["resolucao"]):
					return i
			return 0

	var linha := campo(nome)
	if not linha.has("valores"):
		push_error("Config: campo %s nao tem indice" % nome)
		return 0
	var indice: int = (linha["valores"] as Array).find(_opcoes.get(nome))
	# valor que saiu da tabela -- opcao de uma versao anterior -- cai no primeiro, e nao
	# num indice negativo que a tela usaria para indexar
	return maxi(indice, 0)


## O minimo, o maximo e o passo de um campo de FAIXA.
func faixa_de(nome: String) -> Dictionary:
	var linha := campo(nome)
	if not linha.has("faixa"):
		push_error("Config: campo %s nao e de faixa" % nome)
		return {"minimo": 0.0, "maximo": 1.0, "passo": 0.1}
	return linha["faixa"]


func valor_de(nome: String) -> float:
	var limites := faixa_de(nome)
	return clampf(float(_opcoes.get(nome, 0.0)), limites["minimo"], limites["maximo"])


## Define um campo de FAIXA e aplica. Grava na hora, pelo mesmo motivo do escolher().
func definir(nome: String, valor: float) -> void:
	var linha := campo(nome)
	if not linha.has("faixa"):
		push_error("Config: campo %s nao e de faixa" % nome)
		return
	var limites: Dictionary = linha["faixa"]
	_opcoes[nome] = clampf(valor, limites["minimo"], limites["maximo"])
	_efeito_de(linha)
	gravar()


## Escolhe e aplica. Grava na hora: opcao que so persiste ao fechar o jogo e opcao perdida
## quando o jogo fecha de outro jeito.
##
## ⚠️ RECUSA INDICE QUE NAO EXISTE, e nao grampeia. A primeira versao usava clampi, e um
## indice invalido levava o jogador para a ULTIMA opcao da lista -- que, no campo de slot
## que morava aqui, trocava a partida dele por outra sem ninguem ter pedido. O campo saiu
## (issue #41); a regra fica, porque ela vale para qualquer campo que venha depois.
func escolher(nome: String, indice: int) -> void:
	var linha := campo(nome)
	if linha.is_empty():
		push_error("Config: campo %s nao existe" % nome)
		return
	if indice < 0 or indice >= rotulos_de(nome).size():
		return

	match nome:
		"idioma":
			_opcoes["idioma"] = IDIOMAS[indice]["codigo"]
		"resolucao":
			_opcoes["resolucao"] = _rotulo_de(resolucoes()[indice])
		_:
			if not linha.has("valores"):
				push_error("Config: campo %s nao tem valores" % nome)
				return
			_opcoes[nome] = (linha["valores"] as Array)[indice]

	_efeito_de(linha)
	gravar()


## O que rodar depois de mudar um campo. Vazio e legitimo e comum: opcao lida na hora de
## usar -- avisos, confirmacoes, autosave -- nao tem o que aplicar, e inventar um efeito
## para ela seria inventar um segundo lugar onde o valor vale.
func _efeito_de(linha: Dictionary) -> void:
	var metodo := str(linha.get("aplicar", ""))
	if metodo.is_empty():
		return
	Callable(self, metodo).call()


## Se o campo esta apagado agora. Resolucao em tela cheia nao faz nada, e campo que nao faz
## nada tem que PARECER que nao faz nada -- senao a pessoa mexe nele e conclui que o jogo
## ignorou a escolha dela.
func apagado(nome: String) -> bool:
	return nome == "resolucao" and tela_cheia()


# ------------------------------------------------------------------------------ consultas

## O que cabe NESTE monitor, com a JANELA INTEIRA em conta. Nunca volta vazia: a menor do
## catalogo fica de qualquer jeito, porque uma lista vazia deixaria a pessoa sem campo
## nenhum.
##
## ⚠️ Monitor de tamanho desconhecido (0x0 -- headless, ou o DisplayServer ainda subindo)
## cai no MENOR do catalogo, e nao no maior. Errar para o lado pequeno da uma janela menor
## que o necessario; errar para o grande da uma janela sem barra de titulo alcancavel.
func resolucoes() -> Array[Vector2i]:
	var area := area_util()
	var cabem: Array[Vector2i] = []
	for tamanho in RESOLUCOES:
		if tamanho.x <= area.x and tamanho.y <= area.y:
			cabem.append(tamanho)
	if cabem.is_empty():
		cabem.append(RESOLUCOES[0])
	return cabem


## O maior tamanho de AREA DE CLIENTE que cabe neste monitor: o retangulo util (sem a barra
## de tarefas) menos a moldura que o sistema desenha em volta da janela.
##
## ⚠️ SEM DESCONTAR AS DUAS, A MAIOR RESOLUCAO DA LISTA NUNCA CABE. Medido nesta maquina:
## monitor de 1920x1080, janela de cliente 1920x1080, moldura de 16x39 -- a janela inteira
## pede 1936x1119 e sobra para fora da tela em todas as direcoes. Era o que fazia o jogo
## aparecer cortado nas bordas e com botao que nao da para alcancar.
##
## A lista so vale em janela: em tela cheia o campo fica apagado (apagado("resolucao")), e
## la o jogo usa o monitor inteiro sem passar por aqui.
func area_util() -> Vector2i:
	var tela := DisplayServer.window_get_current_screen()
	var util := DisplayServer.screen_get_usable_rect(tela).size
	return util - moldura_da_janela()


## O que a moldura do sistema come de largura e de altura. Zero quando nao ha janela.
func moldura_da_janela() -> Vector2i:
	var com := DisplayServer.window_get_size_with_decorations()
	var sem := DisplayServer.window_get_size()
	return Vector2i(maxi(com.x - sem.x, 0), maxi(com.y - sem.y, 0))


## Onde por uma janela deste tamanho: centralizada na area, e nunca com a barra de titulo
## fora dela.
##
## ⚠️ REDIMENSIONAR SEM REPOSICIONAR E METADE DO ESTRAGO. window_set_size cresce a janela a
## partir do canto onde ela ja estava: medido nesta maquina, escolher 1920x1080 com a janela
## no lugar padrao deixou o canto em (320, 180) e a janela terminando em (2240, 1260) --
## trezentos e vinte pixels de jogo fora da tela, do lado direito, sem barra de rolagem
## nenhuma para alcancar.
##
## Pura e estatica para a suite poder afirmar isto sem monitor (headless nao tem tela).
static func posicao_centralizada(
	tamanho: Vector2i, area: Rect2i, moldura: Vector2i
) -> Vector2i:
	var livre := area.size - tamanho - moldura
	return Vector2i(
		area.position.x + maxi(livre.x, 0) / 2 + moldura.x / 2,
		# a barra de titulo mora ACIMA da area de cliente: sem descer a altura dela, o
		# unico jeito de mover ou fechar a janela fica fora da tela
		area.position.y + maxi(livre.y, 0) / 2 + moldura.y,
	)


func idioma() -> String:
	return str(_opcoes["idioma"])


## A tabela do idioma em uso. Quem precisa de relogio de 12 h ou de simbolo de moeda
## pergunta aqui, e nao a um ramo por lingua.
func convencoes() -> Dictionary:
	for tabela in IDIOMAS:
		if tabela["codigo"] == _opcoes["idioma"]:
			return tabela
	return IDIOMAS[0]


func tela_cheia() -> bool:
	return bool(_opcoes["tela_cheia"])


func volume() -> float:
	return valor_de("volume")


## Se uma opcao de liga/desliga esta ligada. Quem se importa LE NA HORA DE USAR, e nunca
## guarda o resultado (CONVENCOES.md, regra 2): a pessoa muda a opcao no meio da partida, e
## uma copia guardada continuaria valendo a escolha antiga sem dar erro nenhum.
func ligado(nome: String) -> bool:
	return bool(_opcoes.get(nome, false))


## O limite de quadros que vale AGORA -- derivado, e nunca guardado.
##
## ⚠️ E O UNICO LUGAR QUE ESCREVE Engine.max_fps. Duas fontes para o mesmo global -- o
## campo de limite e o modo economico -- e a familia de bug em que a janela volta do
## segundo plano presa em dez quadros por segundo, sem uma linha no console.
func fps_efetivo() -> int:
	if ligado("modo_economico") and not _em_primeiro_plano:
		return FPS_EM_SEGUNDO_PLANO
	return int(_opcoes.get("limite_de_fps", 0))


## ⚠️ QUEM LIGA, DESLIGA, E NO MESMO LUGAR. O modo economico so existe porque este autoload
## sabe se a janela esta na frente; espalhar esse par pelas cenas seria garantir que uma
## delas esquecesse de religar (CONVENCOES.md).
func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_em_primeiro_plano = false
		_aplicar_ritmo_do_quadro()
	elif que == NOTIFICATION_APPLICATION_FOCUS_IN:
		_em_primeiro_plano = true
		_aplicar_ritmo_do_quadro()


func slot() -> int:
	return clampi(int(_opcoes["slot"]), 1, SLOTS)


func caminho_do_slot(numero: int) -> String:
	return modelo_de_slot % clampi(numero, 1, SLOTS)


## O cartao de um slot, SEM abrir a partida dele (issue #35). E o que o menu chama para
## desenhar a lista dos tres Manuscritos: carregar os tres para saber o que mostrar faria
## cada um creditar a producao offline por cima do outro.
##
## Mora aqui porque quem sabe onde cada slot fica e este autoload; o Manuscrito so entende
## de um caminho por vez, e nao pergunta nada de volta -- ver o aviso la.
func manuscrito_do_slot(numero: int) -> Manuscrito:
	var caminho_do_save := caminho_do_slot(numero)
	# o backup entra como reserva pelo mesmo motivo que ele existe: o menu tem que dizer
	# sobre o slot o mesmo que o Save fara ao abri-lo (issue #36)
	var manuscrito := Manuscrito.de_arquivo(
		caminho_do_save, Save.caminho_do_backup(caminho_do_save)
	)
	manuscrito.slot = clampi(numero, 1, SLOTS)
	return manuscrito


static func _rotulo_de(tamanho: Vector2i) -> String:
	# marca de formato, nao texto: "1920x1080" nao muda de idioma
	return "%dx%d" % [tamanho.x, tamanho.y]


# -------------------------------------------------------------------------------- efeitos

func _aplicar_idioma() -> void:
	TranslationServer.set_locale(idioma())
	EventBus.idioma_mudou.emit(idioma())


func _aplicar_video() -> void:
	_aplicar_ritmo_do_quadro()
	if tela_cheia():
		# FULLSCREEN e nao EXCLUSIVE_FULLSCREEN: a exclusiva pisca a tela a cada alt-tab
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var lista := resolucoes()
	var tamanho := lista[indice_de("resolucao")]
	DisplayServer.window_set_size(tamanho)
	# e reposiciona: crescer a janela a partir do canto onde ela estava joga o lado direito
	# e o rodape para fora da tela, e nao ha rolagem que alcance isso
	var tela := DisplayServer.window_get_current_screen()
	DisplayServer.window_set_position(posicao_centralizada(
		tamanho, DisplayServer.screen_get_usable_rect(tela), moldura_da_janela()
	))


## O ritmo do quadro: vsync e teto de quadros por segundo.
##
## ⚠️ NAO SE APLICA SEM JANELA, e isto ja custou uma tarde. Headless nao desenha nada, mas
## Engine.max_fps continua ritmando o laco principal -- com o teto em 60, cada
## `await process_frame` da fumaca passou a esperar um sexagesimo de segundo, e o teste que
## roda em trinta segundos parou de terminar. Ele nao quebrou: ficou LENTO, que e a versao
## mais cara desse defeito.
##
## O que se perde ao pular: nada que a suite prove. A conta esta em fps_efetivo(), que e
## logica pura e tem portao proprio; o que se pula aqui e so a aplicacao dela numa janela
## que nao existe.
func _aplicar_ritmo_do_quadro() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(
		int(_opcoes.get("vsync", DisplayServer.VSYNC_ENABLED)) as DisplayServer.VSyncMode
	)
	Engine.max_fps = fps_efetivo()


func _aplicar_audio() -> void:
	var barramento := AudioServer.get_bus_index("Master")
	if barramento < 0:
		return
	AudioServer.set_bus_volume_db(barramento, linear_to_db(maxf(volume(), 0.0001)))
	AudioServer.set_bus_mute(barramento, volume() <= 0.0)


## Aponta o jogo para um slot SEM gravar o que estava aberto, e guarda a escolha.
##
## ⚠️ NAO GRAVAR AQUI E DE PROPOSITO. Isto so e chamado a partir do menu ou dos Arquivos, e
## la nao ha partida aberta: o Jogo esta no estado de partida nova que os autoloads
## deixaram, e gravar isso escreveria um Manuscrito VAZIO por cima do Manuscrito de quem so
## passou pela tela. Quem grava a partida que estava aberta e Cenas.voltar_ao_menu, antes
## de chegar ate aqui.
##
## ⚠️ RECUSA, e nao clampi: slot invalido levaria o jogador para o ULTIMO Manuscrito, e
## trocar a partida de alguem por outra sem ninguem ter pedido nao tem desfazer.
##
## Quem carrega o save depois disto e o Cenas -- aqui so se aponta o caminho.
func abrir_slot(numero: int) -> void:
	if numero < 1 or numero > SLOTS:
		push_error("Config: nao existe slot %d" % numero)
		return
	_opcoes["slot"] = numero
	Save.caminho = caminho_do_slot(numero)
	gravar()
	EventBus.slot_mudou.emit(numero)


## ⚠️ AQUI MORAVA _trocar_de_slot, E ELE SAIU NA ISSUE #41. Ele so era alcancado pelo
## campo "slot" da tela de opcoes, que foi removido; codigo morto que afirma uma regra --
## "trocar de slot grava o que estava aberto" -- volta a rodar no dia em que alguem criar o
## primeiro caminho que o alcance, e faz a coisa errada sem uma linha no console.
##
## A regra continua valendo, por outra porta: o unico jeito de trocar de Manuscrito agora e
## voltar ao menu, e Cenas.voltar_ao_menu grava antes de sair.
