# 0002 — Código em português, apesar do GDD

**Data:** 2026-08-30
**Estado:** aceita

## Contexto

O GDD (§28–§30) sugere uma estrutura com nomes em inglês: `GameManager`,
`economy_manager.gd`, `BigNumber`, `MonkeyData`, `scenes/`, `scripts/`, `resources/`.

`CONVENCOES.md` manda o contrário: código em português — variável, função, sinal e
comentário — e pastas em `src/`, `data/`, `tools/`.

O jogo se chama Just Keep Typing e o repositório tem nome em inglês, o que reabre a dúvida
de qual das duas ganha.

## Decisão

Vence o português. O GDD é cânone sobre **o que o jogo é**, não sobre como o código se
chama — a estrutura dele é sugestão, e está marcada como "aproximada" no próprio
documento.

Tradução dos nomes, para ninguém reabrir a discussão a cada arquivo novo:

| GDD | Aqui |
|---|---|
| `GameManager` | `Jogo` — autoload, só estado |
| `EconomyManager` | `Economia` |
| `PrestigeManager` | `Teoremas` |
| `MilestoneManager` | `Marcos` |
| `DiscoveryManager` | `Descobertas` |
| `SaveManager` | `Save` |
| `offline_progress.gd` | `ProgressoOffline` |
| `number_formatter.gd` | `Formatador` — classe, não autoload |
| `BigNumber` | `Grande` — classe pura, ver [0001](0001-numeros-grandes.md) |
| `MonkeyData` | `DadosMacaco` |
| `MachineData` | `DadosMaquina` |
| `Milestone` | `DadosMarco` |
| `scenes/`, `scripts/` | `src/<area>/`, cena e script juntos por área |
| `resources/` | `data/` |

O `id` de cada `.tres` continua em `snake_case` sem acento (`palavras_do_portugues`),
porque ele vai para o save e para chave de dicionário — acento em chave de save é fonte de
bug de codificação, não de clareza.

## Por quê

O nome do jogo é embalagem; o código é ferramenta de trabalho de uma pessoa só, brasileira.
Misturar idiomas dentro do código custa mais do que ganha: `monkey_count` ao lado de
`velocidade_atual` obriga a lembrar, em cada linha, de qual metade do projeto aquele nome
veio.

O que **não** muda para o português continua sendo o que o Godot impõe (`_ready`,
`queue_free`, `position`) — e agora também o nome do jogo, do repositório e da pasta.

## Consequências

- O texto **de interface** não tem nada a ver com isto: ele nasce em português porque é a
  língua de origem do jogo, e vai para `i18n/textos.csv` com a coluna `en` preenchida na
  mesma mudança.
- Quem ler o GDD e o código lado a lado vai ver nomes diferentes. Esta tabela é a ponte, e
  por isso ela vive aqui e não numa mensagem de commit.
