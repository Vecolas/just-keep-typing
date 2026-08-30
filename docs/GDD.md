# GDD — Just Keep Typing

Documento de design. **É cânone**: quando divergir de qualquer outro documento do
repositório, este vence. Mudou de ideia sobre o jogo? Muda aqui primeiro.

O texto abaixo é o plano do autor, preservado como escrito. As decisões de implementação
que ele levanta — nomes de classe, tipo dos números, formato dos dados — estão resolvidas
em `decisoes/` e no `PLANO.md`, não aqui.

---

# PLANO DE DESENVOLVIMENTO — INCREMENTAL DO MACACO INFINITO

## 1. Conceito geral

O jogo será um incremental inspirado no **Teorema do Macaco Infinito**.

A premissa é simples:

Um macaco possui uma máquina de escrever e começa a pressionar teclas aleatoriamente.

No início, o jogador acompanha números extremamente pequenos:

* 1 caractere.
* 10 caracteres.
* 100 caracteres.
* 1.000 caracteres.

Porém, conforme novas máquinas, macacos, salas e tecnologias são adquiridas, a quantidade produzida aumenta exponencialmente.

O principal elemento de progressão narrativa será o **Panorama da Escrita**, mostrando comparações cada vez mais absurdas.

Exemplo:

> Você já digitou caracteres suficientes para escrever todos os adjetivos da língua portuguesa.

Depois:

> Você já digitou caracteres suficientes para escrever todas as palavras da língua portuguesa.

Depois:

> Você já digitou caracteres suficientes para escrever todas as palavras de todas as línguas humanas.

Até eventualmente chegar a escalas como:

> Você já digitou caracteres suficientes para registrar tudo que a humanidade já disse.

> Você já produziu texto suficiente para preencher todos os livros já escritos.

> Você já produziu mais texto do que toda a informação escrita produzida pela humanidade.

> Você já ultrapassou tudo que já foi escrito.

> Agora estamos entrando no território do que poderia ter sido escrito.

O jogo começa como uma piada simples sobre um macaco digitando e lentamente evolui para algo sobre **probabilidade, linguagem, humanidade e infinito**.

---

# 2. Loop principal

O loop básico será:

MACACOS
↓
DIGITAM
↓
GERAM CARACTERES
↓
CARACTERES GERAM DINHEIRO/RECURSOS
↓
COMPRAR MAIS MACACOS
↓
COMPRAR MÁQUINAS MELHORES
↓
PRODUZIR MAIS CARACTERES
↓
ALCANÇAR NOVOS MARCOS
↓
DESCOBRIR TEXTOS
↓
PRESTÍGIO
↓
RECOMEÇAR MAIS FORTE

A principal unidade de produção será:

**Caracteres Digitados**

Exemplo:

12 caracteres

1.240 caracteres

821 mil caracteres

42 milhões de caracteres

17 bilhões de caracteres

4,82 × 10²³ caracteres

Eventualmente os números ficarão tão grandes que o jogo deverá trabalhar quase exclusivamente em notação científica.

---

# 3. Começo do jogo

O jogador começa vendo apenas:

* Um macaco.
* Uma máquina de escrever.
* Uma folha.
* Um contador.
* Um botão ou tecla para digitar manualmente.

Cada clique inicialmente produz:

**+1 caractere**

O macaco ainda não sabe digitar sozinho.

Primeiro upgrade:

### Instinto Digitador

O macaco começa a pressionar teclas sozinho.

Produção:

1 caractere por segundo.

A partir desse momento começa o verdadeiro incremental.

---

# 4. Primeiros upgrades

Os upgrades iniciais devem ser simples e visíveis.

### Dedos Mais Ágeis

+50% velocidade de digitação.

### Duas Mãos

Macaco começa a utilizar mais teclas.

x2 produção.

### Máquina Lubrificada

Reduz o tempo entre teclas.

x1,5 produção.

### Treinamento Questionável

O macaco começa a bater nas teclas com uma técnica surpreendentemente eficiente.

x2 produção.

