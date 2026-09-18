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
const PASTA_MAQUINAS := "res://data/maquinas"
const PASTA_SALAS := "res://data/salas"
const CAMINHO_OFFLINE := "res://data/offline.tres"

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
##
## ⚠️ A ORDEM DE INSERCAO E A DO CUSTO, e nao a que o DirAccess resolveu listar -- que e
## alfabetica. Ate a issue #53 a loja mostrava "Arquivo Vertical" (4 trilhoes) acima de
## "Cafe para o Macaco" (1,6 milhao) so porque A vem antes de C, e a escada inteira
## aparecia embaralhada. Mesmo motivo de _macacos, _maquinas e _salas ja ordenarem aqui.
var _upgrades: Dictionary = {}

## Ordenadas por tier: a escada do GDD §13, e nao a ordem em que o DirAccess listou.
var _maquinas: Array[DadosMaquina] = []

## Ordenadas por tier: a escada do GDD §15.
var _salas: Array[DadosSala] = []

## Teto da producao offline, do .tres. Nulo so se alguem apagar o arquivo.
var _offline: DadosOffline = null


func _ready() -> void:
	for caminho in _listar_tres(PASTA_MACACOS):
		var macaco := ResourceLoader.load(caminho) as DadosMacaco
		if macaco != null:
			_macacos.append(macaco)
	_macacos.sort_custom(func(a: DadosMacaco, b: DadosMacaco) -> bool:
		return a.custo_base < b.custo_base)

	var upgrades_lidos: Array[DadosUpgrade] = []
	for caminho in _listar_tres(PASTA_UPGRADES):
		var upgrade := ResourceLoader.load(caminho) as DadosUpgrade
		if upgrade != null:
			upgrades_lidos.append(upgrade)
	upgrades_lidos.sort_custom(func(a: DadosUpgrade, b: DadosUpgrade) -> bool:
		return a.custo < b.custo)
	for upgrade in upgrades_lidos:
		_upgrades[upgrade.id] = upgrade

	for caminho in _listar_tres(PASTA_MAQUINAS):
		var maquina := ResourceLoader.load(caminho) as DadosMaquina
		if maquina != null:
			_maquinas.append(maquina)
	_maquinas.sort_custom(func(a: DadosMaquina, b: DadosMaquina) -> bool:
		return a.tier < b.tier)

	for caminho in _listar_tres(PASTA_SALAS):
		var sala := ResourceLoader.load(caminho) as DadosSala
		if sala != null:
			_salas.append(sala)
	_salas.sort_custom(func(a: DadosSala, b: DadosSala) -> bool:
		return a.tier < b.tier)

	_offline = ResourceLoader.load(CAMINHO_OFFLINE) as DadosOffline
	if _offline == null:
		push_error("Economia: %s nao carregou" % CAMINHO_OFFLINE)


# --- catalogo -------------------------------------------------------------------------

## O macaco da v0.1. A issue #14 traz os dez tiers do GDD §14 e isto vira escolha por tier.
func macaco_padrao() -> DadosMacaco:
	return _macacos[0] if not _macacos.is_empty() else null


func upgrade_de(id: String) -> DadosUpgrade:
	return _upgrades.get(id)


## O catalogo, do mais barato para o mais caro. Quem quiser agrupar por familia agrupa na
## tela: a familia e leitura, e ordenar por ela aqui seria a economia decidindo layout.
func upgrades() -> Array:
	return _upgrades.values()


func maquinas() -> Array[DadosMaquina]:
	return _maquinas


func salas() -> Array[DadosSala]:
	return _salas


## A sala em uso. Save vazio -- partida nova -- cai na menor da escada, que e a Sala
## Pequena do GDD §15: o macaco comeca numa sala, nao no vazio.
func sala_atual() -> DadosSala:
	for sala in _salas:
		if sala.id == Jogo.sala_atual:
			return sala
	return _salas[0] if not _salas.is_empty() else null


func proxima_sala() -> DadosSala:
	var atual := sala_atual()
	if atual == null:
		return null
	for sala in _salas:
		if sala.tier > atual.tier:
			return sala
	return null


