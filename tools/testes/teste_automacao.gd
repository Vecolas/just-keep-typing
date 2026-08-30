## Suite da automacao (GDD §16).
##
## A afirmacao que a issue #28 pede é uma só, e ela é a razão de o sistema ser seguro:
##
##   O AUTOMATICO COMPRA EXATAMENTE O QUE O MANUAL COMPRARIA.
##
## Ela e testavel porque nao existe caminho de compra separado: agir() chama as mesmas
## funcoes dos botoes. A suite roda os dois lados a partir do MESMO estado e compara o
## resultado -- se um dia alguem escrever um atalho para o automatico, e aqui que aparece.
##
## Mais a regra que a issue repete duas vezes: E SEMPRE DESLIGAVEL.
extends TesteBase

func _init() -> void:
	nome = "automacao"


func executar() -> void:
	_catalogo()
	_compra_e_desliga()
	_o_automatico_compra_o_mesmo()
	_o_administrador_espera_a_sala_encher()
	_o_diretor_so_resolve_punicao()


func _catalogo() -> void:
	var todas := Automacao.todas()
	ok(not todas.is_empty(), "o autoload carregou algum .tres")
	igual(
		todas.size(), DadosAutomacao.Tarefa.values().size(),
		"cada tarefa do GDD §16 tem uma automacao que a entrega",
	)

	var ids := {}
	var tarefas := {}
	for dados in todas:
		ok(not ids.has(dados.id), "%s -- id nao repete" % dados.id)
		ids[dados.id] = true
		ok(not tarefas.has(dados.tarefa), "%s -- tarefa nao repete" % dados.id)
		tarefas[dados.tarefa] = true
		ok(dados.custo > 0.0, "%s -- custo positivo" % dados.id)
		ok(dados.intervalo > 0.0, "%s -- intervalo positivo" % dados.id)
		ok(not dados.nome.strip_edges().is_empty(), "%s -- nome preenchido" % dados.id)
		ok(not dados.descricao.strip_edges().is_empty(), "%s -- descricao preenchida" % dados.id)
		# automacao so entra depois de o jogador ter feito aquilo na mao o bastante
		ok(
			dados.requisito > 0.0,
			"%s -- exige caractere antes de aparecer, e nao chega no primeiro minuto" % dados.id,
		)


func _compra_e_desliga() -> void:
	var guardado := _guardar()
	_zerar()

	var primeira := Automacao.todas()[0]
	ok(not Automacao.comprada(primeira.id), "partida nova nao tem automacao nenhuma")
	# _zerar deixa o total alto para os outros blocos; aqui o ponto e justamente o comeco
	Jogo.total_caracteres = Grande.zero()
	ok(not Automacao.disponivel(primeira.id), "e ela nem aparece sem caractere suficiente")
	ok(not Automacao.comprar(primeira.id), "e comprar antes do requisito falha")

	Jogo.total_caracteres = Grande.de_float(primeira.requisito)
	ok(Automacao.disponivel(primeira.id), "atingido o requisito, ela aparece")
	ok(not Automacao.comprar(primeira.id), "mas sem dinheiro ainda nao compra")

	Jogo.dinheiro = Grande.de_float(primeira.custo)
	ok(Automacao.comprar(primeira.id), "com o dinheiro exato, compra")
	ok(Jogo.dinheiro.e_zero(), "e o custo sai do saldo")
	ok(Automacao.comprada(primeira.id), "ela fica comprada")
	ok(Automacao.ligada(primeira.id), "e ja nasce ligada")
	ok(not Automacao.comprar(primeira.id), "e nao da para comprar duas vezes")

	# e sempre desligavel, e desligar nao apaga a compra
	ok(not Automacao.alternar(primeira.id), "alternar desliga")
	ok(not Automacao.ligada(primeira.id), "e ela para de agir")
	ok(Automacao.comprada(primeira.id), "mas continua comprada")
	ok(Automacao.alternar(primeira.id), "e alternar de novo liga")

	# desligada nao age, nem com cronometro vencido
	Automacao.alternar(primeira.id)
	Jogo.dinheiro = Grande.new(1.0, 20)
	var macacos_antes := Jogo.macacos
	Automacao.tique(1000.0)
	ok(Jogo.macacos.igual_a(macacos_antes), "desligada nao compra nada, por mais tempo que passe")

	_devolver(guardado)


