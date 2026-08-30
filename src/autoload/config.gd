## As opcoes da INSTALACAO: idioma, video, audio e qual slot de save esta aberto.
##
## ⚠️ NAO ENTRAM NO SAVE. Elas moram em user://opcoes.json porque sao da instalacao e nao
## da partida: trocar de slot nao pode mudar a resolucao de quem joga. Ver CONVENCOES.md,
## "Video e opcoes".
##
## CAMPO DE LISTA E GENERICO. rotulos_de / indice_de / escolher sao a API inteira que a
## tela de opcoes usa, e ela nao sabe o que campo nenhum contem -- monta um OptionButton
## para cada nome de CAMPOS e pronto. Opcao nova e uma entrada em PADRAO, uma em CAMPOS e
## um ramo em cada uma das tres funcoes; nenhuma linha da tela muda.
##
## O que a tela nao consegue quebrar, porque nao esta na mao dela:
##
##   ⚠️ A LISTA DE RESOLUCOES E FILTRADA PELO MONITOR. Oferecer 2560x1440 a quem tem 1080p
##   cria uma janela maior que a tela, com a barra de titulo acima da area visivel -- e a
##   pessoa nao tem como voltar as opcoes para desfazer. Nao ha "cancelar" para isso.
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

## Os campos de lista, na ordem em que a tela os desenha.
const CAMPOS: PackedStringArray = ["idioma", "resolucao", "tela_cheia", "slot"]

## Instalacao nova. Tambem e o que preenche opcao que falta num arquivo antigo -- o mesmo
## cuidado do save: campo novo ganha padrao, nunca zero em cima do que a pessoa ja tinha
## escolhido.
const PADRAO := {
	"idioma": "pt_BR",
	"resolucao": "1280x720",
	"tela_cheia": false,
	"volume": 0.8,
	"slot": 1,
}

