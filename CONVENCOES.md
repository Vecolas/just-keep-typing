# Convenções — Just Keep Typing

Base de regras para o desenvolvimento deste projeto (Godot 4.7).

Conciliação de dois documentos de convenções do mesmo autor: um de um projeto de três
pessoas e um de um projeto solo mais recente. Onde os dois divergiam, venceu o mais
recente — ele já tinha passado pela correção da realidade. **Aqui o desenvolvimento é
solo**, e o que mudou por causa disso está marcado com **[solo]**. O resto vale igual: as
práticas são boas independentemente do tamanho do time.

O que está escrito como "existe" descreve o alvo, não o presente — este repositório ainda
está no começo. O que já foi **medido na engine** está marcado como tal, com data.

---

## Git

**Branches**

```text
main                    sempre jogável, sempre verde
feat/<descricao>        funcionalidade nova
fix/<descricao>         correção
tune/<descricao>        só balanceamento (.tres)
docs/<descricao>        só documentação
```

**[solo]** Continua valendo não commitar direto no `main` para qualquer coisa que não seja
trivial. O motivo é que muda: não é mais evitar pisar no pé de alguém, é conseguir
**abandonar uma tentativa sem sujar o histórico**. Com uma pessoa só, o PR vira opcional —
abra quando o diff for grande o bastante para você querer relê-lo antes de mergear, ou
quando quiser que o CI rode antes. Caso contrário, `git merge --no-ff` resolve e mantém a
branch visível no histórico.

```bash
git switch -c feat/gerador-de-salas
# ... trabalha, commita ...
git switch main
git merge --no-ff feat/gerador-de-salas
```

O que **não** muda: `main` sempre jogável. Se está quebrado, não está no `main`.

**Tags** — marque as versões que você conseguiu jogar do início ao fim
(`v0.1-vertical-slice`). É o ponto para onde voltar quando um refactor descarrilar.

**Commits** — em português, imperativo, minúsculo, sem ponto final:

```text
adiciona telegrafo no ataque em anel do chefe
corrige rolamento travando ao encostar na parede
ajusta vida do Vigia de 6 para 5
```

Um commit deve ser revertível sozinho. Se você precisa de "e" no meio da mensagem,
provavelmente são dois commits.

**Pull Requests** — um assunto por PR. Se mexeu em cena, diga qual no título.

### O que nunca vai para o GitHub

```text
.mcp.json    aponta caminhos ABSOLUTOS desta máquina
mcp_tmp/     scratch do servidor MCP
```

Só isso. **O `addons/godot_mcp/` é versionado** — e é assim de propósito.

Ele já esteve fora, e o custo apareceu rápido: com `addons/` ignorado, o bloco
`[editor_plugins]` do `project.godot` não podia ser commitado, então o arquivo era
reescrito por script a cada commit — arrancar o bloco, commitar, recolocar. O Godot lê
`[autoload]` uma vez no boot, e essa reescrita constante foi o que deixou o editor
acusando `Identifier not found: EventBus` por horas, com o código perfeito.

Ter a ferramenta no repositório custa nada: o addon não tem caminho absoluto nem segredo e
escuta só em `127.0.0.1`. O único arquivo realmente específico da máquina é o `.mcp.json`
(aqui o servidor está registrado com escopo `local`, no `.claude.json`, que também não é
versionado — ver `README.md`).

### O `project.godot` é do editor, não seu

Ele é reescrito e normalizado toda vez que o Godot salva: seções são reordenadas e
**comentários são apagados**. Não documente nada dentro dele — a ordem dos autoloads, por
exemplo, vive em `docs/ARQUITETURA.md`.

---

## Uma cena por vez

A regra original era "uma pessoa por cena por vez". **[solo]** Vira **uma cena por vez**,
por outro motivo: cena `.tscn` pela metade é o tipo de trabalho que você não consegue
retomar depois de três dias. Termine ou reverta antes de abrir a próxima.

O mesmo vale para frentes: não comece o inimigo novo com o gerador de salas pela metade.
Duas frentes abertas significam duas cenas em estado inconsistente, e quando um bug
aparece você não sabe de qual das metades ele veio. Se precisar interromper por algo
urgente, `git stash` ou uma branch `fix/` saindo de `main` — nunca empilhada por cima do
trabalho pela metade.

Cenas dão merge — são texto — mas merge de cena é onde mais se perde referência de nó.
Scripts (`.gd`) são muito mais tolerantes: dois arquivos diferentes nunca conflitam.
Balanceamento (`.tres`) é livre — arquivos pequenos, conflito trivial.

**Divisão de pastas**, para o projeto crescer com lugar previsível para cada coisa:

| Área | Arquivos |
|---|---|
| Lógica pura, sem cena | `src/nucleo/` (`Grande`, `Formatador`) |
| Quem gera caractere | `src/producao/` (macacos, máquinas, salas) |
| Marcos, descobertas, teoremas | `src/progressao/` |
| Telas | `src/ui/` |
| A cena das eras e a câmera | `src/cena/` |
| Autoloads | `src/autoload/` |
| Dados de balanceamento | `data/` (`.tres`) |
| Testes, réguas e ferramentas | `tools/` |
| Documentação | `docs/` |
| Textos | `i18n/textos.csv` |

---

## Código

**Idioma.** Código em **português**: nomes de variável, função, sinal e comentário.
Palavras que o Godot impõe (`_ready`, `_process`, `queue_free`, `global_position`) ficam
como são.

**Nomes**

```gdscript
class_name InimigoBase              # PascalCase
var velocidade_maxima: float        # snake_case
const LIMIAR_CONCLUSAO := 0.98      # CONSTANTE_MAIUSCULA
signal sala_limpa(sala: Node2D)     # snake_case, no passado (algo aconteceu)
func _calcular_falloff()            # underscore na frente = privado
```

