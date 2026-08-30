## Quem faz as contas da producao e do custo. Nome traduzido do EconomyManager do GDD
## §30 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## SO CALCULA. O estado e do Jogo, e o que esta classe escreve la e o resultado da conta:
## os acumuladores, o cps que a HUD le e a lista de upgrades comprados.
##
##   cps   = macacos x velocidade x mult_maquina x mult_sala x mult_prestigio x mult_global
##   custo = base x crescimento^quantidade
##
## NENHUM multiplicador e congelado no momento da compra. Todos sao lidos no frame em que
## importam, para que um bonus novo valha inclusive para o que ja esta em jogo
## (CONVENCOES.md, regra 2 de arquitetura).
##
## NENHUM numero de balanceamento mora aqui (GDD §36): eles vem dos .tres de data/, que
## esta classe carrega no _ready. As funcoes de custo continuam puras -- recebem os
## numeros e nao procuram por eles -- porque e assim que a suite consegue testar a formula
## sem depender de nenhum arquivo de balanceamento.
##
## Compra multipla soma em SERIE GEOMETRICA, nunca em laco: comprar maximo com um saldo
## grande pode significar milhares de unidades, e um laco por unidade transformaria um
## clique em travada de quadro.
extends Node

const PASTA_MACACOS := "res://data/macacos"
const PASTA_UPGRADES := "res://data/upgrades"

## Teto da compra multipla. Passar disto num clique so acontece com crescimento
## praticamente igual a 1, que e erro de tuning e nao jogada -- a suite de .tres reprova
## crescimento <= 1. O teto existe para que o erro vire numero grande e nao um floori()
## de infinito.
const COMPRA_MAXIMA: int = 1_000_000_000

## Quantos passos a correcao da estimativa pode dar. O log erra na ultima casa e a conta
## cai no maximo uma unidade fora; mais que isto e sintoma, nao arredondamento.
const CORRECOES_MAXIMAS: int = 8

## Ordenados do mais barato para o mais caro, para que macaco_padrao() seja sempre o
## primeiro da loja e nao a ordem em que o DirAccess resolveu listar a pasta.
var _macacos: Array[DadosMacaco] = []

## id -> DadosUpgrade. Dicionario porque a compra chega por id, vindo do save.
var _upgrades: Dictionary = {}


func _ready() -> void:
	for caminho in _listar_tres(PASTA_MACACOS):
		var macaco := ResourceLoader.load(caminho) as DadosMacaco
		if macaco != null:
			_macacos.append(macaco)
	_macacos.sort_custom(func(a: DadosMacaco, b: DadosMacaco) -> bool:
		return a.custo_base < b.custo_base)

	for caminho in _listar_tres(PASTA_UPGRADES):
		var upgrade := ResourceLoader.load(caminho) as DadosUpgrade
		if upgrade != null:
			_upgrades[upgrade.id] = upgrade


# --- catalogo -------------------------------------------------------------------------

## O macaco da v0.1. A issue #14 traz os dez tiers do GDD §14 e isto vira escolha por tier.
func macaco_padrao() -> DadosMacaco:
	return _macacos[0] if not _macacos.is_empty() else null


func upgrade_de(id: String) -> DadosUpgrade:
	return _upgrades.get(id)


func upgrades() -> Array:
	return _upgrades.values()


# --- upgrades -------------------------------------------------------------------------

## Quanto bonus de UM TIPO existe no total, somando todos os upgrades comprados.
##
## E a regra que vale ouro da CONVENCOES.md: o gameplay nunca pergunta o nivel de um
## upgrade especifico. E o que permite as vinte entradas da issue #18 sem tocar em uma
## linha de gameplay -- upgrade novo e um .tres, e mais nada.
func bonus_de(tipo: DadosUpgrade.Efeito) -> float:
	var total := 1.0
	for id in Jogo.upgrades_comprados:
		var dados: DadosUpgrade = _upgrades.get(id)
		if dados != null and dados.tipo_de_efeito == tipo:
			total *= dados.valor
	return total


## Se existe algum upgrade comprado com esse efeito. Para os efeitos de interruptor, que
## nao multiplicam nada.
func tem_efeito(tipo: DadosUpgrade.Efeito) -> bool:
	for id in Jogo.upgrades_comprados:
		var dados: DadosUpgrade = _upgrades.get(id)
		if dados != null and dados.tipo_de_efeito == tipo:
			return true
	return false


