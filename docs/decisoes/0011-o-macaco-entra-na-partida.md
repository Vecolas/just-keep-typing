# 0011 — O macaco entra na partida

**Contexto:** a reforma de interface do plano de UX. Ela pede três coisas que a
[decisão 0006](0006-pixel-art-no-menu-tipografia-na-partida.md) parecia proibir, e a
contradição precisa ser resolvida no documento antes de existir um único pixel na tela.

## O problema

A decisão 0006 fechou assim:

> **Pixel art no MENU. Tipografia na PARTIDA. E as duas convivem de propósito.**

E o motivo dela era preciso, não estético:

> Seriam catorze eras de assets, cada uma com máquinas, salas e escalas próprias — e o jogo
> que hoje representa 10^50 com quatro linhas de ASCII passaria a precisar de arte para cada
> ordem de grandeza.

A reforma de interface pede o contrário em três lugares: um macaco e uma máquina de
escrever de verdade no centro da tela, ícones nos cabeçalhos da loja, e molduras nos
painéis.

## A decisão

**A regra da 0006 continua valendo para o que ESCALA. Ela nunca valeu para o que não
escala — e isso não estava escrito.**

A partida tem duas coisas diferentes no centro da tela, e a 0006 tratou as duas como uma:

| O que é | Como se comporta | Como se desenha |
|---|---|---|
| a **grade** de fundo | multiplica por era; encolhe com a câmera; vai de 1 a 225 cópias | ASCII, como sempre |
| a **máquina da frente** e o **macaco** | são **dois**, de tamanho **fixo**, em **todas** as catorze eras | pixel art |

O custo que a 0006 recusou era "um asset por era". A máquina da frente e o macaco nunca
foram por era: o próprio `eras.gd` já dizia, desde a issue #26, que *"a maquina da frente
NAO encolhe junto com as outras -- ela fica no tamanho de sempre, e o que muda atras dela e
o mundo"*. São **dois PNGs para o jogo inteiro** — e os dois **já existem**, desenhados para
o menu nas issues #45 e #46.

Pelo mesmo raciocínio entram:

- os **ícones de família** da loja (`icone_banana`, `icone_engrenagem`, `icone_papel`,
  `icone_infinito`) — quatro peças que já existem, uma por família, para o jogo inteiro
- as **molduras** dos painéis, que são `StyleBox` e não arte por conteúdo

## O que esta decisão NÃO muda

- **A grade continua ASCII.** É ela que atravessa catorze eras e 10^50, e é ela que a issue
  #26 existe para não precisar de arte.
- **Nenhum asset novo foi pedido.** Toda peça usada aqui já estava no disco. Isto não é
  detalhe de implementação: pedir um segundo conjunto de ícones para o mesmo significado
  criaria duas famílias que divergem no próximo lote (`CONVENCOES.md`, "derive em vez de
  duplicar").
- **A escala continua inteira**, e continua **calculada**, nunca cravada — a área do centro
  muda com a resolução e com a escala de interface. Escala fracionária em pixel art é o
  borrão que a 0006 se compromete a evitar, e o piso da conta é 1.
- **O texto continua sendo do Godot.** Nenhuma peça tem letra dentro.

## O que esta decisão custa

**1. A partida passa a depender de dois arquivos.** Antes ela subia com zero assets. Hoje,
se `macaco.png` ou `maquina.png` sumirem, a cena precisa continuar utilizável — e continua:
as duas voltam a ser a ASCII de sempre. ⚠️ **E é "as duas ou nenhuma"**: metade em pixel art
e metade em ASCII lê como defeito, e não como arte incompleta (`CONVENCOES.md`, "família se
entrega inteira").

⚠️ **E esse caminho de recurso não é exercitado por portão nenhum.** Ponto cego declarado: o
disco tem os dois arquivos, então a ASCII da frente nunca roda no CI. O que existe é a
`teste_assets` conferindo que as peças declaradas estão lá — ou seja, o portão avisa quando
a pixel art some, e não quando o recurso quebra.

**2. O macaco da partida é o macaco do menu.** Isso é a intenção — a §15 do `ARTE.md` manda
o jogo nunca deixar de parecer ele mesmo, e a mesa do menu passa a ser literalmente a mesa
da partida. O preço é que mexer no `macaco.png` mexe nas duas telas ao mesmo tempo.

**3. A escala de interface não move o cenário, e isso continua valendo.** O painel, os
botões e o texto crescem; o macaco e a máquina são recalculados para a área nova, sempre num
inteiro. A composição vertical entre os dois (catorze pixels de arte) é a mesma do
`CenarioDoMenu`, e é a mesma pelo mesmo motivo: ancorar os dois na mesma linha faria o macaco
pousar em cima da máquina, flutuando.

## O que foi recusado, e por quê

**Pedir um kit de assets novo para a HUD.** O plano previa um lote grande: painéis, botões,
molduras, ícones, cenário central, banners de descoberta. Quase todos os papéis já têm peça
no disco, e a que não tem — o banner — é `StyleBox`, que não é arte por conteúdo. Um lote
novo entregaria um segundo conjunto competindo com o primeiro, e "isso não parece do mesmo
jogo" é justamente o que nenhuma medição pega (`ARTE.md` §17.11). O briefing do que
**faltaria**, se um dia faltar, está em `docs/ASSETS.md`.

**Pixel art também na grade.** Continua recusado, pela razão inteira da 0006.

**Deixar a 0006 como está e "só não levar a sério".** Cânone que contradiz a prática é pior
que cânone ausente: a próxima pessoa a ler aquele documento — inclusive o autor daqui a dois
meses — vai concluir que a partida não pode ter sprite, e vai estar lendo certo.

## Onde isso ficou escrito

- `docs/ARTE.md` §7 — a tabela de renderização, que agora separa a grade das duas peças fixas
- `src/cena/eras.gd` — o aviso no topo do arquivo, e o recurso da ASCII
- `src/ui/vitrine_de_upgrades.gd` — a tabela de ícones por família, e por que ela reusa
- `docs/decisoes/0006-...md` — continua valendo; este arquivo diz o que ela não alcançava