Arquivos e pastas em `snake_case` (`inimigo_base.gd`, `sala_recompensa.tscn`).

**Tipagem.** Sempre que der. `var vida: int = 6`, `func dano(x: int) -> bool`. O Godot
avisa mais cedo e o autocomplete funciona melhor.

**Comentários.** Comente o **porquê**, nunca o **quê**.

```gdscript
# ruim
# subtrai o falloff da mascara

# bom
# passo de meio raio: com passo cheio o rastro sai pontilhado quando o mouse
# viaja mais que um diametro entre dois frames
```

**Documentação de arquivo.** Todo script começa com um bloco `##` explicando o que ele faz
e qual decisão de design ele carrega. **[solo]** Isso importa mais, não menos: esse bloco é
a única pessoa a quem você vai poder perguntar daqui a dois meses.

```gdscript
## Base de todo inimigo. Guarda vida, estado e o alvo atual.
##
## Nao guarda velocidade ja multiplicada: le a dificuldade no frame em que precisa,
## para que inimigo ja em tela responda a progressao. Ver docs/decisoes/0002-....md
class_name InimigoBase
extends CharacterBody2D
```

---

## Arquitetura — as duas regras que sustentam o projeto

### 1. Comunicação por `EventBus`, não por caminho de nó

Nunca escreva `get_node("../../Player")` nem `get_parent().get_parent()`. Quem faz algo
emite um sinal no `EventBus`; quem se importa conecta.

```gdscript
# ruim -- quebra assim que alguem mover um no
get_node("/root/Main/HUD").atualizar_vida(vida)

# bom
EventBus.player_dano_recebido.emit(vida, vida_maxima)
```

Exceção legítima: procurar por **grupo** (`get_first_node_in_group("player")`), que é como
os inimigos acham o alvo.

### 2. Valor derivado de estado global se calcula na hora de usar

Nenhum sistema guarda um valor já multiplicado. Todos leem o autoload no frame em que
precisam. Nos dois projetos anteriores esse autoload se chamava `Deterioracao` (dificuldade
que sobe) e `Upgrades` (bônus comprado); aqui vale para qualquer um que apareça:

```gdscript
# ruim -- congela a dificuldade no momento do spawn
velocidade = 120.0 * Deterioracao.multiplicador_velocidade()

# bom -- responde a barra subindo, inclusive para quem ja esta em tela
func velocidade_atual() -> float:
    return velocidade_base * Deterioracao.multiplicador_velocidade()
```

Cache só com motivo medido, e com um comentário dizendo qual foi.

**Corolário que vale ouro:** o gameplay nunca pergunta o nível de um upgrade específico —
só quanto de bônus de um **tipo** ele tem no total. Assim dá para adicionar dez upgrades de
velocidade sem tocar em nenhum arquivo de gameplay.

---

## Idioma — o jogo fala português e inglês

O jogo nasce em português. O inglês não é tradução feita no fim: **texto novo já entra na
tabela na mesma mudança que o cria**, e há portão que reprova quem esquecer. Adote desde a
primeira tela — retroagir isso depois é o que custa caro.

A tabela é `i18n/textos.csv`, com três colunas: `keys`, `pt_BR`, `en`.

**A chave É o texto em português.** Isso é deliberado:

- a cena continua legível — o `.tscn` diz `text = "Continuar"`, não `text = "MENU_CONTINUAR"`
- o Godot traduz sozinho o `text` de qualquer `Control` que bata com uma chave, então
  acrescentar idioma não exige tocar em nenhuma cena
- o custo é que **mudar o português quebra o vínculo** — e é exatamente disso que o portão
  avisa, em vez de deixar a frase aparecer sozinha na língua errada

### As regras ao escrever texto novo

1. **Escreveu texto que o jogador lê? Acrescente a linha no CSV na mesma mudança.** Vale
   para cena, para `.text` em código e para catálogo em constante.

2. **Texto montado com `%` precisa de `tr()` explícito, e o `tr()` vem ANTES da
   substituição.** Traduz-se o molde, nunca o resultado:

   ```gdscript
   _rotulo.text = tr("Vida %s") % vida        # certo
   _rotulo.text = tr("Vida %s" % vida)        # errado: "Vida 6" nao bate com chave nenhuma
   ```

3. **O tom do texto é cânone nas duas línguas.** Traduzir é o momento mais fácil de perder
   o tom, porque quem escreve o inglês raramente relê o personagem. Se o projeto tiver
   palavras proibidas, o teste varre as duas colunas, não só a portuguesa.

### ⚠️ Tela que monta texto em código tem que ouvir `idioma_mudou`

O Godot retraduz sozinho o `text` que veio da **cena**. O que foi montado com `%` fica
exatamente como estava até outra coisa mexer nele — e o rótulo antigo sobrevive no canto de
uma interface já em inglês.

Não quebra nada, não imprime erro, e some sozinho na próxima atualização daquele rótulo.
Por isso é portão, não recomendação: o teste de scripts reprova arquivo de `src/` que
formate valor para tela sem escutar `EventBus.idioma_mudou`.

Repintar não é reexecutar: separe `_fazer_de_verdade` de `_pintar`, senão chamar a primeira
de novo aplica o efeito duas vezes só porque a pessoa mexeu nas opções.

### Idioma traz as convenções junto, e não só as palavras

Trocar de idioma troca também **como o lugar escreve as coisas** — relógio 24 h × 12 h,
formato de número e de moeda. Isso mora numa tabela em `Config`, uma entrada por língua:

```gdscript
{"codigo": "en", "nome": "English", "relogio_12h": true, "moeda": &"USD"},
```

⚠️ **Número não é convertido, só reescrito.** Muda o símbolo e a pontuação, nunca a
quantia — números canônicos da lore o jogador aprende de cor.

