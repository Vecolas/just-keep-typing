## Vigia o total de caracteres e avisa quando um marco e cruzado. Nome traduzido do
## MilestoneManager do GDD §35 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## Nao tem _process proprio: quem chama verificar() e a Partida, que e quem tem quadro.
## Um autoload com quadro proprio e uma segunda linha do tempo dentro do jogo, e duas
## linhas do tempo e onde nascem os bugs de ordem que ninguem consegue reproduzir.
##
## A lista sai ordenada por REQUISITO e nao por nome de arquivo nem por campo `ordem`
## (decisao 0003): a ordem do Panorama e a ordem dos numeros, e so ela nao desincroniza.
extends Node

const PASTA := "res://data/marcos"

## Ordenados do menor requisito para o maior. Publico por leitura -- o Panorama percorre.
var _marcos: Array[DadosMarco] = []

## Espelho de Jogo.marcos_alcancados como DICIONARIO, e o indice do primeiro marco ainda
## nao cruzado.
##
## Existem porque a regua medir_quadro achou o preco da versao ingenua: verificar()
## percorria os noventa marcos por quadro chamando Array.has() em cada um, e Array.has() e
## busca linear. Com 66 marcos cruzados isso dava mais de dois mil comparacoes de texto
## POR QUADRO -- 30 ms de tempo de processo onde o orcamento inteiro e 16,67 ms.
##
## Com o dicionario e o indice, verificar() olha UM marco por quadro no caso comum.
var _alcancados: Dictionary = {}
var _proximo: int = 0


func _ready() -> void:
	for caminho in _listar_tres(PASTA):
		var marco := ResourceLoader.load(caminho) as DadosMarco
		if marco != null:
			_marcos.append(marco)
	_marcos.sort_custom(func(a: DadosMarco, b: DadosMarco) -> bool:
		return a.requisito_grande().menor_que(b.requisito_grande()))


func todos() -> Array[DadosMarco]:
	return _marcos


func de(id: String) -> DadosMarco:
	for marco in _marcos:
		if marco.id == id:
			return marco
	return null


func alcancado(id: String) -> bool:
	_conferir_espelho()
	return _alcancados.has(id)


## O espelho e reconstruido quando a lista do Jogo muda por fora -- carregar um save,
## provar o Teorema, ou a suite mexendo direto. Comparar o tamanho e barato e pega todos
## esses casos; comparar item a item seria pagar de novo o que este espelho evita.
func _conferir_espelho() -> void:
	if _alcancados.size() == Jogo.marcos_alcancados.size():
		return
	_alcancados.clear()
	for id in Jogo.marcos_alcancados:
		_alcancados[id] = true
	_proximo = 0
	while _proximo < _marcos.size() and _alcancados.has(_marcos[_proximo].id):
		_proximo += 1


## O ultimo marco ja cruzado -- o que a tela mostra em destaque. Nulo no comeco do jogo,
## que e um estado legitimo e nao um erro.
func atual() -> DadosMarco:
	_conferir_espelho()
	return _marcos[_proximo - 1] if _proximo > 0 else null


## O primeiro ainda nao cruzado -- o que a tela mostra em silhueta. Nulo quando o jogador
## alcancou todos, o que na v0.1 acontece rapido e na v0.4 e o fim do jogo.
func proximo() -> DadosMarco:
	_conferir_espelho()
	return _marcos[_proximo] if _proximo < _marcos.size() else null


## Cruza quem tiver de ser cruzado. Percorre a lista inteira em vez de olhar so o proximo
## porque a producao offline pode pular varios marcos de uma vez -- voltar depois de
## quatro horas e atravessar tres faixas de escala e o caso comum, nao o raro.
func verificar() -> void:
	_conferir_espelho()
	while _proximo < _marcos.size():
		var marco := _marcos[_proximo]
		if marco.requisito_grande().maior_que(Jogo.total_caracteres):
			# a lista esta ordenada: daqui para a frente e tudo mais caro
			return
		_proximo += 1
		_alcancados[marco.id] = true
		Jogo.marcos_alcancados.append(marco.id)
		EventBus.marco_alcancado.emit(marco)


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Marcos: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
