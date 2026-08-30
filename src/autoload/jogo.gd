## O estado da partida, e nada mais. Nome traduzido do GameManager do GDD §29 --
## ver docs/decisoes/0002-codigo-em-portugues.md.
##
## SO GUARDA ESTADO. Nao calcula producao, nao toca UI, nao decide nada: quem calcula e
## Economia, quem desenha e a tela, quem avisa e o EventBus. A regra parece burocratica
## e nao e -- ela e o que permite Economia ser trocada inteira sem que ninguem perca o
## save, e o que impede o autoload de virar o lugar onde tudo acaba morando.
##
## Por isso tambem nao ha _process aqui: nem para o tempo_jogado. Quem tem quadro chama
## Economia.acumular(), e e ela que faz o relogio andar.
##
## Os acumuladores sao Grande, o resto e float (decisao 0001: Grande e para acumulador,
## nao para tudo). Grande e imutavel, entao atribuir um aqui e seguro sem copiar.
extends Node

## Nunca reseta. E o numero do Panorama: o que o jogador digitou desde sempre.
var total_caracteres: Grande = Grande.zero()

## Zera no prestigio (GDD §17). E o numero que a run corrente produziu.
var caracteres_da_run: Grande = Grande.zero()

## Producao corrente. Quem escreve e Economia, no frame em que recalcula.
var caracteres_por_segundo: Grande = Grande.zero()

## O que sobra para gastar. Sobe junto com a producao, um caractere por moeda, e desce a
## cada compra -- e a unica diferenca entre ele e caracteres_da_run. Zera no prestigio.
## Ver docs/decisoes/0004-caractere-e-a-moeda.md.
var dinheiro: Grande = Grande.zero()

## Quantos macacos digitam. Grande e nao int porque o endgame chama O MACACO INFINITO --
## a contagem cresce sem teto de design como qualquer outro acumulador.
##
## Comeca em 1: o GDD §3 abre a partida com o jogador vendo um macaco, uma maquina e uma
## folha. Ele so nao sabe digitar sozinho ainda -- quem acende isso e o Instinto Digitador.
var macacos: Grande = Grande.um()

## Ids dos upgrades ja comprados. Guarda o id e nao o Resource porque isto vai para o save
## (issue #8), e id em snake_case sobrevive a renomear arquivo (decisao 0002).
##
## Ninguem le esta lista procurando um id especifico: quem pergunta usa
## Economia.bonus_de(tipo) ou tem_efeito(tipo). Ver CONVENCOES.md, o corolario que vale
## ouro.
var upgrades_comprados: Array[String] = []

## Quantas maquinas de escrever. Conta unica por enquanto; a issue #14 traz os dez tiers
## do GDD §13 e troca isto por contagem por tier.
var maquinas: Grande = Grande.zero()

## Multiplicador que vale para tudo. Continua float de proposito: multiplicador cabe no
## double sem perda, e Grande so paga a pena em acumulador (decisao 0001).
var multiplicador_global: float = 1.0

## Moeda do primeiro prestigio (GDD §17-18). Sobrevive ao reset da run.
var pontos_de_teorema: Grande = Grande.zero()

## Moeda do segundo prestigio (GDD §20). Sobrevive inclusive ao reset dos Teoremas.
var fragmentos: Grande = Grande.zero()

## Segundos de partida acumulados. Float porque e tempo, nao acumulador de recurso.
var tempo_jogado: float = 0.0
