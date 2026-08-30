## As automacoes (GDD §16): Gerente Macaco, Tecnico, Administrador e Diretor de
## Probabilidades.
##
## ⚠️ O AUTOMATICO USA A MESMA FUNCAO DO MANUAL. Nao existe caminho de compra separado --
## `agir()` chama Economia.comprar_macacos, Economia.comprar_maquina,
## Economia.expandir_sala e Eventos.resolver, exatamente as funcoes que os botoes chamam.
##
## E o cuidado mais importante da issue #28, e o motivo e barato de explicar: um segundo
## caminho de compra e um segundo lugar para as regras de capacidade, de saldo e de tier
## se perderem -- e o automatico so seria descoberto errado quando alguem comparasse os
## dois, que e depois de o jogador ja ter jogado a noite inteira.
##
## ⚠️ E SEMPRE DESLIGAVEL. Automacao que nao desliga e o jogo jogando sozinho, e um
## incremental que joga sozinho nao precisa de jogador.
##
## Cada uma tem intervalo proprio: agir todo quadro seriam sessenta compras por segundo
## para uma decisao que o jogador tomava a cada trinta.
##
## Nao tem _process proprio: quem chama tique() e a Partida, como Marcos e Eventos.
extends Node

const PASTA := "res://data/automacoes"

var _automacoes: Array[DadosAutomacao] = []

## id -> segundos ate a proxima acao. Transitorio: nao vai para o save, porque um
## cronometro salvo faria a automacao agir no primeiro quadro depois de carregar, o que e
## uma compra que o jogador nao viu acontecer.
var _relogios: Dictionary = {}


func _ready() -> void:
	for caminho in _listar_tres(PASTA):
		var automacao := ResourceLoader.load(caminho) as DadosAutomacao
		if automacao != null:
			_automacoes.append(automacao)
	_automacoes.sort_custom(func(a: DadosAutomacao, b: DadosAutomacao) -> bool:
		return a.custo < b.custo)


func todas() -> Array[DadosAutomacao]:
	return _automacoes


func de(id: String) -> DadosAutomacao:
	for automacao in _automacoes:
		if automacao.id == id:
			return automacao
	return null


func comprada(id: String) -> bool:
	return Jogo.automacoes.has(id)


## Comprada E ligada. As duas coisas sao diferentes de proposito: desligar nao devolve o
## dinheiro nem apaga a compra, so para a acao.
func ligada(id: String) -> bool:
	return comprada(id) and bool(Jogo.automacoes.get(id, false))


func disponivel(id: String) -> bool:
	var dados := de(id)
	if dados == null or comprada(id):
		return false
	return not Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres)


func comprar(id: String) -> bool:
	var dados := de(id)
	if dados == null or not disponivel(id):
		return false
	var custo := Grande.de_float(dados.custo)
	if custo.maior_que(Jogo.dinheiro):
		return false

	Jogo.dinheiro = Jogo.dinheiro.menos(custo)
	Jogo.automacoes[id] = true
	EventBus.automacao_comprada.emit(id)
	return true


## Liga e desliga. Devolve o estado novo.
func alternar(id: String) -> bool:
	if not comprada(id):
		return false
	Jogo.automacoes[id] = not ligada(id)
	EventBus.automacao_alternada.emit(id, ligada(id))
	return ligada(id)


## Avanca os cronometros e deixa agir quem chegou a vez. Chamado pela Partida.
func tique(delta: float) -> void:
	if delta <= 0.0:
		return
	for automacao in _automacoes:
		if not ligada(automacao.id):
			continue
		var resta: float = float(_relogios.get(automacao.id, 0.0)) - delta
		if resta > 0.0:
			_relogios[automacao.id] = resta
			continue
		_relogios[automacao.id] = automacao.intervalo
		agir(automacao)


## A acao de uma automacao. Publica para a suite conseguir comparar com o manual sem
## esperar cronometro -- e o unico jeito de afirmar que os dois compram a mesma coisa.
##
## Devolve se fez alguma coisa.
func agir(automacao: DadosAutomacao) -> bool:
	match automacao.tarefa:
		DadosAutomacao.Tarefa.COMPRAR_MACACOS:
			# exatamente o que o botao Comprar Maximo faz, e pela mesma funcao
			return Economia.comprar_macacos(Economia.macacos_que_cabem()) > 0
		DadosAutomacao.Tarefa.TROCAR_MAQUINA:
			var proxima := Economia.proxima_maquina()
			return proxima != null and Economia.comprar_maquina(proxima.id)
		DadosAutomacao.Tarefa.EXPANDIR_SALA:
			# "quando o espaco acaba, nunca antes": expandir com vaga sobrando gastaria o
			# saldo que o jogador ia usar em macaco, e o Administrador viraria sabotagem
			if not Economia.vagas_livres().e_zero():
				return false
			var sala := Economia.proxima_sala()
			return sala != null and Economia.expandir_sala(sala.id)
		DadosAutomacao.Tarefa.RESOLVER_EVENTOS:
			for id in Eventos.ativos():
				var evento := Eventos.de(id)
				if evento != null and evento.e_punicao() and Eventos.resolver(id):
					return true
			return false
	return false


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Automacao: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
