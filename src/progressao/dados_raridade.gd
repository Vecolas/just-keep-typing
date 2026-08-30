## A quarentena das descobertas raras (issue #32).
##
## ⚠️ ESTE ARQUIVO EXISTE POR UM MOTIVO DE LEITURA, E NAO DE MATEMATICA. A chance ja tem
## teto: no endgame ela vale 1 para tudo que ainda falta. Sem quarentena, o quadro em que
## o jogador cruza a producao das Lendarias derruba Hamlet, o Romance Inedito, a Biografia,
## o Jogo, a Mensagem e o Proximo Texto em menos de um segundo -- seis avisos empilhados, e
## nenhum deles raro.
##
## "Se o jogador ve duas lendarias na mesma sessao, elas deixam de ser lendarias." A
## raridade nao esta na chance, esta no ESPACO entre uma e outra.
##
## Os numeros ficam aqui, e nao no descobertas.gd, porque sao balanceamento: e uma sessao
## de tuning que decide se quinze minutos e muito ou pouco (CONVENCOES.md).
class_name DadosRaridade
extends Resource

## A partir de qual categoria a quarentena vale. Comum e Incomum saem em rajada sem
## problema nenhum -- elas nao prometem raridade.
@export var categoria_minima: DadosDescoberta.Categoria = DadosDescoberta.Categoria.LENDARIO

## Segundos de jogo entre duas descobertas dessa faixa. Conta em tempo_jogado, e nao em
## tempo de relogio, porque o que precisa de espaco e a SESSAO do jogador: fechar o jogo e
## voltar nao deve entregar a segunda lendaria de graca.
@export var intervalo: float = 900.0