## Quantos macacos cabem na sala em uso.
func capacidade() -> Grande:
	var sala := sala_atual()
	if sala == null:
		return Grande.zero()
	# upgrade de capacidade MULTIPLICA a sala em vez de somar vagas: somar faria a Sala
	# Pequena com tres upgrades valer mais que o Escritorio, e trocar de sala deixaria de
	# valer a pena exatamente quando o segundo eixo deveria estar apertando
	return Grande.de_float(sala.capacidade * bonus_de(DadosUpgrade.Efeito.CAPACIDADE))


## Quantas vagas sobram. Nunca negativo: sala menor que a populacao acontece de verdade --
## producao offline nao expande sala -- e vaga negativa viraria compra negativa.
func vagas_livres() -> Grande:
	var sobra := capacidade().menos(Jogo.macacos)
	return sobra if sobra.sinal() > 0 else Grande.zero()


## Se a compra cabe. Quem explica ao jogador e a tela: a Economia responde sim ou nao, e
## a HUD e que sabe escrever "sala cheia" -- economia nao monta texto.
func cabe_na_sala(quantos: int) -> bool:
	if quantos <= 0:
		return false
	return not Grande.de_float(float(quantos)).maior_que(vagas_livres())


## So a PROXIMA da escada pode ser comprada, pelo mesmo motivo das maquinas: pular tier e
## pagar por um espaco que viria de graca dois cliques depois.
func expandir_sala(id: String) -> bool:
	var proxima := proxima_sala()
	if proxima == null or proxima.id != id:
		return false
	var custo := Grande.de_float(proxima.custo)
	if custo.maior_que(Jogo.dinheiro):
		return false

	Jogo.dinheiro = Jogo.dinheiro.menos(custo)
	Jogo.sala_atual = proxima.id
	EventBus.sala_expandida.emit(proxima.id)
	return true


## A maquina em uso. Save vazio -- partida nova -- cai na mais barata da escada, que e a
## Maquina Velha do GDD §13: o macaco comeca com ela, nao sem maquina nenhuma.
func maquina_atual() -> DadosMaquina:
	for maquina in _maquinas:
		if maquina.id == Jogo.maquina_atual:
			return maquina
	return _maquinas[0] if not _maquinas.is_empty() else null


## A proxima da escada, ou nulo no topo. Ordem vem do tier e nao do custo: se um dia uma
## maquina cara vier antes de uma barata, quem manda e o GDD e nao o balanceamento.
func proxima_maquina() -> DadosMaquina:
	var atual := maquina_atual()
	if atual == null:
		return null
	for maquina in _maquinas:
		if maquina.tier > atual.tier:
			return maquina
	return null


## So a PROXIMA da escada pode ser comprada. Pular tier deixaria o jogador gastar num
## multiplicador que ele ja teria de graca dois cliques depois.
func comprar_maquina(id: String) -> bool:
	var proxima := proxima_maquina()
	if proxima == null or proxima.id != id:
		return false
	var custo := Grande.de_float(proxima.custo)
	if custo.maior_que(Jogo.dinheiro):
		return false

	Jogo.dinheiro = Jogo.dinheiro.menos(custo)
	Jogo.maquina_atual = proxima.id
	EventBus.maquina_trocada.emit(proxima.id)
	return true


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


## A SOMA dos valores de um tipo ADITIVO (issue #60). Dez upgrades de +2 dao +20, e nao
## 2^10 -- e e essa a diferenca inteira entre uma curva que se ajusta e uma que explode.
##
## ⚠️ Zero e o neutro aqui, e nao um. Quem chamar isto esperando um multiplicador faz a
## producao virar zero -- por isso o nome e `soma_de` e nao `bonus_de`.
func soma_de(tipo: DadosUpgrade.Efeito) -> float:
	var total := 0.0
	for id in Jogo.upgrades_comprados:
		var dados: DadosUpgrade = _upgrades.get(id)
		if dados != null and dados.tipo_de_efeito == tipo:
			total += dados.valor
	return total


