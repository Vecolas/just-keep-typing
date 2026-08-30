# 0004 — Um caractere digitado é uma moeda

**Data:** 2026-08-30
**Estado:** aceita

## Contexto

O GDD lista `money` como estado do `GameManager` (§29), mostra **Dinheiro** entre os
recursos da coluna esquerda da interface (§25) e manda o `SaveManager` gravar **Moedas**
(§37). O loop principal (§2) diz:

```text
GERAM CARACTERES → CARACTERES GERAM DINHEIRO/RECURSOS → COMPRAR MAIS MACACOS
```

O que ele **não** diz, em lugar nenhum: de onde o dinheiro sai e a que taxa. A issue #5
precisa dessa resposta antes de escrever qualquer `.tres`, porque ela decide em que
unidade `custo_base` e `custo` estão escritos.

## Decisão

Um caractere digitado vale uma moeda. `Economia.acumular()` soma o mesmo `produzido` em
`dinheiro` e nos dois acumuladores de caractere; a loja gasta `dinheiro`, e só ele desce.

```gdscript
Jogo.total_caracteres = Jogo.total_caracteres.mais(produzido)   # nunca desce
Jogo.caracteres_da_run = Jogo.caracteres_da_run.mais(produzido) # zera no prestigio
Jogo.dinheiro = Jogo.dinheiro.mais(produzido)                   # desce na loja
```

`custo_base` e `custo` dos `.tres` ficam, portanto, em caracteres.

## Por quê

**Explica por que o GDD tem os três campos.** `total_caracteres` é o número do Panorama e
não pode descer — se a loja gastasse dele, comprar um macaco apagaria um marco já
alcançado, que é o oposto do que o §45 quer. `caracteres_da_run` zera no prestígio.
`dinheiro` é o mesmo número, mas gastável. São três vidas diferentes do mesmo evento, e é
por isso que são três campos e não um.

**Não inventa número de balanceamento.** Uma taxa de conversão seria uma alavanca de
tuning a mais para ajustar, num jogo que já tem custo base, crescimento de custo, produção
por macaco, multiplicador de máquina, de sala, de prestígio e global. Ela não compra
nenhuma decisão de design que a curva de custo não compre melhor — dobrar a taxa e dividir
o custo base por dois dão exatamente a mesma partida.

**O tema aguenta.** O jogo é sobre um macaco que aperta teclas ao acaso; o caractere é a
unidade de tudo. Uma moeda intermediária pediria uma ficção para existir — quem paga? por
quê? — e o GDD não tem essa ficção.

## Consequências

- A loja lê `Jogo.dinheiro`, nunca `total_caracteres`. Quem escrever a HUD (#7) precisa
  saber que os dois números começam iguais e se separam na primeira compra — e a coluna da
  esquerda mostra os dois de propósito, porque a diferença entre eles **é** a informação.
- Sem `DadosEconomia`: nenhum `.tres` novo, nenhum autoload novo.
- Se um dia o jogo quiser uma segunda moeda que não seja caractere (patrocínio, prêmio
  literário, o que for), ela é um recurso **novo** ao lado deste, e não uma taxa em cima
  dele. Esta decisão não fecha essa porta; ela só não abre uma taxa que ninguém pediu.

## Alternativa descartada

`dinheiro = caracteres × taxa`, com a taxa num `.tres` de balanceamento global. Descartada
por ser uma alavanca redundante com o custo base, e por exigir um tipo de `Resource` que
nenhuma issue cria — inventar arquivo de balanceamento para um número que não decide nada
é o tipo de estrutura que só aparece como custo, nunca como benefício.
