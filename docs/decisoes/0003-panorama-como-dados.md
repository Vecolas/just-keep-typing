# 0003 — O Panorama é dado, e é ele que define a curva

**Data:** 2026-08-30
**Estado:** aceita

## Contexto

O GDD (§45) diz que o diferencial do jogo não é o número subindo, é o jogador descobrir
**o que aquele número significa**. E aponta (§46) o próximo passo: transformar o Panorama
numa lista ordenada de 80 a 100 marcos, de "você digitou seu nome em caracteres" até todas
as combinações possíveis de textos.

Isso coloca o Panorama num lugar incomum: ele não é uma tela de conquistas pendurada no
fim do desenvolvimento. Ele é a curva de progressão.

## Decisão

1. Cada marco é um `.tres` em `data/marcos/`, com `id`, requisito em `Grande`, título,
   texto, ícone, categoria e era. Nenhum marco no código.
2. A ordem do Panorama **é** a ordem dos requisitos — a tela ordena por requisito, não por
   um campo `ordem` mantido à mão, que desincronizaria no primeiro tuning.
3. O espaçamento entre marcos é ajustado com a régua `medir_ritmo`, não no olho.
4. Os marcos são escritos **antes** dos sistemas que os alcançam. É o único conteúdo do
   projeto com essa inversão.

## Por quê

Os requisitos dos marcos definem, na prática, quanto tempo o jogador leva para atravessar
cada faixa de escala. Quem escolhe `1e9` em vez de `1e12` para "todas as palavras do
português" está decidindo o ritmo de uma hora de jogo — e essa decisão fica invisível se
morar dentro de um `.gd` no meio de um `match`.

A inversão do item 4 tem motivo: a lista de 80–100 marcos é o **esqueleto** contra o qual a
economia é balanceada. Balancear a economia primeiro e encaixar marcos depois produz o
resultado clássico do gênero — vãos longos e mortos entre um marco e o seguinte, no
exato lugar onde o jogo devia estar entregando significado.

Isso não contradiz o "nenhum teste antes de existir lógica" do `TUNING.md`: marcos são
conteúdo, não teste. A régua que mede a distância entre eles continua entrando junto do
sistema que produz caracteres.

## Consequências

- A issue do Panorama completo é a maior issue de conteúdo do projeto, e ela vem antes do
  prestígio — não depois.
- Todo marco tem texto em `i18n/textos.csv` nas duas colunas na mesma mudança que o cria.
  São ~90 marcos: fazer isso no fim seria um mutirão de tradução, fazer junto é uma linha
  por vez.
- Marco não dá bônus. Ele dá significado. Bônus é assunto de descoberta (GDD §9) e de
  upgrade — misturar as duas coisas faria o jogador ler o Panorama como uma loja.
- Como o requisito é `Grande`, um marco de `10^(10^100)` custa o mesmo que um de `1e6`:
  uma linha de dados.