## O fator de DESCONTO de um tipo, com piso (issue #60).
##
## ⚠️ O PISO NAO E ZELO. Descontos multiplicam, e multiplicar descontos sem piso leva o
## custo a zero -- e custo zero e macaco infinito, comprado num laco que nao termina. E a
## familia "zero num divisor" da CONVENCOES, e ela nao da erro: o jogo simplesmente para de
## cobrar.
func desconto_de(tipo: DadosUpgrade.Efeito) -> float:
	return maxf(DadosUpgrade.DESCONTO_MINIMO, bonus_de(tipo))


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


# --- loja de macacos ------------------------------------------------------------------

## Preco de comprar `quantos` macacos a partir da quantidade atual (GDD §31 e §32).
##
## A quantidade que entra na curva inclui o macaco com que o jogo comeca, entao o primeiro
## COMPRADO ja sai por base x crescimento. Se um dia isso incomodar, e um numero no .tres
## e nao uma linha aqui.
func custo_de_macacos(quantos: int) -> Grande:
	var macaco := macaco_padrao()
	if macaco == null:
		return Grande.zero()
	return custo_de(
		_base_do_macaco(macaco),
		macaco.crescimento_custo,
		Jogo.macacos.para_float(),
		quantos,
	)


## O custo base do macaco JA COM O DESCONTO dos upgrades de eficiencia (issue #60).
##
## ⚠️ EXISTE PARA SER UM LUGAR SO. Duas funcoes leem esta base -- custo_de_macacos() e
## macacos_que_cabem() -- e aplicar o desconto em uma delas faria "Comprar Maximo" oferecer
## uma quantidade que a compra recusaria depois do clique. Que e exatamente o
## "silenciosamente inutil" que a issue #15 proibe, chegando por outra porta.
func _base_do_macaco(macaco: DadosMacaco) -> Grande:
	return Grande.de_float(
		macaco.custo_base * desconto_de(DadosUpgrade.Efeito.CUSTO_DE_MACACO)
	)


## Quantos cabem no saldo E na sala. E o "Comprar Maximo" do GDD §32.
##
## O limite da sala entra aqui e nao so na compra: sem isso o botao ofereceria comprar
## cinquenta macacos para uma sala com tres vagas, e a compra seria recusada depois do
## clique -- que e exatamente o "silenciosamente inutil" que a issue #15 proibe.
func macacos_que_cabem() -> int:
	var macaco := macaco_padrao()
	if macaco == null:
		return 0
	var pelo_saldo := quantos_cabem(
		_base_do_macaco(macaco),
		macaco.crescimento_custo,
		Jogo.macacos.para_float(),
		Jogo.dinheiro,
	)
	var vagas := vagas_livres()
	if Grande.de_float(float(pelo_saldo)).maior_que(vagas):
		return int(vagas.para_float())
	return pelo_saldo


## Devolve quantos foram comprados de fato -- zero quando nao da, o que e jogada normal e
## nao erro. Cobra o preco da SERIE inteira de uma vez: comprar 100 num clique tem que
## custar o mesmo que cem cliques em comprar 1, e e a suite que garante.
func comprar_macacos(quantos: int) -> int:
	if quantos <= 0:
		return 0
	if not cabe_na_sala(quantos):
		return 0
	var custo := custo_de_macacos(quantos)
	if custo.sinal() <= 0 or custo.maior_que(Jogo.dinheiro):
		return 0

	Jogo.dinheiro = Jogo.dinheiro.menos(custo)
	var comprados := Grande.de_float(float(quantos))
	Jogo.macacos = Jogo.macacos.mais(comprados)
	# contador de vida, e nao de partida: ele e macacos se separam no primeiro prestigio,
	# e e a diferenca entre os dois que conta a historia (GDD §23)
	Jogo.macacos_comprados = Jogo.macacos_comprados.mais(comprados)
	EventBus.macacos_comprados.emit(quantos)
	return quantos


# --- producao -------------------------------------------------------------------------