### Segunda Máquina

Permite contratar outro macaco.

Esse será o momento em que o jogador começa a perceber que o verdadeiro crescimento será baseado em quantidade.

---

# 5. Sistema de macacos

Os macacos serão a principal unidade produtora.

Cada macaco possui uma quantidade base de:

**caracteres por segundo.**

Fórmula inicial:

Produção = Macacos × Velocidade × Multiplicador das Máquinas × Multiplicadores Globais

Exemplo:

10 macacos

5 caracteres/s por macaco

Máquina x2

Upgrade global x3

Produção:

10 × 5 × 2 × 3

= 300 caracteres/s

---

# 6. Evolução dos locais

O ambiente também deverá evoluir conforme o jogador progride.

Isso ajuda a mostrar visualmente a escala do jogo.

## Era 1 — A Mesa

1 macaco.

1 máquina.

Uma pequena sala.

---

## Era 2 — Sala de Digitação

Dezenas de macacos trabalhando simultaneamente.

Máquinas começam a ocupar todo o ambiente.

---

## Era 3 — Escritório dos Macacos

Centenas de máquinas.

Esteiras levando papel.

Funcionários administrando páginas.

---

## Era 4 — Fábrica Literária

Milhares de macacos.

Máquinas industriais.

Rolos gigantes de papel.

Armazéns de páginas.

---

## Era 5 — Complexo de Digitação

Milhões de macacos.

Grandes prédios dedicados exclusivamente a produzir texto aleatório.

---

## Era 6 — Cidade dos Macacos

Uma cidade inteira dedicada à digitação.

Apartamentos.

Fábricas.

Centros de processamento.

Bibliotecas.

---

## Era 7 — Planeta Tipográfico

O planeta inteiro foi convertido em uma máquina de produção textual.

Continentes cobertos de máquinas.

---

## Era 8 — Sistema Solar

Estações orbitais cheias de macacos.

Lua transformada em servidor de texto.

Mercúrio dedicado à produção de máquinas.

---

## Era 9 — Macacos Interestelares

Sistemas solares inteiros trabalhando.

---

## Era 10 — Galáxia Tipográfica

Bilhões de estrelas abastecendo o processo.

---

## Era 11 — Universo Observável

Toda matéria disponível é utilizada para gerar combinações.

---

## Era 12 — Computação Quântica

Macacos físicos deixam de ser suficientes.

Cada possibilidade começa a ser simulada.

---

## Era 13 — Macacos Multiversais

Cada universo calcula conjuntos diferentes de textos.

---

## Era 14 — Biblioteca do Infinito

O conceito de quantidade de macacos deixa de fazer sentido.

O jogador passa a manipular diretamente:

* Probabilidade.
* Informação.
* Possibilidades.
* Realidades.

---

# 7. O Panorama

O **Panorama** deverá ser uma das telas mais importantes do jogo.

Ele funciona como uma enorme linha de progressão vertical ou horizontal.

Exemplo:

1 caractere

↓

Uma palavra

↓

Uma frase

↓

Uma página

↓

Um livro

↓

Uma biblioteca

↓

Todas as palavras do português

↓

Todas as palavras humanas

↓

Tudo que você já falou

↓

Tudo que uma pessoa fala durante a vida

↓

Tudo que a humanidade falou em um dia

↓

Tudo que a humanidade já falou

↓

Todos os livros já escritos

↓

Toda a internet

↓

Tudo que a humanidade já escreveu

↓

Tudo que a humanidade poderia razoavelmente escrever

↓

Todas as combinações possíveis de pequenas frases

↓

Todas as combinações possíveis de livros

↓

Biblioteca do Infinito

O Panorama cria constantemente novos objetivos.

---

# 8. Exemplos de mensagens do Panorama

Ao alcançar determinados valores, aparecerá uma mensagem especial.

### Primeiros marcos

“Você digitou sua primeira palavra em quantidade de caracteres.”

“Você já produziu o equivalente a uma página.”

“Você já produziu caracteres suficientes para escrever um livro.”

