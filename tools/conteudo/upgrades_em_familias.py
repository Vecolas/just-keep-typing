# -*- coding: utf-8 -*-
"""As quatro familias tematicas da issue #53.

⚠️ OS VINTE IDS QUE JA EXISTEM NAO MUDAM. `upgrades_comprados` no save e uma lista de
ids: renomear um id apaga a compra de quem ja jogou, em silencio e sem erro nenhum. Este
script ACRESCENTA uma coluna aos vinte e cria os novos -- nunca reescreve um id.

⚠️ E AS DESCRICOES SAO O PRODUTO. "+25% de velocidade" nao e descricao; o jogador ja ve o
numero no botao. A descricao existe para dizer POR QUE a producao aumentou, que e a unica
coisa que o numero nao conta.
"""

# --- os efeitos e as familias, como o enum os serializa ---------------------------------
VELOCIDADE, GLOBAL, INTERRUPTOR, CAPACIDADE = 0, 1, 2, 3
MACACO, MAQUINA, ORGANIZACAO, CONHECIMENTO = 1, 2, 3, 4

# ⚠️ A FAMILIA SAI DA EXPLICACAO, e nao do efeito. "Dedos Probabilisticos" mexe na
# velocidade do macaco, mas o que ele explica e que as sequencias provaveis passaram a
# sair mais -- isso e Conhecimento. Agrupar pelo efeito daria quatro familias que o
# jogador ja ve no numero do botao, e nenhuma que ele nao ve.
FAMILIA_DOS_EXISTENTES = {
    "instinto_digitador": MACACO,
    "dedos_mais_ageis": MACACO,
    "duas_maos": MACACO,
    "treinamento_questionavel": MACACO,
    "cafe_para_o_macaco": MACACO,
    "metodo_de_datilografia": MACACO,
    "ergonomia_simiesca": MACACO,

    "maquina_lubrificada": MAQUINA,
    "teclas_mais_leves": MAQUINA,
    "papel_continuo": MAQUINA,
    "revisor_automatico": MAQUINA,

    "segunda_mesa": ORGANIZACAO,
    "turno_da_noite": ORGANIZACAO,
    "mesas_empilhadas": ORGANIZACAO,
    "arquivo_vertical": ORGANIZACAO,
    "espaco_nao_euclidiano": ORGANIZACAO,

    "estatistica_aplicada": CONHECIMENTO,
    "teoria_da_informacao": CONHECIMENTO,
    "dedos_probabilisticos": CONHECIMENTO,
    "o_macaco_percebe": CONHECIMENTO,
}

# ⚠️ DOIS VALORES MUDAM, E OS DOIS ERAM DEFEITO.
#
# Dentro de (Macaco, velocidade), ordenado por custo, o multiplicador CAIA duas vezes:
#
#   dedos_mais_ageis     100      x1,5
#   cafe_para_o_macaco   1,6 mi   x1,4   <- custa 16 mil vezes mais e multiplica MENOS
#   metodo_de_datilog.   10 bi    x2,0
#   ergonomia_simiesca   500 bi   x1,8   <- idem, 50 vezes mais caro
#
# Isso nao aparecia em lugar nenhum: o jogo nao quebra, a suite ficava verde e o jogador
# so descobriria depois de pagar. Quem acusou foi a regua nova da issue #53, e ela nasceu
# junto do sistema que mede -- e nao depois.
AJUSTES_DE_VALOR = {
    "cafe_para_o_macaco": 1.7,
    "ergonomia_simiesca": 2.2,
}

