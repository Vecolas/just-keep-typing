## Quem faz as contas da producao e do custo. Nome traduzido do EconomyManager do GDD
## §30 -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
## SO CALCULA. O estado e do Jogo, e a unica coisa que esta classe escreve la e o
## resultado de acumular(): os acumuladores e o cps que a HUD le.
##
##   cps   = macacos x velocidade x mult_maquina x mult_sala x mult_prestigio x mult_global
##   custo = base x crescimento^quantidade
##
## NENHUM multiplicador e congelado no momento da compra. Todos sao lidos no frame em que
## importam, para que um bonus novo valha inclusive para o que ja esta em jogo
## (CONVENCOES.md, regra 2 de arquitetura).
##
## NENHUM numero de balanceamento mora aqui (GDD §36). Base, crescimento e producao por
## macaco chegam como argumento, vindos do .tres -- por isso as funcoes de custo sao
## puras: recebem os numeros e nao procuram por eles. Enquanto DadosMacaco nao existe
## (issue #5), quem chama passa o numero na mao; quando existir, muda o chamador e nao
## esta classe.
##
## Compra multipla soma em SERIE GEOMETRICA, nunca em laco: comprar maximo com um saldo
## grande pode significar milhares de unidades, e um laco por unidade transformaria um
## clique em travada de quadro.
extends Node

## Teto da compra multipla. Passar disto num clique so acontece com crescimento
## praticamente igual a 1, que e erro de tuning e nao jogada -- a suite de .tres da issue
## #5 reprova crescimento <= 1. O teto existe para que o erro vire numero grande e nao
## um floori() de infinito.
const COMPRA_MAXIMA: int = 1_000_000_000

## Quantos passos a correcao da estimativa pode dar. O log erra na ultima casa e a conta
## cai no maximo uma unidade fora; mais que isto e sintoma, nao arredondamento.
const CORRECOES_MAXIMAS: int = 8


# --- producao -------------------------------------------------------------------------

## Produto de todos os multiplicadores globais, montado no frame em que e pedido.
##
## Continua float porque multiplicador cabe no double sem perda (decisao 0001); se algum
## dia um deles passar de 10^308, ai sim ele vira Grande -- e a conta muda de forma.
func multiplicador_total() -> float:
	return (
		multiplicador_de_maquina()
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


## Caracteres por segundo agora. A producao por macaco vem do DadosMacaco (issue #5).
func producao_por_segundo(producao_por_macaco: float) -> Grande:
	return (
		Jogo.macacos
		.vezes(Grande.de_float(producao_por_macaco))
		.vezes(Grande.de_float(multiplicador_total()))
	)


## Avanca a producao de um quadro. E a unica funcao que escreve no Jogo.
##
## Grava o cps mesmo quando nao ha producao: a HUD le esse campo, e deixar o valor velho
## la mostraria producao que acabou de ser zerada por um prestigio.
func acumular(delta: float, producao_por_macaco: float) -> void:
	Jogo.caracteres_por_segundo = producao_por_segundo(producao_por_macaco)
	if delta <= 0.0 or Jogo.caracteres_por_segundo.e_zero():
		return
	var produzido := Jogo.caracteres_por_segundo.vezes(Grande.de_float(delta))
	Jogo.total_caracteres = Jogo.total_caracteres.mais(produzido)
	Jogo.caracteres_da_run = Jogo.caracteres_da_run.mais(produzido)


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
