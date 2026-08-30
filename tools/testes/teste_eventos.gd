## Suite dos eventos aleatorios (GDD §22).
##
## As duas afirmacoes que a issue #27 pede:
##
##   OS MODIFICADORES EXPIRAM. Evento que nao expira e upgrade permanente com nome errado,
##   e o jogador so descobre quando a producao dele nunca mais volta ao normal.
##
##   E NAO ACUMULAM ALEM DO TETO. Sem teto, tres eventos bons coincidindo dariam um produto
##   que nao aparece em nenhuma conta de balanceamento -- e o jogador ia embora achando que
##   descobriu um truque quando so encontrou um bug.
##
## Mais a regra que o GDD §22 fixa e a issue repete: EVENTO RUIM TEM SAIDA PELA ACAO DO
## JOGADOR. Punicao que so espera passar nao e evento, e imposto.
extends TesteBase

func _init() -> void:
	nome = "eventos"


func executar() -> void:
	_catalogo()
	_saida_pela_acao()
	_os_modificadores_expiram()
	_o_teto_de_simultaneos()
	_a_tecla_presa()
	_o_sorteio()


func _catalogo() -> void:
	var todos := Eventos.todos()
	ok(not todos.is_empty(), "o autoload carregou algum .tres")

	var ids := {}
	for evento in todos:
		ok(not ids.has(evento.id), "%s -- id nao repete" % evento.id)
		ids[evento.id] = true
		ok(evento.duracao > 0.0, "%s -- dura mais que zero" % evento.id)
		ok(evento.peso > 0.0, "%s -- tem peso no sorteio" % evento.id)
		ok(not evento.nome.strip_edges().is_empty(), "%s -- nome preenchido" % evento.id)
		ok(not evento.descricao.strip_edges().is_empty(), "%s -- descricao preenchida" % evento.id)
		ok(evento.multiplicador_producao > 0.0, "%s -- nao zera a producao" % evento.id)
		ok(evento.multiplicador_descoberta >= 0.0, "%s -- chance nao fica negativa" % evento.id)

		# a regra do GDD §22: PUNICAO precisa de saida. Troca nao -- a Tecla Presa piora a
		# descoberta e melhora muito a producao, e dar botao de encerrar a ela
		# transformaria uma decisao ja resolvida em incomodo que se clica por reflexo.
		if evento.e_punicao():
			ok(
				evento.resolve_com_clique,
				"%s e punicao pura, entao tem saida pela acao do jogador" % evento.id,
			)
		else:
			ok(
				not evento.resolve_com_clique or evento.multiplicador_producao < 1.0,
				"%s nao ganha botao de encerrar sem ser punicao" % evento.id,
			)


func _saida_pela_acao() -> void:
	var guardado := _guardar()
	_limpar()

	var ruim: DadosEvento = null
	var bom: DadosEvento = null
	for evento in Eventos.todos():
		if evento.e_punicao() and ruim == null:
			ruim = evento
		if not evento.e_punicao() and not evento.resolve_com_clique and bom == null:
			bom = evento
	ok(ruim != null and bom != null, "o catalogo tem um evento ruim e um bom para testar")

	var terminados: Array[String] = []
	var ouvinte := func(id: String) -> void: terminados.append(id)
	EventBus.evento_terminou.connect(ouvinte)

	ok(not Eventos.resolver(ruim.id), "resolver evento que nao esta ativo nao faz nada")
	ok(Eventos.comecar(ruim.id), "o evento ruim comeca")
	ok(Eventos.ativo(ruim.id), "e fica ativo")
	ok(Eventos.multiplicador_de_producao() < 1.0, "e ele piora a producao")

	ok(Eventos.resolver(ruim.id), "e o jogador resolve com um clique")
	ok(not Eventos.ativo(ruim.id), "e ele acaba na hora")
	perto(Eventos.multiplicador_de_producao(), 1.0, 1e-12, "e a producao volta ao normal")
	igual(terminados.size(), 1, "e o EventBus avisou")

	# clicar num evento BOM nao pode apagar o bonus por engano
	ok(Eventos.comecar(bom.id), "o evento bom comeca")
	ok(not Eventos.resolver(bom.id), "e clicar nele nao encerra nada")
	ok(Eventos.ativo(bom.id), "ele continua ativo")

	EventBus.evento_terminou.disconnect(ouvinte)
	_devolver(guardado)


