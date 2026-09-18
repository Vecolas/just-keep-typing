# -*- coding: utf-8 -*-
"""A traducao das descobertas da issue #52.

⚠️ A PIADA TEM QUE SOBREVIVER AO INGLES, e em varias delas a traducao literal a mata.
"Trocadilho" vira "pun" e a graca continua; "Uma Vogal Sozinha" ao pe da letra perde a
preguica, que e o assunto da frase. Onde precisou, a versao em ingles e OUTRA piada sobre a
mesma coisa -- que e o que traduzir humor quer dizer.

Dois casos merecem nota:

    "EU" vira "I", e a frase muda de "duas letras" para "one letter". O numero esta na
    piada, entao ele acompanha a lingua em vez de ficar errado em ingles.

    "OLA" vira "HELLO", e nao "HI": a descoberta e sobre parecer intencional, e "hello" e
    a saudacao que soa deliberada.
"""

EM_INGLES = {
    # LETRA
    "Uma Letra": "A Letter",
    "A primeira coisa que o macaco produziu de propósito nenhum.":
        "The first thing the monkey produced on purpose of nothing at all.",
    "A Mesma Letra Duas Vezes": "The Same Letter Twice",
    "Duas vezes seguidas. O macaco não tentou, e é isso que impressiona.":
        "Twice in a row. The monkey did not try, and that is the impressive part.",

    # SÍLABA
    "Uma Sílaba": "A Syllable",
    "Consoante e vogal, nessa ordem. Já é mais do que parece.":
        "Consonant then vowel, in that order. That is more than it sounds.",
    "Uma Sílaba Pronunciável": "A Pronounceable Syllable",
    "Dá para dizer em voz alta sem treinar antes.":
        "You can say it out loud without practising first.",
    "Uma sílaba do português cabe em duas a quatro letras. Com vinte e seis teclas, a chance de acertar uma por acaso é bem maior do que a de acertar uma palavra.":
        "A syllable fits in two to four letters. With twenty-six keys, hitting one by accident is far likelier than hitting a whole word.",
    "Uma Vogal Sozinha": "A Vowel On Its Own",
    "Uma letra que já é uma palavra inteira. Preguiça premiada.":
        "One letter that is already a whole word. Laziness, rewarded.",

    # PALAVRA
    "Uma Palavra de Três Letras": "A Three-Letter Word",
    "Curta, comum e completamente acidental.":
        "Short, common and completely accidental.",
    "Uma Palavra Longa": "A Long Word",
    "Doze letras na ordem certa. Ninguém estava olhando na hora.":
        "Twelve letters in the right order. Nobody was watching at the time.",
    "EU": "I",
    "Duas letras. Filosoficamente inconvenientes.":
        "One letter. Philosophically inconvenient.",
    "É o pronome mais curto do português e o mais difícil de ignorar. O macaco não quis dizer nada — e é exatamente por isso que incomoda.":
        "The shortest pronoun there is, and the hardest to ignore. The monkey meant nothing by it — which is exactly why it stings.",
    "OLÁ": "HELLO",
    "Por um instante, pareceu intencional.": "For a moment, it looked deliberate.",
    "BANANA": "BANANA",
    "Contra todas as probabilidades, ele sabe exatamente o que quer.":
        "Against all odds, he knows exactly what he wants.",

    # EXPRESSÃO
    "Uma Pergunta": "A Question",
    "Termina em interrogação e tudo. Ninguém respondeu.":
        "Question mark and everything. Nobody answered.",
    "Uma Negação": "A Denial",
    "O macaco discordou de alguma coisa. Não se sabe de quê.":
        "The monkey disagreed with something. Nobody knows what.",

    # FRASE
    "Uma Frase Gramatical": "A Grammatical Sentence",
    "Estatisticamente improvável. Linguisticamente decepcionante.":
        "Statistically improbable. Linguistically disappointing.",
    "Um Diálogo de Duas Linhas": "A Two-Line Dialogue",
    "Alguém pergunta, alguém responde. Os dois são o mesmo macaco.":
        "Someone asks, someone answers. Both of them are the same monkey.",
    "Uma Definição": "A Definition",
    "Uma palavra e o que ela significa. As duas partes saíram por acaso.":
        "A word and what it means. Both halves came out by accident.",
    "Para uma definição funcionar, duas sequências independentes precisam cair certas ao mesmo tempo. A chance de cada uma se multiplica — é por isso que ela é mais rara que uma frase do mesmo tamanho.":
        "For a definition to work, two independent sequences have to land correctly at once. Their chances multiply — which is why it is rarer than a sentence of the same length.",
    "Um Trocadilho": "A Pun",
    "Involuntário, como todo bom trocadilho.":
        "Involuntary, like every good pun.",

    # PARÁGRAFO
    "Uma Lista": "A List",
    "Três itens e um traço na frente de cada. Organizadíssima e sobre nada.":
        "Three items, each with a dash in front. Immaculately organised, about nothing.",
    "Um Provérbio": "A Proverb",
    "Soa antigo e sábio. Tem doze segundos de idade.":
        "Sounds ancient and wise. It is twelve seconds old.",

    # POEMA
    "Um Haicai": "A Haiku",
    "Cinco, sete, cinco. A métrica saiu certa e ninguém contou.":
        "Five, seven, five. The metre came out right and nobody counted.",
    "Uma Letra de Música": "A Song Lyric",
    "Com refrão. O refrão se repete porque o acaso também se repete.":
        "With a chorus. The chorus repeats because chance repeats too.",

    # CONTO
    "Uma Receita Funcional": "A Working Recipe",
    "Ingredientes, modo de preparo e um tempo de forno plausível. Não teste.":
        "Ingredients, method and a plausible oven time. Do not test it.",
    "Uma Carta de Amor": "A Love Letter",
    "Endereçada a ninguém, assinada por acaso.":
        "Addressed to nobody, signed by chance.",
    "Um Conto": "A Short Story",
    "Começo, meio e fim. Nessa ordem, inclusive.":
        "Beginning, middle and end. In that order, even.",
    "Uma Piada": "A Joke",
    "Tem graça. É a parte mais improvável de tudo isto.":
        "It is funny. That is the least probable part of all this.",

    # TEXTO COERENTE
    "Um Obituário": "An Obituary",
    "De alguém que não existiu. A família fictícia agradece.":
        "For someone who never existed. The fictional family sends its thanks.",
    "Um Verbete": "A Dictionary Entry",
    "Com etimologia. A etimologia também está errada, mas convence.":
        "With an etymology. The etymology is also wrong, but convincing.",
    "Um Capítulo Coerente": "A Coherent Chapter",
    "Onze páginas que se sustentam. A décima segunda não.":
        "Eleven pages that hold together. The twelfth does not.",
    "Um Ensaio": "An Essay",
    "Defende uma tese do começo ao fim. A tese é sobre bananas.":
        "Argues one thesis from start to finish. The thesis is about bananas.",

    # OBRA
    "Um Manifesto": "A Manifesto",
    "Convicto, urgente e completamente sem causa.":
        "Convinced, urgent and entirely without a cause.",
    "Uma Novela Curta": "A Novella",
    "Cento e vinte páginas com personagens que não se contradizem.":
        "A hundred and twenty pages with characters who never contradict themselves.",
    "Um Roteiro Filmável": "A Shootable Screenplay",
    "Cabeçalhos de cena, rubricas e diálogo. Alguém poderia rodar isto.":
        "Slug lines, action and dialogue. Someone could actually shoot this.",
    "Um Tratado": "A Treatise",
    "Quatrocentas páginas sobre um assunto que ele não conhece.":
        "Four hundred pages on a subject he knows nothing about.",
    "Uma Obra-Prima": "A Masterpiece",
    "Ninguém sabe dizer por quê. Só que é.":
        "Nobody can say why. Only that it is.",
    "Um Best-Seller": "A Best-Seller",
    "Teria vendido milhões. Foi produzido por um macaco às três da manhã.":
        "It would have sold millions. A monkey produced it at three in the morning.",
    "Uma Enciclopédia Coerente": "A Coherent Encyclopaedia",
    "Trinta volumes que concordam entre si. Nem as de verdade conseguem.":
        "Thirty volumes that agree with each other. Not even the real ones manage that.",

    # TEXTO IMPROVÁVEL
    "A Teoria da Relatividade": "The Theory of Relativity",
    "As equações certas, na ordem certa. Quarenta anos antes do previsto.":
        "The right equations in the right order. Forty years ahead of schedule.",
    "Uma Língua Inteira": "An Entire Language",
    "Gramática, vocabulário e exceções. As exceções são o mais convincente.":
        "Grammar, vocabulary and exceptions. The exceptions are the convincing part.",
    "Um Dicionário Completo": "A Complete Dictionary",
    "Todas as palavras, cada uma com o significado certo ao lado.":
        "Every word, each with the right meaning beside it.",
    "Um Livro Que Não Existe": "A Book That Does Not Exist",
    "Citado em outros livros, nunca escrito. Agora existe.":
        "Cited in other books, never written. It exists now.",
    "A Sua Próxima Frase": "Your Next Sentence",
    "Aquela que você ia dizer agora. Está aqui, já pronta.":
        "The one you were about to say. It is here already, finished.",

    # TEXTO IMPOSSÍVEL
    "Uma Biblioteca Coerente": "A Coherent Library",
    "Mil livros que se referenciam sem nenhum erro de citação.":
        "A thousand books citing each other without a single wrong reference.",
    "O Texto Perfeito": "The Perfect Text",
    "Nenhuma palavra sobra e nenhuma falta. Ninguém consegue lê-lo duas vezes igual.":
        "Not one word too many, not one missing. Nobody reads it the same way twice.",
    "Uma Prova Matemática": "A Mathematical Proof",
    "De um teorema que ninguém tinha enunciado. A prova está correta.":
        "Of a theorem nobody had stated. The proof is correct.",

    # PARADOXO
    "Sua Própria Descoberta": "This Very Discovery",
    "O macaco acabou de escrever uma descrição desta descoberta.":
        "The monkey has just produced a description of this discovery.",
    "Este Parágrafo": "This Paragraph",
    "Não o parecido. Este, com esta vírgula, nesta posição.":
        "Not one like it. This one, with this comma, in this position.",
    "JUST KEEP TYPING": "JUST KEEP TYPING",
    "Ele escreveu o nome do jogo.": "He wrote the name of the game.",
}

## ⚠️ OS VERSOS SAO TRADUZIDOS COMO POESIA, e nao como frase. Metrica e som importam mais
## que literalidade: "a maquina range como quem lembra" vira "the machine creaks like
## something remembering" porque o ritmo sobrevive, e nao porque as palavras casam.
VERSOS_EM_INGLES = {
    "a tecla desce e o mundo não repara": "the key goes down and the world says nothing",
    "há uma folha esperando desde ontem": "a sheet has been waiting since yesterday",
    "o acaso tem paciência de sobra": "chance has patience to spare",
    "alguém datilografa do outro lado": "someone is typing on the other side",
    "entre duas letras cabe um século": "a century fits between two letters",
    "a máquina range como quem lembra": "the machine creaks like something remembering",
    "nada disto foi dito de propósito": "none of this was said on purpose",
    "a página aceita qualquer coisa": "the page will accept anything",
    "o dedo não sabe o que a linha soube": "the finger never knew what the line knew",
    "tudo que é possível já está escrito": "everything possible is already written",
    "a noite é longa e o papel é branco": "the night is long and the paper is blank",
    "ninguém prometeu que faria sentido": "nobody promised it would make sense",
}
