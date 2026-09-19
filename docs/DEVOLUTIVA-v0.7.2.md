# Devolutiva da v0.7.2 — a interface conta a progressão

Documento de consulta. A v0.7.1 fez o jogador **enxergar o que acontece**; esta versão fez a
interface **dizer o que aquilo significa**.

⚠️ **O número da versão é proposta, e não decisão.** Esta branch nasceu de um plano de UX e
não de uma linha do `PLANO.md` — o recorte é seu. Se ela for outra coisa, renomeie o arquivo.

Se você só for ler uma seção, leia a **§4** — ela é a lição que sobrevive aos números.

---

## 1. O placar

| | |
|---|---|
| plano de UX | **20 seções**, todas endereçadas (2 recusadas com motivo — §7) |
| defeitos achados **no `main`** | **4**, todos consertados aqui |
| defeitos achados **na própria implementação** | **11** |
| peças novas de código | 5 · `Alcance`, `VitrineDeUpgrades`, `CartaoDeUpgrade`, `BannerDeDestaque`, `teste_vitrine` |
| portões novos ou ampliados | **5** |
| decisões registradas | `0011` e `0012` |
| suíte | **7.018 afirmações em 28 suítes** — verde (era 6.761 em 27) |
| fumaça · CI · capturas | verdes |
| commits | 11, num merge `--no-ff` |
| diff | 49 arquivos, **+2.937 / −264** |
| assets novos gerados | **0** |

**Conteúdo do jogo: inalterado.** 91 marcos, 67 descobertas, 44 upgrades — `git diff` em
`data/` é vazio. O congelamento da decisão `0008` valeu do começo ao fim.

**Economia: inalterada.** Nenhum `.tres` de balanceamento foi tocado, e a regra da v0.7.1
("esta versão não mexe na economia") continuou valendo.

---

## 2. O que mudou na tela

| Onde | Antes | Agora |
|---|---|---|
| **loja de upgrades** | `Dedos Mais Ágeis — 124`, o resto no tooltip | cartão com nome, descrição, **efeito em português** e custo — tudo visível |
| **o que vem depois** | não existia na tela | seção `PRÓXIMAS MELHORIAS`, 4 itens, ordenados por requisito, com quanto falta |
| **descoberta** | linha de rodapé, 2,2 s, disputando com o autosave | **banner no topo**, 3,5 s a 7,0 s conforme a raridade |
| **coluna da esquerda** | 6 rótulos empilhados com o mesmo peso | 4 blocos com moldura, e uma barra de progresso para o próximo marco |
| **centro** | ASCII, com o macaco em 3 linhas de texto | o macaco e a máquina de escrever — as mesmas peças do menu |
| **sala e máquina** | só o preço | o preço **e o que elas entregam** |
| **prestígio** | nenhuma linha na tela | banner próprio, em cada um dos dois |

### A frase que resume as duas colunas

> **Preço não é decisão. Decisão é preço + o que aquilo faz + o que vem depois.**

A coluna da direita tinha 44 upgrades com descrição escrita no banco de dados, e o jogador
via preço. É a mesma família da v0.7.1: **conteúdo que existe e o jogador não consegue
consumir não é polimento — é conteúdo inexistente** (decisão `0010`).

---

## 3. Quatro defeitos que já estavam no `main`

Nenhum dos quatro dava erro. Nenhum dos quatro era pego por portão — e o quarto era
**coberto** por um.

### 3.1 O primeiro aviso de uma fila ociosa nunca era desenhado

A HUD repintava o aviso quando `FilaDeAvisos.tique()` devolvia `true`. E o tique **não
devolve `true` na primeira troca**: com a fila vazia, `acrescentar()` mostra o aviso na hora,
sem passar por tique nenhum.

```text
aviso chega com a fila vazia  →  mostrado na fila, tique devolve false  →  tela nunca pinta
aviso chega ATRÁS de outro    →  o anterior expira, tique devolve true  →  tela pinta
```

**Só apareciam os avisos que chegavam atrás de outro.** O aviso ficava a duração inteira dele
na fila, invisível, e saía.

⚠️ **E ele sobreviveu à issue #69 inteira** — a issue que existia *exatamente* para medir
quantos avisos o jogador não conseguia ler. A régua simula `FilaDeAvisos`, e a fila estava
certa: o defeito morava entre a fila e o rótulo.

**Quem acusou foi a captura do banner:** a caixa apareceu na tela, com moldura, e vazia por
dentro.

### 3.2 Upgrade recém-desbloqueado não aparecia até a próxima compra

