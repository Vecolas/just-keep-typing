# -*- coding: utf-8 -*-
"""A redistribuicao dos upgrades da issue #61.

⚠️ MARCO NAO E BOTAO DE TUNING. O `requisito` de um marco e um FATO sobre o mundo -- "A
Biblia completa: 783.000 palavras x 4,5 caracteres" --, e o campo `nota` ao lado existe
para documentar essa conta. Mudar o requisito de `a_biblia` de 3,5e6 para 1e20 nao
redistribuiria nada: faria o Panorama mentir, que e o contrario do que a decisao 0003 e a
issue #51 constroem.

Entao o que esta issue redistribui sao os UPGRADES, cujo `requisito` e `custo` sao numeros
de balanceamento de verdade. Quando cada marco cai e CONSEQUENCIA da velocidade da
economia, e nao uma escolha -- e a issue #65 e quem mexe nisso.

⚠️ A ORDEM RELATIVA E PRESERVADA. Os upgrades sao reordenados pelo custo atual e recebem
custo e requisito novos na MESMA ordem: assim a monotonia dentro de cada escada
(familia, tipo de efeito) continua valendo sem precisar reconferir 44 pares a mao.
"""
import io
import os
import re

QUEBRA = chr(10)

## ⚠️ O TETO SAI DA MEDICAO, e nao de gosto. A regua mostrou a economia cruzando 10^23 aos
## 30 minutos e estacionando; 10^26 e o alvo para o fim da primeira hora, ja contando com o
## primeiro prestigio aos 28 min reacelerando a curva.
EXPOENTE_INICIAL = 1.3   # ~20 caracteres, o primeiro upgrade de hoje
EXPOENTE_FINAL = 18.0

## Quanto do requisito o upgrade custa. Abaixo de 1 para ele ser COMPRAVEL pouco depois de
## aparecer -- upgrade que aparece na loja e fica inalcancavel por dez minutos e uma
## promessa que a interface faz e a economia nao cumpre.
FATOR_DE_CUSTO = 0.12

## ⚠️ O UPGRADE QUE LIGA O JOGO NAO SE ESPALHA. `instinto_digitador` e o interruptor da
## producao automatica: ate ele, o macaco nao digita sozinho (GDD §3) e o clique e a unica
## fonte. Ele tem que estar na loja desde o primeiro quadro, com um custo que dez cliques
## alcancam.
##
## A primeira versao deste script o tratou como mais um da fila e lhe deu requisito 20 --
## o que adia a ignicao do jogo e derruba quatro afirmacoes da suite de Economia. Mesma
## familia de erro do `mesas_empilhadas` na issue #60: regra geral aplicada sem olhar o
## que a peca E.
FIXOS = {
    "instinto_digitador": (0.0, 10.0),  # (requisito, custo)
}


def _campo(texto, chave, padrao=None):
    achou = re.search("^" + chave + r" = (.*)$", texto, re.M)
    return padrao if achou is None else achou.group(1).strip()


def _trocar(texto, chave, valor):
    return re.sub("^" + chave + r" = .*$", "%s = %s" % (chave, valor), texto, flags=re.M)


def _numero(x):
    if abs(x) < 1e16 and float(x).is_integer():
        return "%.1f" % x
    return repr(float(x))


def espalhar(pasta):
    arquivos = []
    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith(".tres"):
            continue
        caminho = os.path.join(pasta, nome)
        s = io.open(caminho, encoding="utf-8").read()
        ident = (_campo(s, "id", "") or "").strip('"')
        if not ident:
            continue
        arquivos.append((float(_campo(s, "custo", "0")), ident, caminho, s))

    # ⚠️ ordena pelo custo ATUAL: e ele que carrega a intencao de ordem que ja existia
    arquivos.sort()
    if len(arquivos) < 2:
        raise SystemExit("upgrades de menos para espalhar: %d" % len(arquivos))

    # ⚠️ id fixo que nao existe mais na pasta e tabela apontando para o nada
    faltando = set(FIXOS) - {a[1] for a in arquivos}
    if faltando:
        raise SystemExit("ids fixos que nao existem: %s" % sorted(faltando))

    mexidos = 0
    tabela = []
    moveis = [a for a in arquivos if a[1] not in FIXOS]
    for ident, (requisito, custo) in FIXOS.items():
        for _antigo, outro, caminho, s in arquivos:
            if outro != ident:
                continue
            antes = s
            s = _trocar(_trocar(s, "requisito", _numero(requisito)), "custo", _numero(custo))
            if s != antes:
                io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
                mexidos += 1
            tabela.append((ident, requisito, custo))

    quantos = len(moveis)
    for i, (_antigo, ident, caminho, s) in enumerate(moveis):
        fatia = float(i) / float(quantos - 1)
        expoente = EXPOENTE_INICIAL + (EXPOENTE_FINAL - EXPOENTE_INICIAL) * fatia
        requisito = 10.0 ** expoente
        custo = requisito * FATOR_DE_CUSTO

        antes = s
        s = _trocar(s, "requisito", _numero(requisito))
        s = _trocar(s, "custo", _numero(custo))
        if s != antes:
            io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
            mexidos += 1
        tabela.append((ident, requisito, custo))

    return mexidos, tabela


if __name__ == "__main__":
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    pasta = os.path.normpath(os.path.join(raiz, "data", "upgrades"))
    mexidos, tabela = espalhar(pasta)
    print("%d upgrades espalhados entre 10^%.1f e 10^%.1f" % (
        mexidos, EXPOENTE_INICIAL, EXPOENTE_FINAL,
    ))
    print("")
    for i, (ident, requisito, custo) in enumerate(tabela):
        if i % 6 == 0 or i == len(tabela) - 1:
            print("  %2d  %-28s aparece em %.3g, custa %.3g" % (i, ident, requisito, custo))
