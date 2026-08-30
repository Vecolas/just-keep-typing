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
	return Jogo.marcos_alcancados.has(id)


## O ultimo marco ja cruzado -- o que a tela mostra em destaque. Nulo no comeco do jogo,
## que e um estado legitimo e nao um erro.
func atual() -> DadosMarco:
	var ultimo: DadosMarco = null
	for marco in _marcos:
		if alcancado(marco.id):
			ultimo = marco
	return ultimo


## O primeiro ainda nao cruzado -- o que a tela mostra em silhueta. Nulo quando o jogador
## alcancou todos, o que na v0.1 acontece rapido e na v0.4 e o fim do jogo.
func proximo() -> DadosMarco:
	for marco in _marcos:
		if not alcancado(marco.id):
			return marco
	return null


## Cruza quem tiver de ser cruzado. Percorre a lista inteira em vez de olhar so o proximo
## porque a producao offline pode pular varios marcos de uma vez -- voltar depois de
## quatro horas e atravessar tres faixas de escala e o caso comum, nao o raro.
func verificar() -> void:
	for marco in _marcos:
		if alcancado(marco.id):
			continue
		if marco.requisito_grande().maior_que(Jogo.total_caracteres):
			# a lista esta ordenada: daqui para a frente e tudo mais caro
			return
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
