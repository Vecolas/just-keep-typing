## Quem decide O QUE vira aviso, e em que ordem (issue #69).
##
## ⚠️ AUTOLOAD, E NAO UM CAMPO DA HUD. Duas telas precisam da mesma fila: a HUD mostra o
## aviso da vez, e as Estatisticas mostram o registro do que passou. Com a fila morando
## dentro da HUD, a segunda tela so a alcancaria por caminho de no -- que e a regra 1 de
## arquitetura sendo quebrada por conveniencia.
##
## E ele e o unico que sabe TRADUZIR acontecimento em prioridade. A HUD so desenha; a regra
## de "descoberta Lendaria e critica, marco de tamanho e normal" mora aqui, perto do dado
## que a sustenta.
##
## ⚠️ O QUE ELE NAO FAZ: desenhar. Nao tem cena, nao tem no filho, nao sabe que a HUD
## existe. Quem quiser mostrar pergunta.
extends Node

var _fila := FilaDeAvisos.new()


func _ready() -> void:
	EventBus.marco_alcancado.connect(_ao_alcancar_marco)
	EventBus.descoberta_encontrada.connect(_ao_encontrar_descoberta)
	# ⚠️ partida nova nao herda o registro da anterior: ele e de SESSAO, e um registro que
	# atravessa o prestigio mostraria acontecimentos de uma run que ja nao existe
	EventBus.jogo_carregado.connect(_fila.limpar)


func tique(delta: float) -> bool:
	return _fila.tique(delta)


func texto_atual() -> String:
	return _fila.texto_atual()


func prioridade_atual() -> int:
	return _fila.prioridade_atual()


func quanto_resta() -> float:
	return _fila.quanto_resta()


func tem_aviso() -> bool:
	return _fila.tem_aviso()


## O que passou, do mais recente para o mais antigo.
func registro() -> Array[Dictionary]:
	return _fila.registro()


func limpar() -> void:
	_fila.limpar()


## ⚠️ AS DUAS OPCOES SAO LIDAS NO INSTANTE DO AVISO, e nunca guardadas (issue #41): o
## jogador desliga no meio da partida e vale na hora. E elas so calam o AVISO -- o marco
## continua caindo e a descoberta continua valendo bonus, porque opcao de interface que
## mexesse em progressao seria dificuldade disfarcada de conforto.
func _ao_alcancar_marco(marco: DadosMarco) -> void:
	if not Config.ligado("aviso_de_marco"):
		return
	# ⚠️ A PRIORIDADE SAI DO DADO, e nao de uma lista de ids. Marco conceitual e o que
	# prepara a transicao para o endgame (issue #51); ele espera menos que um marco de
	# tamanho, que e mais um numero grande entre noventa e um.
	var prioridade := (
		FilaDeAvisos.Prioridade.ALTA
		if marco.tipo == DadosMarco.Tipo.CONCEITUAL
		else FilaDeAvisos.Prioridade.NORMAL
	)
	# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
	_fila.acrescentar(tr("Marco: %s") % tr(marco.titulo), prioridade, Jogo.tempo_jogado)


func _ao_encontrar_descoberta(descoberta: DadosDescoberta) -> void:
	if not Config.ligado("aviso_de_descoberta"):
		return
	# ⚠️ IDEM: a raridade ja existe no dado desde a issue #17. Uma Lendaria que chega igual
	# a uma Comum e a promessa do sistema de raridade sendo desmentida pela interface.
	var prioridade := (
		FilaDeAvisos.Prioridade.CRITICA
		if descoberta.categoria >= DadosDescoberta.Categoria.LENDARIO
		else FilaDeAvisos.Prioridade.ALTA
	)
	_fila.acrescentar(
		tr("Descoberta: %s") % tr(descoberta.nome), prioridade, Jogo.tempo_jogado
	)