“Você já poderia preencher uma pequena estante.”

---

### Língua portuguesa

“Você já digitou caracteres suficientes para escrever milhares de palavras diferentes.”

“Você já produziu o equivalente a todos os adjetivos registrados da língua portuguesa.”

“Você já produziu caracteres suficientes para escrever todas as palavras de um grande dicionário português.”

“Em quantidade de caracteres, seu macaco já poderia ter reescrito a língua portuguesa inteira.”

---

### Linguagem humana

“Você já produziu caracteres suficientes para representar enormes vocabulários de várias línguas.”

“Você já ultrapassou o tamanho necessário para registrar vocabulários de milhares de idiomas.”

“Seu exército de macacos já produziu caracteres suficientes para representar praticamente todas as palavras documentadas pelas civilizações humanas.”

---

### Literatura

“Você já produziu texto suficiente para preencher uma biblioteca.”

“Uma biblioteca já não seria suficiente.”

“Nem mil bibliotecas seriam suficientes.”

“Você já produziu caracteres suficientes para reescrever grandes coleções literárias da humanidade.”

“Tudo que Shakespeare escreveu ocuparia apenas uma fração minúscula da sua produção.”

---

### Humanidade

“Você já produziu caracteres suficientes para registrar anos inteiros de conversas humanas.”

“Você poderia registrar tudo que uma cidade inteira dissesse durante uma vida.”

“Você já produziu caracteres suficientes para representar uma quantidade absurda de toda a comunicação humana.”

“Tudo que a humanidade já escreveu parece pequeno diante da sua produção.”

---

### Internet

“Você já poderia preencher milhões de sites.”

“Você produziu texto suficiente para criar versões gigantescas da internet.”

“Mesmo os maiores arquivos digitais humanos já parecem pequenos.”

---

### Escala impossível

Depois desse ponto os marcos passam a deixar de comparar o jogador apenas com coisas existentes.

“Você ultrapassou aquilo que foi escrito.”

“Agora começamos a contar aquilo que poderia ter sido escrito.”

“Existem mais textos aqui do que histórias que a humanidade teve tempo de imaginar.”

“Para cada livro existente, seus macacos produziram incontáveis livros que jamais existiram.”

---

# 9. Textos significativos

Além da quantidade total de caracteres, haverá um segundo sistema:

**Descobertas**

Os macacos normalmente produzem lixo como:

AKJDLFKWQPOQLDK

Mas ocasionalmente aparecem padrões.

Por exemplo:

“banana”

Isso gera uma descoberta:

### PRIMEIRA PALAVRA

Um macaco produziu acidentalmente uma palavra válida.

Bônus permanente:

+10% produção.

---

Outras descobertas:

“casa”

“macaco”

“eu”

“banana”

Uma frase válida.

Uma frase gramaticalmente correta.

Uma citação famosa.

Uma página coerente.

Um poema.

Um conto.

Um livro.

Uma obra conhecida.

---

# 10. Não simular probabilidades literalmente

É importante não tentar gerar bilhões de caracteres reais.

O jogo deverá apenas calcular a produção.

Por exemplo:

total_caracteres += caracteres_por_segundo × delta

As descobertas podem utilizar uma fórmula separada.

Exemplo:

Chance de descoberta = caracteres produzidos × chance_base × bônus

Assim o jogo consegue representar números absurdos sem realmente produzir o texto.

---

# 11. Descobertas lendárias

Algumas descobertas serão extremamente raras.

Exemplo:

### HAMLET

“Um dos seus macacos aparentemente escreveu Hamlet.”

Recompensa:

x10 produção permanente.

---

### ROMANCE INÉDITO

Um macaco produziu um romance completamente coerente que nunca foi escrito antes.

---

### MINHA BIOGRAFIA

Um macaco aparentemente escreveu toda a vida do jogador.

---

### O JOGO

Um macaco escreveu o código-fonte do próprio jogo.

---

### ESSA MENSAGEM

“Um dos macacos acabou de escrever exatamente este texto.”

---

### O PRÓXIMO TEXTO