## Produto de todos os multiplicadores globais, montado no frame em que e pedido.
##
## Continua float porque multiplicador cabe no double sem perda (decisao 0001); se algum
## dia um deles passar de 10^308, ai sim ele vira Grande -- e a conta muda de forma.
func multiplicador_total() -> float:
	return (
		Eventos.multiplicador_de_producao()
		* bonus_de(DadosUpgrade.Efeito.PRODUCAO_GLOBAL)
		* multiplicador_de_maquina()
		* multiplicador_de_sala()
		* multiplicador_de_prestigio()
		* Jogo.multiplicador_global
	)


## O multiplicador do tier em uso (GDD §13). Lido na hora, e nunca multiplicado dentro do
## macaco: trocar de maquina tem que fazer o macaco que ja estava la produzir mais no
## mesmo quadro (CONVENCOES.md, regra 2 de arquitetura).
func multiplicador_de_maquina() -> float:
	var maquina := maquina_atual()
	return maquina.multiplicador if maquina != null else 1.0


## Macaco sem vaga nao produz (GDD §15), e o excesso entra na formula como MULTIPLICADOR
## e nao como corte seco: com vinte macacos numa sala de dez, metade do trabalho acontece.
##
## Corte seco -- apagar o macaco excedente -- seria roubar o que o jogador comprou. Assim
## ele mantem a compra, ve a producao render menos do que devia, e a saida obvia e
## expandir. E o que faz o espaco virar decisao em vez de parede.
func multiplicador_de_sala() -> float:
	var cabem := capacidade()
	if Jogo.macacos.sinal() <= 0 or not Jogo.macacos.maior_que(cabem):
		return 1.0
	return cabem.dividido(Jogo.macacos).para_float()


## A PARCELA de todas as descobertas ja encontradas (GDD §9 e §11), somada e nunca
## multiplicada. Calculada na hora, para que uma descoberta nova valha no mesmo quadro.
##
## ⚠️ ATE A ISSUE #60 ISTO ERA UM PRODUTO, E ERA A MAIOR EXPLOSAO DO JOGO. Medido: as 62
## descobertas compunham para x1,13 x 10^41 -- vinte e oito ordens de grandeza acima dos
## upgrades, que eram o suspeito obvio. A issue #52 acrescentou 46 delas, e o portao que eu
## mesmo escrevi EXIGIA bonus > 1 de toda descoberta de papel BONUS: a regra que protegia
## contra dado esquecido era a mesma que garantia a composicao.
##
## Como parcela, as mesmas 53 descobertas somam +1.665. O `bonus` do .tres continua sendo o
## numero que o autor escreveu; o que mudou e que ele entra como (bonus - 1) numa SOMA.
##
## ⚠️ E ISSO E O QUE A DECISAO 0008 JA DIZIA: "Descoberta -- nao aumenta CPS diretamente".
## Ela nao deixou de valer nada: ela deixou de MULTIPLICAR.
func soma_de_descobertas() -> float:
	var total := 0.0
	for id in Jogo.descobertas:
		var dados := Descobertas.de(id)
		if dados != null:
			# (bonus - 1): o .tres continua guardando o numero que o autor escreveu como
			# multiplicador, e a conversao para parcela mora AQUI, num lugar so. Reescrever
			# os 62 arquivos daria duas leituras possiveis do mesmo campo.
			total += maxf(0.0, dados.bonus - 1.0)
	return total


## O multiplicador dos Pontos de Teorema ja ganhados mais a Probabilidade Condensada
## (GDD §18 e §19). Quem calcula e o autoload Teoremas -- aqui so entra na formula.
func multiplicador_de_prestigio() -> float:
	# os dois prestigios multiplicam juntos: o Fragmento nao substitui a Arvore, ele
	# recomeca por cima dela
	return Teoremas.multiplicador() * Fragmentos.multiplicador()


