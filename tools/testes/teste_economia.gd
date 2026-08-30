## Suite da Economia: custo exponencial, serie geometrica e compra maxima.
##
## Os numeros de entrada sao os do GDD §31 -- base 10, crescimento 1,15, terceira compra
## custando 13,2 -- de proposito. Nao sao balanceamento morando no teste: sao o exemplo
## que o GDD promete, e a suite reprova quem mudar a formula sem mudar o documento.
##
## As duas afirmacoes que a issue pede valem mais que todas as outras juntas:
##
##   comprar 100 de uma vez custa igual a 100 compras de 1
##   comprar maximo nunca gasta mais do que se tem, e nunca compra 0 por arredondamento
##
## A primeira e o unico jeito de pegar um erro na serie geometrica -- ela devolve um
## numero plausivel para qualquer formula errada, e o jogador so descobre comparando os
## dois botoes. A segunda protege o saldo de quem clica.
##
## O bloco de producao MEXE no autoload Jogo, que e estado global vivo, e devolve tudo no
## fim: sem isso a suite deixaria macaco e multiplicador ligados para quem rodar depois.
extends TesteBase

const BASE: float = 10.0
const CRESCIMENTO: float = 1.15

func _init() -> void:
	nome = "Economia"


func executar() -> void:
	_custo_do_proximo()
	_serie_geometrica()
	_compra_maxima()
	_producao()
	_compra_de_upgrade()
	_escada_de_maquinas()
	_capacidade_da_sala()
	_entradas_invalidas()


func _custo_do_proximo() -> void:
	var base := Grande.de_float(BASE)
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 0.0), 10.0, "GDD §31: primeiro custa 10")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 1.0), 11.5, "GDD §31: segundo custa 11,5")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 2.0), 13.225, "GDD §31: terceiro custa 13,2")
	_vale(Economia.custo_do_proximo(base, CRESCIMENTO, 10.0), 40.4555773570, "decima primeira")

	# o custo tem que crescer sempre: custo nao crescente e compra infinita, e esta na
	# lista de erros de tuning da CONVENCOES.md
	var anterior := Economia.custo_do_proximo(base, CRESCIMENTO, 0.0)
	var sempre_sobe := true
	for i in range(1, 60):
		var atual := Economia.custo_do_proximo(base, CRESCIMENTO, float(i))
		if not atual.maior_que(anterior):
			sempre_sobe = false
		anterior = atual
	ok(sempre_sobe, "o custo sobe a cada unidade, sem excecao em 60 compras")


func _serie_geometrica() -> void:
	var base := Grande.de_float(BASE)

	ok(Economia.custo_de(base, CRESCIMENTO, 0.0, 0).e_zero(), "comprar zero custa zero")
	ok(Economia.custo_de(base, CRESCIMENTO, 0.0, -5).e_zero(), "comprar negativo custa zero")
	ok(
		Economia.custo_de(base, CRESCIMENTO, 7.0, 1).igual_a(
			Economia.custo_do_proximo(base, CRESCIMENTO, 7.0)
		),
		"comprar 1 e o custo do proximo, sem passar pela serie",
	)

	# a afirmacao central da issue
	ok(
		Economia.custo_de(base, CRESCIMENTO, 0.0, 100).igual_a(_somar_uma_a_uma(0.0, 100)),
		"comprar 100 de uma vez custa igual a 100 compras de 1",
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, 37.0, 10).igual_a(_somar_uma_a_uma(37.0, 10)),
		"e continua valendo comecando de uma quantidade qualquer",
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, 0.0, 500).igual_a(_somar_uma_a_uma(0.0, 500)),
		"e continua valendo em 500 compras, onde o erro acumulado apareceria",
	)


