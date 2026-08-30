## Barramento de sinais do jogo. Quem faz algo emite aqui; quem se importa conecta.
##
## Existe para que nenhum script precise saber ONDE outro no mora na arvore:
## get_node("../../Player") quebra assim que alguem reorganiza uma cena, e cena
## reorganizada e coisa que acontece toda semana. A unica excecao aceita a esta
## regra e procurar por grupo. Ver CONVENCOES.md, secao Arquitetura.
##
## Sinal novo entra aqui com tipo declarado nos argumentos e nome no passado
## (algo aconteceu), nunca no imperativo (faca algo) -- imperativo e chamada de
## metodo disfarcada de sinal, e reintroduz o acoplamento que este arquivo evita.
extends Node

## Emitido quando a lingua muda. Toda tela que MONTA texto em codigo (com %,
## formatador de numero ou catalogo em constante) tem que escutar: o Godot
## retraduz sozinho apenas o text que veio da cena.
signal idioma_mudou(codigo: String)
