# Arquitetura

O que o `project.godot` não pode documentar. Ele é reescrito e normalizado toda vez que o
Godot salva: seções são reordenadas e **comentários são apagados**. Então mora aqui.

Regras que sustentam tudo isto: `../CONVENCOES.md`.

---

## 1. Autoloads

Ordem importa: o Godot instancia na ordem da seção `[autoload]`, e um autoload só enxerga
os que vieram antes dele.

| Ordem | Nome | Arquivo | Papel |
|---|---|---|---|
| 1 | `EventBus` | `src/autoload/event_bus.gd` | Só sinais. Não guarda estado, não tem lógica. |
| 2 | `MCPGameBridge` | `addons/godot_mcp/game_bridge/…` | Ponte do editor ao vivo. Ferramenta, não jogo. |

`EventBus` é o primeiro de propósito: qualquer autoload futuro (`Save`, `Config`,
`Deterioracao`, `Audio`) vai querer emitir nele já no `_ready`.

⚠️ **Autoload novo exige reabrir o editor.** O Godot lê `[autoload]` uma vez, no boot. Se o
`project.godot` for editado por fora com o editor aberto, o editor continua sem conhecer o
identificador e acusa `Identifier not found` em todo script que o mencione — com o código
perfeito. Detalhes e como não cair na armadilha ao diagnosticar: `../CONVENCOES.md`.

---

## 2. Pastas

| Pasta | Conteúdo |
|---|---|
| `src/autoload/` | Autoloads. Um arquivo por autoload. |
| `src/player/`, `src/weapons/` | Jogador e armas |
| `src/enemies/` | Inimigos e chefe |
| `src/mapa/`, `src/ui/` | Andar, salas e interface |
| `src/items/` | Itens e loot |
| `data/` | `.tres` de balanceamento — nenhum código |
| `i18n/` | `textos.csv`: `keys,pt_BR,en`. A chave É o texto em português. |
| `tools/` | Testes, réguas e capturas. Nada daqui entra no build. |
| `docs/decisoes/` | Uma decisão de design por arquivo, numerada (`0001-….md`) |
| `docs/capturas/` | Galeria versionada — o diff das imagens mostra o que mudou na tela |

---

## 3. Fluxo de comunicação

```
inimigo ──emit──> EventBus ──signal──> HUD
                     ▲
                     └── qualquer sistema conecta sem saber quem emite
```

Ninguém alcança ninguém por caminho de nó. A única exceção é buscar por **grupo**
(`get_first_node_in_group("player")`), que é como os inimigos acham o alvo.

---

## 4. Estado global

Valor derivado de estado global se calcula **na hora de usar**, nunca é congelado no spawn.
Quando existir o autoload de dificuldade/progressão, o padrão é:

```gdscript
func velocidade_atual() -> float:
    return velocidade_base * Deterioracao.multiplicador_velocidade()
```

Cache só com motivo medido, e com comentário dizendo qual foi.

---

## 5. Traduções

`i18n/textos.csv` existe desde o início, ainda sem linhas — não há texto de interface. O
registro em `[internationalization]` do `project.godot` entra junto do primeiro texto,
porque os `.translation` são gerados na importação e não são versionados (`*.translation`
está no `.gitignore`).