**Idioma novo é uma linha na tabela mais uma coluna no CSV.** Nem o relógio nem o
formatador têm `if` por língua: os dois perguntam à tabela.

### A suíte fixa a língua, como fixa o save

`runner.gd` e `teste_fumaca.gd` gravam o locale, põem `pt_BR` e devolvem no fim. Sem isso a
suíte roda **no idioma em que quem desenvolve deixou o jogo** — as opções moram em
`user://opcoes.json`, que é da instalação. Uma volta na tela de opções e as falas chegam às
asserções em inglês, quebrando testes sem nada ter mudado no código.

Português porque é a língua de origem: a chave da tabela É o texto em português.

### O que não se traduz

Marca de formato (`%02d:%02d`) e número de exemplo que a cena mostra antes de o jogo
escrever o valor real. A lista fica explícita numa constante `SEM_TRADUCAO` no teste.

---

## Vídeo e opções

Tela cheia e resolução moram no `Config` como todas as outras, em `user://opcoes.json`,
porque são da **instalação** e não da partida. Trocar de slot não pode mudar a resolução de
quem joga.

- **Tela cheia sem exclusividade** (`WINDOW_MODE_FULLSCREEN`, não `EXCLUSIVE`): no Windows
  a exclusiva pisca a tela inteira a cada alt-tab
- ⚠️ **A lista de resoluções é filtrada pelo tamanho do monitor.** Oferecer 2560×1440 a
  quem tem 1080p cria uma janela maior que a tela, com a barra de título inalcançável — e a
  pessoa não tem como voltar às opções para desfazer
- Em tela cheia a lista de resolução fica **apagada**, porque ali ela não faz nada
- ⚠️ **A arte do menu É pixel art de escala inteira desde a issue #44** (decisão
  [0006](docs/decisoes/0006-pixel-art-no-menu-tipografia-na-partida.md)), então esta
  ressalva **vale**: só a escala inteira é exata. As outras esticam e um pixel quadrado
  passa a ter larguras diferentes na mesma imagem. Elas continuam existindo porque monitor
  menor que o canvas é real — e é por isso que a dica da tela diz o que diz
- ⚠️ **Pixel art é desenhada com filtro `nearest`, nunca linear.** Interpolação vira
  borrão, e borrão é a única coisa que pixel art não pode ser
- ⚠️ **A escala de interface move a UI, e não o cenário.** 125% em cima de sprite de escala
  inteira faria o pixel quadrado ter larguras diferentes na mesma imagem. Painel, botões e
  texto crescem; a mesa, o macaco e a janela ficam onde estão

**Campo é genérico, e a aba é só mais uma coluna.** `Config.CAMPOS` é uma tabela: nome,
aba, tipo, valores, rótulos e o que aplicar. A tela percorre `Config.ABAS`, pergunta quais
campos moram em cada uma e monta o controle do **tipo** declarado — `rotulos_de` /
`indice_de` / `escolher` para lista, `faixa_de` / `valor_de` / `definir` para barra. Opção
nova é **uma linha** na tabela mais um rótulo na tela; nenhuma linha de lógica muda.

- Aba **sem campo não é desenhada** — aba vazia ensina o jogador a não clicar nas outras
- ⚠️ **O campo "slot" não mora nas opções.** Escolher Manuscrito é a tela de Arquivos;
  trocar de save por dentro das opções, no meio da partida, é o gesto que apaga progresso
  sem querer
- ⚠️ **Opção declarada precisa fazer alguma coisa.** Configuração sem consumidor é arquivo
  órfão: a entrega que a ajustou não muda nada no produto. E opção que faz **menos** do que
  o nome promete declara o resto na dica — "salvamento automático" desligado ainda grava ao
  sair e ao prestigiar, porque não existe botão de gravar na mão neste jogo
- ⚠️ **Um lugar só escreve `Engine.max_fps`.** O limite de quadros e o modo econômico
  entram os dois em `Config.fps_efetivo()`. Duas fontes para o mesmo global seriam a janela
  voltando do segundo plano presa em dez quadros por segundo, sem uma linha no console
- ⚠️ **Sem janela, ritmo de quadro não se aplica.** `Engine.max_fps` continua ritmando o
  laço principal em headless: com o teto em 60, cada `await process_frame` da fumaça passou
  a esperar um sexagésimo de segundo e o teste de trinta segundos parou de terminar. Ele não
  quebrou — ficou **lento**, que é a versão mais cara desse defeito

⚠️ **JSON devolve número como `float`, e a comparação de `Variant` do Godot confere o TIPO
antes do valor**: `[0, 1, 2].find(1.0)` é `-1`. Todo campo numérico voltava do arquivo
mostrando a primeira opção — a configuração da pessoa sumindo a cada abertura do jogo, sem
um erro sequer. O que fecha isso é converter o lido para o tipo que o **padrão** declara, na
leitura, e um portão que faça a ida e volta **pelo disco** para cada índice de cada campo:
afirmar em memória não pega, porque em memória o valor ainda é `int`.

---

## Interface e acessibilidade

Tudo que o jogador lê passa por **duas funções do `Tema`**, e nunca pelo número cru:

```gdscript
rotulo.add_theme_font_size_override("font_size", Tema.fonte(CORPO))
rotulo.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))
fundo.color = Tema.fundo()
```

- ⚠️ **Um único rótulo com o tamanho cravado fica do tamanho antigo quando todo o resto
  cresce**, e o defeito não dá erro — ele só deixa uma linha ilegível no meio de uma tela
  ajustada
- ⚠️ **Alto contraste mantém a matiz.** A paleta continua sendo a do `ARTE.md`, só mais
  separada do fundo. Trocar por branco puro apagaria "dourado é produção, ciano é
  automação" — e a seção 6 proíbe branco puro justamente por isso