## A afirmacao central: mesmo estado de partida, mesmo resultado pelos dois caminhos.
func _o_automatico_compra_o_mesmo() -> void:
	var guardado := _guardar()

	var gerente: DadosAutomacao = null
	var tecnico: DadosAutomacao = null
	for dados in Automacao.todas():
		if dados.tarefa == DadosAutomacao.Tarefa.COMPRAR_MACACOS:
			gerente = dados
		if dados.tarefa == DadosAutomacao.Tarefa.TROCAR_MAQUINA:
			tecnico = dados
	ok(gerente != null and tecnico != null, "o Gerente e o Tecnico existem")

	# manual: comprar o maximo de macacos e trocar a maquina, pelos botoes
	_zerar()
	Jogo.dinheiro = Grande.de_float(1e7)
	Economia.comprar_macacos(Economia.macacos_que_cabem())
	Economia.comprar_maquina(Economia.proxima_maquina().id)
	var manual := _retrato()

	# automatico: o mesmo estado inicial, e agir() em vez dos botoes
	_zerar()
	Jogo.dinheiro = Grande.de_float(1e7)
	Automacao.agir(gerente)
	Automacao.agir(tecnico)
	var automatico := _retrato()

	igual(automatico["macacos"], manual["macacos"], "o automatico compra os mesmos macacos")
	igual(automatico["dinheiro"], manual["dinheiro"], "e gasta exatamente o mesmo")
	igual(automatico["maquina"], manual["maquina"], "e troca para a mesma maquina")


## "Quando o espaco acaba, nunca antes". Expandir com vaga sobrando gastaria o saldo que
## o jogador ia usar em macaco, e o Administrador viraria sabotagem.
func _o_administrador_espera_a_sala_encher() -> void:
	var guardado := _guardar()
	_zerar()

	var administrador: DadosAutomacao = null
	for dados in Automacao.todas():
		if dados.tarefa == DadosAutomacao.Tarefa.EXPANDIR_SALA:
			administrador = dados
	ok(administrador != null, "o Administrador existe")

	Jogo.dinheiro = Grande.new(1.0, 20)
	Jogo.macacos = Grande.um()
	ok(not Economia.vagas_livres().e_zero(), "a sala comeca com vaga sobrando")
	ok(not Automacao.agir(administrador), "e com vaga sobrando ele nao expande")
	igual(Jogo.sala_atual, "", "e a sala continua a mesma")

	Jogo.macacos = Economia.capacidade()
	ok(Economia.vagas_livres().e_zero(), "com a sala cheia")
	ok(Automacao.agir(administrador), "ele expande")
	ok(Jogo.sala_atual != "", "e a sala muda")

	_devolver(guardado)


## O Diretor resolve o que ATRAPALHA a descoberta, e so isso: encerrar um Macaco Inspirado
## por engano seria a automacao jogando contra o jogador.
func _o_diretor_so_resolve_punicao() -> void:
	var guardado := _guardar()
	_zerar()

	var diretor: DadosAutomacao = null
	for dados in Automacao.todas():
		if dados.tarefa == DadosAutomacao.Tarefa.RESOLVER_EVENTOS:
			diretor = dados
	ok(diretor != null, "o Diretor existe")

	Eventos.limpar()
	ok(not Automacao.agir(diretor), "sem evento nenhum ele nao faz nada")

	var bom := Eventos.de("macaco_inspirado")
	Eventos.comecar(bom.id)
	ok(not Automacao.agir(diretor), "com um evento bom ativo ele nao mexe")
	ok(Eventos.ativo(bom.id), "e o evento bom continua valendo")

	var punicao := Eventos.de("banana_na_maquina")
	Eventos.comecar(punicao.id)
	ok(Automacao.agir(diretor), "com uma punicao ativa ele resolve")
	ok(not Eventos.ativo(punicao.id), "e a punicao acaba")
	ok(Eventos.ativo(bom.id), "e o evento bom continua intacto")

	Eventos.limpar()
	_devolver(guardado)


func _retrato() -> Dictionary:
	return {
		"macacos": Jogo.macacos.para_texto(),
		"dinheiro": Jogo.dinheiro.para_texto(),
		"maquina": Jogo.maquina_atual,
		"sala": Jogo.sala_atual,
	}


func _zerar() -> void:
	Jogo.total_caracteres = Grande.new(1.0, 20)
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.um()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.automacoes = {}
	Jogo.teoremas = {}


func _guardar() -> Dictionary:
	return {
		"total": Jogo.total_caracteres, "dinheiro": Jogo.dinheiro, "macacos": Jogo.macacos,
		"maquina": Jogo.maquina_atual, "sala": Jogo.sala_atual,
		"upgrades": Jogo.upgrades_comprados.duplicate(),
		"automacoes": Jogo.automacoes.duplicate(), "teoremas": Jogo.teoremas.duplicate(),
	}


func _devolver(g: Dictionary) -> void:
	Jogo.total_caracteres = g["total"]
	Jogo.dinheiro = g["dinheiro"]
	Jogo.macacos = g["macacos"]
	Jogo.maquina_atual = g["maquina"]
	Jogo.sala_atual = g["sala"]
	Jogo.upgrades_comprados = g["upgrades"]
	Jogo.automacoes = g["automacoes"]
	Jogo.teoremas = g["teoremas"]
