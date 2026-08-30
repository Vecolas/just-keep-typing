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

Dois servidores MCP estão registrados com escopo `local` (ficam no seu
`.claude.json`, **não** são versionados):

### `godot-live` — edição em tempo real (principal)

[`@satelliteoflove/godot-mcp`](https://github.com/satelliteoflove/godot-mcp) v4.1.11.
Conversa com o **editor aberto** por WebSocket, via o addon em `addons/godot_mcp/`
(este sim é versionado). Dá 21 ferramentas / 86 ações: editar cenas e nós ao vivo,
injetar input no jogo rodando, congelar e avançar o relógio do jogo passo a passo,
ler estado de runtime como JSON, tirar screenshots, rodar GDScript dentro do jogo.

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

### `godot` — operações por linha de comando

[`@coding-solo/godot-mcp`](https://github.com/Coding-Solo/godot-mcp). Não usa addon;
roda o Godot headless pelo CLI. Hoje é praticamente redundante com o `godot-live`.

```bash
claude mcp add godot --scope local \
  --env GODOT_PATH="C:\Users\alcyn\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" \
  -- npx -y @coding-solo/godot-mcp
```

Para remover: `claude mcp remove godot --scope local`

Se o executável do Godot mudar de lugar, refaça o comando acima com o novo caminho.
