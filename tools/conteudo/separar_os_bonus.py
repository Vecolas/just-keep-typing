# -*- coding: utf-8 -*-
"""A separacao dos tipos de bonus da issue #60.

⚠️ O PROBLEMA MEDIDO: 38 dos 44 upgrades eram multiplicadores que COMPOEM.

    VELOCIDADE_DO_MACACO  17 upgrades  ->  x5.627
    PRODUCAO_GLOBAL       21 upgrades  ->  x15.650.000
    CAPACIDADE             5 upgrades  ->  x112

Juntos, mais de 10^13 vindos so dos upgrades -- e nenhuma tabela manual de precos
sobrevive a isso.

⚠️ A REGRA DA SEPARACAO: o que um upgrade FAZ no texto decide o tipo dele, e nao o
contrario. Descricao que fala de producao nao vira desconto de custo so porque o
balanceamento precisava de um desconto ali -- isso faria o texto mentir, e a descricao e o
produto (CONVENCOES).

⚠️ E NENHUM ID MUDA. `upgrades_comprados` e uma lista de ids no save.
"""
import io
import os
import re

VELOCIDADE, GLOBAL, INTERRUPTOR, CAPACIDADE, SOMADA, CUSTO_MACACO = 0, 1, 2, 3, 4, 5

# ── OS CINCO MOMENTOS ────────────────────────────────────────────────────────────────────
# ⚠️ Um x2 em TUDO merece nome proprio. Estes cinco continuam multiplicando o global porque
# cada um e um acontecimento na campanha, e nao mais um upgrade da lista. Produto: x168.
GLOBAIS = {
    "duas_maos": 2.0,
    "turno_da_noite": 2.0,
    "sistema_automatico": 3.0,
    "linha_de_producao": 3.5,
    "o_macaco_percebe": 4.0,
}

# ── OS QUATRO QUE AINDA MULTIPLICAM A VELOCIDADE ─────────────────────────────────────────
# Os que falam do macaco ficando melhor NELE MESMO, e nao de mais uma ajuda externa.
# Produto: x15.
VELOCIDADES = {
    "dedos_mais_ageis": 1.5,
    "metodo_de_datilografia": 2.0,
    "motor_eletrico": 2.0,
    "dedos_probabilisticos": 2.5,
}

# ── OS DOIS DESCONTOS ────────────────────────────────────────────────────────────────────
# ⚠️ AQUI O TEXTO MUDA JUNTO, e essas sao as unicas duas descricoes que esta issue reescreve.
# Os dois falavam de producao; como desconto, o texto tem que falar de custo -- senao o
# jogador le "a producao sobe", ve o custo cair e conclui que o jogo esta quebrado.
#
# As duas frases novas entram na lista de texto autoral que ainda espera revisao do autor.
DESCONTOS = {
    "pausa_para_o_almoco": (
        0.85,
        "Macaco descansado vai embora menos. Contratar o próximo ficou mais barato.",
        "A rested monkey leaves less often. Hiring the next one got cheaper.",
    ),
    "departamento_de_digitacao": (
        0.7,
        "Agora existe um organograma. Metade das caixas está em branco, e mesmo assim "
        "contratar ficou mais barato.",
        "There is an org chart now. Half the boxes are empty, and hiring got cheaper anyway.",
    ),
}

# ── A PARCELA DE CADA UM DOS OUTROS ──────────────────────────────────────────────────────
# ⚠️ producao_base do macaco e 1,0: uma parcela de +1 dobra o que um macaco faz.
#
# As parcelas crescem ao longo da campanha porque um upgrade tardio tem que valer algo
# contra uma producao maior -- mas elas SOMAM entre si, entao vinte delas sao vinte, e nao
# 2^20. E essa a diferenca inteira entre uma curva que se ajusta e uma que explode.
PARCELAS = {
    # O Macaco
    "polegar_oponivel": 0.5,
    "banquinho_mais_alto": 1.0,
    "memoria_muscular": 3.0,
    "treinamento_questionavel": 12.0,
    "cafe_para_o_macaco": 40.0,
    "postura_de_trabalho": 400.0,
    "os_dois_pes": 2_000.0,
    "ergonomia_simiesca": 5_000.0,
    "equipe_de_digitacao": 30_000.0,
    # A Máquina
    "fita_nova": 0.6,
    "luz_da_mesa": 0.8,
    "martelos_alinhados": 1.5,
    "maquina_lubrificada": 4.0,
    "carbono_entre_as_folhas": 8.0,
    "molas_reforcadas": 20.0,
    "teclas_mais_leves": 60.0,
    "papel_continuo": 150.0,
    "teclas_industriais": 600.0,
    "revisor_automatico": 8_000.0,
    # A Organização
    "supervisor": 3_000.0,
    # O Conhecimento
    "um_dicionario": 2.0,
    "alfabeto_reordenado": 6.0,
    "tabela_de_frequencia": 25.0,
    "linguistica_estatistica": 200.0,
    "modelagem_probabilistica": 1_500.0,
    "estatistica_aplicada": 10_000.0,
    "teoria_da_informacao": 20_000.0,
}