“Estranhamente, um macaco escreveu aquilo que outro macaco escreveria cinco segundos depois.”

---

Essas descobertas podem adicionar humor conforme o jogo começa a brincar com a própria ideia do infinito.

---

# 12. Categorias de descoberta

As descobertas podem ser divididas em:

## Comum

Palavras.

Pequenas frases.

Expressões.

---

## Incomum

Frases completas.

Parágrafos.

Pequenas histórias.

---

## Raro

Poemas.

Artigos.

Histórias coerentes.

---

## Épico

Livros.

Peças.

Grandes obras.

---

## Lendário

Obras famosas completas.

---

## Impossível

Textos astronomicamente improváveis.

---

## Paradoxal

Textos relacionados ao próprio universo do jogo.

Exemplo:

“O macaco descreveu exatamente o estado atual da sala.”

---

# 13. Máquinas de escrever

Além dos macacos, haverá diferentes níveis de equipamento.

### Máquina Velha

x1 produção.

### Máquina Mecânica

x3.

### Máquina Elétrica

x10.

### Teclado Industrial

x50.

### Terminal Digital

x250.

### Cluster de Digitação

x1.000.

### Simulador Neural

x10.000.

### Processador Quântico

x1.000.000.

### Computador Probabilístico

x1 bilhão.

### Máquina de Possibilidades

Passa a produzir combinações diretamente.

---

# 14. Evolução dos próprios macacos

Os macacos também podem possuir tiers.

### Macaco Comum

Produção básica.

### Macaco Treinado

x5.

### Macaco Especialista

x25.

### Macaco Escritor

x100.

### Macaco Linguista

x1.000.

### Macaco Matemático

x10.000.

### Macaco Cibernético

x1 milhão.

### Macaco Quântico

x1 bilhão.

### Macaco de Schrödinger

Está digitando e não está digitando simultaneamente.

### Macaco Infinito

Produção baseada no número de possibilidades existentes.

---

# 15. Sistema de salas

Cada sala terá capacidade limitada.

Exemplo:

Sala pequena:
10 macacos.

Escritório:
50 macacos.

Galpão:
500 macacos.

Fábrica:
10.000 macacos.

Cidade:
milhões.

Isso cria um segundo eixo de progressão.

O jogador precisa aumentar:

* Quantidade de macacos.
* Velocidade.
* Qualidade das máquinas.
* Espaço disponível.

---

# 16. Automação

No começo:

O jogador compra tudo manualmente.

Depois surgem upgrades.

### Gerente Macaco

Compra automaticamente novos macacos.

### Técnico

Compra upgrades das máquinas.

### Administrador

Expande salas automaticamente.

### Diretor de Probabilidades

Administra descobertas.

Isso é importante para permitir que o jogo gradualmente se torne mais automático.

---

# 17. Prestígio

O jogo deve possuir um sistema de prestígio.

Nome sugerido:

## Teoremas

Ao atingir determinado ponto, o jogador poderá:

**Provar o Teorema**

Isso reinicia:

* Macacos.
* Máquinas.
* Dinheiro.
* Salas.
* Produção.

Em troca recebe:

**Pontos de Teorema**

---

# 18. Cálculo do prestígio

Exemplo simplificado:

Pontos de Teorema = log10(total de caracteres / limite inicial)

Quanto mais avançada a run, mais pontos.

O jogo deverá incentivar o jogador a decidir:

“Faço prestígio agora ou continuo produzindo?”

---

# 19. Árvore de prestígio

Os Pontos de Teorema poderão desbloquear melhorias permanentes.

### Memória Genética

Macacos digitam 25% mais rápido.

Possui vários níveis.

---

### Déjà Vu Literário

Aumenta a chance de descobertas.

---

### Conhecimento Acumulado

Começa cada run com upgrades básicos.

---

### Biblioteca Persistente

Algumas descobertas não são perdidas.

---

### Produção Offline

Macacos continuam trabalhando enquanto o jogo está fechado.

---

### Probabilidade Condensada