`_montar_upgrades()` era chamado em `upgrade_comprado`, `idioma_mudou` e `interface_mudou`.
Cruzar um requisito não estava na lista. Numa coluna cujo assunto é *"o que vem depois"*,
isso era o próprio assunto quebrado.

O conserto compara **um `Grande` por quadro** contra o menor requisito pendente, e não varre
os 44 upgrades.

### 3.3 Três das quatro unidades de era nunca traduziram

O portão de texto varria `nome`, `descricao`, `titulo` e `texto` dos `.tres`. O campo
`unidade` — o nome que a era dá à coisa que o jogador acumula, escrito no título da coluna da
loja desde a issue #30 — **não estava na lista**.

```text
macacos       sem linha no CSV   →  "MACACOS" numa tela em inglês
simulações    sem linha no CSV
universos     sem linha no CSV
possibilidades           ✅       →  a única que traduzia
```

⚠️ **Item que fica fora da lista some da conta, e sumir é pior que reprovar.** A varredura
percorria "o que estava na lista" e nunca acusou o que nunca entrou nela. Quem acusou foi uma
captura em inglês, meses depois.

### 3.4 A dívida cobria duas réguas com uma justificativa falsa

`medir_quadro.gd` e `gerar_galeria.gd` estavam em `SEM_SORTEIO_AINDA` — a lista de quem **não
precisa** fixar a semente do sorteio de descobertas. A justificativa escrita ao lado dos dois
nomes era *"não produzem caractere"*.

**Era falsa.** As duas montam a cena principal, e a Partida tica `Economia.acumular` a cada
quadro: elas produzem caractere sem escrever uma linha de Economia.

E o detector do portão **concordava com a justificativa**, porque media o lugar errado:

```gdscript
var produz := texto.contains("Economia.digitar") or texto.contains("Economia.acumular")
```

Ele procurava a chamada **direta**, no texto do próprio arquivo. Nenhuma das duas a tem.

```text
gerar_galeria   14 fotos de era com uma descoberta aleatória por cima, diferente a cada geração
medir_quadro    descoberta muda a produção, produção muda quantas letras nascem, letras mudam o quadro
```

O conserto foi triplo: as duas **semeiam**, as duas **saíram da lista** (que ficou vazia — e
esse é o estado certo), e o detector passou a contar **montar a cena principal** como produzir
caractere.

> **O detector que mede o lugar errado aprova a própria dívida.**

⚠️ **E é por isso que a tabela de quadro desta versão é a primeira que se compara consigo
mesma:** duas corridas seguidas do mesmo commit deram 3,562 / 3,536 ms na primeira linha. A
variação que sobrou é relógio de parede.

---

## 4. A lição que vale mais que os números

### ⚠️ `PASSOU` não significa que a tela funciona

O momento mais instrutivo desta versão tem quatro linhas:

```text
ERROR: Node not found: "%EspacoFuturos" (relative to ".../HUD").
SCRIPT ERROR: Invalid assignment of property 'visible' on a base object of type 'null'.
  ...
PASSOU (6800 afirmacoes em 27 suites)
```

**A HUD estava lançando erro a cada montagem, e a suíte imprimia `PASSOU`.** Nenhuma
afirmação olhava aquilo: as suítes afirmam lógica, e o que quebrou foi montagem.

O que pegou foi ler o `stderr` — não o código de saída, não o resumo. É a mesma armadilha que
a `CONVENCOES.md` já descreve para `exit 0`, um nível acima: **o resumo verde de uma suíte é
tão pouco confiável quanto um `exit 0`, se ninguém olhar o que ela cuspiu pelo caminho.**

### ⚠️ A régua que mede a tela é a captura, e ela pagou três vezes

Três defeitos de layout, os três invisíveis para qualquer suíte, os três achados olhando uma
foto parada:

| # | o que a foto mostrou | a causa |
|---|---|---|
| 1 | banner com moldura e **vazio por dentro** | o defeito 3.1, que estava no `main` |
| 2 | banner **cobrindo a coluna da direita** | âncoras fracionárias (22%–78%) sobre colunas de largura **fixa** (360 px e 440 px) — a proporção entre elas muda a cada resolução |
| 3 | banner com **mil pixels de altura**, cobrindo o macaco | `size.x = ...` no Godot lê o `Vector2` inteiro e **preserva o y** — e o y inicial era o mínimo calculado com 40 px de largura, onde o autowrap quebrava a frase em quarenta linhas |

