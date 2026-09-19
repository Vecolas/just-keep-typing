# Modelo de playtest — a interface da v0.7.2

Copie para `docs/playtests/AAAA-MM-DD-interface.md` e preencha **enquanto joga**.

> ⚠️ **Este modelo NÃO substitui o `MODELO.md`.** Aquele pergunta se o **jogo** funciona; este
> pergunta se a **interface nova** funciona. Se você só tiver trinta minutos, use o
> `MODELO.md` — ele é a #70, e é o mais antigo dos dois débitos.

A reforma pôs sete coisas novas na tela sem ninguém nunca ter jogado com elas. Todas foram
decididas por argumento e medidas por régua; **nenhuma foi decidida por observação.**

---

## Antes de começar

| | |
|---|---|
| data | |
| commit | `git rev-parse --short HEAD` |
| save | ⚠️ **partida nova** |
| idioma | |
| escala de interface | |

---

## 1. A loja de upgrades

O cartão mostra quatro coisas: **nome**, **descrição**, **efeito** e **custo**. A pergunta é
se ele ajuda a decidir ou se virou parede de texto.

| | resposta |
|---|---|
| Você **leu** as descrições, ou só olhou preço? | |
| Em que minuto parou de lê-las? | |
| Quanto tempo o olho leva para achar **nome → efeito → preço**? | |
| A descrição ficou **entre** você e a informação operacional? | |
| O efeito em português (`+200 por segundo em cada macaco`) mudou alguma decisão sua? | |

⚠️ **A hierarquia hoje é:** nome em creme (corpo), custo em dourado (corpo), descrição em
marrom apagado (legenda), efeito em dourado (legenda). Se o efeito parecer fraco demais para
o peso que tem na decisão, **isso é um achado** — está proposto subi-lo para corpo, e a
mudança está esperando esta sessão.

---

## 2. `PRÓXIMAS MELHORIAS`

⚠️ **Primeiro, o achado que já existe:** em 1920×1080, com a loja cheia, **a seção fica
abaixo da dobra.** Só se chega nela rolando a coluna. A captura `loja_fim` existe para
fotografá-la.

| | resposta |
|---|---|
| Você **rolou** a coluna até o fim alguma vez? Em que minuto? | |
| Você olhou para a seção **espontaneamente**, ou porque este documento mandou? | |
| Ela **ajudou** (deu um alvo) ou **poluiu** (virou lista)? | |
| Você entendeu "faltam 8,74e14 caracteres" sem parar para pensar? | |
| A descrição do upgrade **futuro** acrescenta, ou basta nome + efeito + quanto falta? | |

### As três variantes

Em `docs/playtests/variantes-futuros/` há três capturas do mesmo estado de jogo, mudando só
quantos futuros aparecem:

```text
futuros_3.png    futuros_4.png    futuros_5.png
```

⚠️ **O estado é idêntico nas três** — mesma produção, mesmas descobertas, mesma loja. A única
diferença é a seção. Olhe as três lado a lado e responda:

| | resposta |
|---|---|
| Qual delas você lê como **alvo**, e qual você lê como **lista**? | |
| Alguma passa do ponto em que você pararia de ler? | |

O número hoje é **4**, e é limite de design — escolhido e escrito, não medido. Se as três
parecerem iguais, o número está certo por não importar.

---

## 3. O banner de descoberta

| | resposta |
|---|---|
| Ele **chama atenção demais**? | |
| 7 segundos (Paradoxal) parece longo? | |
| 3,5 segundos (Comum) parece curto? | |
| Você **perdeu** alguma descoberta? Qual, e em que minuto? | |
| Ele atrapalha ver o macaco / a máquina? | |
| Você chegou a **procurar** a descoberta no Arquivo depois de ver o banner? | |

⚠️ **A régua diz que 0% dos avisos são cortados.** Ela não diz se você quis ler. A pergunta
que falta é essa.

---

## 4. A coluna da esquerda

| | resposta |
|---|---|
| Você entende `PRÓXIMO MARCO` sem abrir o Panorama? | |
| A barra ajuda, ou o número já bastava? | |
| `PRODUÇÃO` / `SALDO` / `COLEÇÃO` ficaram distinguíveis, ou ainda leem como um bloco só? | |
| Em que minuto você parou de olhar para essa coluna? | |

---

## 5. O centro

| | resposta |
|---|---|
| O macaco e a máquina acrescentam, ou são decoração que você deixou de ver? | |
| Em que minuto você parou de olhar para eles? | |
| O botão `DIGITAR` ainda recebe atenção **demais** para o que ele rende? | |
| Você notou a máquina sumir na era abstrata? | |

---

## 6. As três perguntas que valem mais que as tabelas

1. **Em que minuto a interface deixou de te dizer algo novo?**
   *(o minuto em que a tela virou fundo)*

2. ⚠️ **O que a régua mostrou e você NÃO sentiu?**
   A medição diz 0% de avisos cortados, quadro em 3,5 ms, loja nunca vazia. Se algo disso
   estava tecnicamente certo e mesmo assim incomodou, **a medição está apontando para o lugar
   errado** — e isso despriorizaria trabalho que hoje parece importante.

3. ⚠️ **E o contrário: o que você sentiu e nenhuma régua mostra?**
   Esta é a metade que nenhuma máquina faz.

---

## 7. O veredito de escopo

> **A reforma da HUD pode ser fechada?**

| | |
|---|---|
| fechar como está | |
| fechar com ajustes pequenos (quais) | |
| não fechar (por quê) | |

⚠️ **Nada aqui vira trabalho antes desta resposta.** A regra da próxima rodada é
**validação, não expansão**: a HUD já tem os elementos certos, e o próximo salto vem de
descobrir se o jogador olha para as coisas certas — não de pôr mais coisas nela.
