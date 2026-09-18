# 0009 — O que a v0.7 consertou, e o que ficou

**Contexto:** a decisão 0008 fixou a meta — reconstruir a distribuição do conteúdo que já
existe. Este documento registra o que a medição diz depois das issues #59 a #63, incluindo
**o que não convergiu e por quê**. A issue #65 pedia que a leitura final virasse decisão
escrita *"inclusive se a decisão for 'está bom'"*. Ela não é.

## O que convergiu

Perfil **normal**, régua de campanha, mesma semente:

| | antes (v0.6) | depois |
|---|---|---|
| marcos em 0–10 min | **76** | **38** |
| upgrades em 0–10 min | **44** | **22** |
| blocos de 10 min com conteúdo | **1 de 6** | **4 de 6** |
| 1º Teorema disponível | 00:03:43 | **00:27:54** |
| 1º Teorema vale a pena | 00:04:22 | **00:37:39** |
| prestígios na 1ª hora | 2 | **1** |

**O primeiro Teorema caiu dentro da faixa de 35 a 50 minutos**, que era o alvo da decisão
0008. A primeira run passou a ter um arco: quase meia hora antes de o prestígio sequer
aparecer, e mais dez minutos até ele compensar.

## O que a medição achou, e ninguém procurava

⚠️ **O maior multiplicador do jogo eram as DESCOBERTAS, não os upgrades.**

| fonte | composição |
|---|---|
| upgrades (todos os tipos) | ~10^13 |
| **descobertas** | **~10^41** |

Vinte e oito ordens de grandeza de diferença. **Separar só os upgrades quase não moveu
nada** — o primeiro Teorema foi de 04:22 para 04:01. Foi preciso medir de novo, fonte por
fonte, para achar onde o número morava.

E a issue #52 criou a maior parte disso: 46 descobertas novas, quase todas com `bonus > 1`.
Pior, **o portão que cobrava `bonus > 1` de toda descoberta de papel `BONUS` era o mesmo que
garantia a composição.** A regra que protegia contra dado esquecido protegia também a
explosão.

## ⚠️ Marco não é botão de tuning

A issue #61 pedia para redistribuir marcos, upgrades e descobertas. **Marco não pode ser
redistribuído.**

O `requisito` de um marco é um fato sobre o mundo, e o campo `nota` existe para documentar a
conta: *"Bíblia completa: 783.000 palavras × 4,5 caracteres"*. Mudar `3.5e6` para `1e20` não
redistribui nada — **faz o Panorama mentir.**

**Quando cada marco cai é consequência da velocidade da economia**, e não uma escolha. Isso
reduz a issue #61 aos upgrades — e limita o quanto a distribuição de marcos pode ser
moldada.

## O que NÃO convergiu

### O bloco de 40 a 60 minutos continua vazio

A distribuição final é **38 / 8 / 22 / 1 / 0 / 0**, contra o alvo **25 / 18 / 15 / 13 / 11 /
9**.

O motivo é estrutural e tem nome: **acima de 10^25 os marcos ficam espaçados por ordens de
grandeza inteiras**, e a economia — depois de todos os 44 upgrades comprados — só cresce
por compra de macaco, que rende **logaritmicamente**. Não há o que atravessar naquele
intervalo.

As três saídas possíveis:

1. **Mais conteúdo entre 10^25 e 10^30** — ⚠️ proibido pelo congelamento de conteúdo da
   decisão 0008, e com razão: foi acrescentar conteúdo que criou o problema anterior.
2. **Uma fonte de crescimento que sobrevive ao fim dos upgrades** — é o que o prestígio
   deveria ser, e ele agora cai aos 37:39. A segunda metade da hora passa a ser *a run
   seguinte*, que é um desenho legítimo mas precisa ser **decidido**, não descoberto.
3. **Aceitar seis blocos com densidade decrescente até zerar** — o que contradiz a decisão
   0008: *"a densidade pode diminuir progressivamente, mas nunca desaparecer"*.

**Esta é uma decisão de produto, e ela não foi tomada.**

### Um critério regrediu: o combo voltou a pesar demais

| | linha de base | depois |
|---|---|---|
| ativo | 00:03:47 | 00:27:36 |
| normal | 00:04:22 | 00:37:39 |
| **vantagem do ativo** | **13%** ✅ | **27%** ❌ |

A decisão 0008 fixou a faixa em 10–20%: *"o combo ajuda sem definir a run"*. A issue #65
avisava que essa propriedade era **o tipo que uma curva nova quebra sem avisar** — e ela
quebrou, porque a economia mais lenta dá mais peso relativo ao que a mão produz.

Não é grave e tem conserto barato (o teto do combo em `data/combo.tres`), mas **não foi
ajustado**: mexer no combo junto com a curva daria uma medição que não diz qual dos dois
mudou o quê. Uma variável por vez.

### O perfil passivo tem a melhor distribuição

Cinco blocos com conteúdo contra quatro do normal. **Quem joga menos atravessa mais devagar,
e por isso encontra mais coisa pelo caminho.** Não é defeito — é uma leitura que vale ter
antes de mexer de novo, porque a tentação natural é acelerar o passivo.

### A forma certa com a escala errada

A primeira iteração da #61 espalhou os upgrades até 10^26. O resultado:

```
distribuição   28 / 5 / 5 / 2 / 1 / 1     ← exatamente o alvo
o jogo         28 caracteres em uma hora  ← parado
```

Vale registrar porque é contraintuitivo: **espalhar upgrades encarece a ignição**, e a
economia nunca pega. Forma certa com escala errada não é meio-caminho — é outro defeito, e
um que a tabela de distribuição sozinha aprovaria.

### E o espalhamento cego quebrou o interruptor do jogo

`instinto_digitador` ganhou requisito 20 como qualquer outro da fila. Ele é o upgrade que
liga a produção automática (GDD §3) e tem de estar na loja no primeiro quadro.

Mesma família do `mesas_empilhadas` na issue #60, que virou parcela de velocidade quando o
texto dele fala de empilhar mesas — ou seja, de **vaga**. **Regra geral aplicada sem olhar o
que a peça é.** Aconteceu duas vezes nesta versão.

## O que falta, em ordem

1. **O playtest** (issue #64) — do autor, e o de *antes* já não é mais possível: a curva
   mudou. Faça o de agora.
2. **Decidir o que ocupa de 40 a 60 minutos**, entre as três saídas acima.
3. **Revisar a voz** — ~70 peças de texto autoral, mais duas descrições que esta versão
   reescreveu (os dois descontos, que falavam de produção e precisavam falar de custo).

## O que esta medição NÃO prova

- **Ninguém jogou.** A régua mede quando as coisas acontecem, não se foram interessantes.
- **O jogador simulado não é o jogador real** — ele compra no instante exato em que o saldo
  fecha.
- **A régua não mede se o jogo ficou chato.** Trinta e oito marcos nos primeiros dez minutos
  ainda é muito, e nenhum número aqui diz se é.
