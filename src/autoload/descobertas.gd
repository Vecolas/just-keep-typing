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
		_carimbar(descoberta.id)
		if _e_rara(descoberta):
			Jogo.tempo_da_ultima_rara = Jogo.tempo_jogado
		EventBus.descoberta_encontrada.emit(descoberta)
		return


## O momento em que uma descoberta saiu (issue #55): QUANDO e com que ORDEM DE GRANDEZA de
## produção total. O Arquivo mostra os dois na entrada aberta, e eles so existem se forem
## carimbados aqui -- reconstruir depois e impossivel.
##
## ⚠️ A DATA VEM EM SEGUNDOS INTEIROS. O JSON do Godot guarda 15 digitos significativos e
## um horario unix ja gasta dez antes da virgula: gravar microssegundos cria um campo que
## muda sozinho ao ir e voltar do disco. Ver CONVENCOES.md, "O save e texto".
##
## ⚠️ E A AUSENCIA E A SENTINELA, e nao um numero. Ordem de grandeza ZERO e valida (de 1 a
## 9 caracteres), entao zero nao pode significar "nao sei" -- descoberta achada antes desta
## versao simplesmente NAO TEM entrada aqui, e a tela mostra o que tem em vez de um zero
## que mente.
func _carimbar(id: String) -> void:
	Jogo.descobertas_quando[id] = floorf(Time.get_unix_time_from_system())
	Jogo.descobertas_grandeza[id] = Jogo.total_caracteres.expoente


## O que se sabe sobre o momento em que uma descoberta saiu. Vazio quando ela e anterior a
## issue #55 -- que e um resultado legitimo, e nao um erro.
func detalhe_de(id: String) -> Dictionary:
	if not Jogo.descobertas_quando.has(id):
		return {}
	return {
		"quando": float(Jogo.descobertas_quando[id]),
		"grandeza": int(Jogo.descobertas_grandeza.get(id, 0)),
	}


## Quantas de uma faixa ja sairam, e quantas existem nela.
##
## ⚠️ VARRE O CATALOGO, e nao uma contagem guardada: faixa nova ou descoberta nova entra
## na conta sozinha, sem ninguem lembrar de somar mais um em algum lugar.
func contagem_da_faixa(faixa: int) -> Array:
	var achadas := 0
	var total := 0
	for descoberta in _descobertas:
		if DadosDescoberta.faixa_de(descoberta.categoria) != faixa:
			continue
		total += 1
		if encontrada(descoberta.id):
			achadas += 1
	return [achadas, total]


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
