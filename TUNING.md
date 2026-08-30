# Tuning

Como ajustar os números do jogo sem abrir um `.gd`.

---

## Onde os números moram

Em `.tres` dentro de `data/`, expostos por `@export` ou por `Resource`. Se você precisou
abrir um script para mudar um número numa sessão de tuning, esse número está no lugar
errado — ver `CONVENCOES.md`, "Números vão para `.tres`".

### Um número que não é de balanço, e mesmo assim mora aqui

`data/raridade.tres` — `intervalo = 900 s` entre duas descobertas Lendárias ou acima.

Ele não muda quanto o jogador produz; muda quanto tempo separa dois momentos raros. No
endgame a chance de tudo o que ainda falta já vale 1, então sem esse intervalo as seis
descobertas do GDD §11 caem no mesmo quadro: seis avisos empilhados não são seis momentos
raros, são um só. A raridade não está na chance, está no **espaço** entre uma e outra — e
espaço é balanceamento como qualquer outro, então mora em `.tres`.

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
| `medir_economia` | curva do prestígio: quando vale provar o Teorema | **existe** |

```bash
godot --headless --path . tools/medir_ritmo.tscn
```

### `medir_economia`

```bash
godot --headless --path . tools/medir_economia.tscn
```

Responde a pergunta que o GDD §18 quer criar: **"faço prestígio agora ou continuo?"**

Em cada ponto ela **bifurca a partida** e simula os dois futuros a partir do mesmo estado —
quanto tempo até a produção dobrar continuando, e quanto tempo até a run nova voltar à
produção de agora prestigiando. O menor dos dois é a resposta certa ali. Onde ficam a menos
de 20% um do outro é a **janela ambígua**, e é ela que faz a pergunta ter dois lados.

Bifurcar só é possível porque o estado inteiro da partida mora no autoload `Jogo`: um
dicionário copia tudo, e devolver é atribuir de volta. Se algum sistema guardasse estado
próprio, esta régua não existiria — é o primeiro retorno concreto daquela regra.

Ela também confere a terceira pergunta da issue #29: se alguma run fica mais lenta que a
anterior, sintoma de árvore mal calibrada.

Demora cerca de dois minutos.

### `medir_quadro`

```bash
godot --path . tools/medir_quadro.tscn --resolution 1920x1080
```

⚠️ **Precisa de janela.** Headless não renderiza, e medir tempo de quadro sem desenhar
mede o nada.

Mede o efeito de letras (issue #22) nas três escalas de produção do GDD §26 mais uma
quarta linha com a piscina de rótulos **saturada** — sem ela o teto seria um número que se
diz medido sem nunca ter sido tocado por uma medição.

⚠️ **Cada linha começa do zero — e isso teve que ser aprendido.** Duas vezes a régua
mentiu por herdar o estado da linha anterior: a era 14 reportou 23 ms que eram dos rótulos
da linha saturada morrendo dentro da amostra, e as linhas depois dela mediram a era 14
achando que mediam a própria. **Ordem de medição é parte da medição.**

Medição depois da caça de custos da issue #30, orçamento de 16,67 ms:

```text
producao/s       rotulos  maquinas media     p95       perdidos
5                14       1        11,2 ms   13,9 ms   0 de 240
500 mil          13       4        11,9 ms   16,3 ms   0 de 240
5e17             14       100      10,9 ms   12,7 ms   0 de 240
SATURADO         64       100       9,4 ms   10,1 ms   0 de 240
ERA 14           14       16       15,7 ms   30,8 ms   77 de 240
```

### Três custos que esta régua achou, e que nenhum teste acharia

**1. `Marcos.verificar()` era O(n²) por quadro.** Ele percorria os noventa marcos chamando
`Array.has()` em cada um, e `has()` é busca linear. Com 66 marcos cruzados isso dava mais
de dois mil comparações de texto **por quadro**. Virou dicionário mais índice do próximo:
um marco por quadro no caso comum.

**2. A troca de era reaplicava estilo em 225 rótulos.** Texto e dois overrides de tema por
rótulo, a cada troca — 675 operações num quadro, e override de tema invalida cache. As
faixas que atravessavam era mediam 30 ms; as que não atravessavam, 8 ms. Agora o estilo só
é reaplicado quando a **metáfora** troca, uma vez por partida.

**3. Glifo que falta na fonte custa mais que o desenho.** A era 14 usava `∑ Ω ◇ ✦` e media
22 ms com dezesseis rótulos, contra 14 ms da era 7 com **seis vezes mais**. Glifo ausente
faz o Godot percorrer a cadeia de fallback a cada desenho. Trocados por glifos que a fonte
monoespaçada tem, a era caiu para 13–16 ms.

⚠️ **A era 14 continua sendo a linha mais cara** e o p95 dela fica acima do orçamento. A
média cabe; os picos não. Fica registrado como o próximo lugar a olhar.

Primeira medição, antes de tudo isso:

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
