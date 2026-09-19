# Just Keep Typing

Incremental sobre o Teorema do Macaco Infinito, em **Godot 4.7**.

Um macaco, uma máquina de escrever e teclas apertadas ao acaso. Você acompanha o contador
sair de 1 caractere para números que já não cabem em nenhuma comparação humana — e o
**Panorama** existe justamente para dizer o que cada número significa.

## Documentos

| Arquivo | O que é |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | Design do jogo. **Cânone** — vence os outros documentos. |
| [`docs/ARTE.md`](docs/ARTE.md) | Direção de arte. Cânone visual. |
| [`docs/PLANO.md`](docs/PLANO.md) | Plano de desenvolvimento em quatro versões, mapeado nas issues. |
| [`CONVENCOES.md`](CONVENCOES.md) | Regras de código, git e testes. |
| [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) | Autoloads, pastas e fluxo de comunicação. |
| [`TUNING.md`](TUNING.md) | Como ajustar balanceamento sem abrir um `.gd`. |
| [`docs/decisoes/`](docs/decisoes/) | Uma decisão de design por arquivo. |
| [`docs/ASSETS.md`](docs/ASSETS.md) | O briefing de cada asset do menu, e o tamanho de cada um. |
| [`docs/ENTREGA-v0.5.md`](docs/ENTREGA-v0.5.md) | A devolutiva das issues #39–#49: o que mudou, os doze defeitos silenciosos que viraram portão, e **o que não está provado**. |

## Testes

```bash
godot --headless --path . --import                   # só se você mexeu no textos.csv
godot --headless --path . tools/testes/runner.tscn   # segundos
godot --headless --path . tools/teste_fumaca.tscn    # segundos
```

Os dois últimos precisam imprimir `PASSOU`. Os `.translation` são gerados na importação e
não são versionados — ver `CONVENCOES.md`, "Antes de mergear".

## Réguas

Régua não aprova nem reprova: ela **mede**. Ver [`TUNING.md`](TUNING.md).

```bash
godot --headless --path . tools/medir_ritmo.tscn                  # tempo até cada marco
godot --path . tools/medir_quadro.tscn --resolution 1920x1080     # tempo de quadro
godot --headless --path . tools/medir_economia.tscn               # quando prestigiar vale
```

`medir_quadro` precisa de janela: headless não renderiza.

## Galeria versionada

Uma captura por era, mais o menu, os Arquivos e o **banner de descoberta**, em
`docs/capturas/`.

⚠️ **O banner tem foto própria porque ele só existe por alguns segundos.** Ele não aparece em
nenhuma captura de era — e sem uma foto dele, nenhum diff mostraria que ele parou de caber,
de contrastar ou de quebrar linha no dia em que alguém mexesse num texto de descoberta. Pelo
mesmo motivo as capturas de era **limpam a fila de avisos** antes do clique: a foto da era é
sobre a era. As imagens estão no
git de propósito: **o diff mostra o que mudou na tela**, e é o jeito mais barato de
perceber que um ajuste estragou a leitura de uma era que ninguém estava olhando.

As duas primeiras entraram como `menu_rascunho.png` e `arquivos_rascunho.png` na issue #38,
quando a interface do caminho era feia de propósito. A issue #46 trouxe a mesa e elas
passaram a se chamar `menu.png` e `arquivos.png` — o "rascunho" descrevia um estado, e o
estado passou. O antes continua no histórico.

```bash
godot --path . tools/gerar_galeria.tscn --resolution 1920x1080
```

## Capturas

```bash
godot --path . tools/capturar.tscn --resolution 1920x1080
godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=panorama
godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=letras producao=5e17
godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=panorama idioma=en
godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=opcoes idioma=en aba=2
godot --path . tools/capturar.tscn -- cenario=abertura instante=0.8
godot --path . tools/capturar.tscn -- cenario=principal largura=1280 altura=720 escala=1.25
godot --path . tools/capturar.tscn --resolution 1920x1080 -- cenario=descobertas contraste=1
```

`instante=` escolhe o segundo da abertura a fotografar — o relógio dela é **adiantado**, e
não esperado, para duas capturas do mesmo commit darem a mesma imagem.

`escala`, `escala_do_texto` e `contraste` entram pelo `Config`, que é a porta do jogador.
Escala acima de 100% na menor resolução é o caso que estoura tudo — e caractere não é pixel,
então só a foto mostra rótulo saindo do botão.

Cenários: `menu`, `menu_cheio`, `arquivos`, `arquivos_cheio`, `principal`, `panorama`,
`descobertas`, `estatisticas`, `letras`, `banner`. Os que começam com `menu` e `arquivos` param antes
da partida; todos os outros entram numa. O sufixo `_cheio` **joga um pouco e volta**, para a
foto ter um Manuscrito no disco — sem save o CONTINUAR sai apagado e o resumo dele não
existe.

A captura em `idioma=en` é o único jeito de ver texto estourando botão — caractere não é
pixel. Ela entra pelo `Config`, e não por `TranslationServer.set_locale`: todo rótulo deste
jogo é montado em código e quem repinta é `EventBus.idioma_mudou`.

Precisa de janela — headless não renderiza. Sai em `user://capturas`.

## Requisitos

- [Godot 4.7.2 (stable, win64)](https://godotengine.org/download)

## Como abrir

Abra o Godot e importe o arquivo `project.godot` desta pasta.

## Estrutura

```
project.godot   # configuração do projeto
main.tscn       # cena principal
icon.svg        # ícone do projeto
```

## Integração MCP (Godot + Claude Code)

O servidor [`@satelliteoflove/godot-mcp`](https://github.com/satelliteoflove/godot-mcp)
v4.1.11 conversa com o **editor aberto** por WebSocket, via o addon em
`addons/godot_mcp/` (este é versionado). Dá 21 ferramentas / 86 ações: editar cenas
e nós ao vivo, injetar input no jogo rodando, congelar e avançar o relógio do jogo
passo a passo, ler estado de runtime como JSON, tirar screenshots, rodar GDScript
dentro do jogo.

Registrado com escopo `local` (fica no seu `.claude.json`, **não** é versionado):

```bash
claude mcp add godot-live --scope local -- npx -y @satelliteoflove/godot-mcp
```

O addon já está habilitado em `project.godot`:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")

[autoload]
MCPGameBridge="res://addons/godot_mcp/game_bridge/mcp_game_bridge.gd"
```

Para atualizar o addon quando sair versão nova:

```bash
npx -y @satelliteoflove/godot-mcp --install-addon .
```

**O editor do Godot precisa estar aberto** para as ferramentas ao vivo funcionarem.
