# Entrega da v0.5 — relatório completo

Este documento é a **devolutiva** das issues #39 a #49 (menu, arquivos, configurações,
áudio, acessibilidade, arte e polimento). Ele existe para consulta: o que foi feito, **por
que** foi feito assim, o que quebrou no caminho, o que ficou provado e — principalmente —
**o que não ficou**.

Quando ele discordar do código, o código ganha e este texto se atualiza.

- **Escopo**: issues #39–#49, a partir do merge da #38 (`4561994`) até a tag `v0.5`
- **Tamanho**: 122 arquivos, +7.676 / −622 linhas
- **Suíte**: 3.967 afirmações em 23 suítes, verde
- **Fumaça**: verde, incluindo o aceite do §48 de ponta a ponta
- **Estado do `main`**: verde em cada um dos onze merges

---

## 1. Índice do que mudou, por issue

| Issue | Título | O que entrou | Provado por |
|---|---|---|---|
| #39 | Menu: as cinco opções e o CONTINUAR | Cinco opções, resumo do CONTINUAR lido do metadado, navegação sem mouse, classe `Relogio`, `TelaSobreposta`, tela de Créditos | fumaça + `teste_relogio` |
| #40 | Arquivos: criar, escolher e excluir | Cartão por slot com três destaques, criação com nome temático, exclusão em dois passos + pressão, `BotaoDeSegurar`, `NomesDeManuscrito` | fumaça + `teste_arquivos` |
| #41 | Configurações em abas | Tabela de campos com aba/tipo/efeito, cinco abas, quatro opções novas em GERAL, três em VÍDEO, campo de slot removido | `teste_config` (352 afirmações) |
| #42 | Áudio: cinco barramentos | Autoload `Audio`, ondas sintetizadas, CLACK com teto constante, mute no zero | `teste_audio` + `medir_quadro` |
| #43 | Interface e Acessibilidade | Escala de interface e de texto, alto contraste, três formatos numéricos, reduzir movimento/flashes, raridade com símbolo | `teste_acessibilidade` + `teste_formatador` + fumaça |
| #44 | Pixel art: mudar o `ARTE.md` | Cânone reescrito (§7 e §16), decisão `0006`, consequência de resolução propagada | decisão escrita + comentário na #34 |
| #45 | Os assets do menu | `docs/ASSETS.md` (briefing), 14 peças em `assets/menu/`, `AssetsDoMenu` | `teste_assets` |
| #46 | O menu ganha a mesa | `CenarioDoMenu`, painel de papel, botões de placa, fonte serifada de título, ∞ nas estrelas | capturas + fumaça |
| #47 | Abertura datilografada | Cena `Abertura`, pulo de quem já viu, `ja_viu_abertura` no `Config` | fumaça (os dois lados) |
| #48 | O menu vivo e a transição | `GestosDoMenu`, poeira, estrelas piscando, aproximação da máquina | `medir_quadro` + fumaça |
| #49 | Polimento e o caminho inteiro | Easter egg da tecla, frases raras, caminho do §48 na fumaça | fumaça (aceite da versão) |

---

## 2. Arquitetura — o que passou a existir

### Autoloads

Um autoload novo, e a **posição dele importa**:

| Ordem | Nome | Papel | Por que nessa posição |
|---|---|---|---|
| 11 | `Audio` | Cria os cinco barramentos e toca os sons | ⚠️ **Antes do `Config`**: `Config._aplicar_audio()` ajusta o volume de cada barramento na abertura, e barramento que ainda não existe não tem volume para ajustar. Por isso `Audio` não lê opção nenhuma no `_ready` dele — quem vem depois **puxa** o que precisa |

### Classes novas

| Classe | Pasta | Papel |
|---|---|---|
| `Relogio` | `src/nucleo/` | "Hoje às 14:32", "Ontem às 09:05", "28/08/2026", e a duração `HH:MM:SS` |
| `NomesDeManuscrito` | `src/progressao/` | O que o nome de um Manuscrito pode ser, e o que o jogo sugere |
| `TelaSobreposta` | `src/ui/` | Base das telas modais: ESC fecha, come a entrada, **toma e devolve o foco** |
| `BotaoDeSegurar` | `src/ui/` | Botão que só dispara depois de um segundo de pressão, com barra |
| `AssetsDoMenu` | `src/ui/` | A tabela dos assets: caminho, tamanho, escala e borda de 9-slice |
| `CenarioDoMenu` | `src/ui/` | A mesa: cenário, máquina, macaco, ∞ das estrelas, poeira, folha |
| `GestosDoMenu` | `src/ui/` | Os gestos sorteados do menu vivo |
| `DescobertasTela`, `Letras` | — | ganharam `class_name` para a suíte poder perguntar a **regra** sem subir cena |

