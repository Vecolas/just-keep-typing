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
const RARIDADE := "res://data/raridade.tres"

## Semente propria. A suite escreve aqui antes de sortear; o jogo deixa aleatoria.
var gerador := RandomNumberGenerator.new()

## Ordenadas da mais comum para a mais rara.
var _descobertas: Array[DadosDescoberta] = []

## A quarentena das raras. Ver dados_raridade.gd.
var _raridade: DadosRaridade = null


func _ready() -> void:
	gerador.randomize()
	_raridade = ResourceLoader.load(RARIDADE) as DadosRaridade
	if _raridade == null:
		push_error("Descobertas: %s nao carregou" % RARIDADE)
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
	# Deja Vu Literario (GDD §19) entra aqui e nao no .tres: a chance base e balanceamento
	# e o bonus e progressao, e misturar os dois faria uma sessao de tuning apagar a
	# arvore sem perceber
	# o evento entra multiplicando junto: a Tecla Presa vale ZERO aqui, e zero vezes
	# qualquer coisa continua zero -- muito caractere e nenhuma descoberta (GDD §22)
	var bonus := (
		Teoremas.bonus_de(DadosTeorema.Efeito.DEJA_VU_LITERARIO)
		* Eventos.multiplicador_de_descoberta()
	)
	var bruta := produzido.vezes(Grande.de_float(descoberta.chance_base * bonus))
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
		if em_quarentena(descoberta):
			continue
		if gerador.randf() >= chance_de(descoberta, produzido):
			continue
		Jogo.descobertas.append(descoberta.id)
		if _e_rara(descoberta):
			Jogo.tempo_da_ultima_rara = Jogo.tempo_jogado
		EventBus.descoberta_encontrada.emit(descoberta)
		return


## Se esta descoberta ainda esta esperando o espaco da anterior da mesma faixa.
##
## ⚠️ ISTO NAO E BALANCEAMENTO DE CHANCE, E RITMO DE LEITURA. No endgame a chance de tudo
## que falta vale 1 -- sem esta funcao, o quadro em que o jogador cruza a producao das
## Lendarias despeja as seis de uma vez, e seis avisos empilhados nao sao seis momentos
## raros: sao um so, e barulhento.
##
## Publica porque a suite precisa afirmar exatamente isto (issue #32).
func em_quarentena(descoberta: DadosDescoberta) -> bool:
	if _raridade == null or not _e_rara(descoberta):
		return false
	# antes da primeira rara nao ha o que espacar; negativo e o "nenhuma ainda" (ver jogo.gd)
	if Jogo.tempo_da_ultima_rara < 0.0:
		return false
	return Jogo.tempo_jogado - Jogo.tempo_da_ultima_rara < _raridade.intervalo


func _e_rara(descoberta: DadosDescoberta) -> bool:
	return _raridade != null and descoberta.categoria >= _raridade.categoria_minima


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
