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
| `medir_quadro` | tempo de quadro por era: média, p95, p99, frames perdidos | **existe** |
| `medir_economia` | curva do prestígio: quando vale provar o Teorema | entra com os Teoremas (#29) |

```bash
godot --headless --path . tools/medir_ritmo.tscn
```

### `medir_quadro`

```bash
godot --path . tools/medir_quadro.tscn --resolution 1920x1080
```

⚠️ **Precisa de janela.** Headless não renderiza, e medir tempo de quadro sem desenhar
mede o nada.

Mede o efeito de letras (issue #22) nas três escalas de produção do GDD §26 mais uma
quarta linha com a piscina de rótulos **saturada** — sem ela o teto seria um número que se
diz medido sem nunca ter sido tocado por uma medição.

Primeira medição, orçamento de 16,67 ms:

```text
producao/s       rotulos  media     p95       p99       perdidos
5                14       11,3 ms   11,9 ms   11,9 ms   0 de 240
500 mil          14       10,9 ms   11,0 ms   11,0 ms   0 de 240
5e17             13       13,7 ms   15,3 ms   15,3 ms   0 de 240
SATURADO         64       11,0 ms   11,3 ms   11,3 ms   0 de 240
```

⚠️ **A escala entra pelo multiplicador global, e não pela contagem de macacos.** Macaco
além da capacidade da sala é cortado pelo multiplicador de sala — a primeira versão desta
régua pôs 500 mil macacos numa Sala Pequena e mediu as três escalas rodando todas a **10
caracteres por segundo**, sem ninguém perceber. Régua que mede a coisa errada é pior que
régua nenhuma, porque ela dá confiança.

O regime permanente do jogo fica em **14 rótulos** (9 por segundo × 1,6 s de vida). O teto
de 64 é margem de mais de quatro vezes, e com ela cheia o quadro ainda cabe no orçamento.

⚠️ **A medição varia entre execuções, e vale saber distinguir os dois casos.**

**Ruído do ambiente.** Em oito rodadas seguidas, sete linhas saíram limpas e três marcaram
**exatamente 120 de 240** quadros perdidos — metade certinha, e alternando qual linha era a
atingida. Metade exata não é custo de código: é a janela sendo estrangulada pelo
compositor quando perde foco. Rode pelo menos duas vezes e ignore o pico que muda de
lugar.

**Custo de verdade.** Ele aparece igual em toda rodada. Foi assim que a transição de era
foi pega: **35 a 41 quadros perdidos em três rodadas seguidas**, todos dentro do 1,4 s da
troca. A primeira versão escalava e reposicionava cem rótulos por quadro; agora a grade
inteira vive dentro de um nó e a transição mexe em **um** transform. Depois disso a linha
passou a sair limpa nas rodadas sem ruído.

O sintoma que separa os dois: custo de código repete, ruído de ambiente pula de linha.

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
