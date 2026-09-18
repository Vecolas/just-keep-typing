# -*- coding: utf-8 -*-
"""As descobertas da issue #52, escritas como tabela e geradas como .tres.

POR QUE UMA TABELA, E NAO QUARENTA E CINCO ARQUIVOS ESCRITOS A MAO: quarenta e cinco
arquivos escritos um a um divergem. Um esquece o campo `papel`, outro escreve a chance com
um zero a mais, um terceiro usa outra ordem de campos e o diff do proximo que mexer neles
fica ilegivel. A tabela e a fonte; os .tres sao a saida.

⚠️ E OS .tres CONTINUAM SENDO A VERDADE DO JOGO. Este arquivo gera e sai de cena -- ele
nao e lido em tempo de execucao, nao entra no build, e mexer num .tres depois disto e
legitimo. Ele vive em tools/ pelo mesmo motivo que as reguas vivem: nada daqui entra no
jogo.

Uso:

    python tools/conteudo/descobertas_novas.py

A CURVA. `chance` e a chance por caractere produzido. Ela tem que CAIR de uma categoria
para a seguinte, e a suite reprova quem inverter -- categoria mais rara saindo antes da
menos rara quebraria a leitura inteira do sistema.

OS TREZE DEGRAUS do plano v0.6 §3, que sao o esqueleto do conteudo:

    LETRA -> SILABA -> PALAVRA -> EXPRESSAO -> FRASE -> PARAGRAFO -> POEMA
    -> CONTO -> TEXTO COERENTE -> OBRA -> TEXTO IMPROVAVEL -> TEXTO IMPOSSIVEL -> PARADOXO
"""
import io
import os

COMUM, INCOMUM, RARO, EPICO, LENDARIO, IMPOSSIVEL, PARADOXAL = range(7)
BONUS, HUMOR, EXPLICACAO, INTERFACE = range(4)