# ── O QUE NAO MUDA ───────────────────────────────────────────────────────────────────────
# ⚠️ Lista explicita e nao "o resto": "o resto" nao acusa o upgrade que ninguem classificou.
INTOCADOS = {
    "instinto_digitador",   # interruptor
    "segunda_mesa",         # capacidade
    "arquivo_vertical",     # capacidade
    "espaco_nao_euclidiano",  # capacidade
    "mesa_maior",           # capacidade
    # ⚠️ ENTROU AQUI DEPOIS DE UM ERRO MEU, e vale registrar qual: eu o tinha posto como
    # parcela de velocidade. "Empilhar mesas" e VAGA, nao velocidade -- o texto dele diz
    # isso, e a regra do topo deste arquivo diz que o texto decide o tipo. Quem acusou foi
    # a composicao de CAPACIDADE cair de x112 para x45 sem eu ter mexido em capacidade
    # nenhuma.
    "mesas_empilhadas",     # capacidade
}

QUEBRA = chr(10)


def _campo(texto, chave, padrao=None):
    achou = re.search("^" + chave + r" = (.*)$", texto, re.M)
    return padrao if achou is None else achou.group(1).strip()


def _trocar(texto, chave, valor):
    return re.sub("^" + chave + r" = .*$", "%s = %s" % (chave, valor), texto, flags=re.M)


def _numero(x):
    if abs(x) < 1e16 and float(x).is_integer():
        return "%.1f" % x
    return repr(float(x))


def aplicar(pasta):
    vistos = set()
    mexidos = 0
    textos_novos = []

    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith(".tres"):
            continue
        caminho = os.path.join(pasta, nome)
        s = io.open(caminho, encoding="utf-8").read()
        ident = (_campo(s, "id", "") or "").strip('"')
        if not ident:
            continue
        vistos.add(ident)
        antes = s

        if ident in INTOCADOS:
            continue
        if ident in GLOBAIS:
            s = _trocar(_trocar(s, "tipo_de_efeito", GLOBAL), "valor", _numero(GLOBAIS[ident]))
        elif ident in VELOCIDADES:
            s = _trocar(
                _trocar(s, "tipo_de_efeito", VELOCIDADE), "valor", _numero(VELOCIDADES[ident])
            )
        elif ident in PARCELAS:
            s = _trocar(_trocar(s, "tipo_de_efeito", SOMADA), "valor", _numero(PARCELAS[ident]))
        elif ident in DESCONTOS:
            fator, em_portugues, em_ingles = DESCONTOS[ident]
            s = _trocar(_trocar(s, "tipo_de_efeito", CUSTO_MACACO), "valor", _numero(fator))
            s = _trocar(s, "descricao", '"%s"' % em_portugues)
            textos_novos.append((em_portugues, em_ingles))
        else:
            raise SystemExit("upgrade sem classificacao: %s" % ident)

        if s != antes:
            io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
            mexidos += 1

    # ⚠️ a outra metade: id classificado que nao existe mais na pasta e tabela desatualizada
    # apontando para o nada, e ela passaria despercebida para sempre
    declarados = set(GLOBAIS) | set(VELOCIDADES) | set(PARCELAS) | set(DESCONTOS) | INTOCADOS
    fantasmas = declarados - vistos
    if fantasmas:
        raise SystemExit("ids classificados que nao existem: %s" % sorted(fantasmas))

    return mexidos, textos_novos


def acrescentar_ao_csv(caminho, textos):
    s = io.open(caminho, encoding="utf-8").read()
    if not s.endswith(QUEBRA):
        s += QUEBRA
    novas = 0
    for em_portugues, em_ingles in textos:
        if QUEBRA + em_portugues + "," in s or QUEBRA + '"' + em_portugues + '",' in s:
            continue
        def cerca(c):
            return '"%s"' % c if "," in c else c
        s += "%s,%s,%s%s" % (cerca(em_portugues), cerca(em_portugues), cerca(em_ingles), QUEBRA)
        novas += 1
    io.open(caminho, "w", encoding="utf-8", newline=QUEBRA).write(s)
    return novas


if __name__ == "__main__":
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    pasta = os.path.normpath(os.path.join(raiz, "data", "upgrades"))
    mexidos, textos = aplicar(pasta)
    print("%d upgrades reclassificados" % mexidos)

    csv = os.path.normpath(os.path.join(raiz, "i18n", "textos.csv"))
    print("%d linhas novas no CSV" % acrescentar_ao_csv(csv, textos))

    print("")
    print("composicao depois:")
    produto = {}
    soma = {}
    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith(".tres"):
            continue
        s = io.open(os.path.join(pasta, nome), encoding="utf-8").read()
        tipo = int(_campo(s, "tipo_de_efeito", "0"))
        valor = float(_campo(s, "valor", "1"))
        if tipo in (VELOCIDADE, GLOBAL, CAPACIDADE, CUSTO_MACACO):
            produto[tipo] = produto.get(tipo, 1.0) * valor
        elif tipo == SOMADA:
            soma[tipo] = soma.get(tipo, 0.0) + valor
    nomes = {0: "VELOCIDADE (x)", 1: "GLOBAL (x)", 3: "CAPACIDADE (x)", 5: "DESCONTO (x)"}
    for tipo in sorted(produto):
        print("  %-16s %.4g" % (nomes[tipo], produto[tipo]))
    for tipo in sorted(soma):
        print("  %-16s +%.4g" % ("SOMADA (+)", soma[tipo]))
