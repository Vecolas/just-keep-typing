## Suite dos .tres de balanceamento: carrega todos e reprova numero que quebraria o jogo.
##
## Esta suite existe por causa de uma familia inteira de erro que nao aparece em lugar
## nenhum -- nem no editor, nem rodando o jogo, nem na suite de scripts. Um crescimento
## de custo igual a 1 nao e erro de sintaxe: e um .tres perfeitamente valido que deixa o
## jogador comprar infinito. Um custo zerado idem. Ver CONVENCOES.md, "Mexeu num numero
## de balanceamento?".
##
## Varre a pasta em vez de listar os arquivos de proposito: .tres novo entra na suite
## sozinho, sem ninguem lembrar de acrescentar uma linha aqui. E a issue #18 traz vinte
## de uma vez.
extends TesteBase

const PASTA_MACACOS := "res://data/macacos"
const PASTA_UPGRADES := "res://data/upgrades"
const PASTA_MAQUINAS := "res://data/maquinas"
const PASTA_SALAS := "res://data/salas"

## O id vai para o save e para chave de dicionario, entao so minuscula, numero e
## sublinhado -- acento em chave de save e fonte de bug de codificacao (decisao 0002).
const PADRAO_DE_ID := "^[a-z][a-z0-9_]*$"

func _init() -> void:
	nome = "dados em .tres"


func executar() -> void:
	_macacos()
	_upgrades()
	_maquinas()
	_salas()


func _macacos() -> void:
	var caminhos := _listar_tres(PASTA_MACACOS)
	ok(not caminhos.is_empty(), "encontrou algum .tres em %s" % PASTA_MACACOS)

	var ids := {}
	for caminho in caminhos:
		var dados := ResourceLoader.load(caminho) as DadosMacaco
		ok(dados != null, "%s carrega como DadosMacaco" % caminho)
		if dados == null:
			continue

		_id_valido(dados.id, ids, caminho)
		_texto_preenchido(dados.nome, dados.descricao, caminho)

		ok(dados.custo_base > 0.0, "%s -- custo_base %s e maior que zero" % [caminho, dados.custo_base])
		# custo que nao cresce e compra infinita: o jogador leva quantos quiser de uma vez
		ok(
			dados.crescimento_custo > 1.0,
			"%s -- crescimento_custo %s e maior que 1" % [caminho, dados.crescimento_custo],
		)
		ok(
			dados.producao_base > 0.0,
			"%s -- producao_base %s e maior que zero" % [caminho, dados.producao_base],
		)
		ok(
			dados.requisito_desbloqueio >= 0.0,
			"%s -- requisito_desbloqueio nao e negativo" % caminho,
		)

		# a prova de que o .tres funciona de verdade e a Economia aceitar os numeros dele
		var custo := Economia.custo_do_proximo(
			Grande.de_float(dados.custo_base), dados.crescimento_custo, 0.0
		)
		ok(custo.sinal() > 0, "%s -- a Economia calcula um custo positivo com estes numeros" % caminho)
		var segundo := Economia.custo_do_proximo(
			Grande.de_float(dados.custo_base), dados.crescimento_custo, 1.0
		)
		ok(segundo.maior_que(custo), "%s -- e o segundo custa mais que o primeiro" % caminho)