# id, nome, texto, categoria, chance, bonus, papel, curiosidade, degrau
NOVAS = [
    # ── LETRA ────────────────────────────────────────────────────────────────────────
    ("uma_letra", "Uma Letra", "A primeira coisa que o macaco produziu de propósito nenhum.",
     COMUM, 3e-3, 1.02, BONUS, "", "LETRA"),
    ("a_mesma_letra_duas_vezes", "A Mesma Letra Duas Vezes",
     "Duas vezes seguidas. O macaco não tentou, e é isso que impressiona.",
     COMUM, 2.4e-3, 1.0, HUMOR, "", "LETRA"),

    # ── SÍLABA ───────────────────────────────────────────────────────────────────────
    ("uma_silaba", "Uma Sílaba", "Consoante e vogal, nessa ordem. Já é mais do que parece.",
     COMUM, 2e-3, 1.03, BONUS, "", "SÍLABA"),
    ("uma_silaba_pronunciavel", "Uma Sílaba Pronunciável",
     "Dá para dizer em voz alta sem treinar antes.",
     COMUM, 1.6e-3, 1.0, EXPLICACAO,
     "Uma sílaba do português cabe em duas a quatro letras. Com vinte e seis teclas, a "
     "chance de acertar uma por acaso é bem maior do que a de acertar uma palavra.",
     "SÍLABA"),
    ("uma_vogal_sozinha", "Uma Vogal Sozinha",
     "Uma letra que já é uma palavra inteira. Preguiça premiada.",
     COMUM, 1.3e-3, 1.0, HUMOR, "", "SÍLABA"),

    # ── PALAVRA ──────────────────────────────────────────────────────────────────────
    ("uma_palavra_de_tres_letras", "Uma Palavra de Três Letras",
     "Curta, comum e completamente acidental.",
     COMUM, 8e-4, 1.05, BONUS, "", "PALAVRA"),
    ("uma_palavra_longa", "Uma Palavra Longa",
     "Doze letras na ordem certa. Ninguém estava olhando na hora.",
     COMUM, 7e-4, 1.08, BONUS, "", "PALAVRA"),
    ("eu", "EU", "Duas letras. Filosoficamente inconvenientes.",
     COMUM, 5e-4, 1.0, EXPLICACAO,
     "É o pronome mais curto do português e o mais difícil de ignorar. O macaco não quis "
     "dizer nada — e é exatamente por isso que incomoda.",
     "PALAVRA"),
    ("ola", "OLÁ", "Por um instante, pareceu intencional.",
     COMUM, 4e-4, 1.0, INTERFACE, "", "PALAVRA"),
    ("banana", "BANANA", "Contra todas as probabilidades, ele sabe exatamente o que quer.",
     COMUM, 2e-4, 1.12, BONUS, "", "PALAVRA"),

    # ── EXPRESSÃO ────────────────────────────────────────────────────────────────────
    ("uma_pergunta", "Uma Pergunta",
     "Termina em interrogação e tudo. Ninguém respondeu.",
     INCOMUM, 8e-6, 1.12, BONUS, "", "EXPRESSÃO"),
    ("uma_negacao", "Uma Negação",
     "O macaco discordou de alguma coisa. Não se sabe de quê.",
     INCOMUM, 7e-6, 1.0, HUMOR, "", "EXPRESSÃO"),

    # ── FRASE ────────────────────────────────────────────────────────────────────────
    ("uma_frase_gramatical", "Uma Frase Gramatical",
     "Estatisticamente improvável. Linguisticamente decepcionante.",
     INCOMUM, 9e-6, 1.18, BONUS, "", "FRASE"),
    ("um_dialogo_de_duas_linhas", "Um Diálogo de Duas Linhas",
     "Alguém pergunta, alguém responde. Os dois são o mesmo macaco.",
     INCOMUM, 5e-6, 1.2, BONUS, "", "FRASE"),
    ("uma_definicao", "Uma Definição",
     "Uma palavra e o que ela significa. As duas partes saíram por acaso.",
     INCOMUM, 4e-6, 1.0, EXPLICACAO,
     "Para uma definição funcionar, duas sequências independentes precisam cair certas ao "
     "mesmo tempo. A chance de cada uma se multiplica — é por isso que ela é mais rara que "
     "uma frase do mesmo tamanho.",
     "FRASE"),
    ("um_trocadilho", "Um Trocadilho",
     "Involuntário, como todo bom trocadilho.",
     INCOMUM, 3.5e-6, 1.0, HUMOR, "", "FRASE"),

    # ── PARÁGRAFO ────────────────────────────────────────────────────────────────────
    ("uma_lista", "Uma Lista",
     "Três itens e um traço na frente de cada. Organizadíssima e sobre nada.",
     INCOMUM, 4.5e-6, 1.22, BONUS, "", "PARÁGRAFO"),
    ("um_proverbio", "Um Provérbio",
     "Soa antigo e sábio. Tem doze segundos de idade.",
     INCOMUM, 2e-6, 1.3, BONUS, "", "PARÁGRAFO"),

    # ── POEMA ────────────────────────────────────────────────────────────────────────
    ("um_haicai", "Um Haicai",
     "Cinco, sete, cinco. A métrica saiu certa e ninguém contou.",
     RARO, 2e-7, 1.6, BONUS, "", "POEMA"),
    ("uma_letra_de_musica", "Uma Letra de Música",
     "Com refrão. O refrão se repete porque o acaso também se repete.",
     RARO, 6e-8, 1.9, BONUS, "", "POEMA"),

    # ── CONTO ────────────────────────────────────────────────────────────────────────
    ("uma_receita_funcional", "Uma Receita Funcional",
     "Ingredientes, modo de preparo e um tempo de forno plausível. Não teste.",
     RARO, 3e-7, 1.4, BONUS, "", "CONTO"),
    ("uma_carta_de_amor", "Uma Carta de Amor",
     "Endereçada a ninguém, assinada por acaso.",
     RARO, 1.5e-7, 1.45, BONUS, "", "CONTO"),
    ("um_conto_curto", "Um Conto",
     "Começo, meio e fim. Nessa ordem, inclusive.",
     RARO, 8e-8, 1.8, BONUS, "", "CONTO"),
    ("uma_piada", "Uma Piada",
     "Tem graça. É a parte mais improvável de tudo isto.",
     RARO, 2e-8, 1.0, HUMOR, "", "CONTO"),

    # ── TEXTO COERENTE ───────────────────────────────────────────────────────────────
    ("um_obituario", "Um Obituário",
     "De alguém que não existiu. A família fictícia agradece.",
     RARO, 4e-8, 2.0, BONUS, "", "TEXTO COERENTE"),
    ("um_verbete", "Um Verbete",
     "Com etimologia. A etimologia também está errada, mas convence.",
     RARO, 3e-8, 2.2, BONUS, "", "TEXTO COERENTE"),
    ("um_capitulo_coerente", "Um Capítulo Coerente",
     "Onze páginas que se sustentam. A décima segunda não.",
     EPICO, 3e-9, 2.5, BONUS, "", "TEXTO COERENTE"),
    ("um_ensaio", "Um Ensaio",
     "Defende uma tese do começo ao fim. A tese é sobre bananas.",
     EPICO, 1e-9, 2.8, BONUS, "", "TEXTO COERENTE"),

    # ── OBRA ─────────────────────────────────────────────────────────────────────────
    ("um_manifesto", "Um Manifesto",
     "Convicto, urgente e completamente sem causa.",
     EPICO, 3e-10, 3.5, BONUS, "", "OBRA"),
    ("uma_novela_curta", "Uma Novela Curta",
     "Cento e vinte páginas com personagens que não se contradizem.",
     EPICO, 7e-11, 4.0, BONUS, "", "OBRA"),
    ("um_roteiro_filmavel", "Um Roteiro Filmável",
     "Cabeçalhos de cena, rubricas e diálogo. Alguém poderia rodar isto.",
     EPICO, 2e-11, 6.0, BONUS, "", "OBRA"),
    ("um_tratado", "Um Tratado",
     "Quatrocentas páginas sobre um assunto que ele não conhece.",
     EPICO, 1e-11, 8.0, BONUS, "", "OBRA"),
    ("uma_obra_prima", "Uma Obra-Prima",
     "Ninguém sabe dizer por quê. Só que é.",
     LENDARIO, 1e-13, 12.0, BONUS, "", "OBRA"),
    ("um_best_seller", "Um Best-Seller",
     "Teria vendido milhões. Foi produzido por um macaco às três da manhã.",
     LENDARIO, 5e-14, 14.0, BONUS, "", "OBRA"),
    ("uma_enciclopedia_coerente", "Uma Enciclopédia Coerente",
     "Trinta volumes que concordam entre si. Nem as de verdade conseguem.",
     LENDARIO, 1e-14, 18.0, BONUS, "", "OBRA"),

    # ── TEXTO IMPROVÁVEL ─────────────────────────────────────────────────────────────
    ("a_teoria_da_relatividade", "A Teoria da Relatividade",
     "As equações certas, na ordem certa. Quarenta anos antes do previsto.",
     LENDARIO, 5e-16, 22.0, BONUS, "", "TEXTO IMPROVÁVEL"),
    ("uma_lingua_inteira", "Uma Língua Inteira",
     "Gramática, vocabulário e exceções. As exceções são o mais convincente.",
     LENDARIO, 1e-16, 28.0, BONUS, "", "TEXTO IMPROVÁVEL"),
    ("um_dicionario_completo", "Um Dicionário Completo",
     "Todas as palavras, cada uma com o significado certo ao lado.",
     LENDARIO, 5e-17, 35.0, BONUS, "", "TEXTO IMPROVÁVEL"),
    ("um_livro_que_nao_existe", "Um Livro Que Não Existe",
     "Citado em outros livros, nunca escrito. Agora existe.",
     IMPOSSIVEL, 1e-18, 40.0, BONUS, "", "TEXTO IMPROVÁVEL"),
    ("a_sua_proxima_frase", "A Sua Próxima Frase",
     "Aquela que você ia dizer agora. Está aqui, já pronta.",
     IMPOSSIVEL, 1e-19, 45.0, BONUS, "", "TEXTO IMPROVÁVEL"),

    # ── TEXTO IMPOSSÍVEL ─────────────────────────────────────────────────────────────
    ("uma_biblioteca_coerente", "Uma Biblioteca Coerente",
     "Mil livros que se referenciam sem nenhum erro de citação.",
     IMPOSSIVEL, 1e-22, 60.0, BONUS, "", "TEXTO IMPOSSÍVEL"),
    ("o_texto_perfeito", "O Texto Perfeito",
     "Nenhuma palavra sobra e nenhuma falta. Ninguém consegue lê-lo duas vezes igual.",
     IMPOSSIVEL, 1e-26, 80.0, BONUS, "", "TEXTO IMPOSSÍVEL"),
    ("uma_prova_matematica", "Uma Prova Matemática",
     "De um teorema que ninguém tinha enunciado. A prova está correta.",
     IMPOSSIVEL, 1e-28, 120.0, BONUS, "", "TEXTO IMPOSSÍVEL"),

    # ── PARADOXO ─────────────────────────────────────────────────────────────────────
    ("sua_propria_descoberta", "Sua Própria Descoberta",
     "O macaco acabou de escrever uma descrição desta descoberta.",
     PARADOXAL, 1e-33, 75.0, BONUS, "", "PARADOXO"),
    ("este_paragrafo", "Este Parágrafo",
     "Não o parecido. Este, com esta vírgula, nesta posição.",
     PARADOXAL, 1e-39, 150.0, BONUS, "", "PARADOXO"),
    ("just_keep_typing", "JUST KEEP TYPING",
     "Ele escreveu o nome do jogo.",
     PARADOXAL, 1e-48, 500.0, BONUS, "", "PARADOXO"),
]

