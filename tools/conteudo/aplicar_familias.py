# -*- coding: utf-8 -*-
"""Aplica as familias da issue #53 em data/upgrades/ e no CSV.

Roda quantas vezes quiser: acrescentar a coluna e idempotente, e o CSV deduplica pela
chave.

⚠️ ESTE SCRIPT CONFERE ANTES DE ESCREVER, e a conferencia e a mesma regra que a suite
cobra depois. Nao e duplicacao ociosa: aqui ela diz QUAL par quebrou enquanto o conteudo
ainda esta na minha mao, e la ela protege contra o proximo .tres escrito a mao. Se as
duas discordarem, quem manda e a suite -- o gerador nao e portao.
"""
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from upgrades_em_familias import (  # noqa: E402
    AJUSTES_DE_VALOR,
    EM_INGLES,
    FAMILIA_DOS_EXISTENTES,
    NOVOS,
    INTERRUPTOR,
)

QUEBRA = chr(10)

MOLDE = """[gd_resource type="Resource" script_class="DadosUpgrade" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/producao/dados_upgrade.gd" id="1_dados_upgrade"]

[resource]
script = ExtResource("1_dados_upgrade")
familia = {familia}
id = "{id}"
nome = "{nome}"
descricao = "{descricao}"
custo = {custo}
tipo_de_efeito = {efeito}
valor = {valor}
requisito = {requisito}
"""


def _numero(x):
    """Do jeito que o Godot serializa float: inteiro pequeno com `.0`, grande em notacao
    cientifica. Escrever `40` em vez de `40.0` faz o Godot reescrever o arquivo no
    proximo save do editor, e um diff que aparece sozinho e um diff que ninguem le."""
    if abs(x) < 1e16 and float(x).is_integer():
        return "%.1f" % x
    return repr(float(x))


def _ler(caminho):
    return io.open(caminho, encoding="utf-8").read()


def _campo(texto, chave, padrao=None):
    achou = re.search("^" + chave + r" = (.*)$", texto, re.M)
    if achou is None:
        return padrao
    return achou.group(1).strip()


def acrescentar_coluna(pasta):
    """Poe `familia` nos .tres que ja existem, e aplica os dois ajustes de valor."""
    mexidos = 0
    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith(".tres"):
            continue
        caminho = os.path.join(pasta, nome)
        s = _ler(caminho)
        ident = _campo(s, "id", "").strip('"')
        if ident not in FAMILIA_DOS_EXISTENTES:
            continue
        antes = s
        familia = FAMILIA_DOS_EXISTENTES[ident]
        if re.search(r"^familia = ", s, re.M):
            s = re.sub(r"^familia = .*$", "familia = %d" % familia, s, flags=re.M)
        else:
            # entra ANTES do id, que e a ordem em que o @export foi declarado: o Godot
            # reescreve o .tres nessa ordem, e escrever fora dela produz um diff
            # espontaneo no proximo toque do editor
            s = s.replace('id = "%s"' % ident, "familia = %d%sid = \"%s\"" % (familia, QUEBRA, ident))
        if ident in AJUSTES_DE_VALOR:
            s = re.sub(
                r"^valor = .*$", "valor = %s" % _numero(AJUSTES_DE_VALOR[ident]), s, flags=re.M
            )
        if s != antes:
            io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
            mexidos += 1
    return mexidos


def escrever_novos(pasta):
    escritos = 0
    for (ident, nome, descricao, custo, efeito, valor, requisito, familia) in NOVOS:
        caminho = os.path.join(pasta, ident + ".tres")
        conteudo = MOLDE.format(
            familia=familia,
            id=ident,
            nome=nome,
            descricao=descricao,
            custo=_numero(custo),
            efeito=efeito,
            valor=_numero(valor),
            requisito=_numero(requisito),
        )
        if os.path.exists(caminho) and _ler(caminho) == conteudo:
            continue
        io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(conteudo)
        escritos += 1
    return escritos


