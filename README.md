# Infinite Monkey

Projeto de jogo em **Godot 4.7**.

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
