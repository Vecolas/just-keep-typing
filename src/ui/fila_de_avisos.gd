## A FILA DE AVISOS (issue #69). Uma mensagem de prioridade menor nunca apaga uma maior.
##
## ⚠️ ELA EXISTE PORQUE UM SLOT SO NAO BASTA, e isso foi MEDIDO. Ate aqui a HUD tinha um
## unico rotulo de aviso: marco, descoberta e autosave escreviam por cima do anterior e
## reiniciavam o relogio. Em trinta minutos de partida:
##
##     avisos que a HUD mostrou:            82
##     apagados antes dos 1,6 s de leitura: 16  (20%)
##
## Um em cada cinco textos que o jogo escreve era fisicamente ilegivel. Conteudo que existe
## no banco de dados e o jogador nao consegue consumir nao e polimento -- e conteudo
## inexistente (decisao 0010).
##
## ⚠️ E A SOLUCAO NAO E AUMENTAR A DURACAO. Mais tempo na tela atrasa a fila inteira e faz
## o proximo aviso chegar depois do momento dele. O que resolve e PRIORIDADE: a mensagem
## importante espera menos, e nunca e apagada pela sem importancia.
##
## ⚠️ ELA NAO DESENHA NADA. E logica pura, sem no e sem cena -- por isso a suite consegue
## afirmar a ordem sem subir a HUD. Quem desenha e a hud.gd.
class_name FilaDeAvisos
extends RefCounted

## ⚠️ A ORDEM DO ENUM E A PRIORIDADE, e maior valor ganha. Entrada nova entra NO LUGAR
## certo da escala, e nao no fim: aqui o enum nao e serializado em .tres nenhum, entao a
## regra do "valor novo entra no fim" nao se aplica -- o que manda e a leitura.
##
##   CRITICA   descoberta rara, teorema, mudanca de era
##   ALTA      descoberta, marco conceitual
##   NORMAL    marco comum, upgrade desbloqueado
##   BAIXA     mensagens operacionais
enum Prioridade {
	BAIXA,
	NORMAL,
	ALTA,
	CRITICA,
}

## Quanto tempo cada prioridade fica na tela.
##
## ⚠️ INDEXADO PELO ENUM, e o tamanho sai de Prioridade.size(). Coleção dimensionada por
## literal e indexada por enum e uma bomba com timer (CONVENCOES).
const SEGUNDOS_POR_PRIORIDADE: Array[float] = [1.2, 1.6, 2.2, 3.0]

## Teto da fila. ⚠️ SEM ELE, uma avalanche de eventos vira uma fila de trinta segundos que
## o jogador assiste sem poder pular -- e a issue #32 ja ensinou que seis avisos empilhados
## nao sao seis momentos: sao um so, e barulhento.
##
## Quando estoura, o que SAI e o de menor prioridade -- nunca o mais recente, que costuma
## ser o mais importante.
const CABEM: int = 6

## O que esta na tela agora, e por quanto tempo ainda.
var _atual: Dictionary = {}
var _ate_trocar: float = 0.0

## Os que esperam. Ordenados por prioridade decrescente, e por chegada dentro dela.
var _esperando: Array[Dictionary] = []

## Tudo que passou, do mais recente para o mais antigo (issue #69).
##
## ⚠️ EXISTE PARA A MENSAGEM NAO SUMIR DO UNIVERSO. Se o jogador perdeu o aviso, ele ainda
## consegue saber o que aconteceu -- e isso reduz a ansiedade de leitura, que e o que fazia
## o aviso precisar ser grande e demorado.
##
## Estado de SESSAO: nao vai para o save. Registro de quinze minutos atras nao e progresso.
var _registro: Array[Dictionary] = []

const REGISTRO_MAXIMO: int = 20


## Poe um aviso na fila. `instante` e o tempo de jogo, para o registro.
func acrescentar(texto: String, prioridade: Prioridade, instante: float = 0.0) -> void:
	if texto.strip_edges().is_empty():
		return
	var aviso := {"texto": texto, "prioridade": int(prioridade), "instante": instante}

	_registro.push_front(aviso)
	while _registro.size() > REGISTRO_MAXIMO:
		_registro.pop_back()

	# ⚠️ NADA INTERROMPE O QUE JA ESTA NA TELA, nem uma CRITICA. Trocar no meio da leitura e
	# exatamente o defeito que esta issue conserta, so que com regra: a critica fura a FILA,
	# e nao o aviso em exibicao.
	if _atual.is_empty():
		_mostrar(aviso)
		return

	_esperando.append(aviso)
	# ordem estavel por prioridade: quem chegou antes, dentro da mesma prioridade, sai antes
	_esperando.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["prioridade"]) > int(b["prioridade"]))
	while _esperando.size() > CABEM:
		_esperando.pop_back()


## Passa o tempo. Devolve `true` quando o que esta na tela mudou.
func tique(delta: float) -> bool:
	if _atual.is_empty() or delta <= 0.0:
		return false
	_ate_trocar -= delta
	if _ate_trocar > 0.0:
		return false
	if _esperando.is_empty():
		_atual = {}
		return true
	_mostrar(_esperando.pop_front())
	return true


func texto_atual() -> String:
	return str(_atual.get("texto", ""))


func prioridade_atual() -> int:
	return int(_atual.get("prioridade", Prioridade.BAIXA))


## De 0 a 1: quanto do tempo do aviso atual ainda resta. A HUD usa para o desvanecimento.
func quanto_resta() -> float:
	if _atual.is_empty():
		return 0.0
	return clampf(_ate_trocar, 0.0, 1.0)


func tem_aviso() -> bool:
	return not _atual.is_empty()


func quantos_esperando() -> int:
	return _esperando.size()


## O registro recente, do mais novo para o mais velho.
func registro() -> Array[Dictionary]:
	return _registro


func limpar() -> void:
	_atual = {}
	_ate_trocar = 0.0
	_esperando.clear()
	_registro.clear()


func _mostrar(aviso: Dictionary) -> void:
	_atual = aviso
	var prioridade: int = clampi(
		int(aviso["prioridade"]), 0, SEGUNDOS_POR_PRIORIDADE.size() - 1
	)
	_ate_trocar = SEGUNDOS_POR_PRIORIDADE[prioridade]
