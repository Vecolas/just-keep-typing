## Suite dos Teoremas: o calculo, o reset e a arvore (GDD §17, §18 e §19).
##
## A afirmacao central e uma so, e ela sustenta o sistema inteiro:
##
##   A RUN SEGUINTE NUNCA RENDE MENOS QUE A ANTERIOR NO MESMO PONTO.
##
## Se essa quebrar, provar o Teorema vira punicao, e a pergunta que o GDD §18 quer criar
## -- "faco prestigio agora ou continuo?" -- deixa de ter dois lados. E ela quebra do jeito
## mais silencioso possivel: bastaria o multiplicador olhar o SALDO de pontos em vez dos
## pontos ganhos na vida, e comprar um no da arvore passaria a deixar o jogo mais lento.
##
## A segunda: prestigiar com o minimo nao zera nada que a arvore promete manter.
##
## E a terceira e sobre os dados: arvore com ciclo trava tudo em silencio, e ninguem
## descobre isso jogando -- so aqui.
extends TesteBase

func _init() -> void:
	nome = "Teoremas"


func executar() -> void:
	_arvore()
	_calculo_dos_pontos()
	_o_reset()
	_a_run_seguinte_nunca_rende_menos()
	_compra_na_arvore()
	_o_teto_offline_le_a_arvore()


## Arvore com ciclo trava a compra inteira sem erro nenhum, e pre-requisito apontando para
## um id que nao existe deixa um no inalcancavel para sempre.
func _arvore() -> void:
	var nos := Teoremas.nos()
	ok(not nos.is_empty(), "o autoload carregou algum no")

	var ids := {}
	for no in nos:
		ok(not ids.has(no.id), "%s -- id nao repete" % no.id)
		ids[no.id] = no
		ok(no.custo > 0.0, "%s -- custo positivo" % no.id)
		ok(no.niveis >= 1, "%s -- tem pelo menos um nivel" % no.id)
		# custo que nao cresce faria o segundo nivel sair pelo preco do primeiro, e o no
		# de oito niveis viraria compra unica disfarcada
		if no.niveis > 1:
			ok(no.crescimento_custo > 1.0, "%s -- custo cresce entre niveis" % no.id)
		ok(not no.nome.strip_edges().is_empty(), "%s -- nome preenchido" % no.id)
		ok(not no.descricao.strip_edges().is_empty(), "%s -- descricao preenchida" % no.id)

	var raizes := 0
	for no in nos:
		if no.pre_requisitos.is_empty():
			raizes += 1
		for anterior in no.pre_requisitos:
			ok(ids.has(anterior), "%s -- o pre-requisito %s existe" % [no.id, anterior])
	ok(raizes >= 1, "existe pelo menos uma raiz, senao nada e comprável")

	# sem ciclo: todo no tem que ser alcancavel comecando so pelas raizes
	var alcancados := {}
	for volta in nos.size():
		for no in nos:
			if alcancados.has(no.id):
				continue
			var pronto := true
			for anterior in no.pre_requisitos:
				if not alcancados.has(anterior):
					pronto = false
			if pronto:
				alcancados[no.id] = true
	igual(alcancados.size(), nos.size(), "todo no e alcancavel a partir das raizes, sem ciclo")

	# os sete efeitos do GDD §19 tem que ter dono: enum sem no e promessa nao cumprida
	var tipos := {}
	for no in nos:
		tipos[no.tipo_de_efeito] = true
	igual(
		tipos.size(), DadosTeorema.Efeito.values().size(),
		"cada efeito do GDD §19 tem um no que o entrega",
	)


## O limite do prestigio, lido do .tres que o jogo le. Um segundo numero digitado na suite
## seria uma segunda fonte para a mesma verdade, e a que envelhece e sempre a copia.
## Um total confortavelmente acima do limite: seis ordens de grandeza, que rendem seis
## pontos. Todo cenario de prestigio da suite parte daqui, e nao de um numero digitado.
func _acima_do_limite() -> Grande:
	return Grande.de_float(_limite_do_prestigio()).vezes(Grande.new(1.0, 6))


func _limite_do_prestigio() -> float:
	var dados := ResourceLoader.load("res://data/prestigio.tres")
	if dados == null:
		return 0.0
	return dados.limite_inicial