func _upgrades() -> void:
	var caminhos := _listar_tres(PASTA_UPGRADES)
	ok(not caminhos.is_empty(), "encontrou algum .tres em %s" % PASTA_UPGRADES)

	var ids := {}
	for caminho in caminhos:
		var dados := ResourceLoader.load(caminho) as DadosUpgrade
		ok(dados != null, "%s carrega como DadosUpgrade" % caminho)
		if dados == null:
			continue

		_id_valido(dados.id, ids, caminho)
		_texto_preenchido(dados.nome, dados.descricao, caminho)

		ok(dados.custo > 0.0, "%s -- custo %s e maior que zero" % [caminho, dados.custo])

		# ⚠️ `valor` QUER DIZER COISAS DIFERENTES POR TIPO desde a issue #60, e cada um e
		# cobrado pela regra DELE. Uma regra so -- "valor > 1" -- aprovaria um desconto de
		# 1,05 (que ENCARECE o macaco) e reprovaria uma parcela de +0,5.
		var tipo: DadosUpgrade.Efeito = dados.tipo_de_efeito
		if tipo == DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA:
			# interruptor nao multiplica nada, e numero solto num campo que ninguem le
			# faz a proxima pessoa procurar um multiplicador que nao existe
			perto(dados.valor, 1.0, 0.0, "%s -- interruptor tem valor neutro" % caminho)
		elif tipo in DadosUpgrade.SOMADORES:
			# parcela: zero e o neutro, e parcela zero e upgrade que nao faz nada
			ok(dados.valor > 0.0, "%s -- parcela %s soma alguma coisa" % [caminho, dados.valor])
		elif tipo in DadosUpgrade.DESCONTOS:
			ok(
				dados.valor > 0.0 and dados.valor < 1.0,
				"%s -- desconto %s esta entre 0 e 1" % [caminho, dados.valor],
			)
			# ⚠️ e ele nao pode furar o piso sozinho: um desconto abaixo do DESCONTO_MINIMO
			# ja chegaria no piso com UMA compra, e os outros da familia virariam enfeite
			ok(
				dados.valor > DadosUpgrade.DESCONTO_MINIMO,
				"%s -- desconto %s nao fura o piso sozinho" % [caminho, dados.valor],
			)
		else:
			# valor 1 e upgrade que nao faz nada: o jogador paga e nao ve diferenca
			ok(dados.valor > 1.0, "%s -- valor %s multiplica alguma coisa" % [caminho, dados.valor])

		# ⚠️ E TODO TIPO TEM QUE ESTAR EM ALGUMA DAS LISTAS. Tipo novo no enum que ninguem
		# classificou cai no `else` acima e e cobrado como multiplicador -- em silencio, e
		# errado. Item que fica fora da lista some da conta.
		ok(
			tipo == DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA
				or tipo in DadosUpgrade.MULTIPLICADORES
				or tipo in DadosUpgrade.SOMADORES
				or tipo in DadosUpgrade.DESCONTOS,
			"%s -- o tipo %d esta classificado em alguma lista" % [caminho, tipo],
		)
		ok(dados.requisito >= 0.0, "%s -- requisito nao e negativo" % caminho)
		ok(
			dados.tipo_de_efeito in DadosUpgrade.Efeito.values(),
			"%s -- tipo_de_efeito e um valor do enum" % caminho,
		)


## A escada do GDD §13. Tier, multiplicador e custo tem que subir JUNTOS: uma maquina que
## custa mais e multiplica menos e dinheiro jogado fora, e o jogador so descobre depois de
## pagar. E o tipo de erro que nao aparece em lugar nenhum a nao ser aqui.
func _maquinas() -> void:
	var caminhos := _listar_tres(PASTA_MAQUINAS)
	ok(not caminhos.is_empty(), "encontrou algum .tres em %s" % PASTA_MAQUINAS)

	var ids := {}
	var tiers := {}
	var por_tier := {}
	for caminho in caminhos:
		var dados := ResourceLoader.load(caminho) as DadosMaquina
		ok(dados != null, "%s carrega como DadosMaquina" % caminho)
		if dados == null:
			continue

		_id_valido(dados.id, ids, caminho)
		_texto_preenchido(dados.nome, dados.descricao, caminho)
		ok(dados.multiplicador >= 1.0, "%s -- multiplicador %s nao encolhe a producao" % [
			caminho, dados.multiplicador,
		])
		ok(dados.custo >= 0.0, "%s -- custo nao e negativo" % caminho)
		ok(not tiers.has(dados.tier), "%s -- tier %d nao repete" % [caminho, dados.tier])
		tiers[dados.tier] = true
		por_tier[dados.tier] = dados

	var ordenados := por_tier.keys()
	ordenados.sort()
	igual(ordenados[0], 1, "a escada comeca no tier 1")
	var anterior: DadosMaquina = null
	for tier in ordenados:
		var atual: DadosMaquina = por_tier[tier]
		if anterior != null:
			igual(tier, anterior.tier + 1, "o tier %d nao pula nenhum degrau" % tier)
			ok(
				atual.multiplicador > anterior.multiplicador,
				"%s multiplica mais que %s" % [atual.id, anterior.id],
			)
			ok(atual.custo > anterior.custo, "%s custa mais que %s" % [atual.id, anterior.id])
		anterior = atual

	# a primeira e a que o jogador ja tem: cobrar por ela seria cobrar pelo estado inicial
	igual(por_tier[1].custo, 0.0, "a maquina do tier 1 e a que vem com o macaco, e nao custa")
	igual(por_tier[1].multiplicador, 1.0, "e ela e o multiplicador neutro")


