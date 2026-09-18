# 0006 — Pixel art no menu, tipografia na partida

**Contexto:** issue #44, que existe porque o cânone visual diz o **contrário** da
ferramenta escolhida, e a contradição precisa ser resolvida no documento antes de existir
um único asset.

## O problema

O `ARTE.md` §7 fechava assim:

> Estilo de renderização: entre ilustração 3D estilizada e pintura digital polida. (…)
> Não é: realista, anime, **pixel art**, nem cartoon 2D simplório.

E o §16 trazia um prompt-base de *"stylized polished 3D cartoon illustration"* que todo
asset futuro herdaria.

O gerador escolhido para os assets do menu (issues #45 e #46) é o **PixelLab**, que produz
pixel art. Os dois textos passam a estar errados no minuto em que o primeiro sprite entrar
— e `ARTE.md` é cânone: quando ele diverge de qualquer outro documento, ele vence. Mudar
cânone é decisão do autor, e é o que este arquivo registra.

## A decisão

**Pixel art no MENU. Tipografia na PARTIDA. E as duas convivem de propósito.**

O jogo hoje não tem sprite nenhum: as eras são arte ASCII (issue #26), as letras são
`Label` (issue #22) e a HUD é `Theme` montado em código (issue #7). Isso não é uma etapa
provisória à espera de arte — é o que faz a partida escalar de 1 caractere a 10^50 sem
nenhum asset por era.

O menu é outra coisa: ele é uma **cena**, parada, de tamanho conhecido, e é a primeira
coisa que o jogador vê. É ali que o macaco, a máquina e a janela estrelada existem como
objetos, e não como aproximações tipográficas.

A separação, então, não é um acidente de ferramenta — é a regra:

| Onde | Como | Por quê |
|---|---|---|
| Menu, Arquivos, Créditos | pixel art + UI tipográfica por cima | cena fixa, conhecida, não escala com a progressão |
| Partida | tipografia, ASCII e `Theme` | tem que atravessar catorze eras e 10^50 sem um asset por era |

O §15 continua valendo e é o que amarra as duas: *"nunca deixa de parecer Just Keep
Typing"*. A cola é a **paleta** (§6, que não muda), o dourado, o `∞` e a máquina de
escrever — não a técnica de renderização.

## O que esta decisão custa

Três coisas, e as três são reais.

**1. A ressalva de resolução volta a valer.** O próprio §7 dizia que, por a arte *não* ser
pixel art de escala inteira, a ressalva do `CONVENCOES.md` não se aplicava. Com pixel art
ela se aplica: **só a escala inteira é exata**. Duas consequências:

- a arte do menu é desenhada com filtro **nearest**, nunca linear — pixel art com
  interpolação vira borrão, e borrão é a única coisa que pixel art não pode ser
- a exatidão é garantida quando a janela tem o tamanho da tela lógica (1920×1080). Em
  qualquer outro tamanho o canvas inteiro é reamostrado — o que **já acontece** com toda
  a tipografia do jogo, e a dica da lista de resoluções já diz isso

**2. A escala de interface da issue #43 não alcança o cenário.** Interface a 125% em cima
de sprite de escala inteira faria o pixel quadrado ter larguras diferentes na mesma
imagem. A regra que resolve é a mesma do plano §6 (*"híbrido: cenário físico com UI
estilizada"*): **a escala de interface move a UI, e não o cenário.** O painel de menu, os
botões e o texto crescem; a mesa, o macaco e a janela ficam onde estão.

Isso é coerente com o que aquelas opções prometem: escala de interface é sobre *ler*, e
ninguém lê o cenário.

**3. O §16 troca de prompt-base, e o antigo sai.** Deixar os dois é garantir que metade
dos assets saia no estilo errado — e gerador de imagem não avisa que escolheu o parágrafo
errado, ele só devolve a peça.

## O que foi recusado, e por quê

**Trocar o gerador para manter o cânone.** O `ARTE.md` descreve ilustração 3D polida, que
é caro de produzir de forma consistente e impossível de manter coerente entre dezenas de
assets gerados um a um. Pixel art com paleta fixa é o oposto: o gerador tem menos espaço
para inventar, e a paleta do §6 entra no pedido.

**Pixel art também na partida.** Seriam catorze eras de assets, cada uma com máquinas,
salas e escalas próprias — e o jogo que hoje representa 10^50 com quatro linhas de ASCII
passaria a precisar de arte para cada ordem de grandeza. A issue #26 existe exatamente
para não precisar disso.

**Deixar o §7 como está e "só não levar a sério".** Cânone que contradiz a prática é pior
que cânone ausente: a próxima pessoa a ler o documento — inclusive o autor daqui a dois
meses — vai gerar o lote no estilo errado, e ninguém vai conseguir dizer que ela estava
errada.

## Onde isso ficou escrito

- `docs/ARTE.md` §7 — o estilo de renderização, reescrito, com a consequência de resolução
- `docs/ARTE.md` §16 — prompt-base novo, para o PixelLab; o antigo saiu
- `CONVENCOES.md`, "Vídeo e opções" — a ressalva de escala inteira, que voltou a valer
- `docs/ARTE.md` §17 — a checagem de arte ganhou a pergunta de paleta e de escala