### O caminho das cenas

```text
main.tscn (Boot)  ──>  Abertura  ──>  Menu  ──>  Arquivos  ──>  Partida  ──>  Menu
                          │
                          └── pulada INTEIRA quando `ja_viu_abertura`
```

### Sinais novos no `EventBus`

| Sinal | Quando |
|---|---|
| `creditos_pedidos` | O jogador pediu a tela de créditos |
| `interface_mudou` | Escala, contraste, formato de número, partículas ou movimento mudaram |

⚠️ **`interface_mudou` é um sinal próprio, e não `idioma_mudou` emitido por conveniência.**
Emitir "a língua mudou" quando a língua não mudou é uma afirmação falsa dentro do
barramento — e o barramento é o único lugar do projeto onde todo mundo acredita no que lê.
O preço de ter dois é alguém conectar só um, e é por isso que o portão de texto passou a
exigir os **dois** de todo arquivo que monta texto em código.

---

## 3. Configurações: a tabela de campos

`Config.CAMPOS` virou uma **tabela** — nome, aba, tipo, valores, rótulos e o que aplicar. A
tela percorre `Config.ABAS`, pergunta quais campos moram em cada uma e monta o controle do
tipo declarado. **Opção nova é uma linha na tabela mais um rótulo na tela; nenhuma linha de
lógica muda.**

| Aba | Campos |
|---|---|
| GERAL | `idioma`, `autosave`, `confirmacoes`, `aviso_de_marco`, `aviso_de_descoberta` |
| ÁUDIO | `volume`, `volume_efeitos`, `volume_interface`, `som_de_digitacao` |
| VÍDEO | `resolucao`, `tela_cheia`, `vsync`, `limite_de_fps`, `modo_economico` |
| INTERFACE | `escala_da_interface`, `formato_numerico`, `particulas_de_letra` |
| ACESSIBILIDADE | `escala_do_texto`, `reduzir_movimento`, `reduzir_flashes`, `alto_contraste` |

**21 campos, 5 abas.** Mais dois valores que **não** são campos, de propósito: `slot` e
`ja_viu_abertura` são estado da instalação, e não opções que a tela ofereça.

### Cada opção tem um consumidor de verdade

Configuração sem consumidor é arquivo órfão: a entrega que a ajustou não muda nada no
produto. Onde cada uma é lida:

| Opção | Quem lê, e quando |
|---|---|
| `autosave` | `Autosave.tique`, **no quadro**. Desliga só o cronômetro — os gatilhos continuam |
| `confirmacoes` | `TeoremasTela`, nos dois pedidos de prestígio. ⚠️ **Não alcança excluir Manuscrito** |
| `aviso_de_marco` / `aviso_de_descoberta` | `HUD`, no instante do aviso |
| `vsync` / `limite_de_fps` / `modo_economico` | `Config.fps_efetivo()` — **um lugar só escreve `Engine.max_fps`** |
| `escala_da_interface` | `content_scale_factor` da janela |
| `escala_do_texto` | `Tema.fonte()` — e **todos** os 44 tamanhos do projeto passam por lá |
| `alto_contraste` | `Tema.cor()` e `Tema.fundo()` — e **todas** as 51 cores de texto passam por lá |
| `formato_numerico` | `Formatador.formatar()`, lido na hora |
| `particulas_de_letra` / `reduzir_movimento` | `Letras.desenhando()`, `Eras._process`, `CenarioDoMenu._process`, `GestosDoMenu.ligado()` |
| `reduzir_flashes` | `Cenas._trocar` — apaga o clarão |
| `som_de_digitacao` | `Audio.timbre_atual()`, lido na hora |

⚠️ **Opção que faz MENOS do que o nome promete declara o resto na dica.** "Salvamento
automático" desligado **ainda grava ao sair e ao prestigiar**, porque não existe botão de
gravar na mão neste jogo — uma opção que desligasse toda gravação seria uma opção que apaga
centenas de horas.

---

## 4. Áudio: os cinco barramentos

