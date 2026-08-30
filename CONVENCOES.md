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
- Se a arte for pixel art de escala inteira, **só a resolução nativa é exata**; as outras
  esticam e um pixel quadrado passa a ter larguras diferentes na mesma imagem. Elas existem
  porque monitor menor que o canvas é real — diga isso na dica da tela

**Campo de lista é genérico.** `Config.rotulos_de` / `indice_de` / `escolher` são a API que
a tela de opções usa para montar **qualquer** campo do tipo lista sem saber o que ela
contém. Opção nova é uma entrada em `PADRAO`, uma em `CAMPOS` e um ramo em cada uma das
três — nenhuma linha da tela de opções muda.

---

## Números vão para `.tres`, não para o código

Se é um número que você vai querer ajustar sem programar, ele é um campo `@export` ou um
`Resource`. Armas, tipos de sala, grupos de inimigo e itens são projetados assim desde o
primeiro dia.

Ao adicionar um número novo, pergunte: **"eu vou querer mexer nisso numa sessão de
tuning?"** Se sim, exporte. Sessão de tuning boa é aquela em que você não abre um `.gd`
nenhuma vez.

---

## Antes de mergear

```bash
godot --headless --path . tools/testes/runner.tscn   # segundos
godot --headless --path . tools/teste_fumaca.tscn    # minutos
```

Os dois precisam imprimir `PASSOU`. Rode o de cima primeiro — termina em segundos.

| | Responde | Quando quebra |
|---|---|---|
| `tools/testes/` | "a conta está certa?" | você mexeu em lógica: dificuldade, economia, progressão, um `.tres` |
| `tools/teste_fumaca.gd` | "a run inteira funciona?" | você mexeu em cena, spawn ou no fluxo de salas |

**[solo]** Os testes fazem o papel que o revisor fazia no time: são a única coisa que
discorda de você antes de o bug chegar no jogo.

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
