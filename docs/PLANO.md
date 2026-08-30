# Plano de desenvolvimento

O GDD (`GDD.md`) diz o que o jogo é. Este documento diz em que ordem ele é construído e
onde cada pedaço vira issue.

Quatro versões, espelhando §39–§42 do GDD. Cada versão é uma tag jogável do início ao fim
— o ponto para onde voltar quando um refactor descarrilar.

| Versão | Milestone | Alvo | Issues |
|---|---|---|---|
| v0.1 | Protótipo | abre, produz, salva, volta com produção offline, 5 marcos | #1–#13 |
| v0.2 | Máquinas e descobertas | máquinas, salas, descobertas, Panorama completo | #14–#23 |
| v0.3 | Prestígio e eras | Teoremas, árvore, eras 1–7, eventos, automação | #24–#29 |
| v0.4 | Endgame | eras 8–14, Fragmentos do Infinito, O MACACO INFINITO | #30–#34 |

Regra de fechamento: **nenhuma issue fecha sem `runner.tscn` e `teste_fumaca.tscn`
imprimindo `PASSOU`.** Issue que cria lógica pura nova traz a suite junto; issue que mexe
em cena estende o teste de fumaça; issue de balanceamento traz a régua.

---

## v0.1 — Protótipo jogável

O GDD §39 é explícito sobre o alvo: um macaco, produção manual e automática, contador, loja,
um upgrade, cinco marcos, save e produção offline. **Quando isso estiver divertido,
expandir** — e não antes.

| # | Issue | GDD | Prova |
|---|---|---|---|
| 1 | `Grande`: números com mantissa e expoente | §33 | suite `teste_grande` |
| 2 | `Formatador`: de `1.240` a `10^(10^100)` | §34 | suite de fronteiras |
| 3 | Autoload `Jogo`: o estado da partida | §29 | suite de scripts |
| 4 | Autoload `Economia`: produção, custo e compra múltipla | §30–32 | suite `teste_economia` |
| 5 | `DadosMacaco` e `DadosUpgrade` em `.tres` | §36 | suite que valida os `.tres` |
| 6 | Digitar no clique e o Instinto Digitador | §3–4 | fumaça |
| 7 | HUD mínima: contador, cps, botão, loja | §25 | fumaça + captura |
| 8 | Autoload `Save`: gravar, carregar, migrar versão | §37 | suite `teste_save` |
| 9 | Produção offline com teto de 4 h | §38 | suite com relógio injetado |
| 10 | `DadosMarco`, autoload `Marcos` e os 5 primeiros | §35 | suite `teste_marcos` |
| 11 | Panorama v0: a lista vertical | §7, §45 | fumaça + captura |
| 12 | `teste_fumaca` cobre a run inteira | — | ele mesmo |
| 13 | Régua `medir_ritmo` | `TUNING.md` | mede, não aprova |

**A ordem importa aqui.** #1 e #2 vêm antes de tudo porque todo o resto fala `Grande`
(ver [decisão 0001](decisoes/0001-numeros-grandes.md)). #8 vem antes de #9 porque produção
offline é uma conta sobre o timestamp do save. #12 fecha a versão amarrando o que as outras
doze construíram.

## v0.2 — Máquinas, salas e descobertas

O eixo único (comprar macaco) vira três eixos: quantidade, qualidade e espaço. E entra o
segundo sistema de recompensa, que não é número: as descobertas.

| # | Issue | GDD | Prova |
|---|---|---|---|
| 14 | Máquinas: 10 tiers e multiplicadores | §13 | suite de `.tres` |
| 15 | Salas: capacidade como segundo eixo | §15 | suite + fumaça |
| 16 | Descobertas: chance por caractere e 7 categorias | §9, §10, §12 | suite `teste_descobertas` |
| 17 | Tela de Descobertas | §9 | fumaça + captura |
| 18 | 20 upgrades em `.tres` | §4 | suite de `.tres` |
| 19 | Panorama completo: 80–100 marcos ordenados | §7, §8, §44, §46 | suite: ordem, unicidade, tradução |
| 20 | Curva do Panorama: espaçar os marcos com a régua | §45 | `medir_ritmo` |
| 21 | Estatísticas, inclusive as inúteis | §23–24 | fumaça |
| 22 | Letras subindo, com degradação por escala | §26 | `medir_quadro` |
| 23 | i18n ligado: traduções registradas e portão de texto | `CONVENCOES.md` | portão reprova texto sem linha no CSV |

**#19 é a issue mais pesada do projeto** e é conteúdo, não código — ela define a curva de
progressão inteira (ver [decisão 0003](decisoes/0003-panorama-como-dados.md)). #20 é a
sessão de tuning que vem logo atrás dela, com número medido na mão.

**#16 nunca gera texto.** O GDD §10 é categórico: o jogo calcula a chance, não produz os
caracteres. Uma descoberta é um sorteio contra um número, e a piada é que o jogador acredita
que o macaco escreveu.

## v0.3 — Prestígio e eras

O jogo ganha o segundo tempo: a run acaba, e recomeçar é vantagem.

| # | Issue | GDD | Prova |
|---|---|---|---|
| 24 | Teoremas: prestígio e reset | §17–18 | suite `teste_teoremas` |
| 25 | Árvore de Teoremas: os 7 nós | §19 | suite de `.tres` |
| 26 | Eras visuais 1 a 7 e a câmera afastando | §6, §27, `ARTE.md` | captura por era |
| 27 | Eventos aleatórios | §22 | suite + fumaça |
| 28 | Automação: gerente, técnico, administrador, diretor | §16 | suite + fumaça |
| 29 | Régua `medir_economia` e a sessão de tuning | §18 | mede, não aprova |

A pergunta que o §18 quer criar — *"faço prestígio agora ou continuo?"* — só existe se a
curva estiver ajustada. Por isso #29 fecha a versão: sem ela, o prestígio é um botão, não
uma decisão.

## v0.4 — Endgame

A escala deixa de ser física. O tom do Panorama muda (§44) e o jogo entrega a frase que
justifica o resto.

| # | Issue | GDD | Prova |
|---|---|---|---|
| 30 | Eras 8 a 14: do sistema solar à Biblioteca do Infinito | §6 | captura por era |
| 31 | Fragmentos do Infinito: segundo prestígio | §20 | suite |
| 32 | Descobertas lendárias, impossíveis e paradoxais | §11–12 | suite + revisão de texto |
| 33 | Panorama de endgame e O MACACO INFINITO | §44 | revisão de texto |
| 34 | Opções: vídeo, idioma e slots de save | `CONVENCOES.md` | fumaça + captura |

---

## O que este plano não faz

- **Não fixa datas.** Uma pessoa, sem prazo; o que importa é a ordem, não o calendário.
- **Não escreve teste antes de existir lógica.** As suites listadas nascem junto do sistema
  de cada issue.
- **Não escreve régua que mede o vazio.** `medir_ritmo` só existe a partir de #13 porque
  antes dela não há marco para cronometrar; `medir_economia` só em #29.
- **Não abre duas frentes.** Uma issue por vez, uma cena por vez — a issue seguinte só
  começa depois do merge da anterior.