O terceiro é o mais barato de cometer: `size.x = largura` **parece** mexer só na largura.
`Control` cresce sozinho até o mínimo e **nunca encolhe sozinho**, então o valor errado ficou.

### ⚠️ A régua de quadro pegou uma regressão minha, e desfez um cache meu

```text
histórico (issue #42)        1,6 – 2,0 ms
primeira versão desta HUD    4,0 ms       ← regressão
depois do conserto           3,5 ms
menu (controle, não mudou)   0,64 → 0,73  ← a máquina é comparável
```

⚠️ **O controle é a linha que torna as outras três legíveis.** Sem o menu — que não mudou —
"3,5 contra 1,9" poderia ser a máquina, a engine, o dia. Com ele, o aumento é da tela nova.

A causa: **cada cartão chamava `add_theme_stylebox_override()` todo quadro.** Cada chamada
aloca um `StyleBoxFlat` novo **e** invalida o cache de tema do nó. É exatamente o preço que a
cena das eras já tinha pagado com 675 overrides num quadro (`TUNING.md`), chegando por outra
porta — e a lição anterior não me protegeu, porque eu não reconheci a forma.

E a régua fez o serviço nas **duas direções**:

> A tentativa seguinte guardou o texto de três rótulos que quase nunca mudam. **A medição não
> mudou em nada mensurável, e o cache foi desfeito.** Cache sem motivo medido é o que a
> `CONVENCOES.md` proíbe — e eu tinha acabado de escrever o comentário explicando o motivo
> que a medição depois não confirmou.

### ⚠️ Uma afirmação que passava com a regra certa **e com a errada**

O portão dizia que os futuros vêm ordenados por requisito. Sabotei a ordenação para `custo`:

```text
vitrine e alcance    148 afirmacoes, 0 falhas     ← a sabotagem passou
```

**No catálogo de hoje, custo e requisito sobem juntos.** Nenhuma afirmação sobre o dado real
consegue distinguir as duas regras. A correção foi dar **controle** ao portão: uma lista
sintética de dois upgrades em que as duas ordens são **opostas** (um caro que desbloqueia já,
um barato que desbloqueia longe).

> **Régua que nunca reprova é carimbo — e o meu tinha 148 afirmações verdes.**

### ⚠️ Constante que muda de casa quebra a régua, e a suíte não vê

Movi `PERTO_O_BASTANTE` da `hud.gd` para a classe `Alcance`. `tools/observar.gd` lia aquela
constante com `preload`. Resultado: **7.018 afirmações verdes, CI verde, e a régua não
compilava.** Só falhou quando eu a rodei à mão.

E esse é o pior tipo de quebra: **régua não é rodada toda hora — ela é rodada no dia em que
alguém precisa decidir um número.** O conserto chegaria no pior momento possível.

A suíte zero passou a varrer `tools/` (§6). A pasta das próprias suítes fica de fora, e por um
motivo medido: carregar `runner.gd` com `CACHE_MODE_IGNORE` **enquanto ele executa** não deu
erro — o runner simplesmente parou de terminar, e o comando estourou em 7 minutos.

---

## 5. O que a implementação encontrou em si mesma

Onze defeitos meus, e a coluna da direita é a que interessa: **o que teria acontecido se
ninguém tivesse olhado.**

| # | defeito | quem pegou | se passasse |
|---|---|---|---|
| 1 | `%EspacoFuturos` sem nome único | `stderr`, com a suíte verde | erro em toda montagem da HUD |
| 2 | banner vazio | captura | descoberta nenhuma seria lida |
| 3 | banner sobre a coluna da direita | captura | topo da loja coberto por 7 s |
| 4 | banner com 1000 px de altura | captura | o macaco sumia atrás dele |
| 5 | `StyleBox` por quadro | `medir_quadro` | 2× no tempo de quadro, para sempre |
| 6 | cache sem ganho | `medir_quadro` | complexidade paga sem retorno |
| 7 | `observar.gd` sem compilar | rodar a régua | régua quebrada até a próxima sessão de tuning |
| 8 | afirmação de ordem sem controle | sabotagem deliberada | a regra poderia inverter em silêncio |
| 9 | 14 fotos de era com banner aleatório | olhar o diff da galeria | galeria não determinística |
| 10 | galeria carregando slot velho | olhar a foto da era 1 | era 1 com 334 mil no saldo e 9 caracteres no contador |
| 11 | varredura travando o runner | o comando não terminar | a suíte pararia de rodar |

