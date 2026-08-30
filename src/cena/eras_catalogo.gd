## O catalogo das eras visuais, lido uma vez e compartilhado.
##
## Existe porque duas coisas muito distantes precisam da MESMA pergunta respondida do mesmo
## jeito: a cena das eras, que desenha a era da producao atual, e o metadado do Manuscrito
## (issue #35), que grava em qual era o slot parou para o menu poder dizer isso sem abrir a
## partida. Duas copias da regra "a mais avancada que couber" divergiriam na primeira era
## nova, e o menu passaria a mentir sobre um save que a cena desenha certo.
##
## Nao e autoload de proposito: nao guarda estado de partida nenhuma, so o catalogo do
## disco. Static var e cache com motivo -- sao quatorze .tres, e a cena das eras perguntava
## a cada quadro.
class_name ErasCatalogo
extends RefCounted

const PASTA := "res://data/eras"

static var _eras: Array[DadosEra] = []


## Todas as eras, da primeira a ultima. A ordem e a do campo numero, e nao a do disco.
static func todas() -> Array[DadosEra]:
	if _eras.is_empty():
		_carregar()
	return _eras


## A era de um total de caracteres: a mais avancada cujo requisito ja foi cumprido.
## Devolve null so quando o catalogo esta vazio -- que e projeto sem data/eras.
static func da_producao(total: Grande) -> DadosEra:
	var escolhida: DadosEra = null
	for era in todas():
		if not era.requisito_grande().maior_que(total):
			escolhida = era
	return escolhida


## A era de um id gravado. O metadado guarda o ID e nao o nome porque nome e texto que o
## jogador le, e texto muda de idioma -- id em snake_case atravessa as duas linguas.
static func por_id(id: String) -> DadosEra:
	for era in todas():
		if era.id == id:
			return era
	return null


static func _carregar() -> void:
	_eras = []
	for caminho in _listar_tres(PASTA):
		var era := ResourceLoader.load(caminho) as DadosEra
		if era != null:
			_eras.append(era)
	_eras.sort_custom(func(a: DadosEra, b: DadosEra) -> bool: return a.numero < b.numero)


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("ErasCatalogo: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
