# Sessão observada — 18/09/2026, perfil normal, 30 minutos

⚠️ **ISTO NÃO É O PLAYTEST DA ISSUE #64, e não o substitui.**

O playtest responde *o que confundiu*, *quando você parou de ler os textos*, *quando ficou
sem objetivo* — e **nenhuma máquina responde isso.** Este documento é a outra metade: a que
nenhum humano faz bem, que é olhar a tela a cada minuto durante trinta minutos sem piscar.

O modelo para a sua metade está em `MODELO.md`, ao lado deste arquivo.

**Ferramenta:** `godot --path . tools/observar.tscn -- perfil=normal minutos=30`
**Semente:** 1, a mesma da régua e da suíte — as duas tabelas se leem lado a lado.

---

## A pergunta que esta ferramenta responde, e a régua não

> **Em que minutos o jogador não tem nada para fazer?**

Um bloco de dez minutos pode estar *"cheio"* na tabela da `medir_ritmo` — marcos caindo — e
mesmo assim não oferecer nenhuma decisão. A régua nunca monta a HUD; esta ferramenta monta,
e conta os botões.

---

## A tabela

| min | produção/s | total | na loja | compras | acontecimentos |
|---|---|---|---|---|---|
| 1 | 23,7 | 603 | 2 | 9 | 12 |
| 2 | 49,2 | 3.045 | 2 | 2 | 11 |
| 3 | 66,45 | 6.785 | 2 | 1 | 2 |
| 4 | 734 | 28.365 | 2 | 5 | 5 |
| 5 | 1.190 | 88.193 | 4 | 10 | 4 |
| 6 | 26.291 | 1,77 mi | 3 | 13 | 13 |
| 7 | 40.432 | 3,53 mi | 3 | 6 | 4 |
| 8 | 59.332 | 6,62 mi | 2 | 1 | 2 |
| 9 | 77.557 | 11 mi | 2 | 1 | 3 |
| 10 | 766 mil | 130 mi | 4 | 6 | 12 |
| 11 | 1,12 mi | 560 mi | 3 | 11 | 2 |
| **12–15** | ~1,2 mi | 629 mi → 848 mi | 3–4 | **1 por minuto** | **0** |
| 16 | 1,69 mi | 1,2 bi | 3 | 3 | 1 |
| 17 | 1,72 mi | 1,61 bi | 3 | 2 | 1 |
| 18 | 1,76 mi | 1,71 bi | 3 | 1 | 1 |
| **19–25** | ~1,8 mi | 1,82 bi → 2,63 bi | 4 | **0–1** | **0** |
| 26 | 12,7 mi | 3,23 bi | 3 | 2 | 1 |
| 27 | 12,9 mi | 4,01 bi | 3 | 2 | 1 |
| 28 | 13,9 mi | 9,61 bi | 3 | 8 | 2 |
| 29 | 14,6 mi | 20,7 bi | 4 | 7 | 1 |
| 30 | 21,5 mi | 35,8 bi | 4 | 5 | 1 |

| | |
|---|---|
| minutos com a **loja vazia** | **0 de 30** ✅ |
| minutos **sem nenhuma compra** | **5 de 30** |
| minutos **sem marco nem descoberta** | **11 de 30** ⚠️ |

---

## O que ela achou

### ✅ A loja nunca fica vazia

Zero minutos sem nada para mirar, contra **24 de 30** na primeira medição. O jogador sempre
vê de dois a quatro upgrades adiante do que pode pagar.

Foi preciso separar `requisito` de `custo` para chegar aqui, e a faixa é estreita:

| custo | resultado |
|---|---|
| requisito × 0,12 | **loja vazia**: compra-se no instante em que aparece |
| requisito × 16,7 | **vitrine**: 4–6 itens visíveis, zero alcançáveis em 27 de 30 min |
| **requisito × 2,5** | aparece caro, fica comprável em um ou dois minutos |

**Botão apagado com preço visível é uma meta; botão nenhum é tela vazia; botão que nunca
acende é uma promessa que a economia não cumpre.** As três são diferentes, e só esta
ferramenta enxerga a diferença.

### ⚠️ Há dois vales longos sem acontecimento

**Minutos 12–15 e 19–25.** A produção sobe, o total sobe, a loja tem o que mirar — e
**nenhum marco, nenhuma descoberta.** Onze minutos de trinta em que a única coisa que muda
na tela é um número crescendo.

É o mesmo buraco que a decisão `0009` descreve, agora visto de dentro da partida.

### O primeiro minuto é bom

12 acontecimentos e 9 compras no minuto 1, 11 acontecimentos no minuto 2. **A abertura
entrega o que a decisão 0008 pede** — *"0–5 min: descoberta extremamente rápida"*.

---

## Dois defeitos DA PRÓPRIA FERRAMENTA, achados ao usá-la

Valem registro porque os dois produziam números convincentes.

### 1. Ela media a política do jogador, não a oferta do jogo

A primeira versão contava quantos upgrades estavam **compráveis no instante da medição**, e
reportou *"27 de 30 minutos sem nenhuma compra possível"*.

O número era real e a leitura era falsa: o jogador simulado varre a loja a cada ciclo, então
no instante da medição **tudo que dava para comprar acabou de ser comprado.**

Substituído por *quantas compras aconteceram no minuto*. **Compra que aconteceu é um fato
sobre o jogo; saldo no instante errado é um fato sobre o medidor.**

### 2. Ela retomava a partida da execução anterior

`Save.apagar()` limpa `Save.caminho` — mas `comecar_partida(1)` troca o caminho para o do
**slot**, e o arquivo do slot sobrevive entre execuções.

O sintoma não parecia defeito: a tabela saía coerente, só começando com produção de 13,9
milhões no minuto 1. **Uma sessão observada que começa no meio da campanha mede outro jogo.**

---

## O que esta sessão NÃO prova

- **Ninguém jogou.** Ela conta botões; não sabe se algum deles fazia sentido.
- **Não sabe se o jogador leu.** A pergunta mais reveladora do playtest — *quando você parou
  de ler os textos* — não tem correspondente aqui, e é por isso que a issue #64 continua
  aberta.
- **Não sabe se foi divertido.**