func _calculo_dos_pontos() -> void:
	var guardado := _guardar()
	_zerar()

	Jogo.total_caracteres = Grande.zero()
	ok(Teoremas.pontos_ao_provar().e_zero(), "sem caractere nao ha ponto")
	ok(not Teoremas.pode_provar(), "e nao da para provar o Teorema")

	# pontos = log10(total / limite): cinco ordens de grandeza acima do limite dao cinco
	#
	# ⚠️ O LIMITE SAI DO .TRES, e nao de um 1e6 digitado aqui. Ele e botao de tuning -- a
	# issue #62 o moveu de 1e6 para 5e17 -- e portao que crava o numero reprova o dado
	# certo no primeiro ajuste. O que esta afirmacao cobra e a REGRA: N ordens de grandeza
	# acima do limite dao N pontos, qualquer que seja o limite.
	var limite := Grande.de_float(_limite_do_prestigio())
	Jogo.total_caracteres = limite.vezes(Grande.new(1.0, 5))
	_vale(Teoremas.pontos_ao_provar(), 5.0, "cinco ordens de grandeza dao cinco pontos")
	ok(Teoremas.pode_provar(), "e ai da para provar")

	Jogo.total_caracteres = limite
	ok(Teoremas.pontos_ao_provar().e_zero(), "exatamente no limite ainda nao rende ponto")
	ok(not Teoremas.pode_provar(), "e provar continua indisponivel")

	# Teorema Refinado multiplica o que se leva (GDD §19)
	Jogo.total_caracteres = limite.vezes(Grande.new(1.0, 4))
	var sem_refino := Teoremas.pontos_ao_provar()
	Jogo.teoremas = {"teorema_refinado": 1}
	ok(
		Teoremas.pontos_ao_provar().maior_que(sem_refino),
		"o Teorema Refinado aumenta os pontos recebidos",
	)

	_devolver(guardado)


func _o_reset() -> void:
	var guardado := _guardar()
	_zerar()

	# ⚠️ DERIVADO DO LIMITE, e nao um 1e12 digitado. O total tem que ficar ACIMA do limite
	# do prestigio para provar funcionar -- com o numero cravado, mover o limite (issue
	# #62) fazia `provar()` recusar e SEIS afirmacoes reprovarem apontando para o reset,
	# que nao tinha nada de errado. Seis dedos apontando para o lugar errado.
	var acima := _acima_do_limite()
	Jogo.total_caracteres = acima
	Jogo.caracteres_da_run = acima
	Jogo.dinheiro = Grande.new(1.0, 10)
	Jogo.macacos = Grande.de_float(500.0)
	Jogo.maquina_atual = "maquina_eletrica"
	Jogo.sala_atual = "galpao"
	Jogo.upgrades_comprados = ["instinto_digitador", "duas_maos"] as Array[String]
	Jogo.descobertas = ["um_poema"] as Array[String]
	Jogo.marcos_alcancados = ["uma_pagina"] as Array[String]
	Jogo.tempo_da_run = 4321.0
	Jogo.tempo_jogado = 99999.0

	var esperados := Teoremas.pontos_ao_provar()
	var ganhos := Teoremas.provar()
	ok(ganhos.igual_a(esperados), "provar devolve o que o botao prometia")

	# o que morre
	ok(Jogo.caracteres_da_run.e_zero(), "os caracteres da run zeram")
	ok(Jogo.dinheiro.e_zero(), "o dinheiro zera")
	ok(Jogo.macacos.igual_a(Grande.um()), "a contagem de macacos volta para um")
	igual(Jogo.maquina_atual, "", "a maquina volta para a do inicio")
	igual(Jogo.sala_atual, "", "e a sala tambem")
	ok(Jogo.upgrades_comprados.is_empty(), "os upgrades da run somem")
	perto(Jogo.tempo_da_run, 0.0, 0.0, "e o relogio da run zera")

	# o que fica -- e e isto que a issue chama de "nada que a arvore promete manter"
	ok(Jogo.total_caracteres.igual_a(acima), "o total do Panorama nao desce")
	igual(Jogo.marcos_alcancados.size(), 1, "os marcos alcancados ficam")
	perto(Jogo.tempo_jogado, 99999.0, 1e-6, "o tempo total de jogo nao zera")
	igual(Jogo.prestigios, 1, "e o contador de prestigios sobe")
	ok(Jogo.pontos_de_teorema.igual_a(ganhos), "os pontos entram no saldo")
	ok(Jogo.pontos_totais.igual_a(ganhos), "e nos ganhos da vida")

	# sem Biblioteca Persistente as descobertas se perdem (GDD §19)
	ok(Jogo.descobertas.is_empty(), "sem a Biblioteca Persistente as descobertas se perdem")

	# com ela, ficam
	Jogo.descobertas = ["um_poema"] as Array[String]
	Jogo.teoremas = {"biblioteca_persistente": 1}
	Jogo.total_caracteres = _acima_do_limite()
	Teoremas.provar()
	ok(Jogo.descobertas.has("um_poema"), "com a Biblioteca Persistente elas sobrevivem")

	# Conhecimento Acumulado devolve os upgrades mais baratos (GDD §19)
	Jogo.teoremas = {"conhecimento_acumulado": 2}
	Jogo.total_caracteres = _acima_do_limite()
	Teoremas.provar()
	igual(Jogo.upgrades_comprados.size(), 2, "o Conhecimento Acumulado devolve dois upgrades")

	# recusar em silencio: reset acidental e o pior bug possivel aqui
	_zerar()
	Jogo.total_caracteres = Grande.de_float(10.0)
	Jogo.macacos = Grande.de_float(77.0)
	ok(Teoremas.provar().e_zero(), "provar sem pontos devolve zero")
	_vale(Jogo.macacos, 77.0, "e nao reinicia nada")

	_devolver(guardado)


