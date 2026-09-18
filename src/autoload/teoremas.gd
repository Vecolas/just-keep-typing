## O prestigio e a Arvore de Teoremas (GDD §17, §18 e §19). Nome traduzido do
## PrestigeManager -- ver docs/decisoes/0002-codigo-em-portugues.md.
##
##   pontos = log10(total_de_caracteres / limite_inicial)
##
## O SISTEMA EXISTE PARA CRIAR UMA PERGUNTA: "faco prestigio agora ou continuo?" (GDD
## §18). Se a resposta for sempre obvia, o balanceamento esta errado e nao o jogador -- e
## e a regua medir_economia da issue #29 que vai dizer qual dos dois.
##
## A RUN SEGUINTE NUNCA RENDE MENOS QUE A ANTERIOR. E o que sustenta o sistema inteiro, e
## por isso o multiplicador global le os pontos GANHOS na vida e nao o saldo disponivel:
## se olhasse o saldo, comprar um no da arvore seria uma punicao.
##
## Prestigiar cedo demais nao pode travar a partida: o unico custo e o reset, e o reset
## sempre devolve pelo menos um ponto -- provar o Teorema por menos de um ponto nem
## aparece como opcao.
extends Node

const PASTA := "res://data/teoremas"
const CAMINHO_PRESTIGIO := "res://data/prestigio.tres"

## Os tetos de producao offline do GDD §38, em horas. O indice e o nivel do no Producao
## Offline; zero e o teto do .tres da issue #9, e o ultimo degrau e SEM LIMITE.
##
## Mora aqui e nao em Economia porque e a arvore que destrava a escada -- o teto LE este
## no, e nao tem copia propria do numero (cuidado da issue #25).
const TETOS_OFFLINE: Array[float] = [8.0, 12.0, 24.0, 72.0, 0.0]

var _nos: Array[DadosTeorema] = []
var _prestigio: DadosPrestigio = null


func _ready() -> void:
	for caminho in _listar_tres(PASTA):
		var no := ResourceLoader.load(caminho) as DadosTeorema
		if no != null:
			_nos.append(no)
	_nos.sort_custom(func(a: DadosTeorema, b: DadosTeorema) -> bool:
		return a.custo < b.custo)

	_prestigio = ResourceLoader.load(CAMINHO_PRESTIGIO) as DadosPrestigio
	if _prestigio == null:
		push_error("Teoremas: %s nao carregou" % CAMINHO_PRESTIGIO)


# --- a arvore ---------------------------------------------------------------------------

func nos() -> Array[DadosTeorema]:
	return _nos


func de(id: String) -> DadosTeorema:
	for no in _nos:
		if no.id == id:
			return no
	return null


func nivel_de(id: String) -> int:
	return int(Jogo.teoremas.get(id, 0))


## Custo do proximo nivel: custo x crescimento^nivel, a mesma forma do GDD §31.
func custo_do_proximo(id: String) -> Grande:
	var no := de(id)
	if no == null or nivel_de(id) >= no.niveis:
		return Grande.zero()
	return Grande.de_float(no.custo).vezes(
		Grande.de_float(no.crescimento_custo).potencia(float(nivel_de(id)))
	)


## Se os pre-requisitos ja tem pelo menos um nivel. No sem pre-requisito esta sempre
## desbloqueado -- e a raiz da arvore.
func desbloqueado(id: String) -> bool:
	var no := de(id)
	if no == null:
		return false
	for anterior in no.pre_requisitos:
		if nivel_de(anterior) <= 0:
			return false
	return true


func pode_comprar(id: String) -> bool:
	var no := de(id)
	if no == null or nivel_de(id) >= no.niveis or not desbloqueado(id):
		return false
	return not custo_do_proximo(id).maior_que(Jogo.pontos_de_teorema)


## Devolve se comprou. Gasta do saldo e nao dos pontos ganhos na vida: o multiplicador
## global olha os ganhos, e comprar um no nunca pode encolher a producao.
func comprar(id: String) -> bool:
	if not pode_comprar(id):
		return false
	Jogo.pontos_de_teorema = Jogo.pontos_de_teorema.menos(custo_do_proximo(id))
	Jogo.teoremas[id] = nivel_de(id) + 1
	EventBus.teorema_comprado.emit(id)
	return true


## Produto do valor de todos os niveis comprados de um tipo. Um no de oito niveis com
## valor 1,25 chega a 1,25^8 -- e a escada do GDD §19.
func bonus_de(tipo: DadosTeorema.Efeito) -> float:
	var total := 1.0
	for no in _nos:
		if no.tipo_de_efeito == tipo:
			total *= pow(no.valor, float(nivel_de(no.id)))
	return total


## Nivel somado de um tipo, para os nos que sao escada e nao multiplicador.
func niveis_de(tipo: DadosTeorema.Efeito) -> int:
	var total := 0
	for no in _nos:
		if no.tipo_de_efeito == tipo:
			total += nivel_de(no.id)
	return total