Cada ordem de grandeza atingida fornece um pequeno multiplicador.

---

### Teorema Refinado

Aumenta os Pontos de Teorema recebidos.

---

# 20. Segundo nível de prestígio

Muito mais tarde pode existir outro reset.

Nome:

## Reescrever o Universo

O jogador sacrifica inclusive:

* Pontos de Teorema.
* Upgrades de prestígio.
* Grande parte do progresso.

Para ganhar:

**Fragmentos do Infinito**

Eles fornecem bônus extremamente grandes.

Isso permite criar progressão de longo prazo.

---

# 21. Humor progressivo

O tom pode começar simples.

“Macaco apertou tecla.”

Depois ficar científico:

“Probabilidade de produzir uma palavra reconhecível aumentou.”

Depois filosófico:

“Talvez a diferença entre acaso e criatividade seja apenas tempo suficiente.”

E finalmente absurdo:

“Existem agora mais versões desta mensagem do que átomos disponíveis para lê-las.”

---

# 22. Eventos aleatórios

Alguns eventos podem aparecer durante a partida.

### Banana na Máquina

Um macaco parou de trabalhar.

Produção -5% durante 30 segundos.

Clicar na banana resolve o problema.

---

### Macaco Inspirado

Um macaco entra em estado de inspiração.

x10 produção por 20 segundos.

---

### Tecla Presa

Uma máquina produz:

AAAAAAAAAAAAAAAAAAAA

Muito rápido.

Grande aumento temporário de caracteres, mas nenhuma descoberta.

---

### Crítico Literário

Uma descoberta recebe um bônus temporário.

---

### Shakespeare?

Durante alguns segundos a chance de descoberta aumenta drasticamente.

---

# 23. Estatísticas

Criar uma tela específica.

Mostrar:

Total de caracteres digitados.

Caracteres desta run.

Caracteres por segundo.

Recorde de caracteres/s.

Macacos comprados.

Máquinas utilizadas.

Prestígios realizados.

Pontos de Teorema ganhos.

Descobertas realizadas.

Palavras encontradas.

Frases encontradas.

Livros encontrados.

Tempo total jogado.

Tempo de jogo desta run.

Produção offline.

---

# 24. Estatísticas engraçadas

Também colocar estatísticas sem grande utilidade.

“Bananas consumidas.”

“Máquinas destruídas.”

“Macacos que aprenderam a escrever.”

“Macacos que aparentemente aprenderam física.”

“Hamlets produzidos.”

“Textos que ninguém jamais lerá.”

“Quantidade estimada de erros ortográficos.”

---

# 25. Interface principal

A tela principal pode possuir três grandes regiões.

### Centro

Cena dos macacos trabalhando.

As máquinas vão aumentando visualmente.

---

### Esquerda

Recursos:

Caracteres

Caracteres/s

Dinheiro

Descobertas

---

### Direita

Loja.

Macacos.

Máquinas.

Upgrades.

---

Na parte superior:

PANORAMA

DESCOBERTAS

PRESTÍGIO

ESTATÍSTICAS

OPÇÕES

---

# 26. Feedback visual

Cada máquina poderá produzir pequenas letras subindo na tela.

Exemplo:

A

B

?

K

L

Durante produção maior:

“+42K caracteres”

Depois:

“+38M”

Não tentar representar individualmente tudo quando a produção aumentar.

O efeito deverá diminuir automaticamente conforme o jogo cresce para evitar poluição visual e perda de desempenho.

---

# 27. Mudança visual pela escala

A apresentação deverá mudar bastante durante a campanha.

Começo:

Um macaco em uma mesa.

Depois:

Sala.

Depois:

Prédio.

Depois:

Cidade.

Depois:

Planeta.

Depois:

Sistema Solar.

Depois:

Galáxia.

Depois:

Universo.

A câmera pode se afastar progressivamente.

Isso dará ao jogo uma sensação forte de evolução mesmo sendo um incremental.

---

# 28. Estrutura recomendada no Godot

Estrutura aproximada:

res://

scenes/