⚠️ **Cinco dos onze só foram pegos porque eu sabotei o código de propósito para ver o portão
morder.** Os portões novos foram alimentados com um caso que **deve** reprovar — e um deles
não reprovou (o #8).

---

## 6. Os portões, antes e depois

| portão | antes | depois |
|---|---|---|
| `teste_scripts` | varria `src/` | varre `src/` **e `tools/`** — 75 afirmações |
| `teste_texto` | 4 campos de `.tres` | **5** — `unidade` entrou |
| `teste_descobertas` | detector procurava a chamada direta de Economia | conta **montar a cena principal** como produzir caractere |
| `teste_fila_de_avisos` | 46 afirmações | **80** — faixa, duração por raridade, carga extra, registro unificado |
| `teste_vitrine` | não existia | **148** afirmações — o efeito de cada tipo, a partição do catálogo, os três estados |
| `observar` | media **uma** faixa | mede **as duas**, com o piso de cada uma vindo de constante |
| galeria | 16 fotos | **17** — o banner entrou, e a geração virou determinística |
| CI | 13 capturas | **15** — `banner` em português e em inglês |

### O que as medições dizem hoje

```text
observar, 30 minutos, perfil padrão
  rodapé -- avisos que a fila entregou:         41 de 42
  rodapé -- que não ficaram os 1,6 s mínimos:   0  (0%)
  banner -- avisos que a fila entregou:         36 de 37
  banner -- que não ficaram os 3,5 s mínimos:   0  (0%)
```

**Trinta e sete descobertas couberam no banner a 3,5–7 s cada, sem cortar nenhuma, e sem
atrasar um único aviso do rodapé.** A referência histórica é a issue #69: **16 de 82 (20%)**
apagados antes do tempo de leitura.

⚠️ **E isso não desmente a #69, que escreveu "a solução não é aumentar a duração".** Ela
estava certa: dentro de **uma** fila, mais tempo atrasa todo mundo atrás. Prioridade responde
*quem vem primeiro*; ela nunca respondeu *quanto tempo cada um precisa*. Com duas filas, as
duas perguntas cabem.

---

## 7. O que eu recusei do plano, e por quê

### 7.1 O painel de detalhe do upgrade (§7.2 e §7.3 do plano)

O plano previa lista curta + painel de detalhe embaixo, para o caso de existirem **duas**
descrições: uma curta na lista e uma longa no detalhe.

`DadosUpgrade` tem **uma** (`descricao`). O painel mostraria exatamente o mesmo texto do
cartão — duas fontes para a mesma verdade, sem uma linha de informação nova, e mais um clique
para chegar nela.

O próprio plano lista isso como "Opção A — card com descrição embutida … **mais
transparente**". Foi a escolhida. **Se um dia existir `descricao_longa`, o painel volta a
fazer sentido — e aí ele é uma mudança de dado, não de tela.**

### 7.2 O lote de assets do PixelLab (§10 a §13 do plano)

O plano pedia um lote novo e grande: painéis, botões, molduras, cartões, banners, ícones e um
cenário central. **Nenhuma peça nova foi gerada**, e o motivo cabe numa tabela:

| o que a interface precisava | o que ela usa | por quê |
|---|---|---|
| macaco e máquina no centro | `macaco.png`, `maquina.png` | são **dois**, fixos, para as catorze eras |
| ícone por família de upgrade | banana, engrenagem, papel, infinito | quatro famílias, quatro ícones que **já significam isso** |
| moldura de painel, cartão e banner | `Tema.painel()`, em código | moldura não é arte por conteúdo |

⚠️ **Pedir um segundo conjunto para o mesmo significado é o erro caro.** Duas famílias de
ícones para "a máquina" divergem no próximo lote, e *"isso não parece do mesmo jogo"* é
exatamente o que nenhuma medição pega (`ARTE.md` §17.11).

**O que a §12 e a §13 do plano pediam — o briefing — foi entregue como briefing**, em
`docs/ASSETS.md`: a ficha da única peça que uma arte faria melhor que o `Theme` (a moldura do
banner), com tamanho, escala, o que a separa das vizinhas e o que a cobre.

⚠️ **Se você quiser o lote mesmo assim, ele é uma sessão à parte** — e a decisão é sua, não
minha. O que eu recuso é gerar quarenta peças sem você ter visto a primeira.

### 7.3 O que eu estendi sem o plano pedir

- **o prestígio ganhou aviso** — os dois maiores acontecimentos do jogo não produziam uma
  linha na tela
- **a galeria virou determinística** — semente fixa, fila limpa e slots apagados
- **`tools/` entrou na varredura de scripts** — porque a minha própria mudança quebrou uma
  régua em silêncio

---

## 8. A decisão de arte, e por que ela precisou de um documento

A decisão `0006` dizia, com todas as letras: **tipografia na partida**. E a razão dela era
precisa — catorze eras não podem custar um asset por era.

O que ela **não** separava: a partida tem duas coisas diferentes no centro da tela.

| o que é | como se comporta | como se desenha |
|---|---|---|
| a **grade** de fundo | multiplica por era, encolhe com a câmera, vai de 1 a 225 cópias | ASCII, como sempre |
| a **máquina da frente** e o **macaco** | são **dois**, de tamanho **fixo**, em **todas** as eras | pixel art |

O `eras.gd` já dizia isso desde a issue #26: *"a máquina da frente NÃO encolhe junto com as
outras — ela fica no tamanho de sempre, e o que muda atrás dela é o mundo"*. O custo que a
`0006` recusou era "um asset por era"; estes são **dois PNGs para o jogo inteiro**, e os dois
já existiam.

**Cânone que contradiz a prática é pior que cânone ausente**, então a `0011` existe. Ela diz
o que a `0006` não alcançava, e registra o que isso custa — inclusive o ponto cego:

⚠️ **O recurso da ASCII no centro não é exercitado por portão nenhum.** O disco tem os dois
arquivos, então aquele caminho nunca roda no CI. Está declarado.

---

## 9. A dívida, hoje

### De produto

| | |
|---|---|
| **leitura visual continua sem régua** | os 3 defeitos de layout saíram de **olhar a foto**, com a suíte verde |
| **ninguém jogou a versão nova** | a #70 continua aberta, e agora com mais tela para olhar |
| **o bloco de 30–40 min** | intocado — decisão sua, três saídas em `0009` |
| **a galeria do menu** | `menu.png` e `arquivos.png` continuam **não determinísticos** (gestos aleatórios). Foram revertidos de propósito nesta branch: o menu não mudou |

### Declarada no código

| lista | conteúdo | mudou? |
|---|---|---|
| `SEM_FONTE_AINDA` | `Musica`, `Ambiente` | não |
| `SEM_SISTEMA_AINDA` | `animacoes_de_numero`, `shake` | não |
| `SEM_SORTEIO_AINDA` | *(vazia)* | ⚠️ **as duas saíram** — a justificativa delas era falsa (§3.4) |
| `SEM_VARRER` (novo) | `res://tools/testes` | com o motivo escrito ao lado |

### O que esta versão NÃO prova

- **que a tela ficou boa.** Ela prova que o texto cabe em duas línguas, em três escalas de
  interface, e que o quadro cabe no orçamento. Bonito e legível são leitura humana
- **que o banner tem a duração certa.** Prova que **nenhum** aviso é cortado. Se 7 s é muito
  ou pouco para ler três linhas, quem responde é quem joga
- **que quatro é o número certo de "próximas melhorias".** É limite de design, escolhido e
  escrito, não medido

---

## 10. Se você só for fazer duas coisas

1. **Abra a galeria e olhe o diff das 15 fotos.** É a única régua que existe para o que esta
   versão mudou — e é exatamente por isso que o banner ganhou foto própria: ele some em
   segundos, e nenhuma outra captura o pega.

2. **Decida o lote de assets.** Eu entreguei a interface inteira com zero peças novas e
   deixei a ficha da única que faria diferença. Se você quiser o lote do plano, ele é uma
   sessão com você olhando cada peça — não um pedido de quarenta de uma vez.

---

## 11. Onde procurar o quê

| assunto | arquivo |
|---|---|
| o macaco na partida, e por que nenhum asset novo | `docs/decisoes/0011-o-macaco-entra-na-partida.md` |
| as quatro decisões da reforma, e os três defeitos do `main` | `docs/decisoes/0012-o-jogador-le-a-loja-sem-o-mouse.md` |
| o quadro medido, e as duas faixas de aviso | `TUNING.md`, seções "A reforma de interface" |
| a ficha da moldura do banner, se um dia ela for pedida | `docs/ASSETS.md` |
| a linha que separa a grade das duas peças fixas | `docs/ARTE.md` §7 |
| a ficha do banner, para quem for desenhar ou mexer | `docs/ARTE.md` §9 |
| o campo de texto novo num `.tres` | `CONVENCOES.md`, "Idioma" |
| o que a loja mostra | `src/ui/vitrine_de_upgrades.gd` |
| a devolutiva da versão anterior | `docs/DEVOLUTIVA-v0.7.md` |
