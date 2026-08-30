## Um evento aleatorio (GDD §22).
##
## ⚠️ EVENTO NEGATIVO TEM SAIDA PELA ACAO DO JOGADOR. Punicao que so espera passar nao e
## evento, e imposto: o jogador aprende a ignorar e o sistema vira ruido com contador. A
## Banana na Maquina existe para ser CLICADA, e e o clique que a resolve.
##
## ⚠️ TECLA PRESA NAO PODE VIRAR A ESTRATEGIA OTIMA. Ela da muito caractere e ZERA a chance
## de descoberta de proposito -- o ganho e real e o custo tambem, e o jogador que quiser
## farmar so ela vai parar de achar coisa. Se um dia a conta deixar de doer, ela vira o
## unico jeito certo de jogar, e o resto do jogo vira decoracao.
##
## A frequencia mora no .tres: evento e a coisa mais facil de deixar irritante por numero
## errado, e ajustar isso nao pode exigir abrir um .gd.
class_name DadosEvento
extends Resource

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

## Multiplicador de producao enquanto o evento estiver ativo. 1 nao mexe em nada.
@export var multiplicador_producao: float = 1.0

## Multiplicador da chance de descoberta. ZERO e valido e e a Tecla Presa: muito
## caractere, nenhuma descoberta.
@export var multiplicador_descoberta: float = 1.0

## Segundos que o evento dura.
@export var duracao: float = 10.0

## Peso no sorteio, relativo aos outros. Nao e probabilidade: e quantas fichas o evento
## poe no chapeu.
@export var peso: float = 1.0

## Se o jogador consegue encerrar o evento clicando. Evento RUIM sem isso e imposto, e a
## suite reprova (GDD §22: "clicar na banana resolve o problema").
@export var resolve_com_clique: bool = false

@export var icone: Texture2D


## Se o evento e PUNICAO PURA -- pior em tudo e melhor em nada. So esses precisam de
## saida pelo clique, e a suite exige.
##
## TROCA NAO E PUNICAO, e a diferenca importa. A Tecla Presa piora a descoberta e melhora
## muito a producao: ela nao e um castigo esperando passar, e uma decisao que o jogador ja
## recebeu resolvida. Dar botao de encerrar a ela seria transformar uma troca em incomodo,
## e o jogador clicaria por reflexo sem nunca perceber o que estava trocando.
##
## A primeira versao desta funcao dizia "pior em alguma coisa", e a suite reprovou a Tecla
## Presa por falta de botao. A suite estava certa sobre a regra e errada sobre o nome --
## quem precisava de precisao era a definicao.
func e_punicao() -> bool:
	var piora := multiplicador_producao < 1.0 or multiplicador_descoberta < 1.0
	var melhora := multiplicador_producao > 1.0 or multiplicador_descoberta > 1.0
	return piora and not melhora
