## Uma automacao (GDD §16).
##
## ⚠️ AUTOMACAO SO ENTRA DEPOIS DE O JOGADOR TER FEITO AQUILO NA MAO O BASTANTE. E o que o
## `requisito` garante. Automatizar cedo demais nao economiza trabalho: apaga o sistema
## antes de o jogador entender o que foi apagado, e ele passa o resto do jogo sem saber o
## que aquele botao fazia.
##
## ⚠️ E SEMPRE DESLIGAVEL. Automacao que nao desliga e o jogo jogando sozinho, e um
## incremental que joga sozinho nao precisa de jogador.
class_name DadosAutomacao
extends Resource

## O que ela faz. Cada uma chama a MESMA funcao que o botao manual chama -- nao existe
## caminho de compra separado para o automatico, e e por isso que a suite consegue afirmar
## que os dois compram a mesma coisa.
enum Tarefa {
	## Gerente Macaco: compra macacos.
	COMPRAR_MACACOS,
	## Tecnico: troca a maquina pelo proximo tier.
	TROCAR_MAQUINA,
	## Administrador: expande a sala.
	EXPANDIR_SALA,
	## Diretor de Probabilidades: resolve os eventos de punicao.
	##
	## "Administrar descobertas" no GDD §16 vira isto aqui porque, nos sistemas que
	## existem, a unica coisa administravel sobre descoberta e o que a atrapalha -- uma
	## Banana na Maquina rodando e tempo de descoberta perdido. E usa Eventos.resolver(),
	## a mesma funcao do botao.
	RESOLVER_EVENTOS,
}

## snake_case sem acento: vai para o save e para chave de dicionario (decisao 0002).
@export var id: String = ""

## Texto que o jogador le -- entra em i18n/textos.csv na mesma mudanca que o cria.
@export var nome: String = ""

@export var descricao: String = ""

@export var tarefa: Tarefa = Tarefa.COMPRAR_MACACOS

## Custo em caracteres (decisao 0004). Compra unica.
@export var custo: float = 0.0

## Quantos caracteres totais liberam a compra. E o numero que garante que o jogador ja fez
## aquilo na mao o bastante para sentir alivio quando parar.
@export var requisito: float = 0.0

## De quanto em quanto tempo ela age. Agir todo quadro seria sessenta compras por segundo
## para uma decisao que o jogador tomava a cada trinta.
@export var intervalo: float = 1.0

@export var icone: Texture2D
