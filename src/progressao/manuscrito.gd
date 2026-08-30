## O cartao de visita de um slot de save: o que o menu precisa saber para desenhar a lista
## de Manuscritos SEM abrir partida nenhuma (issue #35).
##
## ⚠️ ESTE E O PONTO INTEIRO DA CLASSE. Ate aqui o jogo so sabia algo sobre uma partida
## depois de aplica-la no Jogo -- e com tres slots isso seria carregar tres partidas para
## desenhar uma tela, cada uma delas creditando producao offline por cima da outra. O menu
## le metadado; so o slot escolhido vira partida.
##
## ⚠️ METADADO E DERIVADO, NUNCA FONTE. Todo campo daqui existe no save; o .meta e uma
## copia adiantada, escrita na mesma gravacao. Quando os dois discordam, o save vence -- e
## por isso ler um .meta ausente ou corrompido nao e erro: a classe reconstroi tudo lendo o
## JSON do save (sem aplicar nada no Jogo) e o slot abre igual.
##
## O corolario, que custou uma falha de suite: o .meta so vale se o arquivo que ele
## descreve ABRIR. Metadado sobrevive ao save, e um cartao intacto ao lado de um principal
## corrompido anunciaria no menu uma partida que o Save nao carrega.
##
## Nome e data de criacao moram no save pelo mesmo motivo. Se vivessem so no .meta, apagar
## o .meta apagaria o nome que o jogador escolheu, calado.
##
## TRES ESTADOS, E NAO DOIS. Vazio, cheio e ilegivel sao coisas diferentes para quem esta
## na tela: "comecar aqui", "continuar isto" e "alguma coisa aconteceu com este arquivo".
## Tratar ilegivel como vazio ofereceria ao jogador apagar centenas de horas achando que
## esta clicando num slot livre.
class_name Manuscrito
extends RefCounted

enum Estado {
	VAZIO,      ## nao ha save neste slot
	CHEIO,      ## ha partida, e o metadado abaixo vale
	ILEGIVEL,   ## ha arquivo, e nem o save nem o metadado abrem
}

## Sufixo do arquivo de metadados, ao lado do save: user://save_1.json.meta.
const SUFIXO := ".meta"

## Sobe quando a forma do .meta muda. Metadado de versao desconhecida nao e migrado: e
## descartado e reconstruido do save, que e a fonte. Barato, e nunca mente.
const VERSAO: int = 1

var estado: Estado = Estado.VAZIO

## Qual slot este Manuscrito e. Zero quando foi lido de um caminho solto: quem sabe a
## numeracao dos slots e o Config, e e por la que o menu pede um Manuscrito.
##
## ⚠️ ESTA CLASSE NAO PERGUNTA NADA AO Config. Ela chegou a ter um de_slot() proprio, e o
## preco foi um ciclo: Config le Save, Save escreve o metadado, e o metadado voltava a ler
## o Config. O autoload Save subiu como Nil e a suite inteira caiu depois dele -- com todos
## os arquivos corretos, um a um. Caminho entra por parametro.
var slot: int = 0

## O nome dado pelo jogador. Vazio significa "ainda sem nome" -- quem escolhe o rotulo de
## um Manuscrito sem nome e a tela, na issue #40, e nao esta classe.
var nome: String = ""

var criado_em: float = 0.0

## Quando o slot foi gravado pela ultima vez. E a "ultima sessao" da tela.
var ultima_sessao: float = 0.0

var tempo_jogado: float = 0.0

## Id da era em que a partida parou -- id, e nao nome: nome e texto que muda de idioma, e o
## .meta e gravado uma vez e lido em qualquer lingua. Quem quer o nome pergunta ao
## ErasCatalogo e passa por tr().
var era: String = ""

var total_caracteres: Grande = Grande.zero()
var por_segundo: Grande = Grande.zero()
var prestigios: int = 0


func vazio() -> bool:
	return estado == Estado.VAZIO


func cheio() -> bool:
	return estado == Estado.CHEIO


func ilegivel() -> bool:
	return estado == Estado.ILEGIVEL


# ------------------------------------------------------------------------------- leitura

## O Manuscrito de um caminho de save qualquer. Nunca devolve null: slot sem arquivo e um
## Manuscrito VAZIO, e nao a ausencia de um.
##
## `reserva` e o caminho do backup (issue #36). O menu tem que dizer sobre o slot o mesmo
## que o Save fara ao abri-lo: se a partida vai carregar do backup, o slot esta CHEIO, e
## chama-lo de ilegivel seria assustar o jogador com um arquivo que o jogo recupera sozinho.
static func de_arquivo(caminho_do_save: String, reserva: String = "") -> Manuscrito:
	var manuscrito := _de_um_arquivo(caminho_do_save)
	if manuscrito.cheio() or reserva.is_empty():
		return manuscrito

	var copia := _de_um_arquivo(reserva)
	if copia.cheio():
		return copia
	# nenhum dos dois serviu: vazio so quando nao ha arquivo NENHUM, senao ilegivel
	manuscrito.estado = (
		Estado.VAZIO if manuscrito.vazio() and copia.vazio() else Estado.ILEGIVEL
	)
	return manuscrito


