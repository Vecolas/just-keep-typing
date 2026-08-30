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

## O id vai para o save e para chave de dicionario, entao so minuscula, numero e
## sublinhado -- acento em chave de save e fonte de bug de codificacao (decisao 0002).
const PADRAO_DE_ID := "^[a-z][a-z0-9_]*$"

func _init() -> void:
	nome = "dados em .tres"


func executar() -> void:
	_macacos()
	_upgrades()


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
		# valor 1 e upgrade que nao faz nada: o jogador paga e nao ve diferenca
		ok(dados.valor > 1.0, "%s -- valor %s multiplica alguma coisa" % [caminho, dados.valor])
		ok(dados.requisito >= 0.0, "%s -- requisito nao e negativo" % caminho)
		ok(
			dados.tipo_de_efeito in DadosUpgrade.Efeito.values(),
			"%s -- tipo_de_efeito e um valor do enum" % caminho,
		)


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