| Barramento | Campo de volume | Fonte hoje |
|---|---|---|
| `Master` | `volume` | tudo |
| `Musica` | — | ⚠️ **nenhuma** (dívida declarada) |
| `Efeitos` | `volume_efeitos` | o CLACK da digitação |
| `Interface` | `volume_interface` | o clique de todo botão |
| `Ambiente` | — | ⚠️ **nenhuma** (dívida declarada) |

⚠️ **Barramento sem fonte NÃO ganha barra de volume.** Controle de um barramento onde nada
toca é controle que a pessoa mexe e conclui que o jogo ignorou — a mesma regra da resolução
apagada em tela cheia. A dívida está em `Audio.SEM_FONTE_AINDA`, e **o portão morde dos dois
lados**: nome fora da lista tem que ter campo, nome dentro dela tem que continuar sem.

### A regra que sustenta o sistema

⚠️ **Nunca um som por caractere produzido.** No fim do jogo são 10^50 por segundo. A taxa de
CLACK sobe com a **ordem de grandeza** da produção e satura num teto **constante** — e é
essa independência que a suíte afirma: 10^50 e 10^300 clacam na mesma taxa. Uma taxa
proporcional passaria em todo o resto e reprovaria exatamente nessa linha.

Detalhes que importam:

- as ondas são **sintetizadas em código**, com semente fixa — sem binário versionado, como
  as fontes do `Tema`. Semente do relógio daria CLACKs diferentes a cada abertura, e
  nenhuma medição futura seria comparável consigo mesma
- **nada aloca por som tocado**: piscina fixa de tocadores em rodízio
- **volume zero MUTA** o barramento; em −80 dB ele continua sendo processado todo quadro
- o som de interface é ligado num lugar só, por `get_tree().node_added` — a alternativa era
  cada tela conectar o próprio clique, e espalhar esse par por seis telas é garantir que a
  sétima nasça muda, sem erro nenhum

---

## 5. Arte: a decisão e as peças

### A decisão 0006

O `ARTE.md` §7 excluía **pixel art por nome**, e o gerador escolhido é o PixelLab. Cânone que
contradiz a ferramenta muda **antes** do primeiro sprite.

**A decisão não é "agora tudo é pixel art":** é **pixel art no menu, tipografia na partida**.
A partida atravessa catorze eras e 10^50 sem um asset por era — a issue #26 existe para não
precisar disso. O menu é uma cena parada, de tamanho conhecido, e é ali que o macaco e a
máquina existem como objetos.

**O que a decisão custa**, escrito junto dela:

1. a ressalva de escala inteira **voltou a valer** — filtro `nearest`, exatidão só no
   tamanho da tela lógica
2. a escala de interface move a **UI**, e não o cenário
3. o prompt-base antigo **saiu** do §16 — deixar os dois é garantir que metade dos assets
   saia no estilo errado

### As 14 peças

| Família | Escala | Peças |
|---|---|---|
| Cenário | **5×** | `cenario_mesa` (384×216), `maquina` (64×48), `macaco` (48×56) |
| UI | **4×** | `emblema` (64×64), `painel_papel` (48×48), `placa_normal`, `placa_afundada` (48×24), `moldura_manuscrito` (48×32) |
| Ícones | **2×** | `infinito`, `banana`, `engrenagem`, `papel`, `excluir`, `voltar` (32×32) |

O briefing está em `docs/ASSETS.md` e veio **antes** das imagens. A tabela que o jogo lê é
`src/ui/assets_do_menu.gd`, e o `teste_assets` exige que o disco concorde com ela peça por
peça — ler a largura do PNG e chamar aquilo de "o tamanho" aprovaria um sprite gerado em
400×400 por engano.

### Quatro peças foram refeitas, e o motivo de cada uma ficou escrito

| Peça | O que veio errado | O que se fez |
|---|---|---|
| `cenario_mesa` | abajur exatamente onde o painel de menu vai | ⚠️ **a culpa era da ficha**: ela pedia o abajur à direita **e** o espaço negativo à direita. Pedido que se contradiz não é recusado pelo gerador — é cumprido pela metade que veio por último |
| `emblema` | vermelho, fora da paleta, sem o ∞ | regerado com paleta explícita e "no red, no orange, no blue" |
| `icone_infinito` | veio como um X | regerado descrevendo a forma ("two rings touching in the middle") em vez do nome |
| `placa_afundada` | nasceu sozinha: interior claro, moldura diferente, rótulo ilegível | regerada **a partir da normal** (img2img). Peça de uma família que nasce sozinha não pertence à família |