def conferir_monotonia(pasta):
    """Dentro de (familia, tipo de efeito), ordenado por custo, o valor nunca cai.

    ⚠️ O PAR E (FAMILIA, TIPO), e nao a familia sozinha. CAPACIDADE nao e multiplicador de
    producao: comparar "x5 de vaga" com "x2 de producao global" nao quer dizer nada, e uma
    regua que comparasse os dois reprovaria dado certo -- que e o jeito mais rapido de
    ensinar todo mundo a ignorar a regua.
    """
    linhas = []
    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith(".tres"):
            continue
        s = _ler(os.path.join(pasta, nome))
        linhas.append((
            int(_campo(s, "familia", "0")),
            int(_campo(s, "tipo_de_efeito", "0")),
            float(_campo(s, "custo", "0")),
            float(_campo(s, "valor", "1")),
            _campo(s, "id", "").strip('"'),
        ))

    problemas = []
    grupos = {}
    for familia, efeito, custo, valor, ident in linhas:
        if efeito == INTERRUPTOR:
            continue  # interruptor nao multiplica: valor 1.0 nao entra na escada
        grupos.setdefault((familia, efeito), []).append((custo, valor, ident))

    for chave, itens in sorted(grupos.items()):
        itens.sort()
        for i in range(1, len(itens)):
            if itens[i][1] < itens[i - 1][1]:
                problemas.append(
                    "familia %d, efeito %d: %s (custo %.3g, x%s) custa mais que %s "
                    "(custo %.3g, x%s) e multiplica MENOS"
                    % (chave[0], chave[1], itens[i][2], itens[i][0], itens[i][1],
                       itens[i - 1][2], itens[i - 1][0], itens[i - 1][1])
                )
    return grupos, problemas


def linhas_de_csv():
    chaves = []
    for (_i, nome, descricao, _c, _e, _v, _r, _f) in NOVOS:
        chaves.extend([nome, descricao])
    chaves.extend(["O Macaco", "A Máquina", "A Organização", "O Conhecimento", "Sem família"])

    faltando = [c for c in chaves if c not in EM_INGLES]
    if faltando:
        raise SystemExit("sem traducao para %d chave(s): %s" % (len(faltando), faltando[:3]))

    def cerca(c):
        return '"%s"' % c if "," in c else c

    saida = []
    vistas = set()
    for chave in chaves:
        if chave in vistas:
            continue
        vistas.add(chave)
        saida.append((chave, "%s,%s,%s" % (cerca(chave), cerca(chave), cerca(EM_INGLES[chave]))))
    return saida


def acrescentar_ao_csv(caminho):
    """Deduplica PELA CHAVE, e nunca por `split(",")[0]` -- ver descobertas_novas.py."""
    s = _ler(caminho)
    if not s.endswith(QUEBRA):
        s += QUEBRA
    novas = 0
    for chave, linha in linhas_de_csv():
        if QUEBRA + chave + "," in s or QUEBRA + '"' + chave + '",' in s:
            continue
        s += linha + QUEBRA
        novas += 1
    io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
    return novas


if __name__ == "__main__":
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    pasta = os.path.normpath(os.path.join(raiz, "data", "upgrades"))

    print("%d .tres existentes ganharam familia" % acrescentar_coluna(pasta))
    print("%d upgrades novos escritos" % escrever_novos(pasta))

    grupos, problemas = conferir_monotonia(pasta)
    for chave, itens in sorted(grupos.items()):
        print("  familia %d, efeito %d: %d degraus" % (chave[0], chave[1], len(itens)))
    if problemas:
        print(QUEBRA + "REPROVOU:")
        for p in problemas:
            print("  " + p)
        raise SystemExit(1)
    print("monotonia: ok em %d escadas" % len(grupos))

    csv = os.path.normpath(os.path.join(raiz, "i18n", "textos.csv"))
    print("%d linhas novas no CSV" % acrescentar_ao_csv(csv))
    print("total de upgrades: %d" % len([n for n in os.listdir(pasta) if n.endswith(".tres")]))