## A afirmacao que sustenta o sistema. Mesma quantidade de macacos, mesma maquina, mesma
## sala: a producao depois do prestigio tem que ser MAIOR OU IGUAL a de antes.
func _a_run_seguinte_nunca_rende_menos() -> void:
	var guardado := _guardar()
	_zerar()

	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	# ⚠️ ACIMA DO LIMITE, e derivado dele. Com 1e14 cravado aqui, mover o limite do
	# prestigio fazia provar() recusar -- e a afirmacao "o prestigio precisa valer a pena"
	# reprovava dizendo que o prestigio nao rende, quando na verdade ele nem tinha
	# acontecido. Portao que aponta para o lugar errado custa a tarde inteira.
	Jogo.total_caracteres = _acima_do_limite()
	var antes := Economia.producao_por_segundo()

	Teoremas.provar()
	# remonta o mesmo ponto da run: mesma contagem, mesma maquina, mesma sala
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	Jogo.macacos = Grande.de_float(10.0)
	var depois := Economia.producao_por_segundo()

	ok(
		not depois.menor_que(antes),
		"no mesmo ponto, a run depois do prestigio rende %s contra %s de antes" % [
			depois.para_texto(), antes.para_texto(),
		],
	)
	ok(depois.maior_que(antes), "e rende MAIS: o prestigio precisa valer a pena")

	# e comprar na arvore tambem nao pode encolher nada -- o multiplicador le os pontos
	# ganhos na vida, e nao o saldo que a compra gasta
	var com_saldo_cheio := Economia.producao_por_segundo()
	Jogo.pontos_de_teorema = Grande.de_float(1000.0)
	Jogo.pontos_totais = Grande.de_float(1000.0)
	var antes_da_compra := Economia.producao_por_segundo()
	ok(Teoremas.comprar("memoria_genetica"), "compra um no da arvore")
	ok(
		Economia.producao_por_segundo().maior_que(antes_da_compra),
		"e gastar ponto na arvore aumenta a producao em vez de diminuir",
	)
	ok(com_saldo_cheio.sinal() > 0, "a producao base do teste era positiva")

	_devolver(guardado)


func _compra_na_arvore() -> void:
	var guardado := _guardar()
	_zerar()

	var raiz: DadosTeorema = null
	var trancado: DadosTeorema = null
	for no in Teoremas.nos():
		if no.pre_requisitos.is_empty() and raiz == null:
			raiz = no
		if not no.pre_requisitos.is_empty() and trancado == null:
			trancado = no
	ok(raiz != null and trancado != null, "a arvore tem raiz e no trancado para testar")

	ok(not Teoremas.pode_comprar(raiz.id), "sem ponto nao compra nem a raiz")
	Jogo.pontos_de_teorema = Grande.de_float(1e6)
	ok(Teoremas.desbloqueado(raiz.id), "a raiz esta desbloqueada desde o inicio")
	ok(not Teoremas.desbloqueado(trancado.id), "o no com pre-requisito nao")
	ok(not Teoremas.comprar(trancado.id), "e comprar ele falha, mesmo com pontos de sobra")

	var compras: Array[String] = []
	var ouvinte := func(id: String) -> void: compras.append(id)
	EventBus.teorema_comprado.connect(ouvinte)

	var antes := Jogo.pontos_de_teorema
	var custo := Teoremas.custo_do_proximo(raiz.id)
	ok(Teoremas.comprar(raiz.id), "com pontos, compra a raiz")
	igual(Teoremas.nivel_de(raiz.id), 1, "e o nivel sobe para um")
	ok(antes.menos(custo).igual_a(Jogo.pontos_de_teorema), "e o custo sai do saldo")
	igual(compras.size(), 1, "e o EventBus avisou")
	EventBus.teorema_comprado.disconnect(ouvinte)

	ok(
		Teoremas.custo_do_proximo(raiz.id).maior_que(custo),
		"o segundo nivel custa mais que o primeiro",
	)

	# o teto de niveis existe e e respeitado
	for i in raiz.niveis * 2:
		Teoremas.comprar(raiz.id)
	igual(Teoremas.nivel_de(raiz.id), raiz.niveis, "o no para no numero de niveis dele")
	ok(not Teoremas.pode_comprar(raiz.id), "e no cheio nao aceita mais compra")
	ok(Teoremas.custo_do_proximo(raiz.id).e_zero(), "e nao cobra por nivel que nao existe")

	_devolver(guardado)