func _compra_maxima() -> void:
	var base := Grande.de_float(BASE)

	ok(Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.zero()) == 0, "sem saldo, nada cabe")
	ok(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.de_float(-50.0)) == 0,
		"saldo negativo nao compra",
	)
	ok(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Grande.de_float(9.99)) == 0,
		"saldo abaixo do primeiro custo nao compra",
	)

	# arredondamento comendo uma compra legitima e o segundo erro que a issue proibe
	var exato := Economia.custo_do_proximo(base, CRESCIMENTO, 0.0)
	igual(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, exato),
		1,
		"saldo exatamente igual ao custo compra 1, nunca 0",
	)

	# saldo exatamente igual a soma de dez compras tem que comprar as dez
	igual(
		Economia.quantos_cabem(base, CRESCIMENTO, 0.0, Economia.custo_de(base, CRESCIMENTO, 0.0, 10)),
		10,
		"saldo exatamente igual a dez compras leva as dez",
	)

	for disponivel in [
		Grande.de_float(10.0),
		Grande.de_float(123.45),
		Grande.de_float(1000.0),
		Grande.de_float(1e6),
		Grande.new(7.3, 40),
		Grande.new(1.0, 100),
	]:
		_invariantes_do_maximo(base, 0.0, disponivel)
	_invariantes_do_maximo(base, 250.0, Grande.new(4.0, 30))


## As duas promessas, conferidas contra a mesma custo_de() que vai debitar a compra:
## o que cabe cabe mesmo, e nao cabia mais um.
func _invariantes_do_maximo(base: Grande, quantidade: float, disponivel: Grande) -> void:
	var quantos := Economia.quantos_cabem(base, CRESCIMENTO, quantidade, disponivel)
	var rotulo := "maximo com %s a partir de %d" % [disponivel.para_texto(), int(quantidade)]

	ok(quantos >= 1, "%s -- comprou pelo menos uma" % rotulo)
	ok(
		not Economia.custo_de(base, CRESCIMENTO, quantidade, quantos).maior_que(disponivel),
		"%s -- nao gastou mais do que tinha" % rotulo,
	)
	ok(
		Economia.custo_de(base, CRESCIMENTO, quantidade, quantos + 1).maior_que(disponivel),
		"%s -- mais uma nao caberia" % rotulo,
	)