# ⚠️ OS VERSOS DO POEMA SAO ESCRITOS A MAO. O jogo nunca gera texto (GDD §10): ele SORTEIA
# entre linhas curadas. Doze linhas, quatro mostradas de cada vez -- e a semente vem da
# partida, entao o poema de um jogador e sempre o mesmo poema.
VERSOS_DO_POEMA = [
    "a tecla desce e o mundo não repara",
    "há uma folha esperando desde ontem",
    "o acaso tem paciência de sobra",
    "alguém datilografa do outro lado",
    "entre duas letras cabe um século",
    "a máquina range como quem lembra",
    "nada disto foi dito de propósito",
    "a página aceita qualquer coisa",
    "o dedo não sabe o que a linha soube",
    "tudo que é possível já está escrito",
    "a noite é longa e o papel é branco",
    "ninguém prometeu que faria sentido",
]

MODELO = '''[gd_resource type="Resource" script_class="DadosDescoberta" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/progressao/dados_descoberta.gd" id="1_dados_descoberta"]

[resource]
script = ExtResource("1_dados_descoberta")
id = "{id}"
nome = "{nome}"
texto = "{texto}"
categoria = {categoria}
chance_base = {chance}
bonus = {bonus}
papel = {papel}
'''


def escrever(pasta):
    escritos = 0
    for (idd, nome, texto, categoria, chance, bonus, papel, curiosidade, _degrau) in NOVAS:
        corpo = MODELO.format(
            id=idd, nome=nome, texto=texto, categoria=categoria,
            chance=repr(chance), bonus=repr(bonus), papel=papel,
        )
        if curiosidade:
            corpo += 'curiosidade = "%s"\n' % curiosidade
        if idd == "um_haicai":
            pass
        io.open(os.path.join(pasta, idd + ".tres"), "w",
                encoding="utf-8", newline="\n").write(corpo)
        escritos += 1
    return escritos


