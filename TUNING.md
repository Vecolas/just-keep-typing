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

### ⚠️ O instrumento mudou na issue #42, e as tabelas antigas não se comparam com as novas

Duas coisas erradas, e as duas faziam a régua medir a si mesma:

**A régua rodava com o teto de quadros e o vsync do jogador.** Com o limite em 60 a engine
**dorme** o resto de cada quadro: a tabela media relógio de parede, não custo de desenho —
e um sistema que dobrasse de preço não mudaria uma linha enquanto coubesse no orçamento.
Agora ela desliga vsync, teto e modo econômico antes de medir.

**E o instrumento era `Performance.TIME_PROCESS`, que não muda a cada quadro.** Solta a
engine, 240 amostras seguidas saíam **idênticas** — média, p95 e p99 imprimiam o mesmo
número. Pior: com o quadro medido em 1,7 ms ele reportava 57 ms na mesma linha. Hoje o
instrumento é o relógio (`Time.get_ticks_usec()` entre dois quadros), que é o que o jogador
sente e o que o orçamento de 16,67 ms quer dizer. O monitor não voltou nem como coluna de
apoio: número que não pode ser verdade ao lado de um que pode é pior que número nenhum,
porque alguém vai ler os dois.

**Portanto:** os números abaixo não são uma melhora de seis vezes sobre a tabela histórica.
São outra medição. As tabelas antigas ficam registradas como o que eram.

