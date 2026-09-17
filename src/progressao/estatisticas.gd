## As estatisticas da partida, uteis e inuteis (GDD §23 e §24). Logica pura, so estatica.
##
## ⚠️ AS ENGRACADAS SAO DERIVADAS DE ALGO REAL. "Bananas consumidas" nao e um contador
## secreto nem um numero aleatorio: sao macacos vezes tempo, com uma banana a cada meia
## hora. O jogador percebe a diferenca -- numero inventado nao muda quando ele joga, e no
## instante em que ele nota isso a piada morre e a tela inteira vira decoracao.
##
## Por isso cada uma tem a conta escrita ao lado, como os marcos tem a nota: a piada
## depende de o numero ser verdadeiro.
##
## Nao guarda nada. Le Jogo e Economia na hora em que a tela pergunta (CONVENCOES.md,
## regra 2 de arquitetura).
class_name Estatisticas

## Uma banana por macaco a cada meia hora. E o unico numero de balanceamento aqui, e ele
## nao muda partida nenhuma -- e piada, e nao economia, entao nao vai para .tres.
const SEGUNDOS_POR_BANANA: float = 1800.0

## Hamlet tem cerca de 175.000 caracteres.
const CARACTERES_DE_HAMLET: float = 175000.0

## Pagina datilografada, o mesmo numero do marco uma_pagina.
const CARACTERES_POR_PAGINA: float = 1800.0

## Um macaco batendo ao acaso erra quase tudo. "Quase" porque as descobertas provam que
## de vez em quando ele acerta.
const FRACAO_DE_ERRO: float = 0.9999


## As uteis do GDD §23. Cada entrada: {"rotulo": chave de traducao, "valor": Grande|float}.
static func uteis() -> Array[Dictionary]:
	return [
		{"rotulo": "Total de caracteres", "valor": Jogo.total_caracteres},
		{"rotulo": "Caracteres desta run", "valor": Jogo.caracteres_da_run},
		{"rotulo": "Caracteres por segundo", "valor": Jogo.caracteres_por_segundo},
		{"rotulo": "Recorde de caracteres por segundo", "valor": Jogo.recorde_por_segundo},
		{"rotulo": "Macacos trabalhando", "valor": Jogo.macacos},
		{"rotulo": "Macacos comprados", "valor": Jogo.macacos_comprados},
		{"rotulo": "Descobertas realizadas",
			"valor": Grande.de_float(float(Descobertas.quantas_encontradas()))},
		{"rotulo": "Marcos do Panorama alcançados",
			"valor": Grande.de_float(float(Jogo.marcos_alcancados.size()))},
		{"rotulo": "Upgrades comprados",
			"valor": Grande.de_float(float(Jogo.upgrades_comprados.size()))},
		{"rotulo": "Prestígios realizados", "valor": Grande.de_float(float(Jogo.prestigios))},
		{"rotulo": "Pontos de Teorema", "valor": Jogo.pontos_de_teorema},
		{"rotulo": "Produção offline acumulada", "valor": Jogo.total_offline},
	]


## As do GDD §24, que sao metade da piada. Toda uma derivada de estado real.
static func inuteis() -> Array[Dictionary]:
	return [
		{
			"rotulo": "Bananas consumidas",
			# macacos x tempo, uma a cada meia hora
			"valor": Jogo.macacos.vezes(
				Grande.de_float(Jogo.tempo_jogado / SEGUNDOS_POR_BANANA)
			),
		},
		{
			"rotulo": "Máquinas destruídas",
			# cada troca de tier aposenta a anterior, e "aposentar" e generoso
			"valor": Grande.de_float(float(maxi(Economia.maquina_atual().tier - 1, 0))
				if Economia.maquina_atual() != null else 0.0),
		},
		{
			"rotulo": "Macacos que aprenderam a escrever",
			# um por descoberta: alguem ali acertou de propósito
			"valor": Grande.de_float(float(Descobertas.quantas_encontradas())),
		},
		{
			"rotulo": "Macacos que aparentemente aprenderam física",
			# um a cada dez marcos: por volta dai o Panorama para de falar de livro
			"valor": Grande.de_float(floorf(float(Jogo.marcos_alcancados.size()) / 10.0)),
		},
		{
			"rotulo": "Hamlets produzidos",
			"valor": Jogo.total_caracteres.dividido(Grande.de_float(CARACTERES_DE_HAMLET)),
		},
		{
			"rotulo": "Textos que ninguém jamais lerá",
			# todas as paginas, porque nenhuma delas foi lida
			"valor": Jogo.total_caracteres.dividido(Grande.de_float(CARACTERES_POR_PAGINA)),
		},
		{
			"rotulo": "Erros ortográficos estimados",
			"valor": Jogo.total_caracteres.vezes(Grande.de_float(FRACAO_DE_ERRO)),
		},
	]


## Tempo total e tempo da run, ja em texto. Separadas das outras porque duracao nao se
## escreve com o Formatador -- ele formata quantidade, e hora nao e quantidade.
static func tempos() -> Array[Dictionary]:
	return [
		{"rotulo": "Tempo total jogado", "valor": duracao(Jogo.tempo_jogado)},
		{"rotulo": "Tempo desta run", "valor": duracao(Jogo.tempo_da_run)},
	]


## ⚠️ MUDOU DE CASA NA ISSUE #40, e este atalho existe para nao haver duas contas. A tela
## de Arquivos tambem escreve tempo jogado; deixar uma copia aqui daria dois tempos
## diferentes para o MESMO Manuscrito, em duas telas do mesmo jogo, sem erro nenhum.
static func duracao(segundos: float) -> String:
	return Relogio.duracao(segundos)
