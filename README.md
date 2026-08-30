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

## Testes

```bash
godot --headless --path . tools/testes/runner.tscn   # segundos
godot --headless --path . tools/teste_fumaca.tscn    # minutos
```

Os dois precisam imprimir `PASSOU`.

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