func _os_modificadores_expiram() -> void:
	var guardado := _guardar()
	_limpar()

	var evento := Eventos.todos()[0]
	ok(Eventos.comecar(evento.id), "comeca um evento")
	perto(Eventos.restante(evento.id), evento.duracao, 1e-6, "o relogio dele comeca cheio")

	Eventos.tique(evento.duracao * 0.5)
	perto(Eventos.restante(evento.id), evento.duracao * 0.5, 1e-5, "metade do tempo, metade do relogio")
	ok(Eventos.ativo(evento.id), "e ele ainda esta valendo")

	# a fronteira exata: um evento que sobrevive ao proprio fim nunca mais acaba
	Eventos.tique(evento.duracao * 0.5)
	ok(not Eventos.ativo(evento.id), "no fim exato da duracao ele acaba")
	perto(Eventos.multiplicador_de_producao(), 1.0, 1e-12, "e o multiplicador volta a 1")
	perto(Eventos.multiplicador_de_descoberta(), 1.0, 1e-12, "e o de descoberta tambem")

	# tique de zero ou negativo nao pode encerrar nada nem comecar nada
	ok(Eventos.comecar(evento.id), "comeca de novo")
	Eventos.tique(0.0)
	Eventos.tique(-5.0)
	ok(Eventos.ativo(evento.id), "tique de zero ou negativo nao mexe no relogio")

	_devolver(guardado)


func _o_teto_de_simultaneos() -> void:
	var guardado := _guardar()
	_limpar()

	var entraram := 0
	for evento in Eventos.todos():
		if Eventos.comecar(evento.id):
			entraram += 1
	ok(entraram >= 1, "pelo menos um evento entrou")
	ok(
		entraram < Eventos.todos().size(),
		"e o teto barrou os outros: %d de %d entraram" % [entraram, Eventos.todos().size()],
	)
	igual(Eventos.ativos().size(), entraram, "e a lista de ativos bate com quem entrou")

	# o mesmo evento nunca entra duas vezes -- dois Macacos Inspirados seriam x100
	var primeiro: String = Eventos.ativos()[0]
	ok(not Eventos.comecar(primeiro), "o mesmo evento nao entra duas vezes")

	# a vaga liberada no mesmo quadro em que expira: o teto e de simultaneos, e nao de
	# frequencia
	var duracao := Eventos.de(primeiro).duracao
	Eventos.tique(duracao + 1.0)
	ok(Eventos.ativos().is_empty(), "passado o tempo, todos expiram")

	_devolver(guardado)


## A Tecla Presa da muito caractere e ZERA a descoberta. E o unico evento em que o ganho
## vem com custo, e e ele que impede o farm de evento de virar a estrategia otima.
func _a_tecla_presa() -> void:
	var guardado := _guardar()
	_limpar()

	var tecla := Eventos.de("tecla_presa")
	ok(tecla != null, "a Tecla Presa existe")
	ok(tecla.multiplicador_producao > 1.0, "ela da muito caractere")
	perto(tecla.multiplicador_descoberta, 0.0, 0.0, "e zera a chance de descoberta")

	Eventos.comecar(tecla.id)
	perto(Eventos.multiplicador_de_descoberta(), 0.0, 0.0, "com ela ativa, a chance e zero")

	var comum := Descobertas.todas()[0]
	perto(
		Descobertas.chance_de(comum, Grande.new(1.0, 300)), 0.0, 0.0,
		"e nem 10^300 caracteres acham nada enquanto ela dura",
	)

	Eventos.tique(tecla.duracao + 1.0)
	ok(
		Descobertas.chance_de(comum, Grande.new(1.0, 300)) > 0.0,
		"passada a Tecla Presa, as descobertas voltam",
	)

	_devolver(guardado)


## Mesma semente, mesma sequencia. Sem isto a suite dependeria do randi() global.
func _o_sorteio() -> void:
	var guardado := _guardar()
	var semente_original := Eventos.gerador.seed
	_limpar()

	Jogo.total_caracteres = Grande.new(1.0, 20)
	var primeira := _sortear_com(4242)
	var segunda := _sortear_com(4242)
	igual(primeira, segunda, "a mesma semente sorteia a mesma sequencia")

	# abaixo do requisito nao sorteia nada: evento no primeiro minuto e ruido
	_limpar()
	Jogo.total_caracteres = Grande.zero()
	Eventos.gerador.seed = 4242
	for i in 400:
		Eventos.tique(1.0)
	ok(Eventos.ativos().is_empty(), "antes do requisito de caracteres nao nasce evento")

	Eventos.gerador.seed = semente_original
	_devolver(guardado)


func _sortear_com(semente: int) -> Array:
	_limpar()
	Eventos.gerador.seed = semente
	var vistos: Array[String] = []
	var ouvinte := func(evento: DadosEvento) -> void: vistos.append(evento.id)
	EventBus.evento_comecou.connect(ouvinte)
	for i in 400:
		Eventos.tique(1.0)
	EventBus.evento_comecou.disconnect(ouvinte)
	return vistos


func _limpar() -> void:
	Eventos.limpar()


func _guardar() -> Dictionary:
	return {"total": Jogo.total_caracteres}


func _devolver(g: Dictionary) -> void:
	_limpar()
	Jogo.total_caracteres = g["total"]