def acrescentar_versos(pasta):
    """Os versos vao no POEMA, que ja existe desde a v0.2."""
    caminho = os.path.join(pasta, "um_poema.tres")
    s = io.open(caminho, encoding="utf-8").read()
    if "versos = " in s:
        s = s[:s.index("versos = ")].rstrip("\n") + "\n"
    linhas = ", ".join('"%s"' % v for v in VERSOS_DO_POEMA)
    s = s.rstrip("\n") + "\nversos = PackedStringArray(%s)\n" % linhas
    io.open(caminho, "w", encoding="utf-8", newline="\n").write(s)


# ── A ida para o i18n ──────────────────────────────────────────────────────────────────

def linhas_de_csv():
    """Os pares (chave, linha) de i18n/textos.csv para tudo que esta tabela criou.

    ⚠️ FALHA ALTO SE FALTAR TRADUCAO. Emitir a linha com o portugues nas tres colunas
    passaria no portao de texto -- a chave existe! -- e sairia em portugues no jogo em
    ingles, que e exatamente a familia de bug que aquele portao existe para pegar.
    """
    from descobertas_em_ingles import EM_INGLES, VERSOS_EM_INGLES

    chaves = []
    for (_id, nome, texto, _c, _ch, _b, _p, curiosidade, _d) in NOVAS:
        chaves.extend([nome, texto])
        if curiosidade:
            chaves.append(curiosidade)
    chaves.extend(VERSOS_DO_POEMA)

    faltando = [c for c in chaves if c not in EM_INGLES and c not in VERSOS_EM_INGLES]
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
        em_ingles = EM_INGLES.get(chave) or VERSOS_EM_INGLES[chave]
        saida.append((chave, "%s,%s,%s" % (cerca(chave), cerca(chave), cerca(em_ingles))))
    return saida


def acrescentar_ao_csv(caminho):
    """So acrescenta o que ainda nao esta la -- rodar duas vezes nao duplica linha.

    ⚠️ A DEDUPLICACAO E PELA CHAVE, E NUNCA POR `split(",")[0]`. A primeira versao cortava
    a linha na primeira virgula para achar a chave -- e campo com virgula vai entre aspas,
    entao "Comeco, meio e fim. Nessa ordem, inclusive." virou a chave `"Comeco` e casou com
    a linha JA EXISTENTE `"Comeco, meio e fim. O fim e sobre bananas."`. A frase nova foi
    descartada como duplicata, e quem acusou foi o portao de texto: texto sem linha no CSV.
    """
    quebra = chr(10)
    s = io.open(caminho, encoding="utf-8").read()
    if not s.endswith(quebra):
        s += quebra
    novas = 0
    for chave, linha in linhas_de_csv():
        nua = quebra + chave + ","
        entre_aspas = quebra + '"' + chave + '",'
        if nua in s or entre_aspas in s:
            continue
        s += linha + quebra
        novas += 1
    io.open(caminho, "w", encoding="utf-8", newline=quebra).write(s)
    return novas


if __name__ == "__main__":
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    pasta = os.path.normpath(os.path.join(raiz, "data", "descobertas"))
    quantas = escrever(pasta)
    acrescentar_versos(pasta)
    print("%d descobertas escritas em %s" % (quantas, pasta))
    print("%d versos no poema" % len(VERSOS_DO_POEMA))
    csv = os.path.normpath(os.path.join(raiz, "i18n", "textos.csv"))
    print("%d linhas novas no CSV" % acrescentar_ao_csv(csv))