E duas correções **determinísticas**, feitas por código e declaradas na ficha:

- `icone_voltar` foi **espelhado** — o gerador entregou a seta para a direita duas vezes,
  com `direction: west` no pedido. Legítimo numa seta, que não tem lado certo intrínseco;
  seria ilegítimo em qualquer peça com luz direcional
- `moldura_manuscrito` teve o **miolo vazado** — duas gerações pediram moldura oca e as duas
  vieram preenchidas. O recorte é legítimo exatamente porque a ficha **já dizia** que a peça
  é oca: não se inventou nada, cumpriu-se o pedido que o gerador não cumpriu

⚠️ **O `∞` das estrelas saiu do asset.** Duas gerações pediram uma constelação em forma de
oito deitado e nenhuma entregou — gerador de imagem não desenha constelação por encomenda.
Ele passou a ser desenhado **em código**, sobre a janela, com posição exata — o que também é
o que permite ele piscar.

---

## 6. Os defeitos que apareceram, e por que nenhum deles dava erro

Esta é a seção mais útil do documento. **Todos** foram silenciosos.

### 6.1. `Engine.max_fps` ritma o laço principal também em headless

**Sintoma**: a fumaça, que roda em trinta segundos, **parou de terminar**.
**Causa**: a issue #41 passou a aplicar o limite de quadros. Sem janela não há quadro a
ritmar, mas o `Engine.max_fps` continua pausando o laço — com o teto em 60, cada
`await process_frame` passou a esperar um sexagésimo de segundo.
**Por que é caro**: ele não quebrou nada. Ficou **lento**, que é a versão mais cara desse
defeito — um teste que demora demais é um teste que alguém desliga.
**Conserto**: `Config._aplicar_ritmo_do_quadro()` não faz nada sem janela, e a conta
(`fps_efetivo()`) ficou em lógica pura com portão próprio.

### 6.2. JSON devolve número como `float`, e `Variant` compara **tipo** antes de valor

**Sintoma**: todo campo numérico da tela de configurações voltava do arquivo mostrando a
**primeira** opção.
**Causa**: `vsync` gravado como `1` volta `1.0`, e `[0, 1, 2].find(1.0)` é `-1`.
**Por que é caro**: a configuração da pessoa desaparecia a cada abertura do jogo, sem um
erro sequer. Afirmar em memória não pega — em memória o valor ainda é `int`.
**Conserto**: converter o lido para o tipo que o **padrão** declara, na leitura. E o portão
faz a ida e volta **pelo disco**, índice por índice, para cada campo.
**O portão foi verificado dos dois lados**: quebrei o conserto de propósito e ele reprovou.

### 6.3. Linha nova no CSV sem reimportar

**Sintoma**: uma tela inteira de configurações saiu **metade em cada língua** numa captura,
com a suíte verde.
**Causa**: os `.translation` são gerados na importação e não são versionados. A chave existe
no CSV, todos os portões de texto passam, e mesmo assim `tr()` devolve o português.
**Conserto**: o portão de texto passou a conferir **toda** linha cujo inglês difere do
português — 569 afirmações. E o passo `--import` entrou no "Antes de mergear".

### 6.4. `medir_quadro` não rodava desde a issue #38

**Sintoma**: nenhum. A régua simplesmente falhava na primeira linha.
**Causa**: ela procurava `Letras` e `Eras` na cena principal, e o `main.tscn` passou a abrir
no menu naquele merge.
**Por que é caro**: régua que não roda não reprova nada. **Código que ninguém roda apodrece.**

### 6.5. E o instrumento dela mentia

**Sintoma**: com a engine solta, 240 amostras seguidas saíam **idênticas** — média, p95 e p99
imprimiam o mesmo número. Com o quadro medido em 1,7 ms, reportava 57 ms.
**Causa**: `Performance.TIME_PROCESS` não muda a cada quadro.
**Conserto**: o instrumento passou a ser o relógio (`Time.get_ticks_usec()` entre dois
quadros), e a régua desliga vsync, teto e modo econômico antes de medir — com o limite em 60
a engine **dorme** o resto do quadro e a tabela mediria relógio de parede.
**Consequência**: as tabelas históricas do `TUNING.md` **não são comparáveis** com as novas.
Isso está escrito lá, para ninguém achar que houve uma melhora de seis vezes.