## O macaco comeca sem saber digitar sozinho (GDD §3): ate alguem acender isto, so o
## clique produz. Perguntando pelo TIPO, nunca pelo id do Instinto Digitador.
func producao_automatica() -> bool:
	return tem_efeito(DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA)


## Devolve se a compra aconteceu. Recusa em silencio o que e jogada invalida (nao tem
## dinheiro, ja comprou, ainda nao desbloqueou) e grita so no que e erro de programa.
func comprar_upgrade(id: String) -> bool:
	var dados: DadosUpgrade = _upgrades.get(id)
	if dados == null:
		push_error("Economia: upgrade %s nao existe" % id)
		return false
	if Jogo.upgrades_comprados.has(id):
		return false
	if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
		return false

	var custo := Grande.de_float(dados.custo)
	if custo.maior_que(Jogo.dinheiro):
		return false

	Jogo.dinheiro = Jogo.dinheiro.menos(custo)
	Jogo.upgrades_comprados.append(id)
	EventBus.upgrade_comprado.emit(id)
	return true


# --- producao -------------------------------------------------------------------------

## Produto de todos os multiplicadores globais, montado no frame em que e pedido.
##
## Continua float porque multiplicador cabe no double sem perda (decisao 0001); se algum
## dia um deles passar de 10^308, ai sim ele vira Grande -- e a conta muda de forma.
func multiplicador_total() -> float:
	return (
		bonus_de(DadosUpgrade.Efeito.PRODUCAO_GLOBAL)
		* multiplicador_de_maquina()
		* multiplicador_de_sala()
		* multiplicador_de_prestigio()
		* Jogo.multiplicador_global
	)


## Vale 1.0 ate a issue #14 trazer os dez tiers do GDD §13. Existe como funcao desde
## agora para que a formula ja nasca com a forma final, e ligar as maquinas seja mudar
## um corpo em vez de mexer em quem chama.
func multiplicador_de_maquina() -> float:
	return 1.0


## Vale 1.0 ate a issue #15 trazer as salas (GDD §15).
func multiplicador_de_sala() -> float:
	return 1.0


## Vale 1.0 ate a issue #24 trazer os Teoremas (GDD §17-18).
func multiplicador_de_prestigio() -> float:
	return 1.0


## Caracteres por segundo de UM macaco, ja com os upgrades de velocidade.
func producao_por_macaco() -> float:
	var macaco := macaco_padrao()
	if macaco == null:
		return 0.0
	return macaco.producao_base * bonus_de(DadosUpgrade.Efeito.VELOCIDADE_DO_MACACO)


## Caracteres por segundo agora. Zero enquanto ninguem acendeu a producao automatica --
## e o estado em que o jogo comeca (GDD §3), e nao um caso de erro.
func producao_por_segundo() -> Grande:
	if not producao_automatica():
		return Grande.zero()
	return (
		Jogo.macacos
		.vezes(Grande.de_float(producao_por_macaco()))
		.vezes(Grande.de_float(multiplicador_total()))
	)


## O clique do GDD §3: cada um vale +1 caractere enquanto o macaco nao digita sozinho.
##
## Passa pelo MESMO _creditar da producao automatica de proposito. Dois caminhos ate o
## acumulador seriam dois lugares para esquecer de somar no dia em que um recurso novo
## entrar -- e o que ficasse de fora sumiria em silencio, sem erro nenhum.
func digitar(quantos: int = 1) -> void:
	if quantos <= 0:
		return
	_creditar(Grande.de_float(float(quantos)))


## Avanca a partida em delta segundos. E o tique do jogo inteiro: quem tem quadro chama
## isto, e o relogio anda junto.
##
## Grava o cps mesmo quando nao ha producao: a HUD le esse campo, e deixar o valor velho
## la mostraria producao que acabou de ser zerada por um prestigio.
##
## O relogio anda antes da checagem de producao, e de proposito: tempo passa mesmo sem
## producao, e a producao offline da issue #9 e uma conta sobre esse tempo.
func acumular(delta: float) -> void:
	Jogo.caracteres_por_segundo = producao_por_segundo()
	if delta <= 0.0:
		return
	Jogo.tempo_jogado += delta

	if Jogo.caracteres_por_segundo.e_zero():
		return
	_creditar(Jogo.caracteres_por_segundo.vezes(Grande.de_float(delta)))