Medição com o instrumento novo (issue #42), orçamento de 16,67 ms:

```text
producao/s       rotulos  maquinas quadro    p95       p99       perdidos
5                5        1        1,617 ms  1,884 ms  1,943 ms  0 de 240
500 mil          6        4        1,980 ms  2,230 ms  2,397 ms  0 de 240
5e17             7        100      1,937 ms  2,230 ms  2,402 ms  0 de 240
SATURADO         64       100      1,960 ms  2,483 ms  2,803 ms  0 de 240
ERA 14           5        16       1,564 ms  1,858 ms  2,462 ms  0 de 240
```

⚠️ **A contagem de rótulos caiu junto, e não é um sistema mais magro.** Com a engine solta
o quadro dura menos de dois milissegundos, e a piscina de letras nasce por **tempo**: em
240 quadros passa menos tempo do que passava a 60 fps. A linha `SATURADO` existe justamente
para o teto continuar sendo medido em vez de suposto.

### O menu parado, e o menu vivo (issue #48)

O menu é a tela que fica aberta atrás de outra coisa por mais tempo que qualquer outra, e é
ali que "animação a 60 fps num menu parado" vira bateria queimada à toa. A régua mede a
**mesma** tela com `reduzir movimento` ligado (nada se mexe) e desligado (gestos, poeira e
estrelas piscando):

```text
                                 quadro    p95       p99       perdidos
MENU PARADO                      0,636 ms  1,313 ms  2,141 ms  0 de 240
MENU VIVO                        0,629 ms  1,368 ms  3,243 ms  0 de 240
```

**O menu vivo custa 0,007 ms de média — ou seja, nada mensurável.** A diferença entre os
dois é menor que a diferença entre duas medições do mesmo estado, exatamente como no áudio.
O p99 sobe um milissegundo, e essa é a linha a olhar se um dia entrar um gesto mais caro.

E o menu inteiro custa **um terço** do que a partida mais barata custa (0,63 ms contra
1,88 ms), o que é esperado: ele não tem produção, nem letras nascendo, nem marcos a
verificar. O que a tabela garante é que os gestos não mudaram isso.

⚠️ **O modo econômico é o outro lado desta conta, e ele não aparece aqui.** Com a janela em
segundo plano, `Config.fps_efetivo()` desce para 10 quadros por segundo — a régua mede com
a janela na frente, de propósito, porque é ali que o custo existe.

### Áudio antes e depois, na mesma era (issue #42)

O som de digitação é uma piscina fixa de tocadores em rodízio e as formas de onda são
construídas uma vez — **nada aloca por som tocado**. A régua mede as duas ordens, porque a
primeira medição depois de uma troca carrega o que a linha anterior deixou:

```text
SOM DESLIGADO 1  6        100      1,776 ms  2,021 ms  2,161 ms  0 de 240
SOM NORMAL 1     5        100      1,705 ms  2,001 ms  2,071 ms  0 de 240
SOM DESLIGADO 2  6        100      1,689 ms  1,986 ms  2,257 ms  0 de 240
SOM NORMAL 2     5        100      1,690 ms  1,892 ms  2,006 ms  0 de 240
```

A diferença entre ligado e desligado (**0,07 ms**) é menor que a diferença entre duas
medições do **mesmo** estado (0,09 ms). O achado é esse: o custo do áudio não é distinguível
do ruído da medição. Se um dia um som passar a alocar por evento, é aqui que aparece.

Medição histórica, com o instrumento antigo (issue #30) — **não comparável com a de cima**:

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

*(Isso valia com o instrumento antigo. Com o relógio, nenhuma linha passa do orçamento —
inclusive a era 14. O que não quer dizer que o custo sumiu: quer dizer que ele nunca foi
medido direito.)*

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

### ⚠️ A segunda sessão (issue #53): a primeira hora não existe

Medição antes e depois de acrescentar 24 upgrades em quatro famílias, mesmo jogador
simulado, mesmo passo:

| marco | antes (20 upgrades) | depois (44) |
|---|---|---|
| `uma_pagina` | 02:27 | 01:46 |
| `um_livro` | 09:01 | 03:55 |
| `a_biblia` | 10:06 | 03:59 |
| `mil_anos_de_humanidade` | 11:07 | 04:07 |
| `todas_as_palavras_possiveis` | 1h26 | 04:38 |

**Os 73 primeiros marcos do Panorama — de 91 — caem em 4 minutos e 7 segundos.**

A caixa da issue pedia que a curva *"não piorasse"*. Ela não piorou: ela **acelerou 2,7×**,
e isso é um problema diferente e maior. A v0.6 se chama *"A primeira hora"* e, medida, a
primeira hora consome três quartos da campanha inteira nos primeiros quatro minutos.

⚠️ **E o defeito não é dos upgrades novos — eles só tornaram visível o que já estava lá.**
Antes de #53 os mesmos 73 marcos caíam em 11 minutos. Onze minutos para três quartos do
Panorama já era a mesma doença; 24 multiplicadores a mais só encurtaram o prazo o
suficiente para ninguém conseguir mais olhar para o outro lado.

⚠️ **Não se conserta mexendo nos upgrades novos.** Tirá-los devolveria os onze minutos, que
também estão errados. O que corre demais é a produção contra a escada de requisitos — o
mesmo diagnóstico da primeira sessão (*"a distância entre eles em magnitude está certa; o
que corre demais é a produção"*), agora com número em cima. É o assunto inteiro da issue
#56, e o número acima é a entrada dela.

⚠️ **E o jogador simulado não é o jogador real** — ele compra no instante exato em que o
saldo fecha. Um humano é mais lento, então 4:07 é o **piso**, não a experiência. O que a
régua prova é a razão entre duas medições, e a razão é 2,7×.

Um efeito colateral que vale anotar: a régua ficou **2,2× mais lenta** (de ~55 s para
2 min 4 s), porque o jogador simulado percorre o catálogo inteiro a cada compra. Com os
60–70 upgrades da v1.0 isso passa de três minutos.

### O estado no fim da v0.7.1

| | v0.6 | v0.7 | v0.7.1 |
|---|---|---|---|
| blocos de 10 min com conteúdo | 1 de 6 | 5 de 6 | **5 de 6** |
| 1º Teorema vale a pena | 00:04:22 | 00:32:55 | **00:30:48** |
| vantagem do perfil ativo | 13% | **27%** ❌ | **12,4%** ✅ |
| avisos ilegíveis | **20%** | 20% | **0%** |
| minutos com a loja vazia | *não medido* | 24 de 30 | **0 de 30** |
| minutos só com vitrine | *não medido* | *não medido* | **1 de 30** |

⚠️ **E o bloco de 30–40 minutos deixou de ser morto** — minutos 31, 32, 34, 35, 39 e 40
passaram a ter acontecimento (issue #74).

**Mas a régua não mostra isso.** A coluna "descobertas" dela conta só a **primeira de cada
categoria**, e a Estranheza é feita de Épicas — categoria que já tinha aparecido aos 13:35.
Para a régua, o bloco continua em zero.

> **Duas ferramentas medindo coisas diferentes, e só uma enxerga essa issue.** Quem for
> avaliar o bloco de 30–40 lê a **sessão observada**, não a régua.

### A produção, por fonte (issue #71)

A régua passou a decompor. No fim de uma corrida normal:

| fonte | tipo | fator |
|---|---|---|
| base do macaco | soma | 1 |
| upgrades: velocidade somada | soma | 81.034 |
| descobertas | soma | 426 |
| upgrades: velocidade local | vezes | 15 |
| teoremas: memória genética | vezes | 2,44 |
| macacos | vezes | 406 |
| **máquina** | vezes | **10⁹** |
| upgrades: global | vezes | 168 |
| prestígio | vezes | 4,15 |

⚠️ **A máquina sozinha vale mais que upgrades e descobertas somados.** É o tipo de coisa que
`producao = 8,4e17` nunca teria dito — e é exatamente por não ter isso que a v0.7 procurou o
multiplicador no lugar errado.

### O combo de volta para a faixa (issue #73)

Um parâmetro, antes e depois. `data/combo.tres` → `teto`: **1,5 → 1,28**.

| perfil | antes | depois |
|---|---|---|
| ativo | 00:27:36 | 00:28:37 |
| **normal** | 00:37:39 | 00:32:41 |
| passivo | 00:41:57 | 00:40:52 |
| **vantagem do ativo** | **27%** ❌ | **12,4%** ✅ |

A decisão `0008` fixou 10–20%, e a #73 apertou para 12–18%. **Dentro.**

⚠️ **E só este número mudou.** Decaimento, carência e ganho por tecla ficaram como estavam:
mexer em dois daria uma medição que não separa os efeitos.

O jogador ativo deve sentir *"minha interação ajuda"*, e não *"se eu parar de clicar, estou
jogando errado"*.

### ⚠️ A SESSÃO OBSERVADA VIU O QUE A RÉGUA NÃO VÊ (issue #64)

`tools/observar.tscn` monta a partida de verdade e conta os botões da loja a cada minuto.
A régua diz **quando** as coisas acontecem; ela diz **o que está na tela**.

Na primeira execução:

```
⚠️ minutos SEM NENHUMA COMPRA POSSIVEL:   24 de 30
```

**A tabela da régua dizia "4 de 6 blocos com conteúdo". A tela dizia que dos minutos 8 ao 26
o jogador não tinha o que decidir.** Marcos caindo não é a mesma coisa que haver algo a
fazer.

#### A faixa estreita entre loja vazia e vitrine

| custo | resultado observado |
|---|---|
| requisito × 0,12 | **loja vazia** — compra-se no instante em que aparece, 24/30 min sem nada |
| requisito × 16,7 | **vitrine** — 4 a 6 itens visíveis, zero alcançáveis em 27/30 min |
| **requisito × 2,5** | aparece caro, fica comprável em um ou dois minutos |

**Botão apagado com preço visível é uma meta; botão nenhum é tela vazia; botão que nunca
acende é uma promessa que a economia não cumpre.** São três coisas diferentes, e nenhuma
régua distingue as três.

Depois do ajuste:

| | |
|---|---|
| minutos com a loja vazia | **0 de 30** ✅ |
| minutos sem nenhuma compra | 5 de 30 |
| minutos sem marco nem descoberta | **11 de 30** ⚠️ |

Registro completo em `docs/playtests/2026-09-18-sessao-observada.md`.

### O estado final da v0.7

| | v0.6 | v0.7 |
|---|---|---|
| distribuição 0–60 min | **76/0/0/1/0/0** | **34/3/7/0/1/6** |
| blocos com conteúdo | **1 de 6** | **5 de 6** |
| 1º Teorema vale a pena | 00:04:22 | **00:32:55** |
| loja vazia | *não era medido* | **0 de 30 min** |

### O resultado da v0.7 até aqui (issues #60, #61 e #62)

Perfil **normal**, régua de campanha, mesma semente:

| até | marcos antes | marcos depois | upgrades antes | upgrades depois |
|---|---|---|---|---|
| 00:10 | **76** | **38** | **44** | **22** |
| 00:20 | 0 | 8 | 0 | 6 |
| 00:30 | 0 | 22 | 0 | 16 |
| 00:40 | 1 | 1 | 0 | 0 |
| 00:50 | 0 | 0 | 0 | 0 |
| 01:00 | 0 | 0 | 0 | 0 |

| | antes | depois |
|---|---|---|
| 1º Teorema disponível | 00:03:43 | **00:27:54** |
| 1º Teorema vale a pena | 00:04:22 | **00:37:39** ✅ dentro de 35–50 |
| prestígios na 1ª hora | 2 | **1** |

**Quatro dos seis blocos deixaram de estar vazios**, contra um antes.

#### Os três perfis, no fim da v0.7

| perfil | distribuição 0–60 min | 1º disponível | vale a pena |
|---|---|---|---|
| ativo | 43 / 7 / 19 / 0 / 0 / 0 | 00:27:06 | **00:27:36** |
| **normal** | 38 / 8 / 22 / 1 / 0 / 0 | 00:27:54 | **00:37:39** ✅ |
| passivo | 38 / 10 / 12 / 8 / 1 / 0 | 00:29:49 | **00:41:57** ✅ |

**Os três chegam ao Teorema**, e os dois que definem o critério caem na faixa de 35–50.

⚠️ **O perfil PASSIVO tem a melhor distribuição dos três** — cinco blocos com conteúdo
contra quatro do normal. Quem joga menos atravessa mais devagar, e por isso encontra mais
coisa pelo caminho. Não é um defeito; é uma leitura que vale ter antes de mexer de novo.

⚠️ **E um critério REGREDIU.** O ativo passou a ser **27% mais rápido** que o normal
(27:36 contra 37:39). Na linha de base ele era 13%, dentro da faixa de 10–20% que a decisão
0008 fixou. A issue #65 avisava que essa propriedade era *"o tipo que uma curva nova quebra
sem avisar"* — e ela quebrou.

⚠️ **E o que NÃO convergiu: o bloco de 40 a 60 minutos continua vazio.** Ver a decisão
`0009` — o motivo é estrutural e a correção esbarra no congelamento de conteúdo.

### ⚠️ MARCO NÃO É BOTÃO DE TUNING (issue #61)

A issue pedia para redistribuir marcos, upgrades e descobertas. **Marco não pode ser
redistribuído.**

O `requisito` de um marco é um **fato sobre o mundo**, e o campo `nota` ao lado existe
exatamente para documentar a conta:

```
requisito = "3.5e6"
titulo    = "A Bíblia"
nota      = "Biblia completa: 783.000 palavras x 4,5 caracteres."
```

Mudar aquele `3.5e6` para `1e20` não redistribui nada — **faz o Panorama mentir**, que é o
contrário do que a decisão 0003 e a issue #51 constroem. Quando cada marco cai é
**consequência** da velocidade da economia, e não uma escolha.

Então o que a #61 redistribuiu foram os **upgrades**, cujo `requisito` e `custo` são números
de balanceamento de verdade.

#### Duas iterações, e a primeira foi longe demais

| | expoente final | fator de custo | resultado |
|---|---|---|---|
| 1ª | 10^26 | 0,35 | forma **certa** (28/5/5/2/1/1) e escala **colapsada**: 28 caracteres em uma hora |
| 2ª | 10^18 | 0,12 | 38/8/22/1/0/0, Teorema aos 37:39 |

A primeira iteração é instrutiva: **a distribuição ficou exatamente no alvo e o jogo parou
de funcionar.** Espalhar upgrades encarece a ignição, e a economia nunca pega. *Forma certa
com escala errada não é meio-caminho — é outro defeito.*

⚠️ **E o espalhamento cego quebrou o upgrade que LIGA o jogo.** `instinto_digitador` ganhou
requisito 20 como qualquer outro da fila — e ele é o interruptor da produção automática
(GDD §3), que tem de estar na loja no primeiro quadro. Mesma família do `mesas_empilhadas`
na #60: **regra geral aplicada sem olhar o que a peça É.**

### ⚠️ O MAIOR MULTIPLICADOR DO JOGO ERAM AS DESCOBERTAS (issue #60)

O suspeito óbvio eram os upgrades: 38 dos 44 eram multiplicadores que compõem.

| fonte | composição |
|---|---|
| `VELOCIDADE_DO_MACACO` | 17 upgrades → ×5.627 |
| `PRODUCAO_GLOBAL` | 21 upgrades → ×15.650.000 |
| `CAPACIDADE` | 5 upgrades → ×112 |
| **descobertas** | **62 → ×1,13 × 10^41** |
| máquinas | escada, ×10^9 no topo (só a atual conta) |

**As descobertas compunham vinte e oito ordens de grandeza acima dos upgrades.**

⚠️ **E a issue #52 criou a maior parte disso** — 46 descobertas novas, quase todas com
`bonus > 1`. Pior: **o portão que eu mesmo escrevi exigia `bonus > 1` de toda descoberta de
papel `BONUS`.** A regra que protegia contra dado esquecido era a mesma que garantia a
composição.

**Separar só os upgrades quase não moveu nada** — o primeiro Teorema foi de 04:22 para
04:01. Foi preciso medir de novo, por fonte, para achar onde o número morava. *O suspeito
óbvio geralmente mente.*

#### A conversão

As descobertas passam a **somar** na base do macaco em vez de multiplicar a produção:
as mesmas 53 somam **+1.665** no lugar de ×10^41. O `.tres` continua guardando o número que
o autor escreveu; a conversão para parcela mora num lugar só, como `(bonus - 1)`.

É o que a decisão 0008 já dizia: *"Descoberta — não aumenta CPS diretamente"*. Ela não
deixou de valer nada; **deixou de multiplicar**.

#### O antes e o depois (perfil normal)

| | antes | depois |
|---|---|---|
| 0–10 min | 76 marcos, 44 upgrades | **51 marcos, 34 upgrades** |
| 10–20 min | 0, 0 | **17, 10** |
| 20–30 min | 0 | 2 |
| 40–50 min | 0 | 1 |
| 1º Teorema vale a pena | 04:22 | **09:36** |

**Quatro dos seis blocos deixaram de estar vazios**, e isso é a issue #60 sozinha — antes de
qualquer redistribuição (#61) ou de mover o prestígio (#62).

### A linha de base dos três perfis (issues #59 e #63)

Régua de campanha — com eventos, automação e prestígio —, mesma semente nos três:

| perfil | marcos em 10 min | upgrades | 1º Teorema | prestígios na 1ª h |
|---|---|---|---|---|
| ativo | 76 | 44 | 00:03:47 | 3 |
| **normal** | 76 | 44 | **00:04:22** | 2 |
| passivo | 76 | 44 | 00:05:14 | 2 |

**O problema é igual nos três.** A distância entre o ativo e o passivo é de **87 segundos**
numa campanha de 24 horas — ou seja, **a campanha não depende de jogar de uma maneira
específica**. O defeito é estrutural, e não comportamental.

⚠️ **E um critério da #65 já passa:** o ativo é **13% mais rápido** que o normal, dentro da
faixa de 10–20% — digitar ajuda sem definir a run. Isso vale ser re-medido **depois** do
rebalanceamento, porque é exatamente o tipo de propriedade que uma curva nova pode quebrar.

⚠️ **O prestígio agora acontece, e acontece cedo demais**: três vezes na primeira hora no
perfil ativo, a primeira aos 3:47. O reset é a virada da campanha, e ele está virando antes
de haver campanha.

### ⚠️ O INSTRUMENTO MUDOU NA ISSUE #59 (3) — a régua virou campanha

Até a v0.6 a `medir_ritmo` **não executava eventos nem automação**, e o jogador simulado
**nunca prestigiava**. Ela media um pedaço do jogo e chamava aquilo de campanha.

| | antes | agora |
|---|---|---|
| `Eventos.tique` | ❌ não rodava | ✅ |
| `Automacao.tique` | ❌ não rodava | ✅ |
| compra de automação | ❌ | ✅ |
| prestigiar | ❌ **nunca** | ✅ quando dobra a produção |
| seed de `Eventos.gerador` | — | ✅ |

As três coisas que faltavam são justamente as que mexem no **ritmo**: um evento dobra a
produção por trinta segundos, uma automação compra macaco enquanto o jogador olha para
outro lado, e o prestígio reinicia a run com multiplicador.

⚠️ **Tabela medida antes desta issue não se compara com as novas.** É a terceira mudança de
instrumento do projeto (as outras: `medir_quadro` na #42, o jogador que passou a digitar na
#56).

⚠️ **E não existe uma `medir_ritmo_v1` guardada ao lado.** Ver `CONVENCOES.md`, *"Uma régua
por assunto"*: o histórico mora aqui, que é onde ele não pode ser executado por engano.

#### O que o portão novo achou junto

A regra "todo ponto de entrada semeia" passou a cobrar **os dois** geradores. No primeiro
laço ela reprovou a **fumaça**: a semente das descobertas estava lá desde a #56, a de
eventos não.

**É exatamente a forma que "metade do conserto" toma** — e ela é pior que nenhum conserto,
porque agora existe uma linha de semente no arquivo dando a impressão de que o assunto foi
resolvido.

### ⚠️ A RÉGUA NÃO ERA DETERMINÍSTICA, e o cabeçalho dela afirmava que era

`Descobertas.gerador` chama `randomize()` no `_ready`, e **descoberta dá bônus de
produção**. A `medir_ritmo` nunca semeava esse gerador: duas corridas **do mesmo commit**
sorteavam em instantes diferentes, a produção divergia, e a curva inteira andava junto.

Medido: **35 segundos** de diferença no primeiro Teorema entre duas corridas idênticas.

E o cabeçalho da régua dizia, desde sempre:

> *"a régua precisa ser ESTÁVEL, para que a diferença entre duas medições seja a mudança no
> `.tres` e não o humor de quem jogou."*

A suíte e a ferramenta de captura **já semeavam**. As réguas, não. Uma verdade por assunto,
e este assunto tinha duas — o tipo de defeito que só aparece quando alguém roda a mesma
coisa duas vezes e compara, que é exatamente o que ninguém faz com uma régua.

Corrigido: `SEMENTE_DO_SORTEIO = 1` em `medir_ritmo` e em `medir_economia`, com o mesmo
número nas duas — semente diferente por ferramenta daria tabelas que não se comparam entre
si, que é metade do problema de volta. Conferido: **duas corridas seguidas, byte a byte
idênticas.**

#### O que isso invalida das medições anteriores

| afirmação | sobrevive? |
|---|---|
| issue #53: os 73 primeiros marcos caem em ~4 min contra ~11 min antes | **sim** — 2,7× está muito acima do ruído de ~35 s |
| issue #54: com e sem combo terminam no mesmo lugar (0,1% em 24 h) | **sim** — é uma medida de escala grande |
| issue #54: *"o combo custa +37 s por o jogador parar de digitar antes"* | **NÃO** — 37 s é da ordem do ruído, e a conclusão foi construída em cima dele |

⚠️ **A terceira linha é uma retratação, e ela vale a pena ler.** Aquela análise era
plausível, tinha mecanismo, explicava o sinal — e o número que a sustentava era ruído. O
modelo do jogador simulado **estava mesmo errado** e o conserto dele continua certo pelos
próprios méritos; o que não se sustentava era a medição que eu usei como prova. Número
plausível com mecanismo plausível é exatamente a forma que um erro toma quando ninguém
conferiu o instrumento.

Com a semente fixa, a comparação limpa é: **o combo adianta o primeiro prestígio em 27
segundos** (00:03:42 contra 00:04:08). Aceleração, sem inversão nenhuma.

### A tabela da primeira hora (issue #56)

`medir_ritmo` passou a reportar **marco, upgrade, descoberta e primeiro Teorema na mesma
corrida**. Até aqui ela media só marco — e a versão se chama *"A primeira hora"*: metade do
que acontece nela era invisível para quem ajusta os números.

```
ate              marcos   upgrades  descobertas
00:10:00             76         44            5
00:20:00              0          0            0
00:30:00              0          0            0
00:40:00              1          0            0
00:50:00              0          0            0
01:00:00              0          0            0
```

**A primeira hora é quatro minutos seguidos de cinquenta e seis minutos de silêncio.**

E dentro dos quatro minutos, **35 dos 44 upgrades caem nos últimos vinte e dois segundos**,
entre 00:03:21 e 00:03:43. A família *O Conhecimento* inteira — nove upgrades — cabe em
dezoito.

Com a semente fixa (ver a correção acima):

| | com combo | sem combo |
|---|---|---|
| primeiro Teorema disponível | 00:03:38 | 00:04:05 |
| primeiro Teorema vale a pena | **00:03:42** | **00:04:08** |
| 1ª Impossível | 01:48:46 | 01:48:46 |
| 1ª Paradoxal | 03:33:46 | 03:33:46 |

**O combo adianta o primeiro prestígio em 27 segundos, e não muda mais nada depois** — as
duas corridas chegam à primeira Impossível e à primeira Paradoxal no mesmo segundo. É
exatamente a exigência da issue #54: acelera, e não é via nenhuma.

⚠️ **A leitura disso é uma decisão, e ela está escrita**: `docs/decisoes/0007-a-primeira-hora-mede-quatro-minutos.md`.
Resumo: não está bom, não é defeito das issues #52 e #53 (antes delas os mesmos marcos
caíam em onze minutos — a mesma doença com prazo mais longo), e não se conserta com tuning
pontual. A produção cresce por multiplicadores que **compõem**; os custos crescem por
escadas escolhidas à mão. Duas curvas de naturezas diferentes se cruzam **uma vez**, e
depois do cruzamento a produção atravessa todo limite restante em segundos.

### ⚠️ O INSTRUMENTO MUDOU NA ISSUE #56 (2) — o jogador simulado passou a digitar

Até a issue #56, o jogador simulado **parava de digitar no instante em que a produção
automática acendia**. Nos primeiros minutos, clicar a 4/s rende muito mais que a automação
recém-ligada — então o modelo desistia de graça, e media a própria ingenuidade.

Foi o que produziu o resultado invertido da issue #54: o combo, por fazer a primeira compra
chegar **um segundo antes**, aparecia como **37 segundos de atraso** na campanha inteira.

A regra nova não tem número mágico e não precisa de nenhum:

> **ele digita enquanto digitar render mais do que esperar.**

É o mesmo critério da "compra ótima ingênua" aplicado à mão, e ele se desliga sozinho
quando o jogador vira administrador — que é exatamente o arco que o plano da v0.6 descreve.

**Tabela medida antes desta mudança não se compara com as novas**, pela mesma razão da
mudança de instrumento da issue #42: o que mudou não foi o jogo, foi a régua.

### O combo com e sem (issue #54), e o que ele revelou sobre a própria régua

`godot --headless --path . tools/medir_ritmo.tscn -- sem_combo=1` zera o combo depois de
cada clique: mesma corrida, mesmo jogador, sem o efeito.

| marco | sem combo | com combo |
|---|---|---|
| `seu_nome` | 00:07 | **00:06** |
| `um_soneto` | 01:18 | **01:17** |
| `uma_pagina` | **01:51** | 01:56 |
| `um_livro` | **03:30** | 04:06 |
| `voce_nao_produz_mais_texto` | **4h18** | 4h19 |
| fim de 24 h | 7,56e68 | 7,55e68 |

**Os dois terminam no mesmo lugar.** Os mesmos 80 marcos caem nas duas corridas, e a
diferença ao fim de 24 horas é de 0,1% — o que prova, com número, a exigência da issue: o
combo **acelera**, e não é via nenhuma. Quem não puder digitar chega exatamente aonde
chega quem digita.

⚠️ **Mas o sinal inverte em 1 min 30, e o motivo não é o combo — é o jogador simulado.**
Ele para de digitar no instante em que a produção automática acende, e o combo faz esse
instante chegar **um segundo antes**. Nos primeiros minutos, clicar a 4/s rende mais que a
produção automática recém-ligada: desistir um segundo mais cedo custa um segundo de
clique, e reaver isso leva 37 segundos de juros compostos.

Ou seja: **os +37 s não medem o combo, medem a ingenuidade do modelo.** Um humano continua
digitando depois da primeira compra — é justamente para isso que o combo existe.

⚠️ **Nenhuma régua acusa isso sozinha.** Ela devolveu uma tabela perfeitamente consistente
nas duas corridas; o que não batia era a HISTÓRIA que a tabela contava. Só a leitura pega
"este número está certo e mesmo assim não quer dizer o que parece".

O modelo do jogador simulado é assunto da issue #56, que precisa dele correto para medir a
primeira hora. Enquanto isso, as duas linhas ficam escritas na saída da régua:

```
jogador simulado: compra otima ingenua (upgrade assim que da, depois macaco maximo)
⚠️ o jogador simulado nao digita depois do Instinto Digitador
```

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