### 6.6. `set_anchors_preset` num nó que já está na árvore

**Sintoma**: o menu abriu com o fundo vazio da engine. Sem erro, sem aviso.
**Causa**: `set_anchors_preset` **preserva o retângulo atual** — e o atual, dentro do
`_ready`, é zero. Âncoras perfeitas `(0, 0, 1, 1)` sobre um retângulo de tamanho zero, com
`clip_contents` cortando a cena inteira.
**Conserto**: `set_anchors_and_offsets_preset`.

### 6.7. `patch_margin` é medido em pixels da **textura**

**Sintoma**: o papel do painel apareceu **repetido para fora** do painel.
**Causa**: borda de 12 numa textura de 48 pedindo 48 faz as duas margens somarem 96 e se
sobreporem. O Godot não reclama — ele desenha errado.
**Conserto**: ampliar a textura antes, por vizinho mais próximo (`textura_ampliada`).

### 6.8. As duas bordas do 9-slice não esticam

**Sintoma**: o estado "pressionado" saiu com "CRÉDITOS" pela metade.
**Causa**: botão mais baixo que a soma das bordas.
**Conserto**: a altura mínima sai da **peça**, e não de um palpite de layout.

### 6.9. A escala de interface e a de texto dividem o mesmo orçamento

**Sintoma**: com interface 1,5 **e** texto 1,5, oito controles da HUD saíram pela esquerda.
**Conserto**: a lista de escala de texto é **filtrada** pela escala de interface, como a
lista de resoluções é filtrada pelo monitor. E a fumaça percorre **toda combinação
oferecida** — medir só o par (maior, maior) mediria um par que o jogo nunca oferece junto.

### 6.10. `comecar_partida` perguntava `Save.existe()`

**Sintoma**: nenhum ainda — mas o cartão dizia CHEIO e abrir começaria do zero por cima.
**Causa**: `existe()` olha só o arquivo principal, e desde o backup da #36 um slot com o
principal perdido e o `.backup` intacto **é** uma partida. Duas fontes para a mesma verdade,
e a que valia era a errada.
**Conserto**: as duas telas e o `Cenas` leem o **mesmo** `Manuscrito`.

### 6.11. A aproximação da máquina ficava pendurada

**Sintoma**: uma máquina gigante e meio transparente por cima da tela seguinte.
**Causa**: a transição vive num `CanvasLayer` que sobrevive à troca de cena — de propósito —,
e sair antes de ela terminar deixava a sobra.
**Como apareceu**: numa **captura**, e não num teste. É o tipo de sobra que só o olho pega.
**Conserto**: quem liga, desliga — e a troca desliga.

### 6.12. A captura cravava a área lógica no tamanho da janela

**Sintoma**: a primeira captura em escala 125% acusou a interface estourando.
**Causa**: a ferramenta media um layout que **nenhum jogador vê**. O defeito era da captura.

---

## 7. Os portões criados

| Portão | O que ele pega |
|---|---|
| `teste_relogio` | ⚠️ **"Hoje" é dia de CALENDÁRIO**: gravar 23h50 e abrir 00h10 é ontem, e a conta por diferença de segundos diria hoje |
| `teste_arquivos` | Excluir apaga os **três** arquivos do slot **e só os dele** — com controle nos vizinhos. E o nome nunca vira caminho de arquivo |
| `teste_config` | Todo campo responde à API e **pertence a uma aba**; ida e volta **pelo disco** para cada índice; o campo de slot **não** está na lista |
| `teste_audio` | O teto do CLACK não depende da produção; zero muta; barramento sem fonte não tem barra (dos dois lados) |
| `teste_acessibilidade` | Raridade identificável **sem cor**; os glifos existem na **fonte de verdade**; alto contraste **aumenta** a distância de luminância |
| `teste_assets` | O disco concorda com a tabela, peça por peça; a família está inteira |
| `teste_formatador` | Os três formatos, e **nenhum deles arredondando** (valores logo abaixo de um degrau) |
| `teste_texto` | Duas funções de tradução varridas; tabelas em constante cobradas pela **fonte**; toda linha com inglês próprio **chega traduzida**; quem monta texto escuta os **dois** sinais |
| fumaça | O caminho do §48 inteiro; a abertura nos dois lados; o easter egg **não encosta no save**; toda combinação de escala |

### Contagem por suíte

