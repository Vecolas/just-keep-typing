# -*- coding: utf-8 -*-
"""A Estranheza (issue #74): conteudo para os 30-40 minutos, SEM tocar na economia.

⚠️ NADA AQUI MEXE EM CPS, e essa e a regra inteira da issue. A decisao 0009 listou tres
saidas para o bloco vazio, e a escolhida foi a C: conteudo que nao altera a economia. As
outras duas eram aceitar o silencio -- dez minutos e longo demais, e logo antes de o jogador
entender o prestigio -- e acrescentar conteudo economico, que reabriria a explosao que a
v0.7 acabou de fechar.

    "Nao precisa existir uma compra a cada minuto. Precisa existir algo para perceber."

⚠️ E MARCO NAO ENTRA. O requisito de um marco e um fato sobre o mundo (decisao 0003), e
criar marco para preencher minuto faria o Panorama mentir. O veiculo sao DESCOBERTAS de
papel HUMOR e EXPLICACAO, que ja existem desde a issue #52 justamente para isto: descoberta
que nao da bonus nenhum.

⚠️ TEXTO AUTORAL NOVO. Estas cinco entram na fila de revisao do autor, que ja tem ~70 pecas
esperando. Sao poucas de proposito.
"""
import io
import os

HUMOR, EXPLICACAO = 1, 2

## ⚠️ AS CINCO SAO EPICAS, E ISSO NAO E ESCOLHA DE SABOR. A suite cobra que toda descoberta
## de uma categoria seja mais rara que TODA de uma categoria anterior (issue #17), e a
## primeira versao destas cinco quebrou isso: eu escolhi "Raro" e "Epico" pelo peso
## narrativo e escrevi chances que atravessavam as duas faixas.
##
## O vazio de 30 a 40 minutos cai entre a primeira Epica (13:35) e a primeira Lendaria
## (56:22). A folga entre as duas escadas e de 10^-11 a 10^-13 -- e e dentro dela que estas
## cinco moram.
EPICO = 3

## ⚠️ A FOLGA DA FAIXA, para a escada continuar valida. Epico vai ate 1e-11 e Lendario
## comeca em 1e-13: estas cinco ficam ENTRE as duas, na ordem em que devem aparecer.
FOLGA_MAXIMA = 1.0e-11
FOLGA_MINIMA = 1.0e-13

## ⚠️ A CHANCE E O UNICO NUMERO DE BALANCEAMENTO AQUI, e ela nao muda a producao: ela decide
## QUANDO o texto aparece. chance = caracteres_do_tique x chance_base, entao ela e calibrada
## contra a producao da faixa de 30 a 40 minutos.
##
## E o jogador tem que SENTIR variabilidade: a regua mede uma semente fixa, mas duas
## partidas nao devem entregar a mesma sequencia no mesmo minuto. Por isso sao chances, e
## nao um calendario.
##
## (id, nome, texto, categoria, chance_base, papel, curiosidade)
AS_CINCO = [
    (
        "as_paginas_nao_contam_mais",
        "As Páginas Não Contam Mais",
        "Alguém parou de converter em páginas. Não havia mais papel suficiente na metáfora.",
        EPICO, 8.0e-12, EXPLICACAO,
        "Uma página cabe umas duas mil letras. A partir de certo ponto, dizer o número em "
        "páginas exige mais dígitos do que dizer o número.",
    ),
    (
        "a_notacao_mudou",
        "A Notação Mudou",
        "Os números deixaram de caber por extenso. Ninguém avisou; eles simplesmente "
        "encolheram.",
        EPICO, 5.0e-12, EXPLICACAO,
        "Notação científica não é um jeito de escrever números grandes. É o reconhecimento "
        "de que o nome deles deixou de importar.",
    ),
    (
        "um_silencio",
        "Um Silêncio",
        "Por quatro segundos, nenhuma tecla foi pressionada. O macaco depois não soube "
        "explicar.",
        EPICO, 2.5e-12, HUMOR,
        "",
    ),
    (
        "a_mesma_frase_de_novo",
        "A Mesma Frase, De Novo",
        "Já tinha saído antes. Com produção suficiente, tudo já saiu antes.",
        EPICO, 9.0e-13, EXPLICACAO,
        "Com um alfabeto finito, repetir é inevitável antes de esgotar. É por isso que o "
        "teorema fala em certeza, e não em sorte.",
    ),
    (
        "alguma_coisa_vai_acontecer",
        "Alguma Coisa Vai Acontecer",
        "A produção passou de qualquer coisa que se possa querer produzir. E continua "
        "subindo.",
        EPICO, 3.0e-13, EXPLICACAO,
        "Quando a quantidade deixa de ser o problema, o que sobra é a pergunta que o "
        "Teorema faz.",
    ),
]