## Caracteres por segundo de UM macaco, ja com os upgrades de velocidade.
func producao_por_macaco() -> float:
	var macaco := macaco_padrao()
	if macaco == null:
		return 0.0
	# Memoria Genetica multiplica a velocidade do MACACO e nao a producao global, porque
	# e isso que o GDD §19 diz que ela faz -- e a diferenca aparece assim que existir um
	# multiplicador que so vale para um tier de macaco
	# ⚠️ SOMA ANTES, MULTIPLICA DEPOIS (issue #60). A parcela entra na BASE do macaco, e
	# so entao os multiplicadores agem sobre ela -- que e o que mantem um upgrade aditivo
	# relevante no fim do jogo sem ele proprio compor. Somar depois dos multiplicadores
	# faria a parcela virar irrelevante no primeiro prestigio.
	return (
		(
			macaco.producao_base
			+ soma_de(DadosUpgrade.Efeito.VELOCIDADE_SOMADA)
			+ soma_de_descobertas()
		)
		* bonus_de(DadosUpgrade.Efeito.VELOCIDADE_DO_MACACO)
		* Teoremas.bonus_de(DadosTeorema.Efeito.MEMORIA_GENETICA)
	)


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


## A PRODUCAO DECOMPOSTA POR FONTE (issue #71).
##
## ⚠️ ELA EXISTE PORQUE A v0.7 PROCUROU NO LUGAR ERRADO. A regua dizia
## `producao = 8,4e17`, e isso nao permite perguntar DE ONDE VEIO. Os upgrades eram o
## suspeito obvio -- 38 multiplicadores que compunham mais de 10^13 --, e separar todos eles
## moveu o primeiro Teorema de 04:22 para 04:01. O numero estava nas descobertas, x10^41,
## vinte e oito ordens de grandeza acima.
##
## ⚠️ E ELA SAI DA MESMA FORMULA, e nao de uma segunda conta. Somar os fatores por fora faria
## as duas divergirem -- e a decomposicao passaria a mentir exatamente quando alguem
## precisasse dela. Por isso `producao_por_segundo()` e `multiplicador_total()` continuam
## sendo a verdade, e esta funcao devolve as PARTES delas.
##
## ⚠️ E ha portao cruzando as duas: teste_economia reconstroi a producao a partir desta
## arvore e exige que feche. Fonte nova que entre na formula sem entrar aqui reprova -- que
## e o unico jeito de a arvore continuar completa sem alguem lembrar de mante-la.
func producao_por_fonte() -> Array[Dictionary]:
	var macaco := macaco_padrao()
	var base: float = macaco.producao_base if macaco != null else 0.0
	return [
		{"nome": "base do macaco", "fator": base, "tipo": "soma"},
		{
			"nome": "upgrades: velocidade somada",
			"fator": soma_de(DadosUpgrade.Efeito.VELOCIDADE_SOMADA), "tipo": "soma",
		},
		{"nome": "descobertas", "fator": soma_de_descobertas(), "tipo": "soma"},
		{
			"nome": "upgrades: velocidade local",
			"fator": bonus_de(DadosUpgrade.Efeito.VELOCIDADE_DO_MACACO), "tipo": "vezes",
		},
		{
			"nome": "teoremas: memoria genetica",
			"fator": Teoremas.bonus_de(DadosTeorema.Efeito.MEMORIA_GENETICA),
			"tipo": "vezes",
		},
		{"nome": "macacos", "fator": Jogo.macacos.para_float(), "tipo": "vezes"},
		{"nome": "maquina", "fator": multiplicador_de_maquina(), "tipo": "vezes"},
		{
			"nome": "upgrades: global",
			"fator": bonus_de(DadosUpgrade.Efeito.PRODUCAO_GLOBAL), "tipo": "vezes",
		},
		{"nome": "sala", "fator": multiplicador_de_sala(), "tipo": "vezes"},
		{"nome": "prestigio", "fator": multiplicador_de_prestigio(), "tipo": "vezes"},
		{"nome": "eventos", "fator": Eventos.multiplicador_de_producao(), "tipo": "vezes"},
		{"nome": "global do save", "fator": Jogo.multiplicador_global, "tipo": "vezes"},
	]


