# 0005 — O relógio do offline para quando o jogo abre, não quando a partida abre

**Contexto:** issue #38, que dá ao jogo um menu. Até a v0.4 abrir o jogo *era* estar
jogando, e a pergunta abaixo não existia.

## O problema

A produção offline (issue #9) conta do `gravado_em` do save até agora, com teto de 4 h.
Com um menu no caminho, "agora" deixa de ser óbvio:

- o jogador abre o jogo, lê o menu por cinco minutos, escolhe o Manuscrito
- o jogador joga, volta ao menu, fica dez minutos decidindo, entra de novo

Nos dois casos o `gravado_em` é antigo e o relógio do sistema andou. Sem decidir nada, os
**quinze minutos de menu viram produção** — e o jogador não estava jogando.

## A decisão

**Offline é o tempo em que o jogo esteve FECHADO.** Duas regras implementam isso:

1. **O relógio para no instante em que o jogo abriu**, e não no instante em que a partida
   abre. `Cenas` grava `_abriu_em` no `_ready` dele, e o crédito é
   `_abriu_em - gravado_em`. Ler o menu não produz caractere nenhum.

2. **Um Manuscrito recebe offline uma vez por sessão.** Voltar ao menu grava (issue #37),
   e entrar de novo veria o próprio `gravado_em` de um minuto atrás como "um minuto fora".
   Entre uma coisa e outra o jogo não esteve fechado — logo, não há offline.

## O que foi recusado, e por quê

**Creditar mesmo assim, porque é a favor do jogador.** Presente pequeno e constante ensina
a coisa errada: sair para o menu e voltar passaria a ser um gesto de otimização. Um
incremental não pode transformar "mexer no menu" numa mecânica.

**Congelar o `gravado_em` ao entrar na partida.** Gravaria por cima do timestamp que mede
o tempo real fora — e é justamente ele que a issue #9 existe para ler. Um save gravado na
entrada apagaria a ausência de verdade da sessão anterior.

**Contar o tempo de menu como tempo jogado.** `tempo_jogado` alimenta estatística e a
quarentena das descobertas raras (issue #32). Menu não é jogo.

## Consequência que fica registrada

Quem deixa o jogo aberto no menu a noite inteira não ganha nada por isso. Quem **fecha** o
jogo continua ganhando as 4 h de teto. É a leitura literal de "produção offline": ela é
sobre estar *off*, e o menu está *on*.