## Teto de producao offline em horas, ou -1 quando a arvore ainda nao mexeu nele -- ai
## quem manda e o data/offline.tres da issue #9.
func teto_offline_horas() -> float:
	var nivel := niveis_de(DadosTeorema.Efeito.PRODUCAO_OFFLINE)
	if nivel <= 0:
		return -1.0
	return TETOS_OFFLINE[mini(nivel, TETOS_OFFLINE.size()) - 1]


# --- o prestigio ------------------------------------------------------------------------

## Quantos pontos o jogador levaria se provasse o Teorema AGORA (GDD §18).
##
## Sai como Grande e nao como float porque o expoente do total passa de 10^308 na v0.4, e
## log10 de INF nao e ponto de teorema nenhum.
func pontos_ao_provar() -> Grande:
	if _prestigio == null or _prestigio.limite_inicial <= 0.0:
		return Grande.zero()
	var limite := Grande.de_float(_prestigio.limite_inicial)
	if not Jogo.total_caracteres.maior_que(limite):
		return Grande.zero()
	var bruto := Jogo.total_caracteres.dividido(limite).log10()
	return Grande.de_float(floorf(bruto * bonus_de(DadosTeorema.Efeito.TEOREMA_REFINADO)))


func pode_provar() -> bool:
	if _prestigio == null:
		return false
	return not pontos_ao_provar().menor_que(Grande.de_float(_prestigio.pontos_minimos))


## Multiplicador global que os pontos JA GANHADOS dao. Ver o bloco do topo: sao os ganhos
## e nao o saldo, senao comprar na arvore deixaria a run seguinte mais lenta.
func multiplicador() -> float:
	if _prestigio == null:
		return 1.0
	var por_pontos := 1.0 + Jogo.pontos_totais.para_float() * _prestigio.ganho_por_ponto
	return por_pontos * _condensada()


## Probabilidade Condensada (GDD §19): cada ordem de grandeza ja atingida vira um pequeno
## multiplicador. Le o RECORDE e nao o total atual -- senao o bonus sumiria no reset, que
## e exatamente quando ele deveria estar segurando a run nova.
func _condensada() -> float:
	var no_valor := bonus_de(DadosTeorema.Efeito.PROBABILIDADE_CONDENSADA)
	if is_equal_approx(no_valor, 1.0) or Jogo.recorde_de_total.sinal() <= 0:
		return 1.0
	return pow(no_valor, maxf(Jogo.recorde_de_total.log10(), 0.0))


## Prova o Teorema: reinicia a run e devolve os pontos ganhos (GDD §17).
##
## O que MORRE: macacos, maquina, sala, dinheiro, producao e upgrades. O que FICA: total de
## caracteres, marcos, pontos, recorde e as estatisticas de vida -- e as descobertas, se a
## Biblioteca Persistente estiver comprada.
##
## Devolve zero e nao faz nada quando nao da para provar: reset acidental e o pior bug
## possivel aqui, e recusar em silencio e melhor que resetar por engano.
func provar() -> Grande:
	if not pode_provar():
		return Grande.zero()
	var ganhos := pontos_ao_provar()

	Jogo.pontos_de_teorema = Jogo.pontos_de_teorema.mais(ganhos)
	Jogo.pontos_totais = Jogo.pontos_totais.mais(ganhos)
	Jogo.prestigios += 1

	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.tempo_da_run = 0.0
	Jogo.upgrades_comprados = _upgrades_que_sobrevivem()

	if nivel_de_tipo_zero(DadosTeorema.Efeito.BIBLIOTECA_PERSISTENTE):
		Jogo.esquecer_descobertas()

	EventBus.teorema_provado.emit(ganhos)
	return ganhos


## Conhecimento Acumulado (GDD §19): a run nova ja comeca com os upgrades mais baratos.
## Um por nivel, do mais barato para o mais caro -- o que o jogador compraria primeiro.
func _upgrades_que_sobrevivem() -> Array[String]:
	var quantos := niveis_de(DadosTeorema.Efeito.CONHECIMENTO_ACUMULADO)
	if quantos <= 0:
		return [] as Array[String]

	var candidatos := Economia.upgrades().duplicate()
	candidatos.sort_custom(func(a: DadosUpgrade, b: DadosUpgrade) -> bool:
		return a.custo < b.custo)

	var mantidos: Array[String] = []
	for dados in candidatos:
		if mantidos.size() >= quantos:
			break
		mantidos.append(dados.id)
	return mantidos


## Verdadeiro quando o no daquele tipo NAO foi comprado. Nome no negativo porque quem
## chama esta perguntando "posso apagar isto?".
func nivel_de_tipo_zero(tipo: DadosTeorema.Efeito) -> bool:
	return niveis_de(tipo) <= 0


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Teoremas: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
