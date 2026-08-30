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
| 2 | `Jogo` | `src/autoload/jogo.gd` | Só estado da partida. Não calcula, não desenha, não tem `_process`. |
| 3 | `MCPGameBridge` | `addons/godot_mcp/game_bridge/…` | Ponte do editor ao vivo. Ferramenta, não jogo. |

`Jogo` está logo depois do `EventBus` porque `Config` e `Save` ainda não existem — quando
entrarem, os dois se encaixam antes dele, sem que `Jogo` precise mudar de lugar.

`EventBus` é o primeiro de propósito: qualquer autoload futuro vai querer emitir nele já no
`_ready`.

**Ordem planejada**, conforme os autoloads entrarem (ver `PLANO.md`):

```text
EventBus → Config → Save → Jogo → Economia → Marcos → Descobertas → Teoremas → MCPGameBridge
```

O motivo de cada posição:

- `Config` antes de `Save` porque idioma e opções são da **instalação**, não da partida, e
  precisam existir antes de qualquer coisa formatar texto ou número
- `Save` antes de `Jogo` porque `Jogo` nasce do que foi carregado
- `Jogo` antes de `Economia` porque `Economia` só calcula: quem guarda estado é o `Jogo`
- `Marcos`, `Descobertas` e `Teoremas` por último entre os do jogo — todos leem produção,
  nenhum é lido por ela

Os nomes vêm de [`decisoes/0002-codigo-em-portugues.md`](decisoes/0002-codigo-em-portugues.md),
que traduz a estrutura em inglês sugerida pelo GDD §28–§30.

⚠️ **Autoload novo exige reabrir o editor.** O Godot lê `[autoload]` uma vez, no boot. Se o
`project.godot` for editado por fora com o editor aberto, o editor continua sem conhecer o
identificador e acusa `Identifier not found` em todo script que o mencione — com o código
perfeito. Detalhes e como não cair na armadilha ao diagnosticar: `../CONVENCOES.md`.

---

## 2. Pastas

| Pasta | Conteúdo |
|---|---|
| `src/autoload/` | Autoloads. Um arquivo por autoload. |
| `src/nucleo/` | Lógica pura, sem cena: `Grande`, `Formatador`. Testável headless. |
| `src/producao/` | Macacos, máquinas, salas — quem gera caractere |
| `src/progressao/` | Marcos, descobertas, teoremas |
| `src/ui/` | Telas: HUD, Panorama, Descobertas, Estatísticas, Opções |
| `src/cena/` | A cena das eras e a câmera que se afasta |
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