# --- os novos ---------------------------------------------------------------------------
# (id, nome, descricao, custo, efeito, valor, requisito, familia)
NOVOS = [
    # -- O MACACO ------------------------------------------------------------------------
    ("polegar_oponivel", "Polegar Oponível",
     "O polegar já estava ali desde o começo. Ninguém tinha pensado em usá-lo para nada.",
     40.0, VELOCIDADE, 1.3, 20.0, MACACO),
    ("banquinho_mais_alto", "Banquinho Mais Alto",
     "Os cotovelos passam a formar um ângulo reto com a mesa. Ninguém esperava que isso importasse.",
     1_600.0, VELOCIDADE, 1.5, 700.0, MACACO),
    ("memoria_muscular", "Memória Muscular",
     "Os dedos repetem sozinhos o que já repetiram antes. O macaco não aprendeu nada; as mãos aprenderam.",
     12_000.0, VELOCIDADE, 1.6, 4_000.0, MACACO),
    ("postura_de_trabalho", "Postura de Trabalho",
     "Costas retas cansam menos, e o que cansa menos dura mais. É a coisa menos engraçada que aconteceu aqui.",
     4.0e7, VELOCIDADE, 1.8, 9.0e6, MACACO),
    ("os_dois_pes", "Os Dois Pés",
     "Depois das duas mãos, alguém perguntou por que parar nas mãos. Funciona. Ninguém quis investigar.",
     2.2e8, GLOBAL, 2.2, 6.0e7, MACACO),
    ("equipe_de_digitacao", "Equipe de Digitação",
     "Vários macacos na mesma folha, sem combinar nada. O resultado sai antes de qualquer um deles terminar.",
     3.3e12, GLOBAL, 2.6, 9.0e11, MACACO),

    # -- A MÁQUINA -----------------------------------------------------------------------
    ("fita_nova", "Fita Nova",
     "A tinta tinha acabado fazia semanas. Ninguém reparou, porque ninguém estava lendo.",
     600.0, VELOCIDADE, 1.4, 250.0, MAQUINA),
    ("luz_da_mesa", "Luz da Mesa",
     "O macaco vinha datilografando no escuro. Não fazia a menor diferença — e agora faz.",
     900.0, GLOBAL, 1.4, 400.0, MAQUINA),
    ("martelos_alinhados", "Martelos Alinhados",
     "Cada tecla passa a bater onde deveria. Antes, algumas batiam onde desse.",
     4_200.0, VELOCIDADE, 1.4, 1_800.0, MAQUINA),
    ("carbono_entre_as_folhas", "Carbono Entre as Folhas",
     "Uma tecla, duas páginas. A segunda sai mais fraca, e ninguém aqui confere qualidade.",
     45_000.0, GLOBAL, 1.6, 15_000.0, MAQUINA),
    ("molas_reforcadas", "Molas Reforçadas",
     "A tecla sobe antes de o dedo pensar em levantar. A máquina passou a esperar menos pelo macaco.",
     210_000.0, VELOCIDADE, 1.5, 70_000.0, MAQUINA),
    ("teclas_industriais", "Teclas Industriais",
     "Feitas para uma fábrica que datilografava vinte horas por dia. Aqui vão trabalhar bem mais que isso.",
     1.4e8, VELOCIDADE, 1.8, 4.0e7, MAQUINA),
    ("motor_eletrico", "Motor Elétrico",
     "O dedo deixa de fornecer a força e passa apenas a escolher a tecla. A escolha continua aleatória.",
     9.0e9, VELOCIDADE, 2.0, 2.5e9, MAQUINA),
    ("sistema_automatico", "Sistema Automático",
     "A máquina troca a folha, alinha a margem e recomeça. Ninguém precisa estar na sala para isso.",
     2.0e14, GLOBAL, 3.0, 6.0e13, MAQUINA),

    # -- A ORGANIZAÇÃO -------------------------------------------------------------------
    ("mesa_maior", "Mesa Maior",
     "Cabe mais macaco por metro quadrado. É exatamente tão desconfortável quanto parece.",
     2_500.0, CAPACIDADE, 1.5, 1_000.0, ORGANIZACAO),
    ("pausa_para_o_almoco", "Pausa para o Almoço",
     "Vinte minutos parados, e a produção do dia inteiro sobe. A administração não sabe explicar por quê.",
     6.0e6, GLOBAL, 1.6, 1.8e6, ORGANIZACAO),
    ("supervisor", "Supervisor",
     "Ele não datilografa. Ele anda entre as mesas, e as mesas por onde ele passa produzem mais.",
     2.0e10, GLOBAL, 2.2, 6.0e9, ORGANIZACAO),
    ("departamento_de_digitacao", "Departamento de Digitação",
     "Agora existe um organograma. Metade das caixas está em branco e mesmo assim funciona.",
     8.0e13, GLOBAL, 2.8, 2.4e13, ORGANIZACAO),
    ("linha_de_producao", "Linha de Produção",
     "Cada macaco datilografa uma letra e passa a folha adiante. A folha nunca para de andar.",
     5.0e17, GLOBAL, 3.5, 1.5e17, ORGANIZACAO),

    # -- O CONHECIMENTO ------------------------------------------------------------------
    ("um_dicionario", "Dicionário de Bolso",
     "Aberto na mesa, numa página qualquer. Nenhum macaco consultou — e a taxa de palavras subiu.",
     8_000.0, GLOBAL, 1.5, 2_500.0, CONHECIMENTO),
    ("alfabeto_reordenado", "Alfabeto Reordenado",
     "As letras mais prováveis ficam sob os dedos. O acaso continua acaso, só que mais bem servido.",
     55_000.0, VELOCIDADE, 1.5, 18_000.0, CONHECIMENTO),
    ("tabela_de_frequencia", "Tabela de Frequência",
     "Alguém contou quantas vezes cada letra aparece. Só de estar pregada na parede, ajuda.",
     1.1e6, GLOBAL, 1.8, 350_000.0, CONHECIMENTO),
    ("linguistica_estatistica", "Linguística Estatística",
     "A língua vira uma tabela de probabilidades. Fica menos bonita e muito mais produtiva.",
     9.0e8, GLOBAL, 2.0, 2.6e8, CONHECIMENTO),
    ("modelagem_probabilistica", "Modelagem Probabilística",
     "O jogo passa a prever o que sairia — e o que sairia sai mais rápido por ter sido previsto.",
     5.0e11, GLOBAL, 2.3, 1.4e11, CONHECIMENTO),
]