func _producao() -> void:
	var guardado := _guardar_o_jogo()

	Jogo.macacos = Grande.de_float(10.0)
	Jogo.multiplicador_global = 2.0
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.tempo_jogado = 0.0
	Jogo.upgrades_comprados = [] as Array[String]

	# o macaco comeca sem saber digitar sozinho (GDD §3): a producao automatica esta
	# apagada mesmo com dez macacos na sala
	ok(not Economia.producao_automatica(), "sem upgrade a producao automatica esta apagada")
	ok(Economia.producao_por_segundo().e_zero(), "e o cps e zero mesmo com dez macacos")

	Economia.acumular(1.0)
	ok(Jogo.total_caracteres.e_zero(), "um segundo sem producao automatica nao produz nada")
	perto(Jogo.tempo_jogado, 1.0, 1e-9, "mas o relogio anda: a producao offline depende dele")

	# antes do Instinto Digitador o clique e o unico caminho, e ele passa pelo mesmo
	# acumulador da producao automatica
	Economia.digitar(5)
	_vale(Jogo.total_caracteres, 5.0, "cinco cliques dao cinco caracteres")
	_vale(Jogo.caracteres_da_run, 5.0, "e entram na run")
	# decisao 0004: cada caractere digitado vale uma moeda
	_vale(Jogo.dinheiro, 5.0, "e viram cinco moedas")
	Economia.digitar(0)
	Economia.digitar(-3)
	_vale(Jogo.total_caracteres, 5.0, "clique de zero ou negativo nao produz nada")

	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	ok(Economia.producao_automatica(), "o Instinto Digitador acende a producao automatica")

	# o esperado sai do .tres e nao de um literal: uma sessao de tuning em producao_base
	# nao pode reprovar a formula, que e o que esta sendo testado aqui
	var por_macaco := Economia.producao_por_macaco()
	ok(por_macaco > 0.0, "o macaco do .tres produz alguma coisa")
	perto(Economia.multiplicador_total(), 2.0, 1e-12, "so o multiplicador global esta ligado")
	_vale(Economia.producao_por_segundo(), 10.0 * por_macaco * 2.0, "10 macacos x producao x 2")

	var por_segundo := 10.0 * por_macaco * 2.0
	Economia.acumular(0.5)
	_vale(Jogo.caracteres_por_segundo, por_segundo, "acumular grava o cps para a HUD ler")
	_vale(Jogo.total_caracteres, 5.0 + por_segundo * 0.5, "meio segundo entra no total")
	_vale(Jogo.dinheiro, 5.0 + por_segundo * 0.5, "e no dinheiro")
	perto(Jogo.tempo_jogado, 1.5, 1e-9, "e o relogio anda meio segundo")

	Economia.acumular(0.5)
	_vale(Jogo.total_caracteres, 5.0 + por_segundo, "o acumulo e cumulativo")

	# a loja gasta so o dinheiro: total_caracteres e o numero do Panorama e nao pode
	# descer, senao comprar um macaco apagaria um marco ja alcancado
	var total_antes := Jogo.total_caracteres
	Jogo.dinheiro = Jogo.dinheiro.menos(Grande.de_float(4.0))
	_vale(Jogo.dinheiro, 1.0 + por_segundo, "gastar desce o dinheiro")
	ok(Jogo.total_caracteres.igual_a(total_antes), "e nao encosta no total do Panorama")

	# delta nao positivo nao produz, mas o cps continua sendo atualizado: deixar o valor
	# velho na tela mostraria producao que acabou de ser zerada
	Economia.acumular(0.0)
	ok(Jogo.total_caracteres.igual_a(total_antes), "delta zero nao produz nada")
	_vale(Jogo.caracteres_por_segundo, por_segundo, "e mesmo assim atualiza o cps")
	perto(Jogo.tempo_jogado, 2.0, 1e-9, "delta zero nao mexe no relogio")

	Jogo.macacos = Grande.zero()
	Economia.acumular(1.0)
	ok(Jogo.caracteres_por_segundo.e_zero(), "sem macaco o cps zera de verdade")
	ok(Jogo.total_caracteres.igual_a(total_antes), "sem macaco nada e produzido")
	# o tempo passa mesmo sem producao: a producao offline da issue #9 e uma conta sobre
	# esse relogio, e ele parar com zero macaco quebraria a conta
	perto(Jogo.tempo_jogado, 3.0, 1e-9, "mas o relogio anda mesmo sem macaco")

	_devolver_o_jogo(guardado)
	ok(Jogo.macacos == guardado["macacos"], "a suite devolveu o estado do Jogo")


## A compra recusa em silencio o que e jogada invalida -- sem dinheiro, ja comprado, ainda
## nao desbloqueado -- e so grita no que e erro de programa. A diferenca importa: uma
## dessas tres acontece toda hora com o jogador clicando, e nenhuma delas e bug.
func _compra_de_upgrade() -> void:
	var guardado := _guardar_o_jogo()
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.dinheiro = Grande.zero()
	Jogo.total_caracteres = Grande.zero()

	var instinto := Economia.upgrade_de("instinto_digitador")
	ok(instinto != null, "o Instinto Digitador esta no catalogo carregado do .tres")

	ok(not Economia.comprar_upgrade("instinto_digitador"), "sem dinheiro nao compra")
	ok(Jogo.upgrades_comprados.is_empty(), "e a compra recusada nao deixa rastro")

	# o sinal e emitido depois de a compra ja ter acontecido: quem escuta repinta e nao
	# precisa perguntar de volta se deu certo
	var recebidos: Array[String] = []
	var ouvinte := func(id: String) -> void: recebidos.append(id)
	EventBus.upgrade_comprado.connect(ouvinte)

	Jogo.dinheiro = Grande.de_float(instinto.custo)
	ok(Economia.comprar_upgrade("instinto_digitador"), "com o dinheiro exato, compra")
	ok(Jogo.dinheiro.e_zero(), "e o custo sai do saldo")
	ok(Jogo.upgrades_comprados.has("instinto_digitador"), "o id entra na lista do save")
	igual(recebidos.size(), 1, "o EventBus avisou uma vez")
	igual(recebidos[0] if not recebidos.is_empty() else "", "instinto_digitador", "com o id certo")

	Jogo.dinheiro = Grande.de_float(1e6)
	ok(not Economia.comprar_upgrade("instinto_digitador"), "comprar de novo nao acontece")
	igual(recebidos.size(), 1, "e nao emite sinal de novo")
	EventBus.upgrade_comprado.disconnect(ouvinte)

	# requisito ainda nao atingido: o upgrade existe, da para pagar, e mesmo assim nao
	var dedos := Economia.upgrade_de("dedos_mais_ageis")
	ok(dedos != null and dedos.requisito > 0.0, "o outro upgrade tem requisito para testar")
	Jogo.total_caracteres = Grande.zero()
	ok(not Economia.comprar_upgrade("dedos_mais_ageis"), "requisito nao atingido nao compra")
	Jogo.total_caracteres = Grande.de_float(dedos.requisito)
	ok(Economia.comprar_upgrade("dedos_mais_ageis"), "atingido o requisito, compra")

	# e o bonus entra por TIPO, nunca pelo id de quem foi comprado
	perto(
		Economia.bonus_de(DadosUpgrade.Efeito.VELOCIDADE_DO_MACACO),
		dedos.valor,
		1e-12,
		"o bonus de velocidade e o valor do upgrade comprado",
	)
	perto(
		Economia.bonus_de(DadosUpgrade.Efeito.PRODUCAO_GLOBAL),
		1.0,
		1e-12,
		"e o de producao global continua neutro, sem upgrade desse tipo",
	)

	_devolver_o_jogo(guardado)


