# 0008 — A campanha da primeira hora

**Contexto:** a decisão 0007 mediu o problema e parou ali, de propósito: *"redesenhar a
curva de custo do jogo inteiro é decisão do autor sobre o produto, não uma consequência
mecânica de uma medição"*. Este documento registra **a decisão que o autor tomou**, e é
por isso que ela existe num arquivo separado.

## A leitura

> **A v0.6 não revelou que o jogo precisa de mais conteúdo; revelou que ele precisa
> aprender a distribuir o conteúdo que já tem.**

91 marcos, 62 descobertas e 44 upgrades já são material suficiente para uma primeira hora.
O problema não é falta de conteúdo — é **distribuição**.

E acrescentar mais pioraria:

```
conteúdo atual        ████ 4 min
+ 40 upgrades         █████ 5 min
+ 100 marcos          ██████ 6 min
```

**A economia precisa passar a controlar o ritmo do conteúdo, e não apenas crescer.**

## As cinco decisões

### 1. Congelamento de conteúdo

Até a curva estar resolvida, **não** entram: upgrade novo, marco novo, moeda nova, era nova,
multiplicador permanente novo, nem mexida em Fragmentos.

### 2. A régua vem antes do número

Nenhum número muda antes de a régua executar **eventos** e **automação**, e antes de o
comportamento do jogador ser declarado em vez de implícito.

⚠️ **A lição da v0.6 vira regra:** toda fonte de aleatoriedade que um instrumento econômico
toca tem de ser semeada, e a mesma seed tem de dar o mesmo byte. Uma diferença aparente de
+37 s era ruído, e uma conclusão teve de ser retratada por causa disso.

### 3. Três jogadores simulados, e não um

Ativo, normal e passivo. A pergunta que isso responde — e que nenhuma medição de hoje
responde — é: **a campanha funciona apenas se a pessoa jogar de uma maneira específica?**

O perfil **normal** é o que manda no critério. O **passivo** é quem não pode digitar rápido:
se a campanha só fecha para o ativo, a issue #54 foi violada.

### 4. A experiência desejada, escrita antes dos números

| faixa | o que acontece |
|---|---|
| 0–5 min | descoberta extremamente rápida |
| 5–15 min | primeiras decisões reais |
| 15–30 min | construção da máquina econômica |
| 30–45 min | automação começa a assumir tarefas |
| 45–60 min | preparação clara para o primeiro Teorema |

**Primeiro prestígio entre 35 e 50 minutos** numa primeira partida normal. Não porque exista
um número matematicamente correto, mas porque é o espaço necessário para o jogador conhecer
o macaco, aprender a produção, ver o Panorama, entender Descobertas, comprar famílias de
upgrades, experimentar automação, **perceber a desaceleração** e **desejar o prestígio**.

Hoje ele compensa aos **3:42**, o que impede a primeira run de ter arco.

### 5. Redistribuir antes de alterar fórmula

A densidade pode diminuir progressivamente, mas **nunca desaparecer**:

```
hoje              alvo
0 ── 4 min  ████  0–10   ███████████
4 ─ 60 min  ░     10–20  █████████
                  20–30  ████████
                  30–40  ███████
                  40–50  ██████
                  50–60  █████
```

⚠️ **E uma família de upgrades é uma história.** Hoje *O Conhecimento* inteiro atravessa em
18 segundos — o jogador não chega a ler nenhuma das quatro.

⚠️ **Descoberta é a exceção**: ela deve ser menos previsível que upgrade e marco. Janelas por
categoria, e não uma a cada X minutos. *A régua mede uma seed fixa; o jogador tem de sentir
variabilidade* — a seed é do instrumento, a variância é do sistema.

## A métrica que muda

A pergunta deixa de ser:

> *"quanto tempo até prestigiar?"*

e passa a ser:

> **"existe alguma coisa interessante acontecendo durante todo o caminho até prestigiar?"**

## Uma régua, e não duas — a única contraproposta

A proposta original previa manter `medir_ritmo_v1` como instrumento histórico ao lado de uma
`v2`. **Recusada**, e por regras do próprio projeto:

- **duas fontes para a mesma verdade divergem**, e a que vale costuma ser a errada
- **código morto que afirma uma regra errada é pior que código morto**: a v1 voltaria a
  rodar no dia em que alguém a chamasse, medindo uma campanha que já não existe
- ninguém rodaria a v1 — e o que ninguém roda apodrece sem avisar

O precedente do projeto é outro e já está em uso: na issue #42 o instrumento de
`medir_quadro` mudou, e o que se fez foi **declarar alto que as tabelas antigas não se
comparam**. O histórico mora no `TUNING.md`, que é onde ele não pode ser executado por
engano.

## O que continua fora, por ordem e não por esquecimento

Música, midgame, conteúdo cósmico e o endgame de Fragmentos. **Uma variável por vez:** não
se mistura trilha nova, economia nova e campanha nova no mesmo ciclo.

`Musica` e `Ambiente` continuam em `Audio.SEM_FONTE_AINDA`; `animacoes_de_numero` e `shake`
continuam em `Config.SEM_SISTEMA_AINDA`.

## As duas coisas que só o autor faz

1. **O playtest** (issue #64). O de **antes** é o mais valioso: depois do rebalanceamento,
   ele não existe mais. E ele acha a classe de problema que nem régua nem captura alcançam —
   *quando o jogador parou de ler os textos* não é medível.
2. **A revisão de voz.** ~70 peças de texto autoral sem leitura do autor. A voz que saiu é
   seca, inteligente, levemente absurda, autodepreciativa, sem tentar fazer piada em toda
   frase. **Antes de escrever mais 100 textos, revisar 15–20 representativos.**