```text
scripts de src/ compilam          59      audio                             78
Grande                           127      acessibilidade                    55
Formatador                        89      assets do menu                   107
relogio                           14      config                           352
Economia                         125      Cenas                             24
dados em .tres                   383      portao de texto                  569
Save                              68      marcos                          1310
Manuscritos                       63      descobertas                      174
arquivos                          34      Teoremas                          99
Autosave                          16      eventos                           75
producao offline                  25      automacao                         63
Fragmentos                        58
                                          TOTAL                           3967
```

---

## 8. Medições

### Tempo de quadro (`medir_quadro`, instrumento novo)

```text
                                 quadro    p95       p99       perdidos
MENU PARADO                      0,636 ms  1,313 ms  2,141 ms  0 de 240
MENU VIVO                        0,629 ms  1,368 ms  3,243 ms  0 de 240

5 caracteres/s                   1,877 ms  2,096 ms  3,892 ms  0 de 240
500 mil/s                        2,232 ms  2,446 ms  2,815 ms  0 de 240
5e17/s                           2,148 ms  3,816 ms  4,271 ms  0 de 240
SATURADO                         2,240 ms  3,240 ms  4,537 ms  0 de 240
ERA 14                           1,656 ms  1,863 ms  1,944 ms  0 de 240

SOM DESLIGADO 1                  1,994 ms  2,273 ms  4,119 ms  0 de 240
SOM NORMAL 1                     1,933 ms  2,143 ms  2,275 ms  0 de 240
SOM DESLIGADO 2                  1,976 ms  2,226 ms  4,254 ms  0 de 240
SOM NORMAL 2                     1,879 ms  2,121 ms  2,211 ms  0 de 240
```

**Dois achados, e os dois são "não custa nada":**

- **o menu vivo custa 0,007 ms** — menos que a diferença entre duas medições do mesmo estado
- **o áudio custa 0,07 ms** — menos que a diferença entre duas medições do mesmo estado
  (0,09 ms)

Nenhuma linha passa do orçamento de 16,67 ms. ⚠️ **Isso não quer dizer que o custo da era 14
sumiu** — quer dizer que ele nunca foi medido direito antes.

---

## 9. O que **não** está provado

Esta seção existe porque o que o teste não prova precisa estar escrito. Sem ela, todos
assumem que o verde cobre mais do que cobre.

### Arte

- ⚠️ **Nenhuma medição pega "isso não parece do mesmo jogo".** Peça que passa em toda régua
  ainda pode estar errada pelo **conjunto**. As 14 peças passaram na checagem do `ARTE.md`
  §17 por **leitura humana**, e três delas foram refeitas depois de olhar
- **Texto dentro de asset** não é verificável automaticamente — nenhuma medição lê pixel
  procurando letra. Conferido peça por peça, à mão
- **Paleta** não é cobrada por portão: contar cores pegaria o caso grosseiro e reprovaria
  toda peça com uma sombra a mais — o portão morderia o código certo

### Som

- ⚠️ **O timbre dos CLACKs não foi ouvido.** A suíte prova que a onda tem a forma declarada,
  a taxa, o teto e o mute. Ela não prova que o som é **bom** — isso é ouvido, e é do autor
- O mesmo vale para o volume padrão de cada barramento

### Ritmo e sensação

- **O intervalo entre gestos do menu** (1,8 s a 4,5 s) e a duração da abertura (≈3,3 s)
  passam em "dois a quatro segundos" e em "nada excessivamente movimentado" por **decisão
  escrita**, não por medição. Ninguém mediu se incomoda
- **O deslocamento de 6 px do rótulo ao apertar** é design, não medição

### Plataforma

- Tudo foi medido numa máquina só: **Windows 11, GTX 1060, Godot 4.7.2**
- **Headless não renderiza**: nenhuma afirmação sobre pixel vem da suíte. Isso é assunto de
  captura, e captura é leitura humana
- A cobertura de glifo na fonte **não é medida sem fonte do sistema carregada** — o ponto
  cego está declarado dentro do próprio `teste_acessibilidade`

### Integração

- **Não há CI.** Os portões rodam quando alguém os roda
- O caminho do §48 é provado **uma vez**, no fim da fumaça. Ele não é repetido com estados
  variados (slot 2, Manuscrito ilegível, save do futuro)

---

## 10. Dívidas declaradas

Cada uma está numa lista nomeada dentro do código, e **cada lista morde dos dois lados**: o
que está fora dela tem que estar coberto, o que está dentro tem que continuar descoberto.

