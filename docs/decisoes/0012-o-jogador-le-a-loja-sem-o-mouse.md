# 0012 — O jogador lê a loja sem o mouse

**Contexto:** a reforma de interface do plano de UX. Ela olha a tela da partida e diz, em
uma frase: *o jogo funciona como incremental, mas a interface não comunica o que importa
agora, o que virá depois, nem por que um upgrade importa.*

Este arquivo registra as quatro decisões que a reforma tomou e que **contradizem ou
estendem** decisões anteriores. O resto dela é execução.

## 1. A descrição do upgrade sai do tooltip

**Antes:** a loja escrevia `Dedos Mais Ágeis — 124`, e tudo o mais — o que o upgrade faz,
quanto ele rende — vivia no `tooltip_text`.

**Agora:** nome, descrição, efeito e custo aparecem no cartão, sempre.

A issue #43 já tinha decidido que informação essencial não mora em cor sozinha. O tooltip é
o mesmo problema por outra porta: ele não alcança teclado, não alcança toque, não alcança
quem lê a tela de relance, e não alcança ninguém que não saiba que existe um tooltip ali.
Quarenta e quatro upgrades com descrição escrita, e o jogador só via preço.

⚠️ **E o efeito em texto é conteúdo novo, não formatação.** `×1,8` e `+0,35` são o mesmo
borrão para quem nunca abriu um `.tres`. `VitrineDeUpgrades.FRASES_DE_EFEITO` é o único
lugar do jogo que lê o par `(tipo_de_efeito, valor)` e diz em português o que ele faz —
e há portão varrendo o **enum** para exigir uma frase por tipo.

### O painel de detalhe foi recusado

O plano previa lista curta + painel de detalhe embaixo, para o caso de existirem duas
descrições — uma curta na lista, uma longa no detalhe. `DadosUpgrade` tem **uma**
(`descricao`). O painel mostraria exatamente o mesmo texto do cartão: duas fontes para a
mesma verdade, sem uma linha de informação nova, e mais um clique para chegar nela.

Se um dia houver `descricao_longa`, o painel volta a fazer sentido — e aí ele é uma
mudança de dado, não de tela.

## 2. A loja mostra o futuro

**Antes:** a coluna respondia "o que posso comprar". Um upgrade bloqueado por requisito
simplesmente não existia na tela — ele aparecia do nada quando o requisito caía.

**Agora:** uma seção `PRÓXIMAS MELHORIAS` com os quatro próximos, ordenados por **requisito**
e não por custo, cada um dizendo quanto falta.

⚠️ **Quatro, e não a árvore inteira.** Revelar tudo não cria antecipação: cria uma lista que
ninguém lê até o fim, e um spoiler da progressão. O número é limite de design em
`VitrineDeUpgrades.FUTUROS_NA_TELA`.

⚠️ **E ordenar por requisito não é detalhe.** Um upgrade barato de requisito distante na
frente de um caro que desbloqueia no minuto seguinte responde a pergunta errada. No catálogo
de hoje as duas ordens coincidem — por isso o portão que cobra isso usa uma lista
**sintética**, em que elas divergem de propósito. Uma afirmação sobre o catálogo real
passaria com a regra certa e com a errada, e isso é um carimbo.

## 3. As descobertas ganham faixa própria

**Antes:** marco, descoberta e mensagem operacional disputavam um rótulo só no rodapé. A
issue #69 mediu o estrago (16 de 82 avisos apagados antes do tempo de leitura) e resolveu o
empate com **prioridade**.

**Agora:** são **duas faixas**. O banner do topo — descoberta, marco conceitual, Teorema,
Universo — e a linha discreta do rodapé, para marco de tamanho e operacional.

⚠️ **Isto não desmente a issue #69, e é importante dizer por quê.** Ela escreveu que "a
solução não é aumentar a duração", e estava certa: dentro de **uma** fila, mais tempo na
tela atrasa todo mundo atrás. Prioridade responde *quem vem primeiro*; ela nunca respondeu
*quanto tempo cada um precisa*. Com duas filas as duas perguntas cabem: uma descoberta
Lendária fica sete segundos porque não há nada operacional atrás dela, e o autosave nunca
mais apaga um texto colecionável.

⚠️ **Só o marco CONCEITUAL vai para o banner.** São noventa e cinco marcos numa campanha, e
a grande maioria é mais um número grande — esses confirmam no rodapé. O banner só continua
significando "aconteceu algo" enquanto não acontecer o tempo todo, que é a mesma razão pela
qual o ciano é raro (`ARTE.md` §6).

⚠️ **E toda descoberta vai, inclusive a Comum.** Ela é o texto que o macaco produziu por
acidente (GDD §9) — o conteúdo colecionável do jogo, e não uma confirmação de sistema.

**O registro continua sendo um só.** Quem perdeu um aviso não precisa saber em que faixa ele
passou: ele precisa saber o que aconteceu, e em que ordem.

## 4. O prestígio passa a ter aviso

Provar o Teorema e reescrever o Universo são os dois maiores acontecimentos do jogo, e até
aqui **nenhum dos dois produzia uma linha na tela**. O único sinal era o contador zerar — que
lê como perda, e não como conquista.

⚠️ **E eles não passam pelas opções de aviso.** `aviso_de_marco` e `aviso_de_descoberta`
existem porque marco e descoberta acontecem centenas de vezes; prestígio acontece quando o
jogador **aperta** o botão de prestigiar. Calar a confirmação de um gesto que a pessoa
acabou de fazer não é reduzir ruído — é esconder o resultado da ação dela.

## O que a reforma encontrou pelo caminho

Três defeitos silenciosos que já estavam no `main`, e que nenhum portão pegava:

**1. O primeiro aviso de uma fila ociosa nunca era desenhado.** A HUD repintava quando
`FilaDeAvisos.tique()` devolvia `true`, e o tique não devolve `true` na primeira troca — fila
vazia mostra o aviso dentro do próprio `acrescentar()`. O aviso ficava a duração inteira dele
na fila, invisível, e saía. Só apareciam os que chegavam **atrás** de outro. Quem acusou foi
a captura do banner: a caixa apareceu na tela, com moldura, e vazia por dentro.

**2. Upgrade recém-desbloqueado não aparecia até a próxima compra.** A lista era remontada só
em `upgrade_comprado`. Numa coluna em que "o que vem depois" é o assunto, isso era o próprio
assunto quebrado.

**3. Três das quatro unidades de era nunca traduziram.** O portão de texto varria `nome`,
`descricao`, `titulo` e `texto` dos `.tres` — e não `unidade`, que é o nome que a era dá à
coisa que o jogador acumula, e que a HUD escreve no título da coluna da loja desde a issue
#30. O jogo em inglês mostrava `MACACOS` no meio de uma tela em inglês. Quem acusou foi uma
captura em inglês; o campo entrou na varredura junto da correção.

## Onde isso ficou escrito

- `src/ui/vitrine_de_upgrades.gd` — o que a loja mostra, e o efeito em uma frase
- `src/ui/cartao_de_upgrade.gd` — o cartão, e por que não há painel de detalhe
- `src/ui/alcance.gd` — os três estados, agora numa fonte só
- `src/ui/fila_de_avisos.gd` — as duas faixas, a duração por raridade e a classificação
- `src/autoload/avisos.gd` — quem decide faixa, prioridade e duração
- `src/ui/banner_de_destaque.gd` — o banner
- `tools/testes/teste_vitrine.gd` — o portão da loja
- `docs/capturas/banner_de_descoberta.png` — a foto versionada do banner
