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

## Emitido depois que a compra ja aconteceu -- o dinheiro saiu e o id ja esta em
## Jogo.upgrades_comprados. Quem escuta repinta; ninguem precisa perguntar de volta se
## deu certo.
signal upgrade_comprado(id: String)

## Emitido depois da compra, com quantos macacos entraram de verdade -- que pode ser menos
## do que o botao pediu, se o saldo nao cobriu o lote inteiro.
signal macacos_comprados(quantos: int)

## Emitido depois de a partida ser gravada em disco com sucesso.
signal jogo_gravado()

## Emitido depois de um save ja ter sido aplicado no Jogo. Quem escuta pode ler o estado
## novo direto, sem receber nada por argumento.
signal jogo_carregado()
