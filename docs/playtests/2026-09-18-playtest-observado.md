# Playtest observado — 18/09/2026, perfil normal, 30 minutos

⚠️ **O QUE ESTE DOCUMENTO É, E O QUE ELE NÃO É.**

Trinta minutos de partida, com a tela **fotografada em nove instantes** e cada foto **olhada
uma a uma**. As anotações abaixo são o que se vê.

**Não é a sua sessão**, e não a substitui. Um leitor de tela consegue dizer *"todos os botões
estão apagados"*; não consegue dizer *"aqui eu desisti"*. As três perguntas do `MODELO.md`
que dependem de sentir continuam sem resposta:

- quando você **parou de ler os textos**
- quando **teria fechado o jogo**
- se foi divertido

O que segue é a metade que uma máquina que enxerga consegue fazer — e ela achou coisas que
nenhum dos portões, nenhuma régua e nenhuma suíte acharam.

**Como reproduzir:** `godot --path . tools/observar.tscn -- perfil=normal minutos=30`

---

## O que a tela mostrou

### Minuto 1 — ⚠️ a sala já está cheia

| |
|---|
| 603 caracteres · 23,7/s · 5 descobertas |
| **`MACACOS 10` — `Sala cheia`** |

**Os quatro botões de comprar macaco já estão apagados no primeiro minuto.** O jogador tem
226 para gastar e a única saída — `Escritório — 5.000` — custa **22× o saldo**.

⚠️ E o botão **DIGITAR**, o maior e mais brilhante da tela, diz *"+1 caractere por clique ou
espaço"* contra uma produção de **23,7/s**. Já no minuto 1 a ação que o jogo mais destaca é
a que menos importa.

O aviso de descoberta (`Descoberta: Uma Palavra de Três Letras`) aparece em corpo pequeno,
no rodapé, centralizado. Cinco descobertas saíram neste minuto; **nenhuma delas pede
atenção.**

### Minuto 5 — ⚠️ `48,99 macacos`

| |
|---|
| 87.808 caracteres · 1.190/s · 18 descobertas |
| **`MACACOS 48,99`** e `Escritório 48,99 de 75 macacos` |

**Macaco é coisa contável.** "48,99 macacos" lê como defeito — e virou issue própria, porque
a causa não está diagnosticada (pode ser o valor ou o formatador).

A loja mostra **um único upgrade**. A coluna inteira da direita tem um botão aceso.

### Minuto 20 — a campanha aparece

| |
|---|
| 2,06 bilhões · 1,69 milhões/s · 36 descobertas |
| **`TEOREMAS` entrou no menu** ✅ |

O jogador **descobre que o prestígio existe** — o botão aparece sozinho. Um evento está
ativo (`Banana na Máquina 28s`) com o botão `Resolver` visível e legível. A loja mostra três
famílias com cabeçalho. **Esta tela funciona.**

Mas o saldo é 163 milhões e os três upgrades custam 286 mi, 716 mi e 1,78 bi. **Nada é
comprável.**

### Minuto 30 — ⚠️ nada é comprável, e o botão inútil domina a tela

| | |
|---|---|
| saldo | 234 milhões |
| próximo macaco | 4,67 bilhões (**20×**) |
| próxima sala | 5 bilhões |
| próxima máquina | 18,7 bilhões |
| upgrades | 11,1 bi · 27,8 bi · 69,6 bi |

**Todos os botões da coluna direita estão apagados**, exceto os dois interruptores de
automação — que não compram nada, só ligam e desligam.

⚠️ **E o maior botão da tela continua sendo `DIGITAR`, que dá +1 contra 37,7 milhões por
segundo.** Aos trinta minutos, o elemento visual mais proeminente do jogo é o que menos faz
diferença — por sete ordens de grandeza.

---

## O que isto achou, e nenhuma medição achou

| # | achado | virou |
|---|---|---|
| 1 | **`48,99 macacos`** na tela | **#66** |
| 2 | **Coluna da direita inteira apagada** — sala cheia no minuto 1, nada comprável no 30 | **#67** |
| 3 | **DIGITAR domina a tela** quando já é irrelevante por sete ordens de grandeza | **#68** |
| 4 | **As 62 descobertas chegam todas** pela mesma linha de rodapé | **#69** |

Os quatro são **visuais e de leitura**. Nenhum deles aparece em contador nenhum: a tabela da
sessão observada registrou o minuto 30 como *"3 na loja, 6 compras, 1 acontecimento"* — que
lê como um minuto saudável.

⚠️ **"Três na loja" e "três botões apagados" são o mesmo número.**

---

---

## ⚠️ "Quando você parou de ler os textos?" — a metade medível

A pergunta tem duas metades, e uma delas **não depende de sentir**:

> **quantos textos o jogo apaga antes de dar tempo de ler?**

A HUD tem **um slot de aviso** (`hud.gd::_avisar`): marco, descoberta e autosave escrevem
por cima do anterior e reiniciam o relógio de `AVISO_VISIVEL` (1,6 s). Dois avisos dentro
dessa janela significam que o primeiro sumiu antes de ser lido.

Medido nos trinta minutos:

```
⚠️ avisos que a HUD mostrou:                 82
⚠️ apagados antes dos 1.6 s de leitura:      16  (20%)
```

**Um em cada cinco textos que o jogo escreve é fisicamente ilegível.** Não é opinião — é
aritmética sobre os instantes em que os eventos caem.

⚠️ **E o autosave disputa o mesmo slot.** *"Salvando..."* apaga uma descoberta com a mesma
prioridade que um marco raro.

Isso não responde se o jogador **quis** ler. Responde que, em 20% das vezes, ele **não
teve como** — e essa metade agora está na issue **#69** com número em cima.

---

## O que continua sendo do autor

As duas perguntas que sobraram **não têm metade medível**:

- [ ] **Em que minuto você teria fechado o jogo?**
- [ ] **Foi divertido?**

`MODELO.md`, ao lado, tem o formulário. Uma máquina que enxerga chegou até aqui; o resto
precisa de alguém que queira continuar jogando.