## Cada caractere digitado vira uma moeda -- ver docs/decisoes/0004-caractere-e-a-moeda.md.
## Por isso o mesmo produzido entra em tres campos com vidas diferentes: total_caracteres
## nunca desce (e o numero do Panorama), caracteres_da_run zera no prestigio, e dinheiro
## desce a cada compra.
func _creditar(produzido: Grande) -> void:
	Jogo.total_caracteres = Jogo.total_caracteres.mais(produzido)
	Jogo.caracteres_da_run = Jogo.caracteres_da_run.mais(produzido)
	Jogo.dinheiro = Jogo.dinheiro.mais(produzido)


# --- custo ----------------------------------------------------------------------------

## Custo da PROXIMA unidade, com quantidade sendo quantas ja se tem (GDD §31).
func custo_do_proximo(custo_base: Grande, crescimento: float, quantidade: float) -> Grande:
	return custo_base.vezes(Grande.de_float(crescimento).potencia(quantidade))


## Custo de comprar varias de uma vez, pela soma da serie geometrica:
##
##   base x g^quantidade x (g^quantos - 1) / (g - 1)
##
## Comprar 100 de uma vez custa o mesmo que 100 compras de 1, e e a suite que garante --
## um erro aqui e o tipo de coisa que so aparece quando alguem compara os dois botoes.
func custo_de(custo_base: Grande, crescimento: float, quantidade: float, quantos: int) -> Grande:
	if quantos <= 0:
		return Grande.zero()

	var primeiro := custo_do_proximo(custo_base, crescimento, quantidade)
	# uma unidade sai pelo caminho exato: a serie passaria por potencia e log so para
	# devolver o mesmo numero com erro na ultima casa, e comprar 1 e o caso mais comum
	if quantos == 1:
		return primeiro

	if crescimento <= 1.0:
		push_error("Economia: crescimento %s nao e maior que 1" % crescimento)
		# custo constante e o limite da serie quando o crescimento tende a 1
		return primeiro.vezes(Grande.de_float(float(quantos)))

	var fator := Grande.de_float(crescimento).potencia(float(quantos)).menos(Grande.um())
	return primeiro.vezes(fator).dividido(Grande.de_float(crescimento - 1.0))


## Quantas unidades cabem no saldo. E o botao "Comprar Maximo" do GDD §32.
##
## Inverte a serie geometrica em vez de somar de um em um:
##
##   quantos = log_g( 1 + disponivel x (g - 1) / custo_do_proximo )
##
## O log erra na ultima casa e a estimativa pode cair uma unidade fora, entao ela e
## CONFERIDA contra a mesma custo_de() que vai debitar a compra. E o que sustenta as duas
## promessas: nunca gastar mais do que se tem, e nunca devolver 0 quando da para comprar 1.
func quantos_cabem(
	custo_base: Grande, crescimento: float, quantidade: float, disponivel: Grande
) -> int:
	if disponivel.sinal() <= 0:
		return 0

	var primeiro := custo_do_proximo(custo_base, crescimento, quantidade)
	if primeiro.sinal() <= 0:
		push_error("Economia: custo do proximo nao e positivo")
		return 0
	if primeiro.maior_que(disponivel):
		return 0

	if crescimento <= 1.0:
		push_error("Economia: crescimento %s nao e maior que 1" % crescimento)
		return _limitar(disponivel.dividido(primeiro).para_float())

	var razao := disponivel.vezes(Grande.de_float(crescimento - 1.0)).dividido(primeiro)
	var alvo := Grande.um().mais(razao).log10()
	var passo := Grande.de_float(crescimento).log10()
	var quantos := _limitar(alvo / passo)

	var correcoes := 0
	while quantos > 1 and custo_de(custo_base, crescimento, quantidade, quantos).maior_que(disponivel):
		quantos -= 1
		correcoes += 1
		if correcoes >= CORRECOES_MAXIMAS:
			break
	while custo_de(custo_base, crescimento, quantidade, quantos + 1).menor_ou_igual(disponivel):
		quantos += 1
		correcoes += 1
		if correcoes >= CORRECOES_MAXIMAS:
			break
	# chegar aqui com primeiro <= disponivel e nao poder comprar 1 seria arredondamento
	# comendo uma compra legitima, que e exatamente o que a issue proibe
	return maxi(quantos, 1)


static func _limitar(estimativa: float) -> int:
	return int(clampf(floorf(estimativa), 0.0, float(COMPRA_MAXIMA)))


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Economia: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