## A escada do GDD §13: uma maquina de cada vez, sempre a proxima, e o multiplicador
## entrando na formula em vez de dentro do macaco.
func _escada_de_maquinas() -> void:
	var guardado := _guardar_o_jogo()
	Jogo.maquina_atual = ""
	Jogo.dinheiro = Grande.zero()
	Jogo.upgrades_comprados = [] as Array[String]

	var primeira := Economia.maquina_atual()
	ok(primeira != null, "partida nova ja vem com uma maquina")
	igual(primeira.tier, 1, "e ela e a do tier 1, a que veio com o macaco")
	perto(Economia.multiplicador_de_maquina(), 1.0, 1e-12, "e ela e o multiplicador neutro")

	var proxima := Economia.proxima_maquina()
	ok(proxima != null and proxima.tier == 2, "a proxima e o tier 2")

	ok(not Economia.comprar_maquina(proxima.id), "sem dinheiro nao troca de maquina")
	igual(Jogo.maquina_atual, "", "e a recusa nao deixa rastro")

	# pular tier deixaria o jogador pagar por um multiplicador que ele teria de graca dois
	# cliques depois
	var terceira: DadosMaquina = Economia.maquinas()[2]
	# saldo perto do custo, e nao 1e20: com dezoito ordens de grandeza de distancia a
	# parcela menor SOME na subtracao -- que e o comportamento certo do Grande e esta
	# provado em teste_grande -- e o custo pareceria nao ter sido cobrado
	Jogo.dinheiro = Grande.de_float(1e6)
	ok(not Economia.comprar_maquina(terceira.id), "nao da para pular um degrau da escada")
	ok(not Economia.comprar_maquina("maquina_que_nao_existe"), "nem comprar maquina inexistente")

	var trocas: Array[String] = []
	var ouvinte := func(id: String) -> void: trocas.append(id)
	EventBus.maquina_trocada.connect(ouvinte)

	var antes := Jogo.dinheiro
	ok(Economia.comprar_maquina(proxima.id), "com dinheiro, troca")
	igual(Jogo.maquina_atual, proxima.id, "e a maquina em uso passa a ser a nova")
	ok(antes.maior_que(Jogo.dinheiro), "e o custo saiu do saldo")
	perto(
		Economia.multiplicador_de_maquina(), proxima.multiplicador, 1e-9,
		"e o multiplicador da formula e o dela",
	)
	igual(trocas.size(), 1, "e o EventBus avisou")
	EventBus.maquina_trocada.disconnect(ouvinte)

	# a troca vale para o macaco que JA estava la: multiplicador nao e congelado na compra
	Jogo.macacos = Grande.de_float(10.0)
	Jogo.multiplicador_global = 1.0
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	var com_o_tier_dois := Economia.producao_por_segundo()
	ok(Economia.comprar_maquina(Economia.proxima_maquina().id), "sobe mais um degrau")
	ok(
		Economia.producao_por_segundo().maior_que(com_o_tier_dois),
		"e os mesmos dez macacos passam a produzir mais",
	)

	# a escada acaba, e acabar e um estado e nao um erro
	Jogo.dinheiro = Grande.new(1.0, 30)
	while Economia.proxima_maquina() != null:
		Economia.comprar_maquina(Economia.proxima_maquina().id)
	ok(Economia.proxima_maquina() == null, "no topo da escada nao ha proxima")
	igual(Economia.maquina_atual().tier, Economia.maquinas().size(), "e a atual e a ultima")

	_devolver_o_jogo(guardado)