Main.tscn

TypingRoom.tscn

Shop.tscn

Panorama.tscn

Discoveries.tscn

Prestige.tscn

Statistics.tscn

Settings.tscn

scripts/

game_manager.gd

economy_manager.gd

prestige_manager.gd

milestone_manager.gd

discovery_manager.gd

save_manager.gd

offline_progress.gd

number_formatter.gd

resources/

monkeys/

machines/

upgrades/

milestones/

discoveries/

prestige/

ui/

assets/

audio/

---

# 29. GameManager

Criar um Autoload chamado:

GameManager

Responsável por guardar:

total_characters

run_characters

characters_per_second

money

monkeys

machines

global_multiplier

prestige_points

infinity_fragments

play_time

O GameManager não deve controlar diretamente a interface.

Ele apenas mantém o estado do jogo.

---

# 30. EconomyManager

Responsável por calcular:

Produção.

Custos.

Multiplicadores.

Compra de upgrades.

Exemplo:

characters_per_second =
monkey_count
× monkey_speed
× machine_multiplier
× room_multiplier
× prestige_multiplier
× global_multiplier

---

# 31. Custos exponenciais

Utilizar uma fórmula como:

Custo = CustoBase × Crescimento^Quantidade

Exemplo:

Macaco:

Base = 10

Crescimento = 1,15

Primeiro:

10

Segundo:

11,5

Terceiro:

13,2

Depois de dezenas de compras os valores começam a crescer rapidamente.

---

# 32. Compras múltiplas

Adicionar botões:

Comprar 1

Comprar 10

Comprar 100

Comprar Máximo

Em jogos incrementais isso se torna essencial rapidamente.

---

# 33. Sistema de números gigantes

Esse é um ponto extremamente importante.

O jogo poderá facilmente ultrapassar:

10^100

10^500

10^10000

O float padrão do Godot eventualmente não será suficiente.

Criar uma classe própria:

BigNumber

Armazenando:

mantissa

expoente

Exemplo:

5,28 × 10^4321

Armazenamento:

mantissa = 5.28

exponent = 4321

Assim o jogo poderá representar números praticamente arbitrários.

---

# 34. Formatação dos números

No começo:

1.000

15.000

2,5 milhões

Depois:

1,25e12

4,83e28

9,12e140

Quando os números ficarem absurdamente grandes:

10^1000

10^1000000

Eventualmente:

10^(10^100)

pode se tornar parte da progressão do endgame.

---

# 35. MilestoneManager

Cada marco do Panorama deverá existir como um Resource.

Exemplo conceitual:

Milestone

ID:
portuguese_words

Nome:
A Língua Portuguesa

Requisito:
1e9 caracteres

Texto:
“Você já digitou caracteres suficientes para equivaler a um enorme vocabulário da língua portuguesa.”

Ícone:
dicionário

Categoria:
linguagem

Ao ultrapassar o requisito:

milestone.unlocked = true

O jogador recebe uma notificação.

---

# 36. Não colocar todos os valores diretamente no código

Macacos, máquinas, upgrades e marcos devem ser Resources.

Isso permite alterar balanceamento sem modificar o sistema principal.

Exemplo:

MonkeyData

name

description

base_cost

production

cost_scaling

icon

unlock_requirement

---

# 37. Salvamento

SaveManager deverá salvar:

Total de caracteres.

Caracteres da run.

Moedas.

Macacos.

Máquinas.

Upgrades.

Prestígios.

Descobertas.

Milestones.

Configurações.

Timestamp da última sessão.

---

# 38. Produção offline

Ao abrir o jogo:

tempo_offline = agora - último_save

Então:

produção_offline =
characters_per_second × tempo_offline

Pode existir um limite inicialmente.

Exemplo:

Máximo de 4 horas.

Com upgrades:

8 horas.

12 horas.

24 horas.

72 horas.

Sem limite.

---

# 39. Primeira versão jogável

O primeiro protótipo não precisa ter toda a ideia.

Criar apenas:

1 macaco.

Produção manual.