## Idioma traz as convencoes junto, e nao so as palavras (CONVENCOES.md, "Idioma"). Nem o
## relogio nem o Formatador tem ramo por lingua: os dois perguntam a esta tabela.
##
## Idioma novo e uma linha aqui mais uma coluna no CSV.
const IDIOMAS: Array[Dictionary] = [
	{"codigo": "pt_BR", "nome": "Português", "relogio_12h": false, "moeda": &"BRL"},
	{"codigo": "en", "nome": "English", "relogio_12h": true, "moeda": &"USD"},
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
	for campo in PADRAO:
		if cru.has(campo):
			_opcoes[campo] = cru[campo]


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

## Os rotulos de um campo de lista, na ordem dos indices. A tela nao sabe o que sao.
func rotulos_de(campo: String) -> PackedStringArray:
	var rotulos := PackedStringArray()
	match campo:
		"idioma":
			# cada idioma escrito NO PROPRIO idioma, e por isso nao passa por tr(): quem
			# abriu a tela sem querer numa lingua que nao le precisa reconhecer a dele
			for tabela in IDIOMAS:
				rotulos.append(str(tabela["nome"]))
		"resolucao":
			for tamanho in resolucoes():
				rotulos.append(_rotulo_de(tamanho))
		"tela_cheia":
			rotulos.append(tr("Janela"))
			rotulos.append(tr("Tela cheia"))
		"slot":
			# numero cru: marca de formato, nao texto (CONVENCOES.md)
			for numero in range(1, SLOTS + 1):
				rotulos.append(str(numero))
		_:
			push_error("Config: campo %s nao tem rotulos" % campo)
	return rotulos


## O indice escolhido agora. Sempre valido: opcao que saiu do catalogo -- resolucao que nao
## cabe mais porque a pessoa trocou de monitor -- cai no primeiro.
func indice_de(campo: String) -> int:
	match campo:
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
		"tela_cheia":
			return 1 if tela_cheia() else 0
		"slot":
			return clampi(slot() - 1, 0, SLOTS - 1)
	push_error("Config: campo %s nao tem indice" % campo)
	return 0


## Escolhe e aplica. Grava na hora: opcao que so persiste ao fechar o jogo e opcao perdida
## quando o jogo fecha de outro jeito.
func escolher(campo: String, indice: int) -> void:
	match campo:
		"idioma":
			if indice < 0 or indice >= IDIOMAS.size():
				return
			_opcoes["idioma"] = IDIOMAS[indice]["codigo"]
			_aplicar_idioma()
		"resolucao":
			var lista := resolucoes()
			if indice < 0 or indice >= lista.size():
				return
			_opcoes["resolucao"] = _rotulo_de(lista[indice])
			_aplicar_video()
		"tela_cheia":
			_opcoes["tela_cheia"] = indice == 1
			_aplicar_video()
		"slot":
			# ⚠️ RECUSA, e nao clampi. A primeira versao grampeava o indice, e um indice
			# invalido levava o jogador para o ULTIMO slot -- trocando a partida dele por
			# outra sem ninguem ter pedido. Campo de lista recusa o que nao existe; o unico
			# que nao pode e o que mexe em save.
			if indice < 0 or indice >= SLOTS:
				return
			_trocar_de_slot(indice + 1)
		_:
			push_error("Config: campo %s nao existe" % campo)
			return
	gravar()


## Se o campo esta apagado agora. Resolucao em tela cheia nao faz nada, e campo que nao faz
## nada tem que PARECER que nao faz nada -- senao a pessoa mexe nele e conclui que o jogo
## ignorou a escolha dela.
func apagado(campo: String) -> bool:
	return campo == "resolucao" and tela_cheia()


# ------------------------------------------------------------------------------ consultas

## O que cabe NESTE monitor. Nunca volta vazia: a menor do catalogo fica de qualquer jeito,
## porque uma lista vazia deixaria a pessoa sem campo nenhum.
## ⚠️ Monitor de tamanho desconhecido (0x0 -- headless, ou o DisplayServer ainda subindo)
## cai no MENOR do catalogo, e nao no maior. Errar para o lado pequeno da uma janela menor
## que o necessario; errar para o grande da uma janela sem barra de titulo alcancavel.
func resolucoes() -> Array[Vector2i]:
	var tela := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var cabem: Array[Vector2i] = []
	for tamanho in RESOLUCOES:
		if tamanho.x <= tela.x and tamanho.y <= tela.y:
			cabem.append(tamanho)
	if cabem.is_empty():
		cabem.append(RESOLUCOES[0])
	return cabem


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
	return clampf(float(_opcoes["volume"]), 0.0, 1.0)


func definir_volume(valor: float) -> void:
	_opcoes["volume"] = clampf(valor, 0.0, 1.0)
	_aplicar_audio()
	gravar()


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
	var manuscrito := Manuscrito.de_arquivo(caminho_do_slot(numero))
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
	if tela_cheia():
		# FULLSCREEN e nao EXCLUSIVE_FULLSCREEN: a exclusiva pisca a tela a cada alt-tab
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var lista := resolucoes()
	DisplayServer.window_set_size(lista[indice_de("resolucao")])


func _aplicar_audio() -> void:
	var barramento := AudioServer.get_bus_index("Master")
	if barramento < 0:
		return
	AudioServer.set_bus_volume_db(barramento, linear_to_db(maxf(volume(), 0.0001)))
	AudioServer.set_bus_mute(barramento, volume() <= 0.0)


## Trocar de slot GRAVA O QUE ESTAVA ABERTO ANTES. Sem isto, mudar de slot so para dar uma
## olhada apagaria os minutos desde o ultimo autosave -- e o jogador nao pediu isso.
##
## Slot vazio comeca partida nova a partir do MESMO dicionario de padroes que a migracao de
## save usa: duas definicoes de "partida nova" divergiriam na primeira issue.
func _trocar_de_slot(numero: int) -> void:
	if numero == slot():
		return
	Save.gravar()
	_opcoes["slot"] = numero
	Save.caminho = caminho_do_slot(numero)
	if Save.existe():
		Save.carregar()
	else:
		Save.recomecar()
	EventBus.slot_mudou.emit(numero)