| Lista | Itens | Por que ficou de fora |
|---|---|---|
| `Audio.SEM_FONTE_AINDA` | `Musica`, `Ambiente` | Barramento onde nada toca não ganha barra de volume. `Musica` entra com a trilha; `Ambiente` ficou de fora **por decisão** — zumbido contínuo num jogo que fica aberto atrás de outra coisa é som que a pessoa desliga uma vez e nunca mais liga |
| `Config.SEM_SISTEMA_AINDA` | `animacoes_de_numero`, `shake` | O plano §21–§22 pede as duas opções, e os sistemas que elas desligariam **não existem**. Opção que não tem o que desligar é opção que a pessoa mexe e conclui que o jogo ignorou |
| `teste_texto.SEM_TRADUCAO` | marcas de formato | Número cru e porcentagem são marcas de formato, não texto — e a regra é **geral**, não uma lista que envelhece a cada campo numérico novo |

---

## 11. O que foi preenchido pela convenção

Registrado para poder ser corrigido, e não para parecer decidido:

| Decisão | O que foi assumido |
|---|---|
| Lado da luz no cenário | Abajur à **esquerda**, luz para a direita — nada no plano diz de que lado ele fica |
| Lado do espaço negativo | Painel à **direita** (plano §5), então o macaco e o abajur ficam à esquerda |
| Posição do `∞` nas estrelas | Céu, à direita do macaco e à esquerda do painel |
| Símbolos de raridade | `-` `+` `*` `#` `@` `%` `∞` — escalam em densidade, seis ASCII e o sétimo provado presente |
| Nomes temáticos | Seis sugestões, com tradução própria em inglês |
| Créditos | Só o que **existe hoje** — a arte entra na lista quando houver arte creditada |
| Frases raras | `banana` e `hello?`, do plano §24 |

---

## 12. Convenções novas registradas

Tudo abaixo entrou no `CONVENCOES.md`, que é onde a próxima pessoa procura:

- **Foco, teclado e controle** — `FOCUS_NONE` na HUD (o espaço digita), `FOCUS_ALL` no menu;
  a moldura de foco precisa aparecer; tela sobreposta toma e devolve o foco
- **Campo é genérico, e a aba é só mais uma coluna** — incluindo a armadilha do `float` do
  JSON e a do `Engine.max_fps` sem janela
- **Interface e acessibilidade** — tudo passa por `Tema.fonte()` e `Tema.cor()`; dois sinais
  e não um; as duas escalas dividem um orçamento
- **Áudio** — nunca um som por caractere; zero muta; nada aloca por som; barramento sem
  fonte não ganha barra
- **Easter egg** — não encosta no save, e esse silêncio **é** a funcionalidade
- **O menu vivo** — gestos sorteados, um por vez, sem repetir o anterior, sempre voltando ao
  zero; a transição é decoração por cima de um jogo que já começou
- **Pixel art na interface** — `patch_margin` em pixels de textura, bordas que não esticam,
  `set_anchors_and_offsets_preset`
- **Antes de mergear** — o passo `--import` quando se mexe no `textos.csv`

---

## 13. Onde olhar primeiro, se algo quebrar

| Sintoma | Provável lugar |
|---|---|
| Tela abre vazia | `set_anchors_preset` em vez de `set_anchors_and_offsets_preset` |
| Opção volta ao padrão a cada abertura | `Config._do_tipo_de` — tipo do valor lido do JSON |
| Texto em português numa tela em inglês | `--import` não rodou depois de mexer no CSV |
| Uma tela não acompanha escala ou contraste | Falta `EventBus.interface_mudou` **e** `Tema.montar()` na remontagem |
| Moldura repetida para fora do painel | `patch_margin` na textura original em vez da ampliada |
| Rótulo cortado num botão de placa | Altura mínima menor que a soma das bordas do 9-slice |
| Fumaça lenta demais | Alguém voltou a aplicar `Engine.max_fps` sem janela |
| Régua com números impossíveis | Alguém trocou o relógio por um monitor de desempenho |

---

## 14. Resumo em uma frase

A v0.5 deu ao jogo um começo — abertura, menu com a mesa, Manuscritos, configurações em
abas, áudio, acessibilidade — e, no caminho, **doze defeitos silenciosos viraram portão**.
O que não está provado está escrito acima, e é a parte deste documento que vale mais que a
lista do que foi feito.