Produção automática.

Contador de caracteres.

Loja de macacos.

Upgrade de velocidade.

Cinco marcos do Panorama.

Sistema de save.

Produção offline.

Quando isso estiver divertido, expandir.

---

# 40. Segunda versão

Adicionar:

Máquinas.

Salas.

20 upgrades.

20 marcos.

Descobertas.

Animações.

Estatísticas.

---

# 41. Terceira versão

Adicionar:

Prestígio.

Árvore de Teoremas.

50+ marcos.

Novas eras visuais.

Eventos.

Produção offline completa.

---

# 42. Quarta versão

Adicionar:

Planeta.

Espaço.

Computação quântica.

Segundo prestígio.

Fragmentos do Infinito.

Descobertas absurdas.

Endgame.

---

# 43. Exemplo completo de evolução de uma partida

O jogador começa:

1 macaco

1 caractere por clique

↓

Compra Instinto Digitador

1 caractere/s

↓

Compra macacos

15 caracteres/s

↓

Melhora máquinas

500 caracteres/s

↓

Primeiro Panorama:

“Você já escreveu uma página.”

↓

10 mil caracteres/s

↓

“Você já escreveu um livro.”

↓

1 milhão/s

↓

“Você já poderia preencher uma biblioteca.”

↓

Bilhões/s

↓

“Você já produziu caracteres suficientes para representar enormes partes de um idioma.”

↓

Trilhões/s

↓

Novas instalações.

↓

Milhões de macacos.

↓

Primeiro prestígio.

↓

Produção aumenta drasticamente.

↓

Novas runs.

↓

Planeta inteiro digitando.

↓

“Tudo que a humanidade já escreveu representa apenas uma pequena parte da sua produção.”

↓

Computação quântica.

↓

Produção deixa de depender fisicamente de macacos.

↓

Galáxias simulam combinações.

↓

Multiverso.

↓

Biblioteca do Infinito.

---

# 44. Panorama de endgame

No final, os textos do Panorama podem mudar de tom.

“Não existem mais comparações humanas úteis.”

“Bibliotecas deixaram de ser uma unidade de medida relevante.”

“Você não está mais produzindo textos.”

“Você está percorrendo possibilidades.”

Depois:

“Para cada história que poderia ser escrita, existem incontáveis versões nas quais uma única letra é diferente.”

Depois:

“Para cada universo descrito, existem outros textos descrevendo universos quase idênticos.”

Depois:

“Se existe uma combinação finita de caracteres, seus macacos inevitavelmente chegarão até ela.”

Último grande marco:

## O MACACO INFINITO

“Você percebe que nunca esteve tentando fazer o macaco escrever alguma coisa específica.”

“Você estava apenas dando tempo suficiente ao acaso.”

---

# 45. Filosofia de design

O principal diferencial do jogo não deverá ser apenas ver números aumentando.

A recompensa do jogador será constantemente descobrir:

**“O que esse número significa?”**

10 milhões sozinho não impressiona muito.

Mas:

“Você já digitou caracteres suficientes para reescrever centenas de livros.”

faz aquele mesmo número possuir significado.

Por isso, o Panorama deverá receber tanta atenção quanto os próprios upgrades.

O jogador deverá constantemente querer chegar ao próximo marco apenas para descobrir qual será a próxima comparação.

Assim, o crescimento seguirá três escalas simultâneas:

PRODUÇÃO

1 → milhares → bilhões → números absurdos

ESCALA VISUAL

mesa → sala → fábrica → cidade → planeta → galáxia → universo

ESCALA CONCEITUAL

letras → palavras → livros → humanidade → toda informação → todas as possibilidades → infinito

Essa combinação deve formar a identidade principal do jogo.

---

# 46. Próximo passo apontado pelo autor

Transformar o Panorama em uma lista de cerca de **80–100 marcos ordenados**, desde “você
digitou seu nome em quantidade de caracteres” até conceitos cosmológicos e todas as
combinações possíveis de textos. Isso praticamente definiria toda a curva de progressão do
jogo.
