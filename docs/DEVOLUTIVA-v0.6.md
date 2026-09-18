# Devolutiva da v0.6 — o que foi feito, e tudo que ficou de dívida

Documento de consulta, escrito para ser lido por quem vai continuar. A `ENTREGA-v0.6.md`
conta a versão; **este aqui existe para a segunda metade: o que ficou.**

Se você só for ler uma seção, leia a **§7**.

---

## 1. O placar

| | |
|---|---|
| issues da v0.6 | **7 de 7** entregues e fechadas (#50–#56) |
| correções extras | **3**, achadas no caminho |
| defeitos silenciosos corrigidos | **9** |
| conclusão **retratada** | **1** |
| suíte unitária | **6.400 afirmações em 26 suítes** — verde |
| fumaça | verde |
| CI (`push` e `pull_request`) | verde, e **rodando de verdade** desde que o repo virou público |
| capturas automáticas | **13 imagens**: 1080p, duas escalas, pt e en |
| issues abertas | **1** — a #58 |

**Conteúdo do jogo hoje:** 91 marcos · 62 descobertas · 44 upgrades · 714 linhas de texto
traduzido.

---

## 2. O que cada issue entregou

| # | entregou | o que isso muda para o jogador |
|---|---|---|
| **50** | CI em push e PR, capturas automáticas | nada — muda para quem desenvolve: os portões deixaram de depender de memória |
| **51** | três tipos de marco (`=` tamanho, `§` humano, `∞` conceito) | o Panorama passa a ter um eixo de leitura, e não só uma escada de números |
| **52** | 16 → **62** descobertas, em treze degraus | o sistema deixa de ser uma segunda loja: 9 existem **só pela piada** |
| **53** | 20 → **44** upgrades, em quatro famílias | cada upgrade explica **por que** a produção aumentou |
| **54** | combo de digitação | os primeiros minutos deixam de ser só assistir |
| **55** | Arquivo vira coleção, com faixas e `0/?` | o buraco ganha forma, e a última faixa ganha mistério |
| **56** | régua da primeira hora + decisão escrita | nada ainda — e é justamente esse o ponto (ver §4) |

---

## 3. A retratação

⚠️ **Eu te dei uma conclusão errada nesta sessão, e ela está corrigida no repositório.**

Na issue #54 escrevi que o combo **custava +37 s** porque o jogador simulado parava de
digitar mais cedo. A análise era plausível, tinha mecanismo, explicava o sinal observado.

**O número que a sustentava era ruído.** A `medir_ritmo` nunca semeava
`Descobertas.gerador` — que chama `randomize()` no `_ready` — e descoberta **dá bônus de
produção**. Duas corridas *do mesmo commit* divergiam **35 segundos**.

Com a semente fixa, a medição limpa é o contrário: **o combo adianta o primeiro prestígio em
27 segundos** (00:03:42 contra 00:04:08), e as duas corridas chegam à primeira Impossível e
à primeira Paradoxal **no mesmo segundo**.

O conserto do modelo do jogador continua certo pelos próprios méritos. O que não se
sustentava era a prova que usei.

**Número plausível com mecanismo plausível é a forma que um erro toma quando ninguém
conferiu o instrumento.** Só apareceu porque conferi se uma otimização tinha mudado o
resultado — ninguém roda uma régua duas vezes para compará-la consigo mesma.

Está registrado em `TUNING.md`, seção *"A régua não era determinística"*, com uma tabela do
que sobrevive e do que não.

---

## 4. A dívida de produto — a maior de todas

### 4.1 A primeira hora não existe

```
ate              marcos   upgrades  descobertas
00:10:00             76         44            5
00:20:00              0          0            0
00:30:00              0          0            0
00:40:00              1          0            0
00:50:00              0          0            0
01:00:00              0          0            0
```

**Quatro minutos de acontecimento seguidos de cinquenta e seis de silêncio.**

- **35 dos 44 upgrades** caem nos últimos **22 segundos**
- a família **O Conhecimento** inteira — nove upgrades — cabe em **18 segundos**
- o primeiro Teorema **vale a pena aos 00:03:42**

⚠️ **Não é defeito das issues #52 e #53.** Antes delas os mesmos 73 marcos caíam em onze
minutos: a mesma doença com prazo mais longo. As entradas novas só encurtaram o prazo o
suficiente para ninguém conseguir mais olhar para o outro lado.

**Mecanismo:** a produção cresce por multiplicadores que **compõem**; os custos crescem por
escadas **escolhidas à mão**. Duas curvas de naturezas diferentes se cruzam **uma vez** — e
depois do cruzamento a produção atravessa todo limite restante em segundos.

**Onde está:** decisão `docs/decisoes/0007`, issue **#58**.

⚠️ **Por que não consertei:** a issue #56 diz com todas as letras que *"o que esta issue
entrega é a tabela, não um veredito"*. Redesenhar a curva de custo do jogo inteiro é decisão
sua sobre o produto. Fazê-la escondida no commit de uma régua seria uma mudança grande
entrando por um caminho que ninguém olha.

### 4.2 Ninguém jogou isto

O plano da v0.6 listou **quatro** itens a resolver *antes* de construir. Dois estão feitos:

| item | estado |
|---|---|
| CI obrigatório em pull request | ✅ |
| capturas automáticas, 1080p e duas escalas | ✅ |
| **sessão humana curta** | ❌ **não feita** |
| **playtest de 30 minutos** | ❌ **não feito** |

Os dois que faltam são exatamente os que nenhuma máquina faz.

### 4.3 O texto autoral é meu, e você não leu

**46 descobertas e 24 upgrades** foram escritos por mim sem revisão sua. Isso é ~70 peças
de texto que definem a voz do jogo.

Nenhuma régua pega *"isso não soa como o meu jogo"*. Os portões garantem que o texto existe,
está traduzido, não viola as regras de redação e cabe na tela. **Nenhum deles lê tom.**

Amostra para calibrar, se quiser começar por aí:

> **EU** — *Duas letras. Filosoficamente inconvenientes.*
> **Um Provérbio** — *Soa antigo e sábio. Tem doze segundos de idade.*
> **Memória Muscular** — *Os dedos repetem sozinhos o que já repetiram antes. O macaco não aprendeu nada; as mãos aprenderam.*
> **Supervisor** — *Ele não datilografa. Ele anda entre as mesas, e as mesas por onde ele passa produzem mais.*

---

## 5. A dívida declarada no código

Estas listas existem para que o item **não suma da conta**. Cada uma morde dos dois lados:
nome fora dela tem de estar coberto; nome **dentro** dela tem de continuar descoberto.

| lista | onde | conteúdo | por quê |
|---|---|---|---|
| `SEM_FONTE_AINDA` | `audio.gd` | `Musica`, `Ambiente` | barramento sem som para tocar. **Música** espera uma trilha real. **Ambiente** é decisão registrada: zumbido contínuo é som que a pessoa desliga uma vez e nunca mais liga |
| `SEM_SISTEMA_AINDA` | `config.gd` | `animacoes_de_numero`, `shake` | opções sem consumidor. Entram junto do sistema, nunca antes — opção que não tem o que desligar é opção que o jogador mexe e conclui que o jogo ignorou |
| `SEM_SORTEIO_AINDA` | `teste_descobertas.gd` | `medir_quadro.gd`, `gerar_galeria.gd` | pontos de entrada que **não produzem caractere**, e por isso não precisam da semente. Se um deles passar a produzir, o portão reprova |
| `SEM_TRADUCAO` | `teste_texto.gd` | `×`, `10^`, `? ? ?`, `%s — %s`, … | marcas de formato, não texto. Traduzi-las quebraria a substituição |

---

## 6. Os pontos cegos das ferramentas

O que o verde **não** cobre. Sem esta seção, todos assumem que ele cobre mais do que cobre.

### A régua `medir_ritmo`

- ⚠️ **Não mede eventos.** Nunca chama `Eventos.tique` — a campanha medida não tem
  acontecimento aleatório nenhum, nem bom nem ruim
- ⚠️ **Não mede automação.** Nunca chama `Automacao.tique` — Gerente Macaco e os outros não
  compram sozinhos durante a medição
- **O jogador simulado não é o jogador real.** Ele compra no instante exato em que o saldo
  fecha. Os quatro minutos da §4.1 são o **piso**

Os dois primeiros estão **declarados no cabeçalho da régua**. Ligá-los muda o instrumento, e
tabela medida com instrumento diferente não se compara — se for para ligar, ligue **antes**
de medir o "antes" da issue #58.

### O portão de redação

- ⚠️ **A metade em inglês tem buraco.** Ele varre a coluna `en` do CSV, mas **não distingue
  linha de marco de linha de descoberta** ali — então a regra "o macaco escreveu" só é
  cobrada em português. Em inglês, vale a lista comum

### A hierarquia visual

- ⚠️ **Não tem régua nenhuma.** Três defeitos de leitura desta versão — a loja em ordem
  alfabética, o cabeçalho de família com peso de título, e as entradas de 120 px no Arquivo
  — foram achados **olhando a captura**, com a suíte verde
- Nenhuma medição pega *"isso não parece do mesmo jogo"*

### Plataforma

- Tudo medido em **Windows 11 + Godot 4.7.2**, e no runner Linux do CI
- **Headless não renderiza**: nenhuma afirmação sobre pixel vem da suíte
- ⚠️ E a v0.6 provou que isso importa: o defeito da data de criação **passava no Windows e
  reprovava no Linux**, porque o relógio de cá é mais grosso

### Som e arte

- **O timbre dos CLACKs não foi ouvido.** A suíte prova forma de onda, taxa, teto e mute —
  não prova que soa bem
- **Texto dentro de asset** não é verificável automaticamente

---

## 7. Se você só for fazer três coisas

1. **Jogue trinta minutos.** É o item que nenhuma máquina faz, e o único que pode contradizer
   tudo que está escrito aqui.
2. **Leia uma amostra do texto autoral** (§4.3) e diga se o tom serve. São ~70 peças; achar
   agora que a voz está errada custa uma tarde, achar depois de mais uma versão custa um mês.
3. **Decida a issue #58.** A curva está quebrada, o diagnóstico está escrito, e a direção
   proposta está lá — mas redesenhar a economia é decisão sua.

---

## 8. O que este documento não cobre

- **A dívida das versões anteriores** continua em `docs/ENTREGA-v0.5.md` §9. Esta devolutiva
  não a repete, e ela não foi revisada nesta versão
- **O plano a partir da v0.7** está em `docs/PLANO.md`. Música, midgame, conteúdo cósmico e
  o endgame de Fragmentos estão **fora da v0.6 por decisão do plano**, e não por
  esquecimento — não são dívida, são a ordem
- **Nada aqui mede diversão.** "Setenta e seis marcos em quatro minutos" é um fato sobre a
  curva; se isso é bom ou ruim é leitura, e a leitura está assinada em `docs/decisoes/0007`

---

## 9. Onde procurar o quê

| assunto | arquivo |
|---|---|
| as regras que o código segue | `CONVENCOES.md` |
| as medições, e as retratações | `TUNING.md` |
| a decisão sobre a primeira hora | `docs/decisoes/0007-a-primeira-hora-mede-quatro-minutos.md` |
| o relatório da versão | `docs/ENTREGA-v0.6.md` |
| a dívida das versões anteriores | `docs/ENTREGA-v0.5.md` §9 |
| o que fazer a seguir | issue **#58** |
