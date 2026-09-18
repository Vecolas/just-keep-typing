# Devolutiva da v0.7 — a campanha da primeira hora

Documento de consulta. A v0.6 mediu o problema; **esta versão tentou consertá-lo.**

Se você só for ler uma seção, leia a **§3** — ela é a lição que sobrevive aos números.

---

## 1. O placar

| | |
|---|---|
| issues do plano | **7 de 7** entregues e fechadas (#58–#65) |
| defeitos achados **no jogo** | 4, todos viraram issue (#66–#69) |
| defeitos achados **na instrumentação** | **5** |
| ferramenta nova | `tools/observar.tscn` |
| decisões registradas | `0008` e `0009` |
| suíte | **6.445 afirmações em 26 suítes** — verde |
| fumaça · CI · capturas | verdes |
| commits desde a `v0.6` | 18, em 9 merges |

**Conteúdo do jogo: inalterado.** 91 marcos, 62 descobertas, 44 upgrades — exatamente os
mesmos da v0.6, por decisão sua (congelamento de conteúdo, decisão `0008`).

---

## 2. O resultado

| | v0.6 | v0.7 |
|---|---|---|
| distribuição 0–60 min | **76 / 0 / 0 / 1 / 0 / 0** | **34 / 3 / 7 / 0 / 1 / 6** |
| blocos de 10 min com conteúdo | **1 de 6** | **5 de 6** |
| 1º Teorema disponível | 00:03:43 | 00:05:08 |
| 1º Teorema **vale a pena** | 00:04:22 | **00:32:55** |
| minutos com a loja vazia | *não era medido* | **0 de 30** |
| prestígios na 1ª hora | 2 | 1 |

Os três perfis chegam ao Teorema. **A primeira run passou a ter um arco**: meia hora antes
de o prestígio compensar, contra quatro minutos.

---

## 3. A lição que vale mais que os números

### ⚠️ O suspeito óbvio mente

Os upgrades pareciam a causa da explosão — 38 dos 44 eram multiplicadores que compõem, e
juntos davam mais de **10^13**. Separei todos eles em tipos aditivos, locais e globais.

**O primeiro Teorema foi de 04:22 para 04:01.** Quase nada.

O multiplicador estava nas **descobertas**: ×**10^41**, vinte e oito ordens de grandeza
acima. A issue #52 criou a maior parte disso — e **o portão que eu mesmo escrevi exigia
`bonus > 1` de toda descoberta de papel `BONUS`.**

> **A regra que protegia contra dado esquecido era a mesma que garantia a explosão.**

Foi preciso medir de novo, **fonte por fonte**, para achar onde o número morava.

### ⚠️ E o instrumento mente junto

**Cinco defeitos da instrumentação nesta versão**, e os cinco produziam números
convincentes:

| # | defeito | o que ele fazia parecer |
|---|---|---|
| 1 | a régua não semeava `Eventos` | (herdado da v0.6, consertado na #59) |
| 2 | o ouvinte guardava a **última** compra, não a primeira | "1 upgrade na primeira hora" — leria como *"a curva foi consertada"* |
| 3 | a sessão media a **política do jogador**, não a oferta do jogo | "27 de 30 minutos sem compra possível" |
| 4 | a sessão **retomava a partida anterior** | tabela coerente, começando com produção de 13,9 milhões no minuto 1 |
| 5 | meu script de análise lia `"64 bilhões"` como `64` | os dois instrumentos **discordando em 8 ordens de grandeza** |

O quinto é o mais barato de cometer e o mais caro de acreditar: **ele não estava no jogo nem
nas ferramentas do jogo, e sim na análise que eu fiz por cima delas.** Quase virou uma
investigação sobre qual dos dois medidores estava mentindo. Nenhum estava.

### ⚠️ Regra geral aplicada sem olhar o que a peça é — duas vezes

- `mesas_empilhadas` virou parcela de velocidade. O texto dele fala de **empilhar mesas** —
  ou seja, **vaga**. Quem acusou foi a composição de `CAPACIDADE` cair de ×112 para ×45 sem
  eu ter tocado em capacidade nenhuma.
- `instinto_digitador` ganhou requisito 20 como qualquer outro da fila. Ele é o
  **interruptor** que liga a produção automática (GDD §3) e tem de estar na loja no primeiro
  quadro.

### ⚠️ Forma certa com escala errada não é meio-caminho

A primeira iteração da redistribuição produziu:

```
distribuição   28 / 5 / 5 / 2 / 1 / 1     ← exatamente o alvo que você pediu
o jogo         28 caracteres em uma hora  ← parado
```

**A tabela de distribuição sozinha teria aprovado isso.** Espalhar upgrades encarece a
ignição, e a economia nunca pega.

---

## 4. O que só apareceu quando alguém olhou a tela

Eu vinha tratando "playtest" como binário — *é humano, logo não dá* — e estava confundindo
**não sinto** com **não consigo observar**.

`tools/observar.tscn` monta a partida de verdade, conta os botões da loja e **fotografa a
tela**. As nove fotos foram examinadas uma a uma. Quatro defeitos saíram daí:

| | achado | issue |
|---|---|---|
| 1 | **`48,99 macacos`** na tela — macaco é coisa contável | **#66** |
| 2 | **Coluna da direita inteira apagada** — sala cheia no minuto 1 com a saída custando 22× o saldo; nada comprável no minuto 30 | **#67** |
| 3 | **`DIGITAR` domina a tela** aos 30 min dando +1 contra 37,7 milhões/s | **#68** |
| 4 | **As 62 descobertas chegam todas** pela mesma linha de rodapé — cinco no minuto 1 | **#69** |

⚠️ **Nenhum deles aparece em contador nenhum.** A tabela registrou o minuto 30 como *"3 na
loja, 6 compras, 1 acontecimento"* — que lê como um minuto saudável.

> **"Três na loja" e "três botões apagados" são o mesmo número.**

### E a pergunta mais importante ganhou metade de uma resposta

*"Em que minuto você parou de ler os textos?"* tem uma metade que é aritmética:

```
avisos que a HUD mostrou:            82
apagados antes dos 1,6 s de leitura: 16  (20%)
```

**Um em cada cinco textos que o jogo escreve é fisicamente ilegível.** A HUD tem um slot só,
e o **autosave disputa ele com as descobertas** — `"Salvando..."` apaga um marco raro com a
mesma prioridade, e é o único dos três que o jogador não estava esperando.

Isso não diz se você **quis** ler. Diz que em 20% das vezes você **não teve como**.

---

## 5. O que NÃO convergiu

### O bloco de 30 a 40 minutos continua vazio

Acima de 10^25 os marcos ficam espaçados por **ordens de grandeza inteiras**, e a economia —
depois dos 44 upgrades — só cresce por compra de macaco, que rende logaritmicamente.

As três saídas estão na decisão `0009`, e **uma delas contradiz o seu próprio congelamento
de conteúdo**. A escolha é sua, e não foi tomada.

### O combo regrediu

| | linha de base | agora |
|---|---|---|
| vantagem do perfil ativo | **13%** ✅ | **27%** ❌ |

A decisão `0008` fixou a faixa em 10–20%. A #65 avisava que essa propriedade era *"o tipo
que uma curva nova quebra sem avisar"* — e ela quebrou, porque a economia mais lenta dá mais
peso relativo ao que a mão produz.

⚠️ **Não ajustei de propósito.** Mexer no combo junto com a curva daria uma medição que não
diz qual dos dois mudou o quê. Uma variável por vez.

### ⚠️ Marco não é botão de tuning

A #61 pedia para redistribuir marcos. **Não dá.** O `requisito` é um fato sobre o mundo, e o
campo `nota` existe para documentar a conta:

```
requisito = "3.5e6"
titulo    = "A Bíblia"
nota      = "Biblia completa: 783.000 palavras x 4,5 caracteres."
```

Mudar aquele `3.5e6` **faz o Panorama mentir**. Quando cada marco cai é **consequência** da
velocidade da economia — o que limita o quanto a distribuição pode ser moldada, e reduziu a
issue aos upgrades.

---

## 6. O que mudou no jogo, concretamente

### Os tipos de bônus

| tipo | quantos | compõe? |
|---|---|---|
| `VELOCIDADE_SOMADA` (+) | **27** | **não** |
| `PRODUCAO_GLOBAL` (×) | **5** | sim — são os "momentos" |
| `VELOCIDADE_DO_MACACO` (×) | 4 | sim |
| `CAPACIDADE` (×) | 5 | sim |
| `CUSTO_DE_MACACO` (desconto) | 2 | sim, para baixo e **com piso** |
| interruptor | 1 | — |

**A maioria deixou de compor.** E as descobertas passaram a somar na base do macaco em vez
de multiplicar a produção.

### Os números que se movem

| onde | de | para |
|---|---|---|
| `data/prestigio.tres` → `limite_inicial` | `1e6` | `1e4` |
| `custo` dos upgrades | escada manual | `requisito × 2,5` |
| `requisito` dos upgrades | escada manual | espalhado 10^1,3 → 10^18 |

⚠️ **A faixa entre "loja vazia" e "vitrine inalcançável" é estreita**, e foi medida:

| custo | resultado |
|---|---|
| requisito × 0,12 | **loja vazia** — 24 de 30 min sem nada |
| requisito × 16,7 | **vitrine** — 4 a 6 visíveis, zero alcançáveis em 27 de 30 min |
| **requisito × 2,5** | aparece caro, fica comprável em um ou dois minutos |

**Botão apagado com preço visível é uma meta; botão nenhum é tela vazia; botão que nunca
acende é uma promessa que a economia não cumpre.** São três coisas diferentes, e nenhuma
régua distingue as três.

---

## 7. A dívida, hoje

### De produto

| | |
|---|---|
| **30–40 min vazio** | decisão sua, três saídas em `0009` |
| **o combo em 27%** | conserto barato (`data/combo.tres`), deixado para não misturar variáveis |
| **quatro defeitos visuais** | #66 a #69 |
| **~70 peças de texto autoral** sem sua revisão | mais **duas descrições reescritas** nesta versão (os dois descontos) |
| **ninguém jogou** | **#70** |

### Declarada no código

| lista | conteúdo |
|---|---|
| `SEM_FONTE_AINDA` | `Musica`, `Ambiente` |
| `SEM_SISTEMA_AINDA` | `animacoes_de_numero`, `shake` |
| `SEM_SORTEIO_AINDA` | `medir_quadro.gd`, `gerar_galeria.gd` |

Inalteradas — o congelamento de conteúdo valeu também para elas.

### Pontos cegos das ferramentas

- **`medir_ritmo` agora roda eventos, automação e prestígio** — os pontos cegos da v0.6
  foram fechados
- **`observar` conta botões**; não sabe se algum deles fazia sentido
- ⚠️ **Hierarquia visual continua sem régua.** Os quatro defeitos desta versão saíram de
  *olhar a foto*, com a suíte verde. É o mesmo padrão da v0.6

---

## 8. Uma decisão de escopo que é minha, e é discutível

A issue #64 misturava duas coisas de naturezas diferentes:

1. **observar trinta minutos e transformar o que aparecer em trabalho** — entregável
2. **dizer se foi divertido** — um veredito seu

Issue cuja última caixa depende da experiência de outra pessoa **nunca fecha** — e issue que
nunca fecha para de ser um pedido e vira ruído na lista.

Fechei a #64 pelo que era entregável e abri a **#70** para a sua metade, onde ela é o que de
fato é: **uma tarefa para uma pessoa**, com o que já se sabe listado para você não gastar a
sessão redescobrindo.

**Se você discordar do recorte, reabra.** O recorte é meu.

---

## 9. Se você só for fazer duas coisas

1. **Jogue os 30 minutos da #70.** Ela pede duas coisas, e a segunda é a que costuma faltar:
   o que você sentiu e a medição não mostrava, **e o que a medição mostrava e você não
   sentiu**. Medição que aponta um defeito que ninguém sente está apontando para o lugar
   errado — e isso despriorizaria issues que hoje parecem importantes.

2. **Decida o que ocupa de 30 a 40 minutos.** É a única coisa que trava o resto do plano, e
   nenhuma das três saídas pode ser escolhida por mim: uma delas contradiz uma regra que
   você escreveu.

---

## 10. Onde procurar o quê

| assunto | arquivo |
|---|---|
| as regras que o código segue | `CONVENCOES.md` |
| as medições, as iterações e as retratações | `TUNING.md` |
| a decisão de produto que abriu a v0.7 | `docs/decisoes/0008-…` |
| o que convergiu e o que não | `docs/decisoes/0009-…` |
| a sessão observada, minuto a minuto | `docs/playtests/2026-09-18-sessao-observada.md` |
| as nove fotos, examinadas | `docs/playtests/2026-09-18-playtest-observado.md` |
| o formulário da **sua** sessão | `docs/playtests/MODELO.md` |
| a devolutiva da versão anterior | `docs/DEVOLUTIVA-v0.6.md` |
