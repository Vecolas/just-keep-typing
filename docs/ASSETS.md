# Assets do menu — o briefing

Os assets do menu (issues #45 e #46), gerados no **PixelLab**. O estilo foi resolvido pela
issue #44 e mora na decisão
[0006](decisoes/0006-pixel-art-no-menu-tipografia-na-partida.md): **pixel art no menu,
tipografia na partida**.

Este documento é o **pedido**, e ele existe antes das imagens de propósito. Entrega
subjetiva sem ficha escrita é entrega que só pode ser corrigida depois de pronta.

A **lista que vale** é `src/ui/assets_do_menu.gd` — ela tem o caminho e o tamanho de cada
peça, e é ela que o jogo lê e que a suíte confere contra o disco. Este arquivo explica o
*porquê* de cada linha daquela tabela; quando os dois discordarem, o código ganha e este
texto se atualiza.

---

## As cinco regras que valem para toda peça

**1. ⚠️ Nenhum texto dentro do asset.** Nem `CONTINUAR`, nem `JOGAR`, nem o logo escrito.
Todo texto é renderizado pelo Godot — senão não traduz, não escala, a acessibilidade não
alcança e o portão de i18n não enxerga. O plano §41 é categórico, e vale em dobro para
gerador de imagem, que erra letra.

Consequência direta: **o logo do jogo não é um asset de logo.** O asset é o **emblema** — a
máquina de escrever com o `∞` —, e as palavras *JUST KEEP TYPING* são um `Label`.

**2. A paleta é a do `ARTE.md` §6, e ela entra no pedido.** Gerador que escolhe a própria
paleta devolve um jogo diferente a cada asset.

**3. O tamanho é decidido AQUI, antes de gerar.** Sprite em tamanho errado é sprite que vai
ser escalado, e escala não inteira em pixel art é borrão. Recortar depois não conserta — só
esconde.

**4. Cada peça é descrita como OBJETO, nunca pelo que ela faz no sistema.** "Botão de
continuar" vira a palavra *continue* desenhada na imagem. "Placa de metal retangular com
rebites" não.

**5. A família se entrega inteira.** Metade do conjunto num estilo e metade noutro lê como
defeito, e não como incompleto.

---

## A escala, e por que ela é o número mais importante daqui

A tela lógica do jogo é **1920×1080**. A pixel art é desenhada em escala **inteira** sobre
ela, e cada família tem a sua:

| Família | Escala | Por quê |
|---|---|---|
| Cenário e os objetos dentro dele | **5×** | 384×216 × 5 = exatamente 1920×1080 |
| Molduras e painéis da UI | **4×** | borda de 12 px vira 48 px lógicos, que é a margem que o painel já usa |
| Ícones | **2×** | 32×32 → 64×64 lógicos, o tamanho de um botão de barra |

⚠️ **Tudo dentro de uma família compartilha a escala dela.** O macaco e a máquina são
desenhados por cima do cenário: em escala diferente, o pixel quadrado teria dois tamanhos na
mesma imagem — que é exatamente o defeito que a decisão 0006 se compromete a evitar.

⚠️ **O que esta escala NÃO garante**, e está escrito para ninguém se surpreender:

- **janela diferente de 1920×1080** reamostra o canvas inteiro, arte e tipografia juntas.
  Já era assim antes de existir sprite; a lista de resoluções e a dica dela existem por isso
- **escala de interface acima de 100%** (issue #43) move a UI, e com ela as molduras e os
  ícones. A 125% uma borda de 12 px vira 15 px lógicos e o pixel deixa de ser quadrado. É o
  preço declarado da decisão 0006 — borda fina é onde ele menos aparece, e por isso a pixel
  art da UI é **só moldura**: o miolo dos painéis continua sendo `StyleBox` de cor chapada
- **o cenário não escala com a interface.** Ele é cenário, e ninguém lê cenário

---

## O cenário e o que vive dentro dele

### `cenario_mesa.png` — 384×216, escala 5×

**O que é:** uma mesa de madeira escura vista de frente, com uma janela atrás dela. Pela
janela, céu noturno com estrelas. Sobre a mesa, **à esquerda**, um abajur de metal aceso
jogando luz quente para a direita. Papéis soltos e um copo com lápis, também à esquerda.

**Separa das vizinhas:** é a única peça sem fundo transparente — ela **é** o fundo.

**Espaço negativo obrigatório:** a **metade direita** da imagem fica calma — sem objeto
alto, sem detalhe fino, sem contraste forte. O painel de menu vai por cima dela. Cenário
bonito com a UI em cima de um armário cheio de coisa é cenário que brigou com a interface e
ganhou.

⚠️ **A primeira versão desta ficha se contradizia**, e a primeira imagem obedeceu: ela pedia
o abajur à direita **e** o espaço negativo à direita. Veio um abajur exatamente onde o
painel ia. Pedido que se contradiz não é recusado pelo gerador — ele é cumprido pela metade
que veio por último.

**Luz:** quente vindo do abajur à esquerda; azul frio e fraco vindo da janela. As duas
convivendo é a assinatura visual da franquia (`ARTE.md` §7).

⚠️ **O `∞` das estrelas NÃO está nesta peça, e isso é decisão.** Duas gerações pediram
estrelas formando um oito deitado e nenhuma das duas entregou — gerador de imagem não
desenha constelação por encomenda. Ele passou a ser **desenhado em código** pela cena do
menu, sobre a área da janela: pontos numa lemniscata, posição exata, e é o que permite que
ele pisque na issue #48.

`ARTE.md` §12 continua mandando: ele é **discreto**. Se o jogador tiver que procurar,
funcionou; se aparecer antes do macaco, está errado.

### `maquina.png` — 64×48, escala 5×, fundo transparente

**O que é:** uma máquina de escrever mecânica antiga, vista de frente e ligeiramente de
cima. Corpo de metal escuro, teclas redondas creme com aros de bronze, rolo cilíndrico no
alto, uma folha de papel creme saindo dele.

**Separa das vizinhas:** é a única peça com teclas. A silhueta é larga e baixa.

**O papel saindo do rolo fica em branco** — é nele que a issue #49 vai desenhar as letras
que o jogador digita, e letra desenhada no asset seria letra que não some.

### `macaco.png` — 48×56, escala 5×, fundo transparente

**O que é:** um macaco marrom pequeno, sentado, visto de frente, das costas da máquina para
cima — cabeça, ombros e os dois braços à frente, com as mãos no nível das teclas. Olhos
grandes, orelhas grandes, topete, óculos redondos de aro fino.

**Obedece ao dado:** marrom `#8B5E34`, que é a cor de macaco da paleta. Os óculos são de
bronze, não de plástico.

**Separa das vizinhas:** é a única peça viva. Silhueta alta e estreita, para caber atrás da
máquina sem cobri-la.

**A pose é NEUTRA**, de olhos abertos e mãos paradas. As variações — piscar, coçar a
cabeça, olhar para o jogador — são a issue #48, e nascem desta pose.

### `emblema.png` — 64×64, escala 4×, fundo transparente

**O que é:** uma máquina de escrever vista de frente, muito simplificada, com um `∞` de
metal dourado no lugar do rolo de papel.

**Separa das vizinhas:** é a única peça simétrica e centrada; ela é lida como marca, e não
como objeto da cena.

⚠️ **Sem uma única letra.** As palavras do título são um `Label` por cima.

---

## As molduras da interface

Todas são **9-slice**: o miolo estica, a borda não. O número da borda está na tabela do
código, e é ele que o `NinePatchRect` recebe.

### `painel_papel.png` — 48×48, borda 12, escala 4×

**O que é:** uma folha de papel creme envelhecido, retangular, com as bordas levemente
escurecidas e irregulares e um grampo de metal no canto superior esquerdo.

**Separa das vizinhas:** é clara. Todas as outras molduras são escuras.

**O miolo é liso** — ele vai esticar, e qualquer detalhe ali vira uma listra quando o painel
crescer.

### `placa_normal.png` e `placa_afundada.png` — 48×24, borda 8, escala 4×

**O que são:** uma placa retangular de metal escuro com moldura de bronze e quatro rebites,
uma em cada canto. A `afundada` é a mesma placa recuada para dentro, com a sombra por cima
em vez de por baixo.

⚠️ **São DUAS peças para QUATRO estados, e isso é decisão.** Gerar quatro placas
independentes daria quatro placas diferentes — a família se entrega inteira ou lê como
defeito. Os quatro estados saem assim:

| Estado | Como |
|---|---|
| normal | `placa_normal` |
| hover | `placa_normal` + moldura de foco dourada (desenhada pelo `Tema`) |
| pressionado | `placa_afundada` — a placa **se move**, e isso se vê sem cor |
| desabilitado | `placa_normal` esmaecida, sem moldura |

⚠️ **Os quatro têm que ser distinguíveis sem cor** (issue #46): dois deles diferem por
**forma** (a placa afunda) e um por **presença** (a moldura de foco existe ou não). Só o
desabilitado depende de valor — e valor não é matiz.

### `moldura_manuscrito.png` — 48×32, borda 10, escala 4×

**O que é:** uma moldura retangular de bronze fino com cantos reforçados, como a borda de
uma etiqueta de arquivo. Miolo vazio e transparente.

**Separa das vizinhas:** é a única moldura **sem preenchimento** — o cartão do Manuscrito
desenha o próprio fundo por baixo dela.

---

## Os ícones — 32×32 cada, escala 2×, fundo transparente

Todos na mesma linguagem: silhueta grossa, poucos detalhes, contorno escuro, sombra chapada.
Um ícone que precise de mais de três cores está detalhado demais para o tamanho em que vai
ser visto.

| Arquivo | O que é | Separa das vizinhas por |
|---|---|---|
| `icone_infinito.png` | um `∞` de metal dourado, levemente tridimensional | é o único símbolo abstrato |
| `icone_banana.png` | uma banana madura, curva, vista de lado | é a única peça amarela e orgânica |
| `icone_engrenagem.png` | uma engrenagem de bronze de oito dentes | é a única peça circular com dentes |
| `icone_papel.png` | uma folha creme com o canto superior direito dobrado | é a única peça clara |
| `icone_excluir.png` | um `X` grosso de metal escuro com marcas de desgaste | é a única peça com duas barras cruzadas |
| `icone_voltar.png` | uma seta grossa apontando para a esquerda | é a única peça com ponta |

⚠️ **A seta foi ESPELHADA depois de gerada.** O gerador entregou uma seta para a direita —
duas vezes, com `direction: west` no pedido. Espelhar é legítimo aqui porque uma seta não
tem lado certo intrínseco, só sentido; seria ilegítimo numa peça com iluminação direcional,
que é o caso de todo o resto. Fica registrado para ninguém regerar achando que o arquivo
saiu assim.

---

## O que foi preenchido pela convenção, e não pedido

⚠️ **Isto está escrito para poder ser corrigido antes da entrega, e não depois.** Quem pediu
não informou, e inventar em silêncio é o mesmo que inventar sem ninguém para discordar:

- **a direção da luz** — quente vindo da **direita**, porque o abajur está lá. Nada no plano
  diz de que lado ele fica
- **o lado do espaço negativo** — o painel de menu vai à **direita** (plano §5), então a
  metade calma é a direita e o abajur, os papéis e o macaco ficam à esquerda
- **o número de rebites da placa** — quatro, um por canto
- **os oito dentes da engrenagem** — número escolhido por legibilidade em 32×32; mais dentes
  viram serrilha
- **o `∞` nas estrelas fica no alto à esquerda**, longe do painel, para não competir com a
  UI

---

## O que cobre cada peça

| Prova | O que ela pega | O que ela NÃO pega |
|---|---|---|
| `teste_assets` (suíte) | o arquivo existe, carrega, e tem **exatamente** o tamanho declarado | se a peça é bonita, ou se pertence à família |
| `tools/gerar_galeria` | o diff da imagem versionada mostra o que mudou na tela | nada sobre o arquivo do asset em si |
| Checagem de arte, `ARTE.md` §17 | paleta, texto embutido, tamanho, família | é uma leitura humana, e é a única que pega as quatro |

⚠️ **Nenhuma medição pega "isso não pertence a esta família".** Peça que passa em toda régua
ainda pode estar errada pelo conjunto — e é por isso que a pergunta 11 da checagem de arte
manda olhar a peça **ao lado das vizinhas**, e não sozinha.
