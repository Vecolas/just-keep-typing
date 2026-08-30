## Decide QUANDO a partida e gravada. Quem grava continua sendo o Save, e so ele.
##
## Ate aqui havia dois momentos: o cronometro de trinta segundos e fechar a janela (issue
## #8). Faltavam os momentos em que o jogador ESPERA que o jogo tenha guardado -- provar o
## Teorema, reescrever o Universo, trocar de era e sair para o menu. Perder um prestigio
## por um desligamento trinta segundos depois dele nao e perder trinta segundos: e desfazer
## a decisao mais cara da run.
##
## ⚠️ GRAVA DEPOIS DO RESET, E ISSO E DECISAO, nao detalhe de implementacao. teorema_provado
## e universo_reescrito chegam com a run JA reiniciada, e e esse estado que vai para o
## disco. Gravar o de antes guardaria a run que o jogador acabou de trocar por pontos: um
## desligamento logo em seguida devolveria a run e comeria o prestigio, desfazendo a escolha
## que ele tinha acabado de tomar. O save reflete o que ele tem AGORA.
##
## ⚠️ O CRONOMETRO REINICIA A CADA GATILHO. Sem isso, um prestigio no segundo 29,9 grava
## duas vezes -- uma pelo sinal e outra pelo relogio, no mesmo quadro -- e a segunda
## gravacao existe so para gastar disco.
##
## Nao mostra nada. Quem avisa "Salvando..." e a HUD, escutando EventBus.jogo_gravado: o
## aviso e discreto, nunca popup e nunca rouba foco, porque este e um jogo que fica aberto
## atras de outra coisa (o mesmo motivo pelo qual a tela cheia nao e exclusiva, issue #34).
extends Node

## De quanto em quanto tempo a partida e gravada quando nada acontece. Trinta segundos e o
## maximo de progresso que um desligamento na tomada pode custar -- e o minimo de escrita
## em disco que nao incomoda. Veio da Partida, onde morava desde a issue #8.
const INTERVALO: float = 30.0

var _ate_gravar: float = INTERVALO


func _ready() -> void:
	# os tres gatilhos que ja existem. "Voltar ao menu" e o quarto, e entra na issue #39
	# chamando gravar_agora() -- nao ha sinal para ele porque nao ha menu ainda, e sinal
	# que ninguem emite e combinado esquecido.
	EventBus.teorema_provado.connect(_ao_acontecer_algo_que_o_jogador_nao_quer_perder)
	EventBus.universo_reescrito.connect(_ao_acontecer_algo_que_o_jogador_nao_quer_perder)
	EventBus.era_mudou.connect(_ao_acontecer_algo_que_o_jogador_nao_quer_perder)


## Quem tem quadro chama, como chama Eventos.tique e Automacao.tique. Este autoload nao tem
## _process de proposito: a ordem em que as coisas acontecem no quadro e da cena.
func tique(delta: float) -> void:
	_ate_gravar -= delta
	if _ate_gravar <= 0.0:
		gravar_agora()


## Grava e reinicia o cronometro. E o ponto de entrada de todo gatilho -- inclusive dos que
## ainda nao existem, como o botao de voltar ao menu.
func gravar_agora() -> bool:
	_ate_gravar = INTERVALO
	return Save.gravar()


## Quanto falta para a gravacao automatica. Existe para a suite poder afirmar que o
## cronometro reiniciou, que e a metade invisivel da regra de nao gravar duas vezes.
func segundos_ate_gravar() -> float:
	return _ate_gravar


## Um handler so para os tres sinais: cada um traz um argumento diferente e nenhum deles
## importa aqui. O que importa e que ALGO que o jogador nao quer refazer acabou de
## acontecer, e o disco ainda nao sabe.
func _ao_acontecer_algo_que_o_jogador_nao_quer_perder(_qualquer: Variant) -> void:
	gravar_agora()
