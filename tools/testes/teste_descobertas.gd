## Suite das descobertas: o teto da chance, a ordem das raridades e o sorteio reprodutivel.
##
## As tres afirmacoes que a issue #16 pede, e cada uma protege uma coisa diferente:
##
##   TETO -- a chance nunca passa de 1. Sem ele, meia hora de endgame daria chance 10^40,
##   que nao significa nada e faria o catalogo inteiro cair no mesmo quadro, esvaziando o
##   sistema justamente quando ele deveria estar mais raro.
##
##   ORDEM -- categoria mais rara nunca sai antes da menos rara na mesma faixa de
##   producao. E uma regra sobre os DADOS, e nao sobre o codigo: basta alguem digitar um
##   zero a menos num .tres para o Epico virar mais provavel que o Comum.
##
##   SEMENTE -- o sorteio tem gerador proprio. Sem isso a suite dependeria do randi()
##   global e falharia de vez em quando, que e o pior tipo de teste que existe.
##
## ⚠️ Nenhuma afirmacao aqui olha texto gerado, porque o jogo NAO GERA TEXTO (GDD §10). O
## que se testa e a conta.
extends TesteBase

func _init() -> void:
	nome = "descobertas"


func executar() -> void:
	_catalogo()
	_ordem_das_raridades()
	_teto_da_chance()
	_sorteio_reprodutivel()
	_bonus_permanente()
	_as_lendarias_e_o_espaco_entre_elas()


func _catalogo() -> void:
	var todas := Descobertas.todas()
	ok(not todas.is_empty(), "o autoload carregou algum .tres")

	var ids := {}
	for descoberta in todas:
		ok(not ids.has(descoberta.id), "%s -- id nao repete" % descoberta.id)
		ids[descoberta.id] = true
		ok(descoberta.chance_base > 0.0, "%s -- chance_base positiva" % descoberta.id)
		# bonus 1 seria descoberta que nao recompensa nada, e descoberta E o sistema de
		# bonus do jogo (o de significado e o Panorama)
		ok(descoberta.bonus > 1.0, "%s -- bonus %s recompensa alguma coisa" % [
			descoberta.id, descoberta.bonus,
		])
		ok(not descoberta.nome.strip_edges().is_empty(), "%s -- nome preenchido" % descoberta.id)
		ok(not descoberta.texto.strip_edges().is_empty(), "%s -- texto preenchido" % descoberta.id)
		ok(
			descoberta.categoria in DadosDescoberta.Categoria.values(),
			"%s -- categoria e um valor do enum" % descoberta.id,
		)
		ok(Descobertas.de(descoberta.id) == descoberta, "%s -- e achada por id" % descoberta.id)


## Regra sobre os dados: a categoria seguinte tem que ser toda mais rara que a anterior.
## Um zero a menos num .tres faria o Epico sair antes do Comum, e nada mais no jogo
## perceberia.
func _ordem_das_raridades() -> void:
	var menor_da_categoria := {}
	var maior_da_categoria := {}
	for descoberta in Descobertas.todas():
		var c: int = descoberta.categoria
		menor_da_categoria[c] = minf(menor_da_categoria.get(c, INF), descoberta.chance_base)
		maior_da_categoria[c] = maxf(maior_da_categoria.get(c, 0.0), descoberta.chance_base)

	var categorias := menor_da_categoria.keys()
	categorias.sort()
	for i in range(1, categorias.size()):
		var anterior: int = categorias[i - 1]
		var atual: int = categorias[i]
		ok(
			maior_da_categoria[atual] < menor_da_categoria[anterior],
			"a categoria %d e toda mais rara que a %d" % [atual, anterior],
		)

	# e a lista sai ordenada da mais comum para a mais rara, que e como a tela mostra
	var ordem_certa := true
	var anterior_categoria := -1
	for descoberta in Descobertas.todas():
		if descoberta.categoria < anterior_categoria:
			ordem_certa = false
		anterior_categoria = descoberta.categoria
	ok(ordem_certa, "a lista sai da mais comum para a mais rara")


