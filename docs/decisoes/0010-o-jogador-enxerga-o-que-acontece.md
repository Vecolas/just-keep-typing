# 0010 — O jogador enxerga o que acontece

**Contexto:** a v0.7 consertou o problema estrutural que a v0.6 revelou — a primeira run
passou de quatro minutos para meia hora antes de o prestígio compensar. Este documento
registra a leitura do autor sobre **o que fazer a seguir**, e ela não é mais economia.

## A leitura

> **A interface está escondendo ou desvalorizando o que a economia produz.**

A distribuição atual (**34 / 3 / 7 / 0 / 1 / 6**) é incomparavelmente melhor que os
**76 / 0 / 0 / 1 / 0 / 0** da v0.6. O vazio de 30–40 minutos precisa ser resolvido, mas há
algo mais urgente:

**conteúdo que existe no banco de dados e o jogador não consegue consumir.**

O caso decisivo: **20% dos avisos somem antes do tempo mínimo de leitura.** Autosave, marcos
e descobertas disputam o mesmo espaço, e `"Salvando..."` pode apagar uma descoberta rara.

> **Isso já não é polimento. É conteúdo inexistente.**

## A decisão: uma v0.7.1 antes da v0.8

Pequena, focada exclusivamente em UX. **Não haverá outra cirurgia econômica.**

| # | | prioridade |
|---|---|---|
| **#69** | notificações com fila e prioridade; autosave sai da fila | **1ª** |
| **#67** | três estados visuais na loja | 2ª |
| **#68** | `DIGITAR` perde protagonismo junto com o papel do jogador | 3ª |
| **#66** | formatação discreta × contínua, sistêmica | 4ª |
| **#73** | o combo de volta para 12–18% | 5ª |
| **#74** | 30–40 min preenchido **sem tocar na economia** | 6ª |
| **#71** | a régua decompõe por fonte, e emite valor cru | ferramenta |
| **#72** | papel do upgrade vira dado com invariante | ferramenta |

E antes de tudo: **a #70**, que é do autor.

## As três regras novas

### 1. Medir por FONTE, nunca só pelo resultado

A v0.7 gastou uma investigação inteira procurando o multiplicador no lugar errado. A régua
dizia `producao = 8,4e17`, e isso não permite perguntar **de onde veio**.

> **Toda mudança de balanceamento precisa ser medida por fonte, não apenas pelo resultado
> final.**

### 2. Formato humano é terminal, nunca fonte de dados

O script de análise lia `"64 bilhões"` como `64`, e isso fez dois instrumentos **parecerem
discordar em oito ordens de grandeza**.

Ferramenta de análise **nunca** lê número a partir de texto formatado para humano. A saída
traz os dois:

```json
{ "valor": 64000000000, "texto": "64 bilhões" }
```

### 3. Objeto antes de fórmula

Dois erros da v0.7 vieram de aplicar regra geral sem olhar o significado da peça:
`mesas_empilhadas` (que é **vaga**, não velocidade) e `instinto_digitador` (que é o
**interruptor** do jogo). Nos dois casos a semântica vivia **só no texto da descrição**, que
nenhuma ferramenta lê.

O papel do upgrade vira **dado com invariante**, e a invariante é o que teria pego os dois.

## O que NÃO se mexe

⚠️ **A arquitetura de bônus está congelada** até o midgame existir:

| tipo | quantos | compõe? |
|---|---|---|
| `VELOCIDADE_SOMADA` | 27 | **não** |
| `PRODUCAO_GLOBAL` | 5 | sim — os "momentos" |
| `VELOCIDADE_DO_MACACO` | 4 | sim |
| `CAPACIDADE` | 5 | sim |
| `CUSTO_DE_MACACO` | 2 | sim, com piso |
| interruptor | 1 | — |

**A maioria não compor é saudável**, e é o que a v0.7 comprou caro.

## O vazio de 30–40 minutos

Três saídas estavam na decisão `0009`. A escolhida é a **C**:

| | |
|---|---|
| **A** aceitar o silêncio | ❌ dez minutos é longo demais, e logo antes de o jogador entender o prestígio |
| **B** conteúdo econômico novo | ❌ acabamos de congelar e rebalancear 44 upgrades; multiplicador novo reabre a explosão |
| **C** conteúdo que **não altera a economia** | ✅ |

> **Não precisa existir uma compra a cada minuto. Precisa existir algo para perceber.**

O período vira **"A Estranheza"**: a produção já saiu da escala cotidiana, e o jogo começa a
comentar isso. A transição passa a ser:

```
trabalho → produção industrial → escala absurda → algo está mudando → TEOREMA
```

⚠️ **E marco continua fora**: o requisito é um fato sobre o mundo (decisão `0003`), e criar
marco para preencher minuto faria o Panorama mentir.

## Sobre a issue #64

**Fica fechada.** O recorte separou o que era entregável (observar e transformar em trabalho)
do que depende de uma pessoa (dizer se foi divertido), e isso evita uma tarefa eternamente
incompleta.

Só seria reaberta para redefinir a issue como *"playtest humano completo"* — e não há
necessidade: isso é a **#70**.

## O que esta decisão NÃO resolve

- **Ninguém jogou** — a #70 continua sendo a coisa mais valiosa da lista
- **~70 peças de texto autoral** continuam sem revisão, e a #74 acrescenta algumas. A dívida
  é explícita: **revisar uma amostra antes de criar mais**
- **Hierarquia visual continua sem régua.** Os quatro defeitos desta rodada saíram de olhar
  a foto, com a suíte verde — e nada garante que os próximos apareçam