## O segundo eixo do GDD §15: macaco sem vaga nao produz, e a sala vira decisao.
##
## As duas afirmacoes que a issue pede: comprar acima da capacidade falha, e expandir
## libera EXATAMENTE a diferenca entre as duas capacidades -- nem uma vaga a mais.
func _capacidade_da_sala() -> void:
	var guardado := _guardar_o_jogo()
	Jogo.sala_atual = ""
	Jogo.macacos = Grande.zero()
	Jogo.dinheiro = Grande.new(1.0, 30)
	Jogo.upgrades_comprados = [] as Array[String]

	var pequena := Economia.sala_atual()
	ok(pequena != null, "partida nova ja vem com uma sala")
	igual(pequena.tier, 1, "e ela e a do tier 1")
	_vale(Economia.capacidade(), pequena.capacidade, "a capacidade e a dela")
	_vale(Economia.vagas_livres(), pequena.capacidade, "e com zero macaco tudo esta livre")

	# encher a sala exatamente ate a borda
	var cabem := int(pequena.capacidade)
	ok(Economia.cabe_na_sala(cabem), "a sala inteira cabe de uma vez")
	ok(not Economia.cabe_na_sala(cabem + 1), "um a mais que a capacidade nao cabe")
	igual(Economia.comprar_macacos(cabem), cabem, "comprou a sala cheia")
	ok(Economia.vagas_livres().e_zero(), "e nao sobrou vaga")

	# comprar acima da capacidade falha -- e falha ANTES de cobrar
	var dinheiro_antes := Jogo.dinheiro
	igual(Economia.comprar_macacos(1), 0, "com a sala cheia, comprar mais falha")
	ok(Jogo.dinheiro.igual_a(dinheiro_antes), "e nao cobra nada por uma compra que nao aconteceu")
	igual(Economia.macacos_que_cabem(), 0, "e o botao de maximo tambem oferece zero")

	# expandir libera exatamente a diferenca
	var proxima := Economia.proxima_sala()
	ok(proxima != null and proxima.tier == 2, "a proxima sala e o tier 2")
	var diferenca := proxima.capacidade - pequena.capacidade

	var expansoes: Array[String] = []
	var ouvinte := func(id: String) -> void: expansoes.append(id)
	EventBus.sala_expandida.connect(ouvinte)
	ok(Economia.expandir_sala(proxima.id), "expandiu")
	EventBus.sala_expandida.disconnect(ouvinte)

	igual(expansoes.size(), 1, "e o EventBus avisou")
	_vale(Economia.vagas_livres(), diferenca, "e liberou exatamente a diferenca")
	ok(Economia.cabe_na_sala(int(diferenca)), "a diferenca inteira cabe")
	ok(not Economia.cabe_na_sala(int(diferenca) + 1), "e um a mais que ela nao")

	ok(not Economia.expandir_sala(pequena.id), "nao da para voltar para a sala anterior")
	ok(not Economia.expandir_sala("sala_que_nao_existe"), "nem expandir para sala inexistente")

	# excesso e MULTIPLICADOR e nao corte seco: com vinte macacos numa sala de dez, metade
	# do trabalho acontece -- o jogador mantem a compra e ve a producao render menos
	Jogo.sala_atual = ""
	Jogo.macacos = Grande.de_float(pequena.capacidade)
	perto(Economia.multiplicador_de_sala(), 1.0, 1e-9, "sala na medida nao penaliza nada")
	Jogo.macacos = Grande.de_float(pequena.capacidade * 2.0)
	perto(Economia.multiplicador_de_sala(), 0.5, 1e-9, "o dobro da capacidade rende metade")
	Jogo.macacos = Grande.de_float(pequena.capacidade * 4.0)
	perto(Economia.multiplicador_de_sala(), 0.25, 1e-9, "o quadruplo rende um quarto")
	ok(Economia.vagas_livres().e_zero(), "e vaga livre nunca fica negativa")

	_devolver_o_jogo(guardado)