## Teto da producao offline em segundos. Zero significa sem limite (GDD §38).
##
## A ARVORE MANDA QUANDO ELA JA MEXEU NISSO. O no Producao Offline destrava a escada de
## 8, 12, 24, 72 horas e sem limite, e este teto LE a arvore em vez de guardar uma copia
## propria dos numeros (cuidado da issue #25). Sem no comprado, quem manda e o
## data/offline.tres da issue #9.
func teto_offline_segundos() -> float:
	var da_arvore := Teoremas.teto_offline_horas()
	if da_arvore >= 0.0:
		return da_arvore * 3600.0
	return _offline.teto_segundos() if _offline != null else 0.0


## Credita o que a partida produziu enquanto estava fechada e devolve quanto foi.
##
## Passa pelo mesmo _creditar do clique e do quadro: producao offline nao e um recurso
## paralelo, e o mesmo caractere chegando de outro jeito.
##
## Emite sempre, inclusive com zero: a tela de volta e metade da recompensa de reabrir o
## jogo, e quem escuta precisa saber que a conta foi feita para decidir se mostra algo.
func creditar_offline(segundos_ausente: float) -> Grande:
	var segundos := ProgressoOffline.segundos_creditados(segundos_ausente, teto_offline_segundos())
	var produzido := ProgressoOffline.producao(producao_por_segundo(), segundos)
	if produzido.sinal() > 0:
		_creditar(produzido)
		Jogo.tempo_jogado += segundos
		Jogo.tempo_da_run += segundos
		Jogo.total_offline = Jogo.total_offline.mais(produzido)
	EventBus.voltou_do_offline.emit(produzido, segundos)
	return produzido


## O clique do GDD §3: cada um vale +1 caractere enquanto o macaco nao digita sozinho.
##
## Passa pelo MESMO _creditar da producao automatica de proposito. Dois caminhos ate o
## acumulador seriam dois lugares para esquecer de somar no dia em que um recurso novo
## entrar -- e o que ficasse de fora sumiria em silencio, sem erro nenhum.
## ⚠️ O COMBO (issue #54) MULTIPLICA AQUI E SO AQUI. Ele nao entra em
## multiplicador_total(), e essa e a decisao inteira da issue: preso ao clique, ele
## envelhece sozinho conforme a automacao cresce, em vez de valer x1,5 para sempre. Ver
## src/autoload/combo.gd.
##
## ⚠️ E A ORDEM E CONTRATO: credita com o multiplicador de AGORA, marca depois. Marcando
## primeiro, a propria tecla ganharia o aumento que ela mesma acabou de causar, e o
## primeiro caractere de uma partida nova sairia valendo mais que um.
##
## ⚠️ A conta fica em float e NAO e arredondada para int. Um clique vale 1, e 1 x 1,2
## truncado volta a ser 1 -- o combo existiria, apareceria na tela e nao faria NADA ate o
## teto passar de 2,0. E a armadilha do percentual sobre inteiro, e ela nao da erro.
## Caractere fracionario ja e o normal aqui: o tique credita cps x delta desde a v0.1.
func digitar(quantos: int = 1) -> void:
	if quantos <= 0:
		return
	_creditar(Grande.de_float(float(quantos) * Combo.multiplicador()))
	Combo.marcar(quantos)


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
	# recorde antes da checagem de delta: ele e sobre a producao, e nao sobre o tempo
	if Jogo.caracteres_por_segundo.maior_que(Jogo.recorde_por_segundo):
		Jogo.recorde_por_segundo = Jogo.caracteres_por_segundo
	if Jogo.total_caracteres.maior_que(Jogo.recorde_de_total):
		Jogo.recorde_de_total = Jogo.total_caracteres
	if delta <= 0.0:
		return
	Jogo.tempo_jogado += delta
	Jogo.tempo_da_run += delta
	# o combo cai no mesmo tique em que o tempo anda. Um _process proprio no Combo seria
	# um segundo relogio para a mesma partida, e os dois divergiriam assim que alguem
	# pausasse um deles
	Combo.decair(delta)

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
	# descoberta entra pelo mesmo caminho do caractere, pelo mesmo motivo: um sorteio
	# separado para o clique e outro para o quadro seriam dois lugares para esquecer
	Descobertas.sortear(produzido)


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
