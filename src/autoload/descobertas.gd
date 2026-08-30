## Sorteia as descobertas conforme os macacos produzem. Nome traduzido do
## DiscoveryManager do GDD §9 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## ⚠️ NAO GERA TEXTO NENHUM. O GDD §10 e categorico: o jogo calcula a chance e nao produz
## os caracteres. Nao ha string sorteada em lugar nenhum deste arquivo -- ha um numero
## comparado com outro numero. A piada e que o jogador acredita que o macaco escreveu, e
## e por isso que ela funciona com 10^300 caracteres do mesmo jeito que com mil.
##
##   chance = caracteres_produzidos x chance_base x bonus
##
## A CHANCE NUNCA PASSA DE 1, por mais absurda que a producao fique. Sem o teto, meia hora
## de endgame produziria uma chance de 10^40 -- que nao significa nada, e faria toda
## descoberta cair no mesmo quadro, esvaziando o sistema justamente quando ele deveria
## estar mais raro.
##
## O sorteio tem GERADOR PROPRIO, e nao o randi() global: assim a suite fixa a semente e
## sorteia sempre a mesma coisa, sem congelar o resto do jogo junto.
extends Node

const PASTA := "res://data/descobertas"

## Semente propria. A suite escreve aqui antes de sortear; o jogo deixa aleatoria.
var gerador := RandomNumberGenerator.new()

## Ordenadas da mais comum para a mais rara.
var _descobertas: Array[DadosDescoberta] = []


func _ready() -> void:
	gerador.randomize()
	for caminho in _listar_tres(PASTA):
		var descoberta := ResourceLoader.load(caminho) as DadosDescoberta
		if descoberta != null:
			_descobertas.append(descoberta)
	_descobertas.sort_custom(func(a: DadosDescoberta, b: DadosDescoberta) -> bool:
		if a.categoria != b.categoria:
			return a.categoria < b.categoria
		return a.chance_base > b.chance_base)


func todas() -> Array[DadosDescoberta]:
	return _descobertas


func de(id: String) -> DadosDescoberta:
	for descoberta in _descobertas:
		if descoberta.id == id:
			return descoberta
	return null


func encontrada(id: String) -> bool:
	return Jogo.descobertas.has(id)


func quantas_encontradas() -> int:
	return Jogo.descobertas.size()


## A chance de uma descoberta especifica sair com essa producao, ja com o teto.
##
## Recebe Grande porque `produzido` num quadro de endgame nao cabe em float, e sai float
## porque probabilidade vive em [0, 1] -- e o unico lugar da conta onde Grande nao paga.
func chance_de(descoberta: DadosDescoberta, produzido: Grande) -> float:
	if descoberta.chance_base <= 0.0 or produzido.sinal() <= 0:
		return 0.0
	var bruta := produzido.vezes(Grande.de_float(descoberta.chance_base))
	# comparar em Grande antes de converter: para_float() de 10^400 vira INF, e INF
	# clampado ainda e 1 -- mas por acidente, e nao por decisao
	if not bruta.menor_que(Grande.um()):
		return 1.0
	return bruta.para_float()


## Sorteia uma vez por descoberta ainda nao encontrada. Chamado por Economia._creditar,
## entao vale igual para clique, para quadro e para producao offline -- descoberta nao tem
## caminho proprio pelo mesmo motivo que caractere nao tem.
##
## Percorre da mais comum para a mais rara e para no primeiro acerto: uma descoberta por
## credito. Sem isso, voltar de quatro horas offline despejaria o catalogo inteiro de uma
## vez, e cada uma delas merece o seu momento.
func sortear(produzido: Grande) -> void:
	for descoberta in _descobertas:
		if encontrada(descoberta.id):
			continue
		if gerador.randf() >= chance_de(descoberta, produzido):
			continue
		Jogo.descobertas.append(descoberta.id)
		EventBus.descoberta_encontrada.emit(descoberta)
		return


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Descobertas: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
