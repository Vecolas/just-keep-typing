# 0007 — A primeira hora mede quatro minutos

**Contexto:** issue #56. A versão v0.6 se chama *"A primeira hora"*, e até esta issue
ninguém tinha medido a primeira hora. A `medir_ritmo` foi instrumentada para reportar
marco, upgrade, descoberta e primeiro Teorema na mesma corrida — e o que ela devolveu
muda o plano da versão.

## O que a régua mediu

Jogador simulado, compra ótima ingênua, com combo ligado:

| até | marcos | upgrades | descobertas (1ª de cada categoria) |
|---|---|---|---|
| **00:10:00** | **76** | **44** | **5** |
| 00:20:00 | 0 | 0 | 0 |
| 00:30:00 | 0 | 0 | 0 |
| 00:40:00 | 1 | 0 | 0 |
| 00:50:00 | 0 | 0 | 0 |
| 01:00:00 | 0 | 0 | 0 |

A primeira hora é **quatro minutos seguidos de cinquenta e seis minutos de silêncio.**

E dentro dos quatro minutos, o aperto é pior do que a linha de dez minutos deixa ver.
**Trinta e cinco dos quarenta e quatro upgrades são comprados nos últimos vinte e dois
segundos** — entre 00:03:21 e 00:03:43:

| família | na 1ª hora | do primeiro ao último |
|---|---|---|
| O Macaco | 13 | 00:00:02 → 00:03:42 |
| A Máquina | 12 | 00:01:06 → 00:03:42 |
| A Organização | 10 | 00:02:32 → 00:03:43 |
| O Conhecimento | 9 | **00:03:25 → 00:03:43** |

A família **O Conhecimento** inteira — nove upgrades, a escada que deveria contar a
transição de "macaco batendo em teclas" para "o acaso sendo modelado" — **é comprada em
dezoito segundos.** A issue #53 pediu quatro famílias que contam uma história cada; o
jogador não chega a ler nenhuma.

E o primeiro Teorema:

| | com combo | sem combo |
|---|---|---|
| disponível | 00:03:38 | 00:04:05 |
| vale a pena (dobra a produção) | **00:03:42** | 00:04:08 |

A issue #56 pedia que o primeiro prestígio caísse *"dentro da primeira hora ou logo
depois — não em cinco horas"*. Ele cai em **três minutos e quarenta e dois segundos**, o
que é o erro oposto e igualmente grande: o prestígio é a virada da campanha, e ela
acontece antes de o jogador ter entendido o que está comprando.

## A decisão

**Isto não está bom, e não se conserta com tuning pontual.**

⚠️ **E não é defeito das issues #52 e #53.** Antes delas os mesmos 73 marcos caíam em onze
minutos — a mesma doença, com prazo mais longo. As vinte e quatro entradas novas não
criaram o problema: elas encurtaram o prazo o suficiente para ninguém conseguir mais olhar
para o outro lado.

**O mecanismo:** a produção cresce por multiplicadores que **compõem** (macacos × velocidade
× máquina × sala × global), enquanto os custos e os requisitos crescem por escadas
**escolhidas à mão**. Duas curvas de naturezas diferentes só se cruzam uma vez — e depois
do cruzamento a produção atravessa todo limite restante em segundos. Espaçar marco não
resolve, e já estava escrito no `TUNING.md` desde a primeira sessão de tuning:

> *"A distância entre eles em magnitude está certa; o que corre demais é a produção."*

Agora há número em cima disso.

**A direção**, que é a issue #58 e não esta:

1. O custo de upgrade tem de crescer em função da **mesma composição** que a produção usa,
   e não de uma escada digitada. Curva derivada contra curva derivada se cruzam sempre
   no mesmo lugar relativo.
2. O `limite_inicial` do prestígio (hoje `1e6`) é calibrado para uma economia que já não
   existe: ele é cruzado em três minutos.
3. A meta a perseguir é de **ritmo**, e não de número: um acontecimento a cada poucos
   minutos ao longo de sessenta, e não setenta e seis em quatro.

## O que esta issue entrega, e o que ela deliberadamente não entrega

**Entrega:** a régua instrumentada, a tabela, a comparação com e sem combo, e este
documento.

**Não entrega:** o rebalanceamento. A issue #56 diz, com todas as letras, que **régua não
aprova nem reprova — ela mede**, e que *"o que esta issue entrega é a tabela, não um
veredito"*. Redesenhar a curva de custo do jogo inteiro é decisão do autor sobre o produto,
não uma consequência mecânica de uma medição. Fazê-la em silêncio, escondida no commit de
uma régua, seria exatamente o tipo de mudança grande entrando por um caminho que ninguém
olha.

## O que a régua NÃO prova

- **O jogador simulado não é o jogador real.** Ele compra no instante exato em que o saldo
  fecha. Os quatro minutos são o **piso**; um humano é mais lento. O que a régua prova é a
  RAZÃO entre duas medições, e a densidade relativa entre as faixas.
- **Nada aqui mede diversão.** "Setenta e seis marcos em quatro minutos" é um fato sobre a
  curva; se isso é bom ou ruim é leitura, e a leitura está acima, assinada.
- **O combo (issue #54) não é a causa e não é a cura**: com e sem, ele adianta o primeiro
  prestígio em 27 segundos e não muda nada depois.

⚠️ **E esta medição só vale porque a régua foi consertada no meio do caminho.** Ela nunca
semeava o sorteio de descobertas, e descoberta dá bônus de produção: duas corridas do mesmo
commit diferiam em 35 segundos. Ver `TUNING.md`, *"A régua não era determinística"* — uma
conclusão da issue #54 foi retratada por causa disso.