func _teto_da_chance() -> void:
	var comum := Descobertas.todas()[0]

	perto(Descobertas.chance_de(comum, Grande.zero()), 0.0, 0.0, "zero caractere, zero chance")
	perto(
		Descobertas.chance_de(comum, Grande.de_float(-5.0)), 0.0, 0.0,
		"producao negativa nao vira chance",
	)
	perto(
		Descobertas.chance_de(comum, Grande.de_float(1.0)), comum.chance_base, 1e-15,
		"um caractere da exatamente a chance base",
	)
	perto(
		Descobertas.chance_de(comum, Grande.de_float(1.0 / comum.chance_base)), 1.0, 1e-9,
		"o inverso da chance base satura em 1",
	)

	# o caso que o teto existe para aguentar: producao que nem cabe em float
	perto(
		Descobertas.chance_de(comum, Grande.new(1.0, 400)), 1.0, 0.0,
		"10^400 caracteres continuam dando chance 1 e nao INF",
	)
	for descoberta in Descobertas.todas():
		var chance := Descobertas.chance_de(descoberta, Grande.new(1.0, 300))
		ok(chance <= 1.0 and chance >= 0.0, "%s -- a chance fica em [0, 1]" % descoberta.id)


## Mesma semente, mesmo resultado. E o que permite a suite afirmar qualquer coisa sobre um
## sorteio.
func _sorteio_reprodutivel() -> void:
	var guardado := Jogo.descobertas.duplicate()
	var semente_original := Descobertas.gerador.seed

	var primeira := _sortear_com(1234, 12)
	var segunda := _sortear_com(1234, 12)
	igual(primeira, segunda, "a mesma semente sorteia a mesma sequencia")

	var terceira := _sortear_com(999, 12)
	ok(primeira != terceira or primeira.is_empty(), "sementes diferentes divergem")

	# producao que satura a chance: com chance 1 em tudo, a primeira da lista sai sempre,
	# e sai UMA por credito -- voltar de quatro horas offline nao despeja o catalogo
	Jogo.descobertas = [] as Array[String]
	Descobertas.gerador.seed = 7
	Descobertas.sortear(Grande.new(1.0, 300))
	igual(Jogo.descobertas.size(), 1, "chance saturada solta uma descoberta, nao todas")
	igual(Jogo.descobertas[0], Descobertas.todas()[0].id, "e e a mais comum da lista")

	# e nao repete a que ja saiu
	Descobertas.sortear(Grande.new(1.0, 300))
	igual(Jogo.descobertas.size(), 2, "o credito seguinte solta a proxima")
	ok(Jogo.descobertas[1] != Jogo.descobertas[0], "e nao repete a anterior")

	Descobertas.gerador.seed = semente_original
	Jogo.descobertas = guardado


func _sortear_com(semente: int, creditos: int) -> Array:
	Jogo.descobertas = [] as Array[String]
	Descobertas.gerador.seed = semente
	for i in creditos:
		Descobertas.sortear(Grande.de_float(500.0))
	return Jogo.descobertas.duplicate()


## Descoberta da bonus; marco nao da. Sao os dois sistemas de recompensa do jogo e eles
## nao se misturam (decisao 0003).
func _bonus_permanente() -> void:
	var guardado := Jogo.descobertas.duplicate()
	Jogo.descobertas = [] as Array[String]
	perto(Economia.multiplicador_de_descobertas(), 1.0, 1e-12, "sem descoberta, bonus neutro")

	var primeira := Descobertas.todas()[0]
	Jogo.descobertas = [primeira.id] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), primeira.bonus, 1e-12,
		"uma descoberta vale o bonus dela",
	)

	var segunda := Descobertas.todas()[1]
	Jogo.descobertas = [primeira.id, segunda.id] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), primeira.bonus * segunda.bonus, 1e-12,
		"duas descobertas multiplicam, nunca somam",
	)

	Jogo.descobertas = ["id_que_nao_existe"] as Array[String]
	perto(
		Economia.multiplicador_de_descobertas(), 1.0, 1e-12,
		"id de save antigo que nao existe mais e ignorado, e nao quebra a producao",
	)

	Jogo.descobertas = guardado