func _guardar_o_jogo() -> Dictionary:
	return {
		"macacos": Jogo.macacos,
		"multiplicador_global": Jogo.multiplicador_global,
		"total_caracteres": Jogo.total_caracteres,
		"caracteres_da_run": Jogo.caracteres_da_run,
		"caracteres_por_segundo": Jogo.caracteres_por_segundo,
		"dinheiro": Jogo.dinheiro,
		"tempo_jogado": Jogo.tempo_jogado,
		"upgrades_comprados": Jogo.upgrades_comprados.duplicate(),
		"maquina_atual": Jogo.maquina_atual,
		"sala_atual": Jogo.sala_atual,
	}


func _devolver_o_jogo(guardado: Dictionary) -> void:
	Jogo.macacos = guardado["macacos"]
	Jogo.multiplicador_global = guardado["multiplicador_global"]
	Jogo.total_caracteres = guardado["total_caracteres"]
	Jogo.caracteres_da_run = guardado["caracteres_da_run"]
	Jogo.caracteres_por_segundo = guardado["caracteres_por_segundo"]
	Jogo.dinheiro = guardado["dinheiro"]
	Jogo.tempo_jogado = guardado["tempo_jogado"]
	Jogo.upgrades_comprados = guardado["upgrades_comprados"]
	Jogo.maquina_atual = guardado["maquina_atual"]
	Jogo.sala_atual = guardado["sala_atual"]


## Crescimento que nao cresce e o erro de tuning que permite compra infinita. As linhas
## ERROR no stderr durante a suite sao esperadas: a Economia grita em vez de dividir por
## zero calada. Ver CONVENCOES.md, "Mexeu num numero de balanceamento?".
func _entradas_invalidas() -> void:
	print("    (as linhas ERROR abaixo sao de proposito -- crescimento invalido sob teste)")
	var base := Grande.de_float(BASE)

	# com crescimento 1 o custo e constante, que e o limite da serie: 10 compras custam 100
	_vale(Economia.custo_de(base, 1.0, 0.0, 10), 100.0, "crescimento 1 vira soma linear")
	igual(
		Economia.quantos_cabem(base, 1.0, 0.0, Grande.de_float(95.0)),
		9,
		"crescimento 1 ainda respeita o saldo",
	)
	igual(
		Economia.quantos_cabem(Grande.zero(), CRESCIMENTO, 0.0, Grande.de_float(100.0)),
		0,
		"custo zerado nao vira compra infinita",
	)
	# id que nao existe e erro de programa, nao jogada: aqui a Economia grita
	ok(not Economia.comprar_upgrade("upgrade_que_nao_existe"), "upgrade inexistente nao compra")


func _somar_uma_a_uma(quantidade: float, quantos: int) -> Grande:
	var somado := Grande.zero()
	for i in quantos:
		somado = somado.mais(
			Economia.custo_do_proximo(Grande.de_float(BASE), CRESCIMENTO, quantidade + float(i))
		)
	return somado


func _vale(obtido: Grande, esperado: float, descricao: String) -> void:
	perto(obtido.para_float(), esperado, absf(esperado) * 1e-9 + 1e-9, descricao)