static func _de_um_arquivo(caminho_do_save: String) -> Manuscrito:
	var manuscrito := Manuscrito.new()
	if not FileAccess.file_exists(caminho_do_save):
		return manuscrito

	# ⚠️ O SAVE ABRE ANTES DE O .meta SER CONSULTADO. O metadado sobrevive ao arquivo que
	# ele descreve: um principal corrompido com o .meta intacto ao lado faria o menu
	# anunciar uma partida que o Save nao consegue carregar -- e o jogador clicaria nela.
	# Cartao vale por um arquivo que existe; abrir o JSON e barato, aplicar e que nao e.
	var cru = _ler_json(caminho_do_save)
	if typeof(cru) != TYPE_DICTIONARY:
		manuscrito.estado = Estado.ILEGIVEL
		return manuscrito
	manuscrito.estado = Estado.CHEIO

	var meta = _ler_json(caminho_do_meta(caminho_do_save))
	if typeof(meta) == TYPE_DICTIONARY and int(meta.get("versao", 0)) == VERSAO:
		manuscrito._do_metadado(meta)
		return manuscrito

	# sem .meta, ou com um .meta que nao serve: o save e a fonte. E o caminho de todo save
	# gravado antes da issue #35 -- ele abre e ganha o metadado na gravacao seguinte, sem o
	# jogador ver diferenca.
	manuscrito._do_save(cru)
	return manuscrito


## O Manuscrito da partida que esta na memoria agora. E o que a gravacao carimba no disco.
static func do_jogo() -> Manuscrito:
	var manuscrito := Manuscrito.new()
	manuscrito.estado = Estado.CHEIO
	manuscrito.nome = Jogo.nome
	manuscrito.criado_em = Jogo.criado_em
	manuscrito.ultima_sessao = Time.get_unix_time_from_system()
	manuscrito.tempo_jogado = Jogo.tempo_jogado
	manuscrito.era = _era_de(Jogo.total_caracteres)
	manuscrito.total_caracteres = Jogo.total_caracteres
	manuscrito.por_segundo = Jogo.caracteres_por_segundo
	manuscrito.prestigios = Jogo.prestigios
	return manuscrito


static func caminho_do_meta(caminho_do_save: String) -> String:
	return caminho_do_save + SUFIXO


# ------------------------------------------------------------------------------- gravacao

## Grava o metadado ao lado do save. Em temporario e renomeia, pelo mesmo motivo do Save:
## desligar no meio da escrita deixa o .meta anterior, que e velho mas inteiro.
func gravar_em(caminho_do_save: String) -> bool:
	var destino := caminho_do_meta(caminho_do_save)
	var temporario := destino + ".tmp"
	var arquivo := FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		push_error("Manuscrito: nao abriu %s para escrita" % temporario)
		return false
	arquivo.store_string(JSON.stringify(para_dicionario(), "\t"))
	arquivo.close()

	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)
	var erro := DirAccess.rename_absolute(temporario, destino)
	if erro != OK:
		push_error("Manuscrito: nao renomeou %s (erro %d)" % [temporario, erro])
		return false
	return true


## Apaga o metadado de um save. Chamado quando o save some -- .meta orfao faria o menu
## mostrar um Manuscrito que nao existe mais.
static func apagar_de(caminho_do_save: String) -> void:
	var destino := caminho_do_meta(caminho_do_save)
	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)


func para_dicionario() -> Dictionary:
	return {
		"versao": VERSAO,
		"nome": nome,
		"criado_em": criado_em,
		"ultima_sessao": ultima_sessao,
		"tempo_jogado": tempo_jogado,
		"era": era,
		"total_caracteres": total_caracteres.para_texto(),
		"por_segundo": por_segundo.para_texto(),
		"prestigios": prestigios,
	}


# --------------------------------------------------------------------------- reconstrucao

func _do_metadado(dados: Dictionary) -> void:
	nome = str(dados.get("nome", ""))
	criado_em = float(dados.get("criado_em", 0.0))
	ultima_sessao = float(dados.get("ultima_sessao", 0.0))
	tempo_jogado = float(dados.get("tempo_jogado", 0.0))
	era = str(dados.get("era", ""))
	total_caracteres = Grande.de_texto(str(dados.get("total_caracteres", "0")))
	por_segundo = Grande.de_texto(str(dados.get("por_segundo", "0")))
	prestigios = int(dados.get("prestigios", 0))


## Reconstroi o metadado a partir do JSON do save, sem aplicar nada no Jogo. As chaves sao
## as do Save; a unica que muda de nome e gravado_em, que aqui e a ultima sessao.
func _do_save(dados: Dictionary) -> void:
	nome = str(dados.get("nome", ""))
	criado_em = float(dados.get("criado_em", 0.0))
	ultima_sessao = float(dados.get("gravado_em", 0.0))
	tempo_jogado = float(dados.get("tempo_jogado", 0.0))
	total_caracteres = Grande.de_texto(str(dados.get("total_caracteres", "0")))
	por_segundo = Grande.de_texto(str(dados.get("caracteres_por_segundo", "0")))
	prestigios = int(dados.get("prestigios", 0))
	era = _era_de(total_caracteres)


static func _era_de(total: Grande) -> String:
	var alcancada := ErasCatalogo.da_producao(total)
	return alcancada.id if alcancada != null else ""


static func _ler_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		return null
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return null
	var texto := arquivo.get_as_text()
	arquivo.close()
	return JSON.parse_string(texto)