## As seis do GDD §11, e a regra que faz elas VALEREM alguma coisa.
##
## "Se o jogador ve duas lendarias na mesma sessao, elas deixam de ser lendarias." Esta e a
## afirmacao que a issue #32 pede, e ela nao e sobre chance: no endgame a chance de tudo
## que ainda falta vale 1, entao sem quarentena as seis caem no MESMO QUADRO. Seis avisos
## empilhados nao sao seis momentos raros -- sao um so, e barulhento.
func _as_lendarias_e_o_espaco_entre_elas() -> void:
	var guardado_descobertas := Jogo.descobertas.duplicate()
	var guardado_tempo := Jogo.tempo_jogado
	var guardado_ultima := Jogo.tempo_da_ultima_rara
	var semente_original := Descobertas.gerador.seed

	# as seis do GDD §11 existem, e cada uma das tres faixas de cima tem alguem
	var faixas := {}
	for id in [
		"hamlet", "romance_inedito", "minha_biografia",
		"o_jogo", "essa_mensagem", "o_proximo_texto",
	]:
		var dados := Descobertas.de(id)
		ok(dados != null, "%s existe no catalogo" % id)
		if dados == null:
			continue
		ok(
			dados.categoria >= DadosDescoberta.Categoria.LENDARIO,
			"%s e Lendaria ou acima" % id,
		)
		faixas[dados.categoria] = true
	for categoria in [
		DadosDescoberta.Categoria.LENDARIO,
		DadosDescoberta.Categoria.IMPOSSIVEL,
		DadosDescoberta.Categoria.PARADOXAL,
	]:
		ok(faixas.has(categoria), "a faixa %d tem pelo menos uma descoberta" % categoria)

	# Hamlet e o unico bonus que o GDD crava: x10 permanente (§11)
	perto(Descobertas.de("hamlet").bonus, 10.0, 1e-12, "Hamlet vale os x10 do GDD §11")

	# O CASO QUE IMPORTA: chance saturada, credito atras de credito, e as raras uma so vez
	Jogo.descobertas = [] as Array[String]
	Jogo.tempo_jogado = 0.0
	# negativo e o "nenhuma rara ainda" -- zero seria uma rara achada no instante zero
	Jogo.tempo_da_ultima_rara = -1.0
	Descobertas.gerador.seed = 42
	var raras := 0
	for i in 200:
		Descobertas.sortear(Grande.new(1.0, 300))
	for id in Jogo.descobertas:
		if Descobertas.de(id).categoria >= DadosDescoberta.Categoria.LENDARIO:
			raras += 1
	igual(raras, 1, "duzentos creditos no mesmo instante soltam UMA rara, e nao seis")

	# e as comuns continuam saindo: a quarentena espaca as raras, nao congela o sistema
	ok(Jogo.descobertas.size() > raras, "as comuns continuam caindo durante a quarentena")

	# passado o intervalo, a proxima rara pode sair
	var quarentena: DadosDescoberta = null
	for descoberta in Descobertas.todas():
		if not Descobertas.encontrada(descoberta.id) 				and descoberta.categoria >= DadosDescoberta.Categoria.LENDARIO:
			quarentena = descoberta
			break
	ok(quarentena != null, "ainda ha rara por achar depois da primeira")
	ok(Descobertas.em_quarentena(quarentena), "e ela esta em quarentena no mesmo instante")

	Jogo.tempo_jogado = Jogo.tempo_da_ultima_rara + 10000.0
	ok(not Descobertas.em_quarentena(quarentena), "passado o intervalo, ela e liberada")
	Descobertas.sortear(Grande.new(1.0, 300))
	ok(Descobertas.encontrada(quarentena.id), "e o credito seguinte a solta")

	# e a quarentena nunca vale para as comuns -- elas nao prometem raridade nenhuma
	ok(
		not Descobertas.em_quarentena(Descobertas.todas()[0]),
		"a mais comum do catalogo nunca fica em quarentena",
	)

	Descobertas.gerador.seed = semente_original
	Jogo.descobertas = guardado_descobertas
	Jogo.tempo_jogado = guardado_tempo
	Jogo.tempo_da_ultima_rara = guardado_ultima
