# Tuning

Como ajustar os números do jogo sem abrir um `.gd`.

---

## Onde os números moram

Em `.tres` dentro de `data/`, expostos por `@export` ou por `Resource`. Se você precisou
abrir um script para mudar um número numa sessão de tuning, esse número está no lugar
errado — ver `CONVENCOES.md`, "Números vão para `.tres`".

---

## Réguas ≠ testes

| | O que faz | Saída |
|---|---|---|
| `tools/testes/` | aprova ou reprova | `PASSOU` / `FALHOU` |
| réguas de `tools/` | **medem** | números para você decidir |

Régua não tem opinião sobre o que é certo. Ela mede e imprime; a decisão é sua. É o que
sustenta a sessão de tuning: sem número medido, ajustar balanceamento é chute com etapa
extra.

**Régua entra junto do sistema que ela mede.** Régua que mede o vazio é cerimônia — e
nenhum teste é escrito antes de existir lógica para testar.

---

## Réguas

| Régua | Mede | Estado |
|---|---|---|
| `medir_ritmo` | tempo até cada marco do Panorama, com a produção no momento | **existe** |
| `medir_quadro` | tempo de quadro: média, p95, p99, frames perdidos | entra com as letras subindo (#22) |
| `medir_economia` | curva do prestígio: quando vale provar o Teorema | entra com os Teoremas (#29) |

```bash
godot --headless --path . tools/medir_ritmo.tscn
```

### `medir_ritmo`

Roda uma partida inteira sem ninguém assistindo e imprime quanto tempo levou até cada
marco, com a produção naquele instante. Termina em cerca de doze segundos para um dia de
jogo simulado.

⚠️ **O jogador simulado não é o jogador real.** Ele faz a compra ótima ingênua: gasta em
upgrade assim que dá, e no resto compra o máximo de macacos que couber; clica a quatro por
segundo até a produção automática entrar, e depois para. Nenhum humano joga assim. Isso é
proposital — a régua precisa ser **estável**, para que a diferença entre duas medições
seja a mudança no `.tres` e não o humor de quem jogou.

A saída é texto alinhado, e não CSV nem JSON, porque o que se faz com ela é `diff` entre
duas sessões de tuning.

### O que a primeira sessão de tuning descobriu (issue #20)

A régua achou **dezesseis marcos cujo requisito não batia com a própria nota** — um deles
errado por 1096×. É o defeito que o campo `nota` do `DadosMarco` existe para pegar, e ele
pagou por si no primeiro uso: sem a conta escrita ao lado do número, ninguém conferiria.

Ela também achou algo que **não se conserta espaçando marco**: vinte e um marcos caindo no
mesmo segundo de jogo, porque a economia atravessa sete ordens de grandeza naquele
instante. A distância entre eles em magnitude está certa; o que corre demais é a produção.
Marco tão perto do anterior que passa despercebido virou regra de suíte
(`DISTANCIA_MINIMA`, 1,15×), mas a avalanche do meio da curva é assunto de economia, e
espera decisão de design.

A primeira régua a escrever é sempre a que sustenta a **decisão de design mais cara ainda
não medida**. Num projeto anterior isso apagou uma suposição inteira: o custo de uma
máscara pintável não estava no upload de textura (0.079 ms, irrelevante) mas no laço por
pixel — o que obrigou o pincel a virar LUT pré-calculada. A régua veio antes do tuning
porque a decisão dependia dela.

---

## Sessão de tuning

1. Rode a régua e anote os números **antes** de mexer em qualquer coisa.
2. Ajuste os `.tres`. Só os `.tres`.
3. Rode `tools/testes/runner.tscn` — boa parte das suites existe justamente para pegar erro
   de tuning: cadência 0 virando divisão por zero, custo zerado que trava um sorteio, custo
   de upgrade não crescente que permite compra infinita.
4. Rode a régua de novo e compare.
5. Commit `tune/<descricao>` com os números do antes e do depois na mensagem estendida.