- ⚠️ **`Theme` é um objeto construído: ele não se atualiza sozinho.** Quem escuta
  `interface_mudou` tem que chamar `Tema.montar()` de novo, e não só repintar
- ⚠️ **As duas escalas dividem o mesmo orçamento de espaço.** A lista de escala de texto é
  **filtrada** pela escala de interface escolhida, como a lista de resoluções é filtrada
  pelo monitor. Medido: interface 1,5 **e** texto 1,5 ao mesmo tempo jogam oito controles
  da HUD para fora da tela. A fumaça percorre **toda combinação oferecida** — medir só o
  par (maior, maior) mediria um par que o jogo nunca oferece junto
- ⚠️ **Opção que não tem o que desligar não entra.** Animações de número e *shake* estão
  em `Config.SEM_SISTEMA_AINDA` porque os sistemas não existem — elas entram junto do
  sistema, não antes dele

**Dois sinais, e não um.** `idioma_mudou` é a língua; `interface_mudou` é escala, contraste,
formato de número, partículas e movimento. Emitir "a língua mudou" quando a língua não mudou
é uma afirmação falsa dentro do barramento — e o barramento é o único lugar do projeto onde
todo mundo acredita no que lê. O preço de ter dois é alguém conectar só um, e é por isso que
o portão de texto exige os **dois** de todo arquivo que monta texto em código.

