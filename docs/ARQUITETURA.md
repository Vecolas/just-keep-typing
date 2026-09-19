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
| 3 | `Save` | `src/autoload/save.gd` | Grava, carrega, migra, verifica e guarda backup. |
| 3.5 | `Combo` | `src/autoload/combo.gd` | O multiplicador de digitação (issue #54). |
| 4 | `Economia` | `src/autoload/economia.gd` | Produção, custo, compra. Só calcula. |
| 5 | `Marcos` | `src/autoload/marcos.gd` | O Panorama: quando um número ganha significado. |
| 6 | `Descobertas` | `src/autoload/descobertas.gd` | A chance por caractere e as sete categorias. |
| 7 | `Teoremas` | `src/autoload/teoremas.gd` | O primeiro prestígio e a Árvore. |
| 8 | `Eventos` | `src/autoload/eventos.gd` | Os eventos aleatórios. |
| 9 | `Automacao` | `src/autoload/automacao.gd` | Gerente, técnico, administrador e diretor. |
| 10 | `Fragmentos` | `src/autoload/fragmentos.gd` | O segundo prestígio. |
| 11 | `Audio` | `src/autoload/audio.gd` | Os cinco barramentos e os sons. Cria o mixer; não lê opção. |
| 11.5 | `Avisos` | `src/autoload/avisos.gd` | O que vira aviso, em que **faixa** da tela e por quanto tempo. |
| 12 | `Config` | `src/autoload/config.gd` | As opções da **instalação**, e onde cada slot mora. |
| 13 | `Autosave` | `src/autoload/autosave.gd` | **Quando** gravar. Quem grava é o `Save`. |
| 14 | `Cenas` | `src/autoload/cenas.gd` | O caminho Boot → Menu → Arquivos → Partida → Menu. |
| 15 | `MCPGameBridge` | `addons/godot_mcp/game_bridge/…` | Ponte do editor ao vivo. Ferramenta, não jogo. |

⚠️ **`Audio` vem ANTES do `Config`, e isso é a ordem inteira.** `Config._aplicar_audio()`
ajusta o volume de cada barramento na abertura, e barramento que ainda não existe não tem
volume para ajustar. Por isso o `Audio` não lê opção nenhuma no `_ready` dele: quem vem
depois **puxa** o que precisa, e a leitura acontece quando o `Config` pede.

`Autosave` e `Cenas` são os dois últimos do jogo porque são os únicos que **mandam** nos
outros: um chama `Save.gravar()`, o outro chama `Config`, `Save` e `Economia` em ordem.
Autoload que orquestra vem depois de tudo que ele orquestra.

⚠️ **Autoload novo exige reabrir o editor.** O Godot lê `[autoload]` uma vez, no boot. Se o
`project.godot` for editado por fora com o editor aberto, o editor continua sem conhecer o
identificador e acusa `Identifier not found` em todo script que o mencione — com o código
perfeito. Detalhes e como não cair na armadilha ao diagnosticar: `../CONVENCOES.md`.

---

## 1.1. O caminho das cenas

```text
main.tscn (Boot)  ──>  Abertura  ──>  Menu  ──>  Arquivos  ──>  Partida  ──>  Menu
                          │
                          └── pulada inteira quando `ja_viu_abertura` (issue #47)
```

⚠️ **Quem já viu a abertura pula ANTES de ela ser montada**, e não dentro dela. Sem isso,
quem abre o jogo todo dia pagaria o custo de montar uma cena inteira para ela se desmontar
sozinha no quadro seguinte — e um quadro de tela preta é uma piscada que a pessoa vê. Quem
decide é `Cenas.ir_para_abertura()`; o Boot só pede.

`main.tscn` **não é mais a partida** (issue #38). Ele é o Boot: não desenha nada, segura o
nó do grupo `raiz_de_cena` e pede o menu ao `Cenas`. Quem monta e desmonta cena é o
`Cenas`, e sempre no mesmo nó de grupo.

Três regras que valem ouro aqui, e as três já custaram um bug:

- **Monta em nó de grupo, não com `change_scene_to_packed`.** Trocar a cena da árvore
  libera a cena atual — e a cena atual, quando a fumaça roda, é a própria fumaça.
- **Tira da árvore antes de liberar.** `queue_free()` sozinho deixa a cena velha viva até o
  fim do quadro: duas Partidas com `_process` mexendo no mesmo `Jogo`.
- **Quem carrega o save é o `Cenas`, não a `Partida`.** Carregar nos dois creditaria a
  produção offline duas vezes.

O relógio da produção offline para no instante em que o **jogo** abre, e não no instante em
que a partida abre — ver [decisão 0005](decisoes/0005-o-relogio-do-offline.md).

**Menu e Partida hospedam as mesmas telas sobrepostas.** Opções e Créditos são instâncias
dentro do `menu_tela.tscn`; Opções, Panorama, Descobertas, Estatísticas e Teoremas são
instâncias dentro do `partida.tscn`. Só uma das duas cenas está montada por vez, então as
duas instâncias de `OpcoesTela` nunca coexistem — e nenhuma delas sabe da outra: as duas
escutam `EventBus.opcoes_pedidas`.

⚠️ **Sair grava, e pelos dois caminhos.** Fechar pelo X da janela grava porque a Partida
escuta `NOTIFICATION_WM_CLOSE_REQUEST`; o botão SAIR do menu **não passa por ela** —
`get_tree().quit()` não dispara aquela notificação. Por isso o par mora em `Cenas.sair()`,
que é quem sabe se há partida aberta.

---

## 2. Pastas

| Pasta | Conteúdo |
|---|---|
| `src/autoload/` | Autoloads. Um arquivo por autoload. |
| `src/nucleo/` | Lógica pura, sem cena: `Grande`, `Formatador`, `Relogio`. Testável headless. |
| `src/producao/` | Macacos, máquinas, salas — quem gera caractere |
| `src/progressao/` | Marcos, descobertas, teoremas, `Manuscrito` (o cartão de um slot) e `NomesDeManuscrito` (o que o nome pode ser) |
| `src/ui/` | Telas: Abertura, Menu, Arquivos, HUD, Panorama, Descobertas, Estatísticas, Opções, Créditos — mais `TelaSobreposta` (base das que abrem por cima), `BotaoDeSegurar`, `CenarioDoMenu` e `AssetsDoMenu`. E as quatro peças da loja e dos avisos: `VitrineDeUpgrades` (o que a loja mostra), `CartaoDeUpgrade` (como cada upgrade se desenha), `Alcance` (os três estados de compra) e `BannerDeDestaque` (a faixa do topo) |
| `src/cena/` | O Boot, a Partida, a cena das eras e a câmera que se afasta |
| `assets/menu/` | A pixel art do menu (issue #45). O briefing é `docs/ASSETS.md`; a tabela que vale é `src/ui/assets_do_menu.gd` |
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

`i18n/textos.csv` tem uma linha por texto que o jogador lê, em três colunas
(`keys,pt_BR,en`), e a chave **é** o texto em português. Está registrado em
`[internationalization]` no `project.godot`; os `.translation` são gerados na importação e
**não** são versionados (`*.translation` está no `.gitignore`).

Quem cobra é o `teste_texto` — e ele varre **três** origens de literal, porque as três já
deixaram passar texto sem tradução:

| Origem | Como é varrida |
|---|---|
| `.tscn` de `src/` | o `text` de cada `Control`, menos o marcado como não traduzível |
| `.tres` de `data/` | `nome`, `descricao`, `titulo` e `texto` de todo dado |
| `.gd` de `src/` | os literais das **duas** funções de tradução: a das cenas e a `_traduzir` das classes estáticas, que não têm `self` |

⚠️ **Molde que mora em constante não é literal na hora do uso** — `"%s mil"` chega ao
jogador por uma variável, e varredura de literal não alcança variável. Esses são cobrados
pela **fonte**: a suíte lê a própria tabela do `Formatador` e exige linha no CSV para cada
molde dela.
