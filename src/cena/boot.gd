## A cena que o jogo abre, e a unica que nunca sai do ar. Nao desenha nada: ela existe
## para segurar o no onde as outras sao montadas e para dar a partida ao Cenas.
##
## ⚠️ O BOOT NAO E O PRIMEIRO A RODAR. Os autoloads sobem antes de qualquer cena, e o
## Config ja carregou as opcoes e ja apontou o Save.caminho para o ultimo slot quando este
## _ready acontece. Fingir que aqui e o comeco de tudo -- reaplicar idioma, reapontar save
## -- e fazer duas vezes o que ja foi feito uma, com a segunda vez podendo discordar da
## primeira.
##
## O que ele NAO faz e igualmente de proposito: nao carrega save, nao credita offline e nao
## escolhe Manuscrito. Quem escolhe e o jogador, na tela de Arquivos.
extends Node


func _ready() -> void:
	Cenas.ir_para_menu()
