## O estado da partida, e nada mais. Nome traduzido do GameManager do GDD §29 --
## ver docs/decisoes/0002-codigo-em-portugues.md.
##
## SO GUARDA ESTADO. Nao calcula producao, nao toca UI, nao decide nada: quem calcula e
## Economia, quem desenha e a tela, quem avisa e o EventBus. A regra parece burocratica
## e nao e -- ela e o que permite Economia ser trocada inteira sem que ninguem perca o
## save, e o que impede o autoload de virar o lugar onde tudo acaba morando.
##
## Por isso tambem nao ha _process aqui: nem para o tempo_jogado. Quem tem quadro chama
## Economia.acumular(), e e ela que faz o relogio andar.
##
## Os acumuladores sao Grande, o resto e float (decisao 0001: Grande e para acumulador,
## nao para tudo). Grande e imutavel, entao atribuir um aqui e seguro sem copiar.
extends Node

## Nunca reseta. E o numero do Panorama: o que o jogador digitou desde sempre.
var total_caracteres: Grande = Grande.zero()

## Zera no prestigio (GDD §17). E o numero que a run corrente produziu.
var caracteres_da_run: Grande = Grande.zero()

## Producao corrente. Quem escreve e Economia, no frame em que recalcula.
var caracteres_por_segundo: Grande = Grande.zero()

## O que sobra para gastar. Sobe junto com a producao, um caractere por moeda, e desce a
## cada compra -- e a unica diferenca entre ele e caracteres_da_run. Zera no prestigio.
## Ver docs/decisoes/0004-caractere-e-a-moeda.md.
var dinheiro: Grande = Grande.zero()

## Quantos macacos digitam. Grande e nao int porque o endgame chama O MACACO INFINITO --
## a contagem cresce sem teto de design como qualquer outro acumulador.
##
## Comeca em 1: o GDD §3 abre a partida com o jogador vendo um macaco, uma maquina e uma
## folha. Ele so nao sabe digitar sozinho ainda -- quem acende isso e o Instinto Digitador.
var macacos: Grande = Grande.um()

## Ids dos upgrades ja comprados. Guarda o id e nao o Resource porque isto vai para o save
## (issue #8), e id em snake_case sobrevive a renomear arquivo (decisao 0002).
##
## Ninguem le esta lista procurando um id especifico: quem pergunta usa
## Economia.bonus_de(tipo) ou tem_efeito(tipo). Ver CONVENCOES.md, o corolario que vale
## ouro.
var upgrades_comprados: Array[String] = []

## Id do tier de maquina em uso. Maquina e TIER e nao quantidade: a formula do GDD §30 tem
## um multiplicador de maquina no singular, e o jogador troca a maquina em vez de acumular.
##
## Vazio significa a mais barata da lista -- e o estado de partida nova, e nao um erro.
var maquina_atual: String = ""

## Id da sala em uso. Vazio significa a menor da lista -- o estado de partida nova.
##
## Macaco sem vaga nao produz (GDD §15): e o que transforma "comprar macaco" em decisao
## em vez de reflexo, e o que faz o espaco ser um eixo de progressao ao lado da
## quantidade, da velocidade e da qualidade da maquina.
var sala_atual: String = ""

## Multiplicador que vale para tudo. Continua float de proposito: multiplicador cabe no
## double sem perda, e Grande so paga a pena em acumulador (decisao 0001).
var multiplicador_global: float = 1.0

## Moeda do primeiro prestigio (GDD §17-18). Sobrevive ao reset da run.
var pontos_de_teorema: Grande = Grande.zero()

## Pontos de Teorema JA GANHADOS na vida. Nunca desce, nem gastando na arvore: e ele que
## alimenta o multiplicador global, e se o multiplicador olhasse o saldo, comprar um no da
## arvore deixaria a run seguinte mais lenta -- que e o que a issue #25 proibe.
var pontos_totais: Grande = Grande.zero()