# ⚠️ A TRADUCAO E DO TEXTO, e nao das palavras. "Treinamento Questionavel" ja existia; os
# novos seguem a mesma regra que as descobertas da issue #52 -- quando a piada nao
# sobrevive ao ingles, a versao em ingles e OUTRA piada sobre a mesma coisa.
EM_INGLES = {
    "Polegar Oponível": "Opposable Thumb",
    "O polegar já estava ali desde o começo. Ninguém tinha pensado em usá-lo para nada.":
        "The thumb had been there all along. Nobody had thought to use it for anything.",
    "Banquinho Mais Alto": "A Taller Stool",
    "Os cotovelos passam a formar um ângulo reto com a mesa. Ninguém esperava que isso importasse.":
        "The elbows now meet the desk at a right angle. Nobody expected that to matter.",
    "Memória Muscular": "Muscle Memory",
    "Os dedos repetem sozinhos o que já repetiram antes. O macaco não aprendeu nada; as mãos aprenderam.":
        "The fingers repeat what they have already repeated. The monkey learned nothing; the hands did.",
    "Postura de Trabalho": "Working Posture",
    "Costas retas cansam menos, e o que cansa menos dura mais. É a coisa menos engraçada que aconteceu aqui.":
        "A straight back tires less, and what tires less lasts longer. It is the least funny thing that has happened here.",
    "Os Dois Pés": "Both Feet",
    "Depois das duas mãos, alguém perguntou por que parar nas mãos. Funciona. Ninguém quis investigar.":
        "After both hands, someone asked why stop at hands. It works. Nobody wanted to look into it.",
    "Equipe de Digitação": "Typing Team",
    "Vários macacos na mesma folha, sem combinar nada. O resultado sai antes de qualquer um deles terminar.":
        "Several monkeys on one sheet, agreeing on nothing. The result arrives before any of them finishes.",

    "Fita Nova": "A Fresh Ribbon",
    "A tinta tinha acabado fazia semanas. Ninguém reparou, porque ninguém estava lendo.":
        "The ink had run out weeks ago. Nobody noticed, because nobody was reading.",
    "Luz da Mesa": "A Desk Lamp",
    "O macaco vinha datilografando no escuro. Não fazia a menor diferença — e agora faz.":
        "The monkey had been typing in the dark. It made no difference at all — and now it does.",
    "Martelos Alinhados": "Aligned Typebars",
    "Cada tecla passa a bater onde deveria. Antes, algumas batiam onde desse.":
        "Every key now strikes where it should. Before, some struck wherever they could.",
    "Carbono Entre as Folhas": "Carbon Between the Sheets",
    "Uma tecla, duas páginas. A segunda sai mais fraca, e ninguém aqui confere qualidade.":
        "One key, two pages. The second comes out fainter, and nobody here checks quality.",
    "Molas Reforçadas": "Stronger Springs",
    "A tecla sobe antes de o dedo pensar em levantar. A máquina passou a esperar menos pelo macaco.":
        "The key rises before the finger thinks of lifting. The machine now waits less on the monkey.",
    "Teclas Industriais": "Industrial Keys",
    "Feitas para uma fábrica que datilografava vinte horas por dia. Aqui vão trabalhar bem mais que isso.":
        "Built for a factory that typed twenty hours a day. Here they will work rather longer than that.",
    "Motor Elétrico": "Electric Motor",
    "O dedo deixa de fornecer a força e passa apenas a escolher a tecla. A escolha continua aleatória.":
        "The finger stops supplying the force and merely picks the key. The picking is still random.",
    "Sistema Automático": "Automatic System",
    "A máquina troca a folha, alinha a margem e recomeça. Ninguém precisa estar na sala para isso.":
        "The machine changes the sheet, sets the margin and begins again. Nobody need be in the room.",

    "Mesa Maior": "A Bigger Desk",
    "Cabe mais macaco por metro quadrado. É exatamente tão desconfortável quanto parece.":
        "More monkey fits per square metre. It is exactly as uncomfortable as it sounds.",
    "Pausa para o Almoço": "Lunch Break",
    "Vinte minutos parados, e a produção do dia inteiro sobe. A administração não sabe explicar por quê.":
        "Twenty minutes of nothing, and the whole day's output rises. Management cannot explain it.",
    "Supervisor": "Supervisor",
    "Ele não datilografa. Ele anda entre as mesas, e as mesas por onde ele passa produzem mais.":
        "He does not type. He walks between the desks, and the desks he passes produce more.",
    "Departamento de Digitação": "Typing Department",
    "Agora existe um organograma. Metade das caixas está em branco e mesmo assim funciona.":
        "There is an org chart now. Half the boxes are empty and it works anyway.",
    "Linha de Produção": "Production Line",
    "Cada macaco datilografa uma letra e passa a folha adiante. A folha nunca para de andar.":
        "Each monkey types one letter and passes the sheet along. The sheet never stops moving.",

    "Dicionário de Bolso": "A Pocket Dictionary",
    "Aberto na mesa, numa página qualquer. Nenhum macaco consultou — e a taxa de palavras subiu.":
        "Open on the desk at no page in particular. No monkey consulted it — and the word rate went up.",
    "Alfabeto Reordenado": "Reordered Alphabet",
    "As letras mais prováveis ficam sob os dedos. O acaso continua acaso, só que mais bem servido.":
        "The likelier letters sit under the fingers. Chance is still chance, just better served.",
    "Tabela de Frequência": "Frequency Table",
    "Alguém contou quantas vezes cada letra aparece. Só de estar pregada na parede, ajuda.":
        "Someone counted how often each letter appears. Merely pinned to the wall, it helps.",
    "Linguística Estatística": "Statistical Linguistics",
    "A língua vira uma tabela de probabilidades. Fica menos bonita e muito mais produtiva.":
        "Language becomes a table of probabilities. Less beautiful, far more productive.",
    "Modelagem Probabilística": "Probabilistic Modelling",
    "O jogo passa a prever o que sairia — e o que sairia sai mais rápido por ter sido previsto.":
        "The game starts predicting what would come out — and what would come out arrives faster for having been predicted.",

    # os nomes das familias, que a loja mostra como cabecalho
    "O Macaco": "The Monkey",
    "A Máquina": "The Machine",
    "A Organização": "The Organisation",
    "O Conhecimento": "The Knowledge",
    "Sem família": "No family",
}