## O cuidado da issue #25: o teto de producao offline LE a arvore, e nao tem copia propria
## dos numeros. Sem no comprado, quem manda continua sendo o data/offline.tres da #9.
func _o_teto_offline_le_a_arvore() -> void:
	var guardado := _guardar()
	_zerar()

	var do_tres := Economia.teto_offline_segundos()
	ok(do_tres > 0.0, "sem no comprado, o teto vem do .tres da issue #9")

	Jogo.teoremas = {"producao_offline": 1}
	var com_um_nivel := Economia.teto_offline_segundos()
	ok(com_um_nivel > do_tres, "o primeiro nivel do no estica o teto")

	Jogo.teoremas = {"producao_offline": 4}
	ok(
		Economia.teto_offline_segundos() > com_um_nivel,
		"e cada nivel seguinte estica mais",
	)

	# o ultimo degrau do GDD §38 e SEM LIMITE, e sem limite se escreve zero
	Jogo.teoremas = {"producao_offline": 5}
	perto(Economia.teto_offline_segundos(), 0.0, 0.0, "o ultimo nivel tira o teto")
	perto(
		ProgressoOffline.segundos_creditados(1e6, 0.0), 1e6, 0.0,
		"e sem teto mil horas fora contam mil horas",
	)

	_devolver(guardado)


func _vale(obtido: Grande, esperado: float, descricao: String) -> void:
	perto(obtido.para_float(), esperado, absf(esperado) * 1e-9 + 1e-9, descricao)


func _zerar() -> void:
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.caracteres_por_segundo = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.multiplicador_global = 1.0
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.pontos_totais = Grande.zero()
	Jogo.recorde_de_total = Grande.zero()
	Jogo.prestigios = 0
	Jogo.tempo_da_run = 0.0
	Jogo.tempo_jogado = 0.0
	Jogo.teoremas = {}
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.descobertas = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]


func _guardar() -> Dictionary:
	return {
		"total": Jogo.total_caracteres, "run": Jogo.caracteres_da_run,
		"cps": Jogo.caracteres_por_segundo, "dinheiro": Jogo.dinheiro,
		"macacos": Jogo.macacos, "maquina": Jogo.maquina_atual, "sala": Jogo.sala_atual,
		"global": Jogo.multiplicador_global, "pontos": Jogo.pontos_de_teorema,
		"totais": Jogo.pontos_totais, "recorde": Jogo.recorde_de_total,
		"prestigios": Jogo.prestigios, "tempo_run": Jogo.tempo_da_run,
		"tempo": Jogo.tempo_jogado, "teoremas": Jogo.teoremas.duplicate(),
		"upgrades": Jogo.upgrades_comprados.duplicate(),
		"descobertas": Jogo.descobertas.duplicate(),
		"marcos": Jogo.marcos_alcancados.duplicate(),
	}


func _devolver(g: Dictionary) -> void:
	Jogo.total_caracteres = g["total"]
	Jogo.caracteres_da_run = g["run"]
	Jogo.caracteres_por_segundo = g["cps"]
	Jogo.dinheiro = g["dinheiro"]
	Jogo.macacos = g["macacos"]
	Jogo.maquina_atual = g["maquina"]
	Jogo.sala_atual = g["sala"]
	Jogo.multiplicador_global = g["global"]
	Jogo.pontos_de_teorema = g["pontos"]
	Jogo.pontos_totais = g["totais"]
	Jogo.recorde_de_total = g["recorde"]
	Jogo.prestigios = g["prestigios"]
	Jogo.tempo_da_run = g["tempo_run"]
	Jogo.tempo_jogado = g["tempo"]
	Jogo.teoremas = g["teoremas"]
	Jogo.upgrades_comprados = g["upgrades"]
	Jogo.descobertas = g["descobertas"]
	Jogo.marcos_alcancados = g["marcos"]