## Nivel comprado de cada no da Arvore de Teoremas, por id. Dicionario e nao lista porque
## no tem NIVEL e nao so presenca (GDD §19).
var teoremas: Dictionary = {}

## Maior total de caracteres ja atingido. Nao desce no prestigio, e e ele que a
## Probabilidade Condensada le -- o bonus por ordem de grandeza nao pode sumir no reset,
## que e exatamente quando ele deveria estar segurando a run nova.
var recorde_de_total: Grande = Grande.zero()

## Moeda do segundo prestigio (GDD §20). Sobrevive inclusive ao reset dos Teoremas.
var fragmentos: Grande = Grande.zero()

## Ids dos marcos ja cruzados. Guarda o id e nao o Resource porque isto vai para o save.
##
## Marco nao da bonus, da significado (decisao 0003) -- por isso esta lista so serve para
## a tela saber o que ja foi lido e para o autoload Marcos nao emitir duas vezes.
var marcos_alcancados: Array[String] = []

## Ids das descobertas ja encontradas. O bonus delas e derivado desta lista e calculado
## na hora de usar, nunca guardado ja multiplicado (CONVENCOES.md, regra 2).
var descobertas: Array[String] = []

## Maior producao por segundo ja atingida. Recorde nao desce nem no prestigio: e a marca
## da melhor partida, e nao o estado da partida atual.
var recorde_por_segundo: Grande = Grande.zero()

## Quantos macacos foram COMPRADOS na vida, e nao quantos existem agora. Os dois numeros
## se separam no primeiro prestigio, e e a diferenca entre eles que conta a historia.
var macacos_comprados: Grande = Grande.zero()

## Quanto a producao offline ja rendeu no total. Estatistica pura -- nada le isto para
## calcular nada.
var total_offline: Grande = Grande.zero()

## Quantas vezes o Teorema foi provado (GDD §17). Fica em zero ate a issue #24.
var prestigios: int = 0

## id da automacao -> se esta LIGADA. A chave existir significa comprada; o valor diz se
## esta agindo. Sao duas coisas diferentes de proposito: desligar nao devolve o dinheiro
## nem apaga a compra (GDD §16).
##
## Sobrevive ao prestigio: automacao comprada e conquista de vida, e nao de run.
var automacoes: Dictionary = {}

## Quantas vezes o Universo foi reescrito (GDD §20). Nao zera nunca.
var reescritas: int = 0

## tempo_jogado no instante da ultima descoberta Lendaria ou acima. E o que espaca uma
## rara da seguinte -- ver Descobertas.em_quarentena e dados_raridade.gd.
##
## Vai para o save de proposito: fechar o jogo e voltar nao pode entregar a segunda
## lendaria de graca, senao a quarentena vira um botao.
##
## ⚠️ NEGATIVO significa "nenhuma ainda", e nao zero. A primeira versao usava zero e a
## quarentena nunca ligava: a primeira rara costuma cair com tempo_jogado ainda baixo,
## gravava zero de volta, e zero era justamente o valor que desligava a regra. A suite
## pegou seis lendarias no mesmo instante.
var tempo_da_ultima_rara: float = -1.0

## Segundos desta run, que zeram no prestigio. tempo_jogado nao zera.
var tempo_da_run: float = 0.0

## Segundos de partida acumulados. Float porque e tempo, nao acumulador de recurso.
var tempo_jogado: float = 0.0

## O nome que o jogador deu a este Manuscrito (issue #35). Vazio significa "ainda sem
## nome", e nao erro: quem escolhe o nome e a tela de Arquivos, que so chega na issue #40.
##
## Mora AQUI e nao no .meta de proposito. O metadado e derivado e o save e a fonte -- nome
## que so existisse no .meta seria nome que o jogo perderia ao reconstruir o metadado de um
## save antigo, e ninguem notaria ate ja ter perdido.
var nome: String = ""

## Quando este Manuscrito nasceu, no relogio do sistema. Zero significa "ainda nao
## gravado": a primeira gravacao carimba a data e ela nao muda mais.
var criado_em: float = 0.0
