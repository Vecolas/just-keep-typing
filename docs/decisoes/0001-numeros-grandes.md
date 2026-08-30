# 0001 — Números grandes desde o primeiro dia

**Data:** 2026-08-30
**Estado:** aceita

## Contexto

O jogo é um incremental cujo recurso central — caracteres digitados — cresce sem teto de
design. O GDD (§33) já prevê `10^100`, `10^10000` e, no endgame, `10^(10^100)` como parte
da progressão.

O `float` do Godot é um double IEEE 754: ele vai até ~`1.8e308` e depois vira `INF`. Isso
cobriria as versões v0.1 a v0.3 com folga, então existe a tentação de começar com `float` e
migrar quando doer.

## Decisão

Implementar a classe `Grande` (mantissa + expoente) **na primeira issue**, antes de existir
economia, e fazer todo o resto do código já nascer falando `Grande`.

```gdscript
# 5,28 × 10^4321
mantissa = 5.28   # normalizada em [1, 10)
expoente = 4321
```

## Por quê

O tipo do recurso central não é um detalhe local: ele aparece na economia, no custo
exponencial, na comparação com o requisito de cada marco, no save, no formatador e em toda
a UI. Migrar depois significa tocar **todos esses sistemas ao mesmo tempo** — exatamente o
refactor que uma pessoa sozinha não consegue fazer numa sessão, e o tipo de mudança que
não é revertível sozinha.

O custo de fazer agora, por outro lado, é o menor possível: `Grande` é lógica pura sobre
dois números, sem cena e sem autoload. Roda headless, é testável por suite unitária desde o
primeiro dia, e falha de forma visível (uma soma errada quebra uma asserção, não um jogo
salvo do jogador).

## Consequências

- Toda comparação de recurso passa por métodos (`maior_que`, `mais`, `vezes`), nunca por
  `>` e `+` diretos. É mais verboso, e é o preço.
- O save grava mantissa e expoente, não um `float` — desde a primeira gravação, para não
  precisar de migração já na v0.1.
- A suite de `Grande` é a mais densa do projeto de propósito: normalização, soma de
  expoentes muito distantes (onde a parcela menor simplesmente some), `log10`, potência,
  ida e volta para texto.
- Onde o número **cabe** em `float` sem perda — delta de frame, multiplicadores de upgrade,
  probabilidades — continua `float`. `Grande` é para acumuladores, não para tudo.

## Alternativa descartada

`float` até a v0.3 e migração depois. Descartada pelo tamanho do refactor, não por
desempenho: o custo real da migração seria pago no pior momento, com jogo salvo em campo e
sistemas já entrelaçados.