EM_INGLES = {
    "As Páginas Não Contam Mais": "Pages No Longer Count",
    "Alguém parou de converter em páginas. Não havia mais papel suficiente na metáfora.":
        "Someone stopped converting into pages. There was not enough paper left in the "
        "metaphor.",
    "Uma página cabe umas duas mil letras. A partir de certo ponto, dizer o número em "
    "páginas exige mais dígitos do que dizer o número.":
        "A page holds some two thousand letters. Past a point, saying the number in pages "
        "takes more digits than saying the number.",
    "A Notação Mudou": "The Notation Changed",
    "Os números deixaram de caber por extenso. Ninguém avisou; eles simplesmente encolheram.":
        "The numbers stopped fitting when spelled out. Nobody announced it; they simply "
        "shrank.",
    "Notação científica não é um jeito de escrever números grandes. É o reconhecimento "
    "de que o nome deles deixou de importar.":
        "Scientific notation is not a way of writing large numbers. It is the admission "
        "that their names stopped mattering.",
    "Um Silêncio": "A Silence",
    "Por quatro segundos, nenhuma tecla foi pressionada. O macaco depois não soube explicar.":
        "For four seconds, no key was pressed. The monkey could not explain it afterwards.",
    "A Mesma Frase, De Novo": "The Same Sentence, Again",
    "Já tinha saído antes. Com produção suficiente, tudo já saiu antes.":
        "It had come out before. With enough production, everything has come out before.",
    "Com um alfabeto finito, repetir é inevitável antes de esgotar. É por isso que o "
    "teorema fala em certeza, e não em sorte.":
        "With a finite alphabet, repetition comes before exhaustion. That is why the "
        "theorem speaks of certainty, not luck.",
    "Alguma Coisa Vai Acontecer": "Something Is About To Happen",
    "A produção passou de qualquer coisa que se possa querer produzir. E continua subindo.":
        "Production has passed anything anyone might want produced. And it keeps rising.",
    "Quando a quantidade deixa de ser o problema, o que sobra é a pergunta que o "
    "Teorema faz.":
        "When quantity stops being the problem, what remains is the question the Theorem "
        "asks.",
}

QUEBRA = chr(10)

MOLDE = """[gd_resource type="Resource" script_class="DadosDescoberta" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/progressao/dados_descoberta.gd" id="1_dados"]

[resource]
script = ExtResource("1_dados")
id = "{id}"
nome = "{nome}"
texto = "{texto}"
categoria = {categoria}
chance_base = {chance}
bonus = 1.0
papel = {papel}
curiosidade = "{curiosidade}"
"""


def escrever(pasta):
    escritos = 0
    for (ident, nome, texto, categoria, chance, papel, curiosidade) in AS_CINCO:
        caminho = os.path.join(pasta, ident + ".tres")
        conteudo = MOLDE.format(
            id=ident, nome=nome, texto=texto, categoria=categoria,
            chance=repr(chance), papel=papel, curiosidade=curiosidade,
        )
        if os.path.exists(caminho) and io.open(caminho, encoding="utf-8").read() == conteudo:
            continue
        io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(conteudo)
        escritos += 1
    return escritos


def acrescentar_ao_csv(caminho):
    chaves = []
    for (_i, nome, texto, _c, _ch, _p, curiosidade) in AS_CINCO:
        chaves.extend([nome, texto])
        if curiosidade:
            chaves.append(curiosidade)

    faltando = [c for c in chaves if c not in EM_INGLES]
    if faltando:
        raise SystemExit("sem traducao: %s" % faltando[:2])

    s = io.open(caminho, encoding="utf-8").read()
    if not s.endswith(QUEBRA):
        s += QUEBRA
    novas = 0
    for chave in chaves:
        if QUEBRA + chave + "," in s or QUEBRA + '"' + chave + '",' in s:
            continue
        def cerca(c):
            return '"%s"' % c if "," in c else c
        s += "%s,%s,%s%s" % (cerca(chave), cerca(chave), cerca(EM_INGLES[chave]), QUEBRA)
        novas += 1
    io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
    return novas


if __name__ == "__main__":
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    pasta = os.path.normpath(os.path.join(raiz, "data", "descobertas"))
    print("%d descobertas narrativas escritas" % escrever(pasta))
    csv = os.path.normpath(os.path.join(raiz, "i18n", "textos.csv"))
    print("%d linhas novas no CSV" % acrescentar_ao_csv(csv))
