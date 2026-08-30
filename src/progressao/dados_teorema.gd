## Um no da Arvore de Teoremas (GDD §19). Nome traduzido do PrestigeManager -- ver
## docs/decisoes/0002-codigo-em-portugues.md.
##
## O efeito entra por TIPO e nunca por id, como os upgrades: o gameplay pergunta quanto
## bonus de um tipo a arvore da, e no novo do mesmo tipo nao mexe em codigo nenhum.
##
## NENHUM NO PODE DEIXAR A RUN SEGUINTE MAIS LENTA QUE A ANTERIOR. E o que a issue #25
## proibe, e e por isso que os pontos que alimentam o multiplicador global sao os GANHOS
## na vida e nao os disponiveis: comprar um no gasta ponto, e se o multiplicador olhasse o
## saldo, comprar seria uma punicao.
class_name DadosTeorema
extends Resource

## Os sete do GDD §19. Cada um conversa com um sistema diferente, e a conversa acontece no
## sistema -- e nao aqui.
enum Efeito {
	## Macacos digitam mais rapido. Varios niveis (GDD §19).
	MEMORIA_GENETICA,
	## Aumenta a chance de descobertas.
	DEJA_VU_LITERARIO,
	## Comeca cada run com upgrades basicos ja comprados.
	CONHECIMENTO_ACUMULADO,
	## Algumas descobertas nao sao perdidas no reset. E regra de SAVE, e nao de tela.
	BIBLIOTECA_PERSISTENTE,
	## Destrava os tetos de producao offline: 8 h, 12 h, 24 h, 72 h e sem limite.
	## O teto da issue #9 LE este no; ele nao tem copia propria do numero.
	PRODUCAO_OFFLINE,
	## Cada ordem de grandeza ja atingida da um pequeno multiplicador.
	PROBABILIDADE_CONDENSADA,
	## Aumenta os Pontos de Teorema recebidos.
	TEOREMA_REFINADO,
}

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

@export var tipo_de_efeito: Efeito = Efeito.MEMORIA_GENETICA

## Custo do PRIMEIRO nivel, em Pontos de Teorema.
@export var custo: float = 0.0

## Quanto o custo cresce a cada nivel comprado. Em 1 o no de varios niveis sairia de graca
## depois do primeiro, e a suite reprova.
@export var crescimento_custo: float = 1.0

## Quantos niveis existem. Um para os nos de liga-desliga; varios para Memoria Genetica e
## Producao Offline, que sao escadas.
@export_range(1, 10) var niveis: int = 1

## O que cada nivel acrescenta. O significado depende do tipo: multiplicador para os de
## producao e de chance, e degrau da escada para Producao Offline.
@export var valor: float = 1.0

## Ids dos nos que precisam existir antes deste. A suite reprova ciclo e no orfao -- um
## ciclo trava a arvore inteira em silencio, e ninguem descobre jogando.
@export var pre_requisitos: PackedStringArray = PackedStringArray()

@export var icone: Texture2D
