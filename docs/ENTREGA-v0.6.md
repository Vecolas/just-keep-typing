# Entrega da v0.6 — A primeira hora

Relatório de consulta. Sete issues (#50–#56), mais três correções que saíram no caminho.

**Estado dos portões no fim:**

| | |
|---|---|
| suíte unitária | **PASSOU — 6.400 afirmações em 26 suítes** |
| fumaça | **PASSOU** |
| CI (`push` e `pull_request`) | **verde**, e rodando de verdade |
| capturas | **14 imagens**, 1080p, duas escalas, pt e en |

---

## 1. O que a versão pedia, e o que saiu

| issue | pedido | estado |
|---|---|---|
| **#50** | CI obrigatório e capturas automáticas | ✅ |
| **#51** | Panorama com três tipos de marco | ✅ |
| **#52** | Descobertas: 16 → ~60, em treze degraus | ✅ **62** |
| **#53** | Upgrades em quatro famílias temáticas | ✅ **44** |
| **#54** | Combo de digitação | ✅ |
| **#55** | Arquivo de Descobertas vira coleção | ✅ |
| **#56** | A régua da primeira hora | ✅ — e o que ela achou virou a issue **#58** |

**Conteúdo novo:** 46 descobertas, 24 upgrades, 6 faixas de coleção, 1 sistema (combo),
2 campos de save, 1 decisão de design registrada.

---

## 2. O achado que vale mais que a versão inteira

**A régua não era determinística, e o cabeçalho dela afirmava que era.**

`Descobertas.gerador` chama `randomize()` no `_ready`, e **descoberta dá bônus de
produção**. A `medir_ritmo` nunca semeava esse gerador: duas corridas **do mesmo commit**
divergiam **35 segundos** no primeiro Teorema, e a divergência cresce com o tempo simulado
porque o bônus entra na composição.

O cabeçalho da régua dizia, desde sempre:

> *"a régua precisa ser ESTÁVEL, para que a diferença entre duas medições seja a mudança no
> `.tres` e não o humor de quem jogou."*

A suíte e a ferramenta de captura **já semeavam**. As réguas, não.

⚠️ **Só apareceu porque conferi se uma otimização tinha mudado o resultado.** Ninguém roda
uma régua duas vezes para compará-la consigo mesma — e é por isso que este defeito
atravessou todas as sessões de tuning do projeto.

### E ele me obrigou a retratar uma conclusão

Eu tinha escrito, na issue #54, que o combo **custava +37 s** porque o jogador simulado
parava de digitar mais cedo. A análise era plausível, tinha mecanismo, explicava o sinal —
**e 37 s é da ordem do ruído.** O conserto do modelo do jogador continua certo pelos
próprios méritos; o que não se sustentava era a medição que usei como prova.

Com a semente fixa: **o combo adianta o primeiro prestígio em 27 segundos**, e as duas
corridas chegam à primeira Impossível e à primeira Paradoxal **no mesmo segundo**.

**Número plausível com mecanismo plausível é exatamente a forma que um erro toma quando
ninguém conferiu o instrumento.**

---

## 3. E o que a régua consertada mediu

```
ate              marcos   upgrades  descobertas
00:10:00             76         44            5
00:20:00              0          0            0
00:30:00              0          0            0
00:40:00              1          0            0
00:50:00              0          0            0
01:00:00              0          0            0
```

**A primeira hora é quatro minutos seguidos de cinquenta e seis minutos de silêncio.**

- **35 dos 44 upgrades** caem nos últimos **22 segundos**
- a família **O Conhecimento** inteira — nove upgrades — cabe em **18 segundos**
- o primeiro Teorema **vale a pena aos 00:03:42**

⚠️ **Não é defeito das issues #52 e #53.** Antes delas os mesmos 73 marcos caíam em onze
minutos: a mesma doença com prazo mais longo. As entradas novas só encurtaram o prazo o
suficiente para ninguém conseguir mais olhar para o outro lado.

A leitura está assinada em `docs/decisoes/0007`, e o rebalanceamento é a **issue #58** —
deliberadamente **fora** desta versão, porque a #56 diz com todas as letras que *"o que esta
issue entrega é a tabela, não um veredito"*.

---

## 4. Os defeitos silenciosos desta versão

Nove. Nenhum deles quebrava o jogo; todos passavam com a suíte verde.

### 4.1 A data de criação mudava sozinha ao ir ao disco — **e só falhava no Linux**

O `JSON.stringify` do Godot guarda **15 dígitos significativos**; um horário unix já gasta
dez antes da vírgula. `criado_em` ia ao disco com microssegundos e voltava diferente.

**A suíte comparava com tolerância `0,0` desde a v0.5 e passava no Windows**, cujo relógio
entrega ~1 ms — o valor cabia nos quinze dígitos. O do Linux entrega microssegundos.

Foi **a primeira coisa que o CI encontrou no primeiro job que conseguiu rodar**, e é a
justificativa da issue #50 numa linha: **portão que só roda numa máquina só prova aquela
máquina.**

### 4.2 Dois upgrades custavam mais e multiplicavam menos

| | custo | efeito |
|---|---|---|
| `dedos_mais_ageis` | 100 | x1,5 |
| `cafe_para_o_macaco` | 1,6 mi | **x1,4** |
| `metodo_de_datilografia` | 10 bi | x2,0 |
| `ergonomia_simiesca` | 500 bi | **x1,8** |

Escondido desde a issue #18. O jogo não quebra, nenhuma suíte reprovava, e o jogador paga,
não vê diferença e nunca sabe por quê.

### 4.3 O portão de redação que eu tinha acabado de escrever estava errado

Ele aplicava a **marco** e a **descoberta** a mesma proibição — e numa descoberta o macaco
*realmente* produziu aquele texto. Uma lista só teria proibido a frase certa
(*"Ele escreveu o nome do jogo"*). Agora são duas, e a diferença está escrita.

### 4.4 `continue` derrubando as afirmações seguintes

Ao tornar a checagem de bônus condicional ao papel, o `continue` teria feito **nove
descobertas deixarem de ter o nome conferido** — com a suíte verde.

### 4.5 A loja listava em ordem alfabética

"Arquivo Vertical" (4 trilhões) aparecia acima de "Café para o Macaco" (1,6 milhão) porque
A vem antes de C. A escada inteira aparecia embaralhada.

### 4.6 O cabeçalho de família derrubaria o quadro

O laço que pinta os botões perguntava a `meta("id")` de **todo** filho da lista. Um `Label`
sem essa meta derruba o laço — e com ele o resto do quadro.

### 4.7 A captura dependia da velocidade da máquina

Ela esperava dez **quadros**; a transição dura 0,45 **segundos**. Numa máquina rápida, dez
quadros são 0,17 s: a foto saía com a máquina de escrever em pleno voo por cima do botão
DIGITAR. No runner do CI, mais lento, saía limpa.

**A mesma ferramenta, no mesmo commit, produzindo imagens diferentes** — e a galeria não tem
como distinguir isso de uma regressão.

### 4.8 O padrão de save só valia para o arquivo migrado

Um save **na versão atual** sem algum campo caía direto em `_aplicar`, que indexa
`dados["nome"]` sem `.get` e morre ali, com a partida pela metade.

Foi assim que o primeiro caso de teste da coleção reprovou, e **o reflexo teria sido
consertar o teste**: o arquivo era JSON válido, na versão certa, e não carregava.

### 4.9 O gerador deduplicava o CSV cortando na primeira vírgula

Campo com vírgula vai entre aspas: `"Começo, meio e fim. Nessa ordem"` casou com
`"Começo, meio e fim. O fim é sobre bananas"`, já existente. A frase nova foi descartada
como duplicata.

---

## 5. As decisões que sustentam o resto

**O combo multiplica só o que o jogador digita** — nunca a produção automática. Isso paga
três exigências com um mecanismo: ele **envelhece sozinho** quando a automação cresce, não
vira imposto, e a progressão não depende dele. Um multiplicador global de ×1,5 continuaria
valendo ×1,5 na era 14 — nunca envelheceria.

**A família de upgrade é uma coluna do `.tres` e não decide nada.** O gameplay continua
perguntando pelo TIPO de efeito. Há portão varrendo `economia.gd` atrás da palavra
`.familia`, porque um `if familia ==` ali não quebraria nada — só tornaria o próximo upgrade
mais caro de escrever.

**A sentinela é a AUSÊNCIA da chave, nunca um número.** Ordem de grandeza **zero é legítima**
(1 a 9 caracteres). Com zero como sentinela, toda descoberta antiga diria *"encontrada em 1
de janeiro de 1970"*. **Dado inventado que parece dado é pior que dado faltando.**

**Num marco o jogo compara tamanho; numa descoberta o macaco produziu aquilo.** Duas listas
de proibição, e a diferença entre elas está escrita.

---

## 6. O que NÃO está provado

- **Ninguém jogou isto.** Não houve sessão humana nem playtest de 30 minutos — dois dos
  quatro itens de validação que o plano da v0.6 pediu **antes** de construir. Os outros dois
  (CI em PR, capturas automáticas) estão feitos.
- **O texto autoral é meu.** 46 descobertas e 24 upgrades foram escritos sem revisão do
  autor. Nenhuma régua pega *"isso não soa como o meu jogo"*.
- **A régua não mede eventos nem automação.** Ela nunca chama `Eventos.tique` nem
  `Automacao.tique` — a campanha medida não tem acontecimento aleatório nenhum. **Ponto cego
  declarado**, e está no cabeçalho dela.
- **O jogador simulado não é o jogador real.** Os quatro minutos são o **piso**.
- **A hierarquia visual não tem régua.** Os dois defeitos de leitura desta versão (4.5, 4.6 e
  o cabeçalho com peso de título) foram achados **olhando a captura**, com a suíte verde.
- **A cobertura em inglês do portão de redação tem buraco**: ele não distingue linha de marco
  de linha de descoberta dentro do CSV.

---

## 7. Onde procurar o quê

| assunto | arquivo |
|---|---|
| todas as regras novas | `CONVENCOES.md` |
| as medições e as retratações | `TUNING.md` |
| a decisão sobre a primeira hora | `docs/decisoes/0007-…` |
| o que fazer a seguir | issue **#58** |
