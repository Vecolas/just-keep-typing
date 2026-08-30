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

## Réguas previstas

Nenhuma existe ainda: não há gameplay para medir. Entram nesta ordem, cada uma com o
sistema correspondente.

| Régua | Mede | Entra com |
|---|---|---|
| `medir_quadro` | tempo de quadro: média, p95, p99, frames perdidos | o primeiro sistema com muita coisa em tela |
| `medir_ritmo` | tempo médio por sala e por andar, por tipo e por tier | o fluxo de salas |
| `medir_composicao` | custo e variedade dos sorteios de inimigo | o gerador de encontros |
| `medir_economia` | quanto tempo até cada marco de progressão | a economia |

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
