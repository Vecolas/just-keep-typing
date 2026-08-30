## Os eventos aleatorios (GDD §22).
##
## ⚠️ EVENTO NEGATIVO TEM SAIDA PELA ACAO DO JOGADOR. Punicao que so espera passar nao e
## evento, e imposto -- o jogador aprende a ignorar e o sistema vira ruido com contador. A
## suite reprova evento ruim sem resolve_com_clique.
##
## ⚠️ OS MODIFICADORES EXPIRAM E NAO ACUMULAM ALEM DO TETO. Sem teto, tres eventos bons
## coincidindo dariam um produto que nao aparece em nenhuma conta de balanceamento -- e o
## jogador ia embora achando que descobriu um truque, quando so encontrou um bug. O teto e
## `maximo_simultaneos`, do .tres.
##
## O sorteio tem GERADOR PROPRIO, como o das descobertas, e pelo mesmo motivo: sem ele a
## suite dependeria do randi() global e falharia de vez em quando.
##
## O evento ativo NAO vai para o save. Ele e transitorio por definicao: um Macaco
## Inspirado que sobrevive a fechar e reabrir o jogo vira upgrade de vinte segundos que se
## renova sozinho, e ai o jeito otimo de jogar passa a ser reabrir o jogo.
##
## Nao tem _process proprio: quem chama tique() e a Partida, que e quem tem quadro -- o
## mesmo motivo do autoload Marcos.
extends Node

const PASTA := "res://data/eventos"
const CAMINHO_FREQUENCIA := "res://data/eventos.tres"

## Semente propria. A suite escreve aqui antes de sortear.
var gerador := RandomNumberGenerator.new()

var _eventos: Array[DadosEvento] = []
var _frequencia: DadosEventos = null

## id -> segundos restantes. Dicionario e nao lista porque o mesmo evento nunca entra duas
## vezes: dois Macacos Inspirados ao mesmo tempo seriam x100, e ninguem projetou x100.
var _ativos: Dictionary = {}


func _ready() -> void:
	gerador.randomize()
	for caminho in _listar_tres(PASTA):
		var evento := ResourceLoader.load(caminho) as DadosEvento
		if evento != null:
			_eventos.append(evento)
	_eventos.sort_custom(func(a: DadosEvento, b: DadosEvento) -> bool: return a.id < b.id)

	_frequencia = ResourceLoader.load(CAMINHO_FREQUENCIA) as DadosEventos
	if _frequencia == null:
		push_error("Eventos: %s nao carregou" % CAMINHO_FREQUENCIA)


func todos() -> Array[DadosEvento]:
	return _eventos


func de(id: String) -> DadosEvento:
	for evento in _eventos:
		if evento.id == id:
			return evento
	return null


func ativo(id: String) -> bool:
	return _ativos.has(id)


func ativos() -> Array:
	return _ativos.keys()


## Segundos que faltam. Zero quando o evento nao esta ativo.
func restante(id: String) -> float:
	return float(_ativos.get(id, 0.0))


## O produto dos multiplicadores de producao de tudo que esta ativo.
func multiplicador_de_producao() -> float:
	var total := 1.0
	for id in _ativos:
		var evento := de(id)
		if evento != null:
			total *= evento.multiplicador_producao
	return total


## O produto dos multiplicadores de chance de descoberta. ZERO e valido e e a Tecla Presa:
## muito caractere, nenhuma descoberta.
func multiplicador_de_descoberta() -> float:
	var total := 1.0
	for id in _ativos:
		var evento := de(id)
		if evento != null:
			total *= evento.multiplicador_descoberta
	return total


## A saida pela acao do jogador. Devolve se resolveu -- so evento marcado como resolvivel
## aceita, e clicar num Macaco Inspirado nao apaga o bonus por engano.
func resolver(id: String) -> bool:
	var evento := de(id)
	if evento == null or not evento.resolve_com_clique or not ativo(id):
		return false
	_ativos.erase(id)
	EventBus.evento_terminou.emit(id)
	return true


## Avanca o relogio dos ativos e sorteia um novo. Chamado pela Partida.
##
## O relogio anda ANTES do sorteio: um evento que expira neste quadro tem que liberar a
## vaga para o proximo no mesmo quadro, senao o teto de simultaneos vira teto de
## frequencia sem ninguem ter pedido.
func tique(delta: float) -> void:
	if delta <= 0.0:
		return
	_expirar(delta)
	_talvez_sortear(delta)


## Encerra tudo que estiver ativo, sem sortear nada. Para suite e ferramenta -- o jogo
## nunca chama.
##
## Existe porque o atalho obvio nao funciona: tique() com um delta enorme expira tudo E
## sorteia um evento novo, porque a chance por quadro e delta/intervalo e um delta enorme
## da chance 1. As duas primeiras versoes da suite e do teste de fumaca usaram esse atalho
## e falharam com "nao deu para disparar a Banana" -- a vaga do teto de simultaneos ja
## estava ocupada por um evento que a propria limpeza tinha criado.
func limpar() -> void:
	for id in _ativos.keys():
		_ativos.erase(id)
		EventBus.evento_terminou.emit(id)


## Comeca um evento na marra. E o que a suite e o teste de fumaca usam -- o jogo nunca
## chama, ele so deixa o sorteio acontecer.
func comecar(id: String) -> bool:
	var evento := de(id)
	if evento == null or ativo(id):
		return false
	if _frequencia != null and _ativos.size() >= _frequencia.maximo_simultaneos:
		return false
	_ativos[id] = evento.duracao
	EventBus.evento_comecou.emit(evento)
	return true


func _expirar(delta: float) -> void:
	for id in _ativos.keys():
		var resta: float = float(_ativos[id]) - delta
		if resta <= 0.0:
			_ativos.erase(id)
			EventBus.evento_terminou.emit(id)
		else:
			_ativos[id] = resta


func _talvez_sortear(delta: float) -> void:
	if _frequencia == null or _frequencia.intervalo_medio <= 0.0:
		return
	if _ativos.size() >= _frequencia.maximo_simultaneos:
		return
	# evento no primeiro minuto e ruido: o jogador ainda nao sabe o que e producao normal
	if Grande.de_float(_frequencia.requisito).maior_que(Jogo.total_caracteres):
		return
	# chance por quadro de delta/intervalo: o intervalo medio sai certo sem ninguem
	# guardar um cronometro, e sem o evento nascer sempre no mesmo segundo redondo
	if gerador.randf() >= delta / _frequencia.intervalo_medio:
		return
	var sorteado := _sortear_por_peso()
	if sorteado != null:
		comecar(sorteado.id)


## Sorteio por peso. Peso nao e probabilidade: e quantas fichas o evento poe no chapeu, e
## a soma nao precisa dar 1 -- assim acrescentar evento novo nao obriga a reajustar os
## outros cinco.
func _sortear_por_peso() -> DadosEvento:
	var soma := 0.0
	for evento in _eventos:
		if not ativo(evento.id) and evento.peso > 0.0:
			soma += evento.peso
	if soma <= 0.0:
		return null

	var alvo := gerador.randf() * soma
	for evento in _eventos:
		if ativo(evento.id) or evento.peso <= 0.0:
			continue
		alvo -= evento.peso
		if alvo <= 0.0:
			return evento
	return null


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Eventos: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
