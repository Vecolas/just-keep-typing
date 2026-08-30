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

Este ambiente usa o servidor MCP [`@coding-solo/godot-mcp`](https://github.com/Coding-Solo/godot-mcp),
que permite ao Claude Code rodar o projeto, capturar erros do console, abrir o editor
e inspecionar cenas.

Registrado com escopo `local` (não versionado):

```bash
claude mcp add godot --scope local \
  --env GODOT_PATH="C:\Users\alcyn\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" \
  -- npx -y @coding-solo/godot-mcp
```

Se o executável do Godot mudar de lugar, refaça o comando acima com o novo caminho.