## A escada do GDD §15. Capacidade e custo tem que subir juntos, e a primeira sala e a
## que o jogador ja ocupa -- cobrar por ela seria cobrar pelo estado inicial.
func _salas() -> void:
	var caminhos := _listar_tres(PASTA_SALAS)
	ok(not caminhos.is_empty(), "encontrou algum .tres em %s" % PASTA_SALAS)

	var ids := {}
	var por_tier := {}
	for caminho in caminhos:
		var dados := ResourceLoader.load(caminho) as DadosSala
		ok(dados != null, "%s carrega como DadosSala" % caminho)
		if dados == null:
			continue

		_id_valido(dados.id, ids, caminho)
		_texto_preenchido(dados.nome, dados.descricao, caminho)
		# sala sem vaga nenhuma pararia o jogo inteiro em silencio
		ok(dados.capacidade > 0.0, "%s -- capacidade %s cabe alguem" % [caminho, dados.capacidade])
		ok(dados.custo >= 0.0, "%s -- custo nao e negativo" % caminho)
		ok(not por_tier.has(dados.tier), "%s -- tier %d nao repete" % [caminho, dados.tier])
		por_tier[dados.tier] = dados

	var ordenados := por_tier.keys()
	ordenados.sort()
	igual(ordenados[0], 1, "a escada comeca no tier 1")
	var anterior: DadosSala = null
	for tier in ordenados:
		var atual: DadosSala = por_tier[tier]
		if anterior != null:
			igual(tier, anterior.tier + 1, "o tier %d nao pula nenhum degrau" % tier)
			ok(atual.capacidade > anterior.capacidade, "%s cabe mais que %s" % [atual.id, anterior.id])
			ok(atual.custo > anterior.custo, "%s custa mais que %s" % [atual.id, anterior.id])
		anterior = atual

	igual(por_tier[1].custo, 0.0, "a sala do tier 1 e onde o jogo comeca, e nao custa")


func _id_valido(id: String, ja_vistos: Dictionary, caminho: String) -> void:
	ok(not id.is_empty(), "%s -- id preenchido" % caminho)
	var expressao := RegEx.new()
	expressao.compile(PADRAO_DE_ID)
	ok(expressao.search(id) != null, "%s -- id %s e snake_case sem acento" % [caminho, id])
	ok(not ja_vistos.has(id), "%s -- id %s nao repete" % [caminho, id])
	ja_vistos[id] = caminho


## Texto que o jogador le nao pode chegar vazio na tela. A conferencia de que ele tem
## linha no i18n/textos.csv e o portao da issue #23, que ainda nao existe.
func _texto_preenchido(nome_do_dado: String, descricao: String, caminho: String) -> void:
	ok(not nome_do_dado.strip_edges().is_empty(), "%s -- nome preenchido" % caminho)
	ok(not descricao.strip_edges().is_empty(), "%s -- descricao preenchida" % caminho)


func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