**Reduzir movimento alcança os dois lugares que se mexem sozinhos**: as letras subindo
(issue #22) e a câmera das eras (issue #26). Com a opção ligada a era troca **num quadro** —
o destino é o mesmo, o caminho é que some. E nenhuma dessas opções encosta na produção:
opção de interface que mexesse em progressão seria dificuldade disfarçada de conforto.

---

## Redação do conteúdo

Regras que valem para todo marco e toda descoberta. **Duas delas são portão**
(`teste_redacao`).

⚠️ **Equivalência em caracteres NÃO é ter escrito a obra.** O texto diz *"caracteres
suficientes para preencher um livro"*, e **nunca** *"você escreveu um livro"*. Isso não é
preciosismo: é o conceito probabilístico inteiro do jogo. O macaco não escreveu Hamlet — ele
produziu tanto caractere quanto Hamlet tem. No dia em que o texto afirmar autoria, o jogo
deixa de ser sobre o Teorema do Macaco Infinito e passa a ser sobre um macaco talentoso.

O vocabulário certo, que é a metade positiva da regra:

```text
caracteres suficientes para…     o mesmo número de…
…em caracteres                   o tamanho exato de…
```

⚠️ **E a regra vale nas DUAS línguas.** O portão quase nasceu protegendo metade do produto:
ele varria só os `.tres`, que estão em português. O marco "Um Livro" dizia *"Você já escreveu
um livro"* e foi pego; a linha em inglês do mesmo marco dizia *"You have written a book"* e
passou inteira.

⚠️ **O portão pega a CONSTRUÇÃO, não o sentido.** Ele varre uma lista de construções
proibidas, cada uma com o motivo escrito ao lado. Uma expressão regular ampla — `escrev` em
qualquer lugar — reprovaria *"tudo que a humanidade escreveu"*, que é uma frase **certa**.
Portão que morde o código certo é portão que alguém desliga. O que ele **não** pega é
autoria afirmada por outras palavras: isso é leitura humana.

**O marco tem dois eixos, e eles respondem perguntas diferentes:**

| Eixo | Pergunta | Valores |
|---|---|---|
| `Categoria` | sobre **o que** este número fala | a escala do GDD §45: `LETRAS → … → INFINITO` |
| `Tipo` | **o que a frase faz** com o jogador | `QUANTITATIVO`, `HUMANO`, `CONCEITUAL` |

⚠️ **Os conceituais são os mais importantes** — são eles que preparam a transição para o
endgame. E eles moram na **metade final** do Panorama: um "as comparações acabaram" na
primeira hora seria o jogo desistindo antes de começar. Isso é portão.

⚠️ **Marco não dá bônus** (decisão 0003) — continua valendo. O Panorama é a única tela do
jogo que não é uma loja.

⚠️ **Num MARCO o jogo compara tamanho; numa DESCOBERTA o macaco produziu aquilo.** A
diferença é o sistema inteiro, e o portão tem **duas** listas por causa dela:

| | marco | descoberta |
|---|---|---|
| "você escreveu…" | proibido | proibido |
| "o macaco escreveu…" | **proibido** — ali a comparação é de tamanho | **permitido** — é o fato |

O erro só apareceu ao escrever a descoberta *JUST KEEP TYPING*: "Ele escreveu o nome do
jogo" não é exagero, é o que uma descoberta **é** (GDD §9). Uma lista só, aplicada aos dois,
teria proibido a frase certa.

**Descoberta tem PAPEL, e é ele que separa "sem bônus" de "campo esquecido":**

| Papel | Exige |
|---|---|
| `BONUS` | `bonus > 1.0` — senão é dado pela metade |
| `HUMOR`, `EXPLICACAO`, `INTERFACE` | `bonus == 1.0` — senão é bônus escondido num papel que não o anuncia |

Até a v0.5 a regra era "toda descoberta tem bônus > 1", e o padrão inválido protegia contra
dado esquecido. Com descobertas que existem **só pela piada**, 1.0 virou legítimo. A regra
nova não é mais frouxa: as duas metades juntas pegam **mais** que a antiga, que não percebia
bônus escondido.

⚠️ **Papel declarado precisa ter o que entregar.** `INTERFACE` sem efeito é a mesma família
de defeito da opção sem consumidor (issue #41) — e o que decide é o **papel no `.tres`**,
nunca um id dentro do código.

---

## Easter egg

Só existe um, e ele tem uma regra: ⚠️ **easter egg não encosta no save.** A tecla que o
jogador aperta no menu faz o macaco bater aquela tecla e a letra aparece na folha — e mais
nada. Nada em `CenarioDoMenu.datilografar` escreve em `Jogo`, `Save` ou `Economia`, e esse
silêncio **é** a funcionalidade: é o que permite a brincadeira existir sem que um bug nela
custe progresso a alguém.

A fumaça afirma as duas metades: a letra aparece **e** o total de caracteres não muda.

---

## O menu vivo

- ⚠️ **Gestos independentes e sorteados, nunca um vídeo único.** Um vídeo de dez segundos é
  reconhecível na terceira vez e irritante na décima — e este é um menu que fica aberto
  atrás de outra coisa. Gesto novo é **uma linha** em `GestosDoMenu.GESTOS`
- ⚠️ **Nada excessivamente movimentado.** Os deslocamentos são de um ou dois **pixels de
  arte**, e entre um gesto e outro o menu fica parado por segundos
- ⚠️ **Um gesto por vez.** Dois somam deslocamento e o macaco sai do lugar. "Independentes"
  quer dizer que eles não formam sequência, não que se empilham
- ⚠️ **O mesmo gesto não sai duas vezes seguidas.** Sorteio com peso entrega "pisca, pisca,
  pisca" com frequência perfeitamente normal para um sorteio e perfeitamente errada para um
  olho — o jogador não vê probabilidade, vê um tique
- ⚠️ **O gesto volta ao zero.** O envelope é 0 → 1 → 0: sem a volta, cada gesto termina
  deslocado e a peça vai andando para o lado a cada sorteio
- ⚠️ **`reduzir_movimento` para o `_process` inteiro**, e não só o gesto. Menu parado que
  continua redesenhando poeira e estrelas é bateria queimada à toa
- **Quem decide o gesto não mexe em nó nenhum.** `GestosDoMenu` devolve o **estado**; quem
  desenha é o cenário. Espalhar o conhecimento da árvore por dois lugares é garantir que o
  segundo esqueça de desfazer alguma coisa

**A transição para a partida é decoração por cima de um jogo que já começou.** A partida é
montada primeiro; a máquina crescendo vem depois, num `CanvasLayer` do `Cenas` que sobrevive
à troca. ⚠️ Uma transição que exigisse `await` **antes** de montar abriria a janela em que um
segundo clique começa uma segunda partida — que é exatamente a janela que a issue #38 fechou
escolhendo o clarão em vez da travessia. É por isso que a fumaça atravessa a transição sem
esperar tempo real nenhum.

---

## Pixel art na interface

A arte do menu é pixel art de **escala inteira** (decisão
[0006](docs/decisoes/0006-pixel-art-no-menu-tipografia-na-partida.md)). Três armadilhas, e
as três já custaram uma captura:

- ⚠️ **`patch_margin` e `texture_margin` são medidos em pixels da TEXTURA**, não da tela.
  Uma placa de 48×24 com borda 8 desenha uma borda de 8 px — minúscula em 1920 lógicos. E
  pedir 32 numa textura de 48 faz as duas margens somarem 64 e se **sobreporem**: o Godot
  não reclama, ele desenha a peça repetida para fora do painel. O que resolve é **ampliar a
  textura antes**, por vizinho mais próximo (`AssetsDoMenu.textura_ampliada`)
- ⚠️ **As duas bordas do 9-slice não esticam.** Controle mais baixo que a soma delas sai com
  o rótulo cortado. A altura mínima sai da **peça**, e não de um palpite de layout
- ⚠️ **`set_anchors_preset` num nó que JÁ ESTÁ na árvore preserva o retângulo atual** — e o
  atual, dentro do `_ready`, é zero. O resultado são âncoras perfeitas sobre um retângulo de
  tamanho zero, com `clip_contents` cortando a cena inteira: nenhum erro, nenhum aviso, a
  tela abre vazia. Quem zera os offsets é `set_anchors_and_offsets_preset`

**Escala inteira, sempre, e calculada — nunca cravada.** A escala do cenário é o menor
inteiro que ainda **cobre** a área; o que sobrar sai pelas bordas, centralizado. Sobra
cortada é melhor que pixel torto, e infinitamente melhor que tarja preta.

**Asset é opcional em tempo de execução.** `textura_de` devolve `null` quando o arquivo não
existe, e toda tela cai no desenho tipográfico — menu que não abre porque um PNG não veio é
pior que menu sem arte.

---

## Áudio

Cinco barramentos — Geral (`Master`), Música, Efeitos, Interface e Ambiente —, criados em
código pelo autoload `Audio`, e não num `default_bus_layout.tres`: o `.tres` seria um
arquivo reescrito pela ferramenta, hostil a merge e sem espaço para comentário, e a decisão
de **por que** Interface é separada de Efeitos moraria fora dele de qualquer jeito.

- ⚠️ **Nunca um som por caractere produzido.** No fim do jogo são 10^50 por segundo: o áudio
  é uma **representação** da atividade, não um contador — a mesma regra do GDD §10 que
  proíbe gerar os caracteres de verdade, aplicada ao ouvido. A taxa de CLACK sobe com a
  **ordem de grandeza** da produção e satura num teto **constante**
- ⚠️ **Volume zero muta o barramento**, e não só abaixa: em −80 dB ele continua sendo
  processado todo quadro
- ⚠️ **Nada aloca por som tocado.** Formas de onda construídas uma vez, tocadores numa
  piscina fixa em rodízio. Som que aloca por evento aparece na `medir_quadro`
- ⚠️ **Barramento sem fonte não ganha barra de volume.** Controle de um barramento onde nada
  toca é controle que a pessoa mexe e conclui que o jogo ignorou. A dívida é declarada em
  `Audio.SEM_FONTE_AINDA`, e o portão morde dos **dois** lados: nome fora da lista tem que
  ter campo, nome dentro dela tem que continuar sem
- As ondas são sintetizadas em código com **semente fixa**, sem versionar binário — como as
  fontes do `Tema`. Semente do relógio daria CLACKs diferentes a cada abertura, e nenhuma
  medição futura seria comparável consigo mesma

---

## Foco, teclado e controle

Teclado, mouse e controle funcionam **juntos**, e não um de cada vez. Quem decide isso é
uma propriedade só, `focus_mode`, e ela tem **dois valores certos em lugares diferentes**:

| Onde | `focus_mode` | Por quê |
|---|---|---|
| HUD e telas de dentro da partida | `FOCUS_NONE` | ⚠️ o espaço **digita um caractere** (issue #6), e `ui_accept` é a mesma ação: botão focado compraria macaco a cada tecla |
| Menu, Arquivos e telas sobrepostas | `FOCUS_ALL` | ali não há o que digitar, e sem foco não há navegação por teclado nem por controle |

Três consequências, e as três já custaram alguma coisa:

- ⚠️ **A moldura de foco precisa aparecer.** Ela já foi `StyleBoxEmpty` no `Tema`, e fazia
  sentido enquanto todo botão era `FOCUS_NONE` — ela nunca chegava a desenhar. No menu ela
  desenha, e é a **única** coisa que diz onde o cursor do teclado está. Sem ela,
  "navegável sem mouse" vira navegar às cegas
- ⚠️ **Tela sobreposta toma o foco, e devolve ao fechar.** `_unhandled_input` não alcança o
  que o foco de interface já consumiu: com um botão do menu focado atrás do painel,
  apertar espaço aperta o botão **de trás** — inclusive o que acabou de abrir a tela. Quem
  garante isso é a base `TelaSobreposta`, e é por isso que ela existe em vez de três cópias
- **Foco não pousa em botão desabilitado.** Abrir o menu com o cursor de teclado parado num
  CONTINUAR apagado é a versão de teclado do mesmo defeito que a issue #34 consertou no
  mouse: um controle que não faz nada parecendo que faz

**O que a fumaça prova aqui**: que os botões pegam foco, que a seta **move** o foco (cadeia
de vizinhos quebrada deixa cada botão focável e nenhum alcançável) e que o ESC fecha a tela
sobreposta. O que ela **não** prova é como a moldura fica — isso é captura.

---

## Números vão para `.tres`, não para o código

Se é um número que você vai querer ajustar sem programar, ele é um campo `@export` ou um
`Resource`. Armas, tipos de sala, grupos de inimigo e itens são projetados assim desde o
primeiro dia.

Ao adicionar um número novo, pergunte: **"eu vou querer mexer nisso numa sessão de
tuning?"** Se sim, exporte. Sessão de tuning boa é aquela em que você não abre um `.gd`
nenhuma vez.

---

## O save é texto, e texto não guarda todo float

⚠️ **Número que o formato não carrega é número que muda sozinho.** O `JSON.stringify` do
Godot guarda **15 dígitos significativos**. Um horário unix já gasta dez antes da vírgula,
então sobram cinco casas — e o que passa disso é descartado na ida ao disco, sem erro,
sem aviso e sem uma linha no console.

Medido no 4.7.2:

| escrito | no arquivo | lido de volta | erro |
|---|---|---|---|
| `1789699053,5935123` | `1789699053.59351` | `1789699053,5935099` | 2,4 µs |
| `1789699701,936` | `1789699701.936` | `1789699701,936` | zero |

A perda acontece **uma vez** e não acumula: a segunda ida e volta devolve idêntico.

**A regra:** campo que vai para o save nasce com a precisão que o formato guarda. Data de
criação é carimbada com `floorf()`, em segundos inteiros, porque quem a consome mostra
DATA — e precisão que ninguém consegue ver só serve para mentir.

⚠️ **E o que pega isso é uma afirmação NA ORIGEM.** Comparar "antes" com "depois da ida e
volta" também acusa, mas aponta para a leitura quando o defeito está no carimbo — e
apontar para o lugar errado custa a tarde inteira.

### Por que isto atravessou a v0.5 inteira

A suíte comparava a data com tolerância `0,0` desde sempre. **Ela passava no Windows e
reprovava no Linux**: o relógio do Windows entrega ~1 ms de resolução, e `…701,936` cabe
inteiro nos quinze dígitos; o do Linux entrega microssegundos, e não cabe.

Foi a primeira coisa que o CI da issue #50 encontrou, no primeiro job que ele conseguiu
rodar — e é a justificativa inteira daquela issue numa linha: **portão que só roda numa
máquina só prova aquela máquina.**

## Antes de mergear

```bash
godot --headless --path . --import                   # só se você mexeu no textos.csv
godot --headless --path . tools/testes/runner.tscn   # segundos
godot --headless --path . tools/teste_fumaca.tscn    # minutos
```

Os dois últimos precisam imprimir `PASSOU`. Rode o de cima primeiro — termina em segundos.

⚠️ **Mexeu no `i18n/textos.csv`? Reimporte antes de rodar.** Os `.translation` são gerados
na importação e não são versionados: linha acrescentada e não importada fica escrita, passa
em todos os portões de texto — a chave existe! — e mesmo assim sai em português no jogo em
inglês. Foi assim que uma tela inteira de configurações saiu metade em cada língua numa
captura, com a suíte verde. Hoje o portão de texto confere **toda** linha cujo inglês
difere do português, então ele reprova em vez de deixar passar.

| | Responde | Quando quebra |
|---|---|---|
| `tools/testes/` | "a conta está certa?" | você mexeu em lógica: dificuldade, economia, progressão, um `.tres` |
| `tools/teste_fumaca.gd` | "a run inteira funciona?" | você mexeu em cena, spawn ou no fluxo de salas |

**[solo]** Os testes fazem o papel que o revisor fazia no time: são a única coisa que
discorda de você antes de o bug chegar no jogo.

### O CI roda os dois sozinho (issue #50)

`.github/workflows/portoes.yml` roda em **push no `main`** e em **todo pull request**. Até
ele existir, as 3.967 afirmações dependiam de alguém lembrar de rodá-las — e portão que
depende de memória é portão que um dia não roda, justamente no dia em que teria pegado
alguma coisa.

Por isso o PR deixou de ser opcional para diff grande: **abra um PR quando quiser que o CI
rode antes**, que é o que a regra de git desta página já previa.

⚠️ **`exit 0` não significa que o portão rodou.** O Godot sai 0 quando a cena principal não
carrega, quando um autoload não sobe, quando o caminho do argumento está errado. Um CI que
confiasse no código de saída ficaria verde para sempre a partir do dia em que alguém
renomeasse `runner.tscn`. Por isso cada passo passa por `tools/ci/exigir_passou.sh`, que
**exige a palavra `PASSOU` na saída** e reprova se aparecer `FALHOU` — as duas metades.

⚠️ **A versão do Godot é fixada no workflow**, e não "a mais recente": engine nova é uma
mudança que ninguém pediu entrando por um caminho que ninguém olha, e ela chegaria como uma
falha de teste sem commit correspondente.

⚠️ **Captura precisa de janela**, e no CI isso é `xvfb-run`. Se ele não estiver disponível o
passo **falha alto** em vez de pular: captura pulada em silêncio é a galeria envelhecendo
sem ninguém saber. E cada captura é conferida uma a uma — "faltou uma foto" é exatamente o
tipo de coisa que ninguém nota num artefato.

### O que cada ferramenta prova — e o que ela NÃO prova

Medido na engine em 2026-08-26, com Godot 4.7.2. Não é teoria.

| Ferramenta | Prova | **Não** prova |
|---|---|---|
| rodar o projeto | O projeto sobe; o que a cena principal alcança carrega | **Nada sobre código que a cena não alcança** |
| importar | Classes globais registradas, assets importados | Idem — não valida scripts órfãos |
| avaliar GDScript solto | Lógica pura, sem precisar de cena | Nada visual, e **nada que toque autoload** |
| `capturar.tscn` | Leitura visual | Só funciona **com janela**, nunca headless |

**A armadilha do falso verde.** Um script com erro de tipo e chamada inexistente foi
colocado em `src/`, sem nenhuma referência na cena principal. Resultado: rodar e importar
deram **exit 0, zero diagnósticos** — com código quebrado no projeto. Rodar o jogo só
carrega o que a cena principal alcança. Enquanto o jogo tiver pouca coisa ligada na cena,
**exit 0 não significa quase nada** — e esse é justamente o período em que dá para se
enganar achando que está tudo verde. Que é exatamente o período em que este projeto está.

**Como detectar de verdade.** A primeira suite de `tools/testes/` varre todo `.gd` de
`src/` e tenta carregar. O detector confiável é `can_instantiate()`:

```gdscript
var s: Script = ResourceLoader.load(caminho, "Script", ResourceLoader.CACHE_MODE_IGNORE)
if s == null or not s.can_instantiate():
    # quebrado
```

Os dois jeitos óbvios **não** funcionam:

- `load(...) == null` — nunca dá `null`. Script com erro de parse volta como objeto; os
  erros só aparecem no stderr. Testado: a varredura reportou zero quebrados enquanto o
  stderr cuspia três erros de parse.
- `reload()` — dá falso positivo. Retorna `22` (`ERR_UNAVAILABLE`) em qualquer script que
  já tenha instância viva, o que inclui **todo autoload**. O `event_bus.gd`, saudável,
  retornou 22.

**Headless não renderiza.** `DisplayServer.get_name()` devolve `"headless"` e
`FEATURE_SUBWINDOWS` é `false`. Qualquer coisa que dependa de pixel na tela precisa de
janela de verdade.

**Autoload novo exige reabrir o editor.** O Godot lê a seção `[autoload]` do
`project.godot` uma vez, no boot, e guarda em memória. Se o `project.godot` for editado por
fora com o editor aberto — que é exatamente o que acontece quando o autoload é adicionado
por script ou por MCP — o editor continua sem conhecer o identificador, e **todo script que
o mencionar** passa a acusar:

```text
Compile Error: Identifier not found: EventBus
Failed to load script "res://src/..." with error "Compilation failed"
```

O erro é convincente e mentiroso: o código está certo, o `project.godot` está certo, e uma
engine nova sobe com exit 0. Antes de investigar um erro desses, **rode o projeto numa
instância limpa**. Se lá passa, o problema é a sessão do editor, não o código — feche e
reabra. Vale para cada autoload novo.

**Duas armadilhas ao diagnosticar isso pelo editor:**

- **`can_instantiate()` com `CACHE_MODE_IGNORE` dá falso negativo** quando o script tem
  instâncias vivas — e uma cena aberta no editor conta. Ao sondar o editor, todos os
  scripts do jogo apareceram como "não compilam", inclusive dois que nem mencionam
  `EventBus`. Era artefato da sonda. Use `load()` normal para essa checagem; o
  `CACHE_MODE_IGNORE` serve ao runner headless, onde nada do jogo está instanciado.
- **`/root/EventBus` não existe dentro do editor**, e isso é normal. O editor registra o
  autoload como identificador para o parser (`ProjectSettings.has_setting("autoload/…")`
  devolve `true`) mas não cria o nó. O nó só existe no jogo rodando. Checar pelo nó leva a
  concluir que o autoload está quebrado quando ele está perfeito.

O que **de fato** prova que o editor está são: os nós da cena resolverem seus tipos
(`inimigo is InimigoBase`) e `load()` normal devolver os scripts.

**Avaliação de GDScript solto não carrega autoloads.** Rodar com `--script` sobe um
`MainLoop` sem passar pela lista de autoloads do `project.godot`. Qualquer script que
mencione `EventBus` — direta ou indiretamente, inclusive uma classe que ele importe — falha
com `Compile Error: Identifier not found: EventBus`. Medição de código de gameplay tem que
rodar **como cena**.

**Mexeu num número de balanceamento?** Rode o unitário. Boa parte das suites existe
justamente para pegar erro de tuning. Erros dessa família, dos projetos anteriores:

- cadência 0 virando divisão por zero
- sala de recompensa com inimigo dentro
- custo de inimigo zerado — o sorteio de composição nunca terminaria
- custo de upgrade não crescente — compra infinita
- arma perdendo uma propriedade que o GDD promete

**Criou lógica pura nova?** Adicione uma suite: crie o arquivo em `tools/testes/`, herde de
`TesteBase`, implemente `executar()` e liste em `SUITES` no `runner.gd`. Não há framework —
`ok`, `igual`, `perto` e `entre` dão conta, e cada falha já diz o esperado e o obtido.
**Nenhum teste é escrito antes de existir lógica para testar.**

### Visual

```bash
godot --path . tools/gerar_galeria.tscn                    # galeria versionada
godot --path . tools/capturar.tscn                          # quadro avulso
```

A galeria são capturas fixas sobrescritas em `docs/capturas/` e **versionadas**: como as
imagens estão no git, o diff mostra exatamente o que mudou na tela — é o jeito mais barato
de perceber que um ajuste de shader estragou a leitura. Obrigatória antes de publicar
release ou atualizar página de loja.

O `capturar.tscn` é para olhar, não para versionar; sai em `user://capturas`. Vários
problemas de leitura visual só aparecem numa captura parada.

### Réguas

Além dos testes que passam ou falham, existem **réguas** em `tools/`: elas não aprovam
nada, elas **medem**, e a saída delas é o que sustenta uma sessão de tuning. Cada uma entra
junto do sistema que ela mede — régua que mede o vazio é cerimônia. Ver `TUNING.md`.

Nos projetos anteriores foram `medir_quadro` (tempo de quadro: média, p95, p99, frames
perdidos), `medir_ritmo` (tempo médio por unidade de progresso) e `medir_composicao`.
A primeira régua a escrever é a que sustenta a decisão de design mais cara ainda não
medida — foi assim que se descobriu que o gargalo de uma máscara pintável era o laço por
pixel e não o upload de textura (0.079 ms), o que obrigou o pincel a virar LUT
pré-calculada.

---

## Editor ao vivo (MCP)

Este projeto tem o addon `godot_mcp` habilitado: dá para editar cenas e nós, injetar input
no jogo rodando, congelar o relógio e ler estado de runtime como JSON, com o editor aberto
(ver `README.md`).

- **O que ficar tem que estar no arquivo versionado.** Depois de mexer ao vivo, salve a
  cena e confira o `git diff` antes de commitar.
- **Para testar `.gd` editado, basta parar e rodar o jogo** — o jogo lançado carrega os
  scripts do disco. Reiniciar o editor só é necessário para staleness do lado do editor:
  código `@tool`/addon, shader com compile cacheado, e `project.godot` editado por fora.
- **Depois de editar o `project.godot` no disco, cheque staleness** — o editor nunca relê o
  arquivo sozinho. É a mesma armadilha do autoload descrita acima.
- **Prefira digest de estado de runtime a screenshot.** Texto é barato e não decai;
  screenshot só quando a pergunta for mesmo sobre aparência.

---

## Checagem de arte

A identidade visual é **cânone** e mora em `docs/ARTE.md`: paleta oficial, mascote, máquina
de escrever, tipografia, linguagem de UI, progressão visual por tier, raridades, o que
evitar e os prompts-base para gerar asset novo.

Antes de criar ou revisar qualquer arte, UI, ícone, shader, partícula ou prompt de imagem,
passe pela checagem da última seção de lá. Não invente paleta, fonte ou estilo por conta
própria — a identidade só funciona se for a mesma em todas as eras do jogo.

Cor de identidade **não** vai para `.tres`: ela não é número de balanceamento e não muda em
sessão de tuning. Vive numa constante (`Paleta`), com o hex vindo de `docs/ARTE.md`.

---

## Checagem de design

`docs/GDD.md` é **cânone** e vence os outros documentos — inclusive este. Antes de mergear
qualquer coisa com texto, economia ou progressão, confira se ela continua fiel a ele.
Mudou de ideia sobre o jogo? Muda no GDD primeiro, e aí implementa.

Três perguntas que valem para toda mudança de conteúdo:

1. **O número ganhou significado?** O GDD §45 diz que o diferencial não é o número subindo,
   é o jogador descobrir o que ele significa. Produção nova sem marco correspondente é
   número solto.
2. **O tom cabe na escala?** O humor muda com o jogo (§21): "macaco apertou tecla" no
   começo, científico no meio, filosófico depois, absurdo no fim. Piada de era errada
   quebra a progressão de tom.
3. **Nada está sendo simulado à toa?** §10 é categórico: o jogo calcula probabilidade, não
   produz caractere. Se uma feature nova precisa gerar texto de verdade para funcionar, ela
   está errada.

Quando `docs/LORE.md` existir, ele entra acima do GDD na mesma checagem.

Ordem de precedência hoje: `docs/GDD.md` → `docs/ARTE.md` (visual) → este documento →
`docs/ARQUITETURA.md` e `TUNING.md`.
