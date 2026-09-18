## As quatro familias tematicas dos upgrades (issue #53).
##
## Suite propria e nao mais um bloco em teste_dados.gd porque as perguntas sao de outra
## natureza: teste_dados pergunta "este arquivo esta bem formado?", olhando um .tres de
## cada vez. Aqui as tres perguntas so existem quando se olha o CONJUNTO -- qual escada
## cada upgrade ocupa, se algum id sumiu, se a escada sobe.
##
## ⚠️ E O QUE ELA MEDE NAO APARECE EM LUGAR NENHUM. Upgrade que custa mais e multiplica
## menos nao quebra o jogo, nao imprime nada e nao reprova nenhuma outra suite: o jogador
## paga, nao ve diferenca e nunca sabe por que. Foi assim que `cafe_para_o_macaco` (x1,4
## por 1,6 milhao) ficou entre dois upgrades de x1,5 e x1,6 mais baratos desde a issue
## #18, e ninguem viu.
extends TesteBase

const PASTA_UPGRADES := "res://data/upgrades"

## ⚠️ ESTA LISTA E O CONTRATO COM QUEM JA JOGOU. `Jogo.upgrades_comprados` e uma lista de
## ids que vai para o save: renomear um id apaga a compra de quem tinha comprado, em
## silencio -- o jogo carrega, o upgrade simplesmente nao esta mais la, e o jogador so
## percebe pela producao que caiu.
##
## Por isso ela e escrita A MAO e nao derivada da pasta: derivada, ela concordaria com
## qualquer rename e nao protegeria nada. Id novo NAO entra aqui; esta lista so cresce
## quando um upgrade novo ja tiver sido publicado numa versao.
const IDS_DA_v0_5: PackedStringArray = [
	"instinto_digitador",
	"dedos_mais_ageis",
	"duas_maos",
	"maquina_lubrificada",
	"treinamento_questionavel",
	"segunda_mesa",
	"cafe_para_o_macaco",
	"teclas_mais_leves",
	"papel_continuo",
	"turno_da_noite",
	"mesas_empilhadas",
	"metodo_de_datilografia",
	"revisor_automatico",
	"ergonomia_simiesca",
	"arquivo_vertical",
	"estatistica_aplicada",
	"teoria_da_informacao",
	"dedos_probabilisticos",
	"espaco_nao_euclidiano",
	"o_macaco_percebe",
]

## Quantos upgrades uma familia precisa ter para valer como familia. Uma familia de um
## upgrade so nao e uma escada, e um cabecalho de loja com uma linha embaixo le como bug.
const MINIMO_POR_FAMILIA: int = 4


func _init() -> void:
	nome = "familias de upgrade"


func executar() -> void:
	var upgrades := _carregar()
	ok(not upgrades.is_empty(), "carregou algum upgrade de %s" % PASTA_UPGRADES)
	if upgrades.is_empty():
		return

	_toda_familia_declarada(upgrades)
	_os_ids_publicados_continuam_existindo(upgrades)
	_toda_familia_tem_escada(upgrades)
	_custo_e_efeito_sobem_juntos(upgrades)
	_a_familia_nao_decide_nada_no_gameplay()


## Familia SEM_FAMILIA e o zero do enum, que e o que todo recurso esquecido recebe. Ele
## existe para REPROVAR: sem ele, um .tres criado pela metade nasceria dizendo que e da
## familia Macaco e ninguem descobriria lendo o arquivo.
func _toda_familia_declarada(upgrades: Array) -> void:
	for dados in upgrades:
		ok(
			dados.familia != DadosUpgrade.Familia.SEM_FAMILIA,
			"%s declara familia" % dados.id,
		)
		ok(
			dados.familia in DadosUpgrade.Familia.values(),
			"%s -- familia e um valor do enum" % dados.id,
		)

	# ⚠️ A tabela de nomes e indexada pelo enum: tamanho que sai de um literal e uma bomba
	# com timer -- familia nova entra no enum, ninguem lembra do nome, e a loja mostra
	# cabecalho vazio sem erro nenhum.
	igual(
		DadosUpgrade.NOMES_DE_FAMILIA.size(),
		DadosUpgrade.Familia.values().size(),
		"ha um nome para cada entrada de Familia",
	)
	for texto in DadosUpgrade.NOMES_DE_FAMILIA:
		ok(not texto.strip_edges().is_empty(), "nome de familia preenchido: %s" % texto)


## Id que ja foi publicado nao pode sumir nem mudar: ele esta no save de quem jogou.
func _os_ids_publicados_continuam_existindo(upgrades: Array) -> void:
	var presentes := {}
	for dados in upgrades:
		presentes[dados.id] = true
	for id_antigo in IDS_DA_v0_5:
		ok(
			presentes.has(id_antigo),
			"o id %s da v0.5 continua existindo -- renomear apagaria a compra do save" % id_antigo,
		)


func _toda_familia_tem_escada(upgrades: Array) -> void:
	var quantos := {}
	for dados in upgrades:
		quantos[dados.familia] = int(quantos.get(dados.familia, 0)) + 1

	for familia in DadosUpgrade.Familia.values():
		if familia == DadosUpgrade.Familia.SEM_FAMILIA:
			# a afirmacao de cima ja garante que ninguem esta aqui; contar seria repetir
			continue
		var tem := int(quantos.get(familia, 0))
		ok(
			tem >= MINIMO_POR_FAMILIA,
			"a familia %s tem %d upgrades (minimo %d)" % [
				DadosUpgrade.NOMES_DE_FAMILIA[familia], tem, MINIMO_POR_FAMILIA,
			],
		)


## Dentro de uma escada, ordenada pelo custo, o multiplicador nunca cai.
##
## ⚠️ A ESCADA E O PAR (FAMILIA, TIPO DE EFEITO), e nao a familia sozinha. CAPACIDADE nao
## multiplica producao -- ela da vaga. Comparar "x5 de vaga" com "x2 de producao global"
## nao quer dizer nada, e uma regua que comparasse os dois reprovaria dado CERTO, que e o
## jeito mais rapido de ensinar todo mundo a ignorar a regua.
##
## ⚠️ E O INTERRUPTOR FICA DE FORA. LIGA_PRODUCAO_AUTOMATICA tem valor 1,0 por contrato
## (teste_dados cobra isso); incluido aqui, ele seria sempre o degrau mais barato e mais
## fraco de uma escada que ele nao pertence.
func _custo_e_efeito_sobem_juntos(upgrades: Array) -> void:
	var escadas := {}
	for dados in upgrades:
		if dados.tipo_de_efeito == DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA:
			continue
		var chave := "%d/%d" % [dados.familia, dados.tipo_de_efeito]
		if not escadas.has(chave):
			escadas[chave] = []
		escadas[chave].append(dados)

	# ⚠️ Escada nenhuma seria uma aprovacao vazia: um laco que caiu inteiro no `continue`
	# imprime "tudo certo" com ZERO degraus medidos.
	ok(not escadas.is_empty(), "achou pelo menos uma escada para medir")

	var degraus_medidos := 0
	for chave in escadas:
		var itens: Array = escadas[chave]
		itens.sort_custom(func(a: DadosUpgrade, b: DadosUpgrade) -> bool:
			return a.custo < b.custo)
		for i in range(1, itens.size()):
			var antes: DadosUpgrade = itens[i - 1]
			var depois: DadosUpgrade = itens[i]
			degraus_medidos += 1
			# ⚠️ NO DESCONTO, "MELHOR" E MENOR (issue #60). A regra e "o mais caro nao
			# rende menos", e para um desconto render mais quer dizer valor MENOR --
			# comparar `>=` ali reprovaria a escada certa e aprovaria a errada.
			var sobe: bool = (
				depois.valor <= antes.valor
				if depois.tipo_de_efeito in DadosUpgrade.DESCONTOS
				else depois.valor >= antes.valor
			)
			ok(
				sobe,
				"escada %s: %s (%s por %s) nao rende menos que %s (%s por %s)" % [
					chave, depois.id, depois.valor, depois.custo,
					antes.id, antes.valor, antes.custo,
				],
			)
	ok(degraus_medidos > 0, "mediu %d degraus de escada" % degraus_medidos)


## ⚠️ A FAMILIA E PARA LEITURA. O gameplay pergunta pelo TIPO de efeito
## (Economia.bonus_de) e nunca pela familia -- e o que sustenta "upgrade novo e um .tres,
## e mais nada". No dia em que aparecer um `if familia ==` dentro da economia, upgrade
## novo volta a exigir codigo, e essa regressao nao quebra nada: ela so torna o proximo
## upgrade mais caro de escrever, e ninguem liga os dois fatos.
##
## E uma varredura de texto, e nao um parser: ela le o arquivo procurando a palavra.
func _a_familia_nao_decide_nada_no_gameplay() -> void:
	var proibido := ["res://src/autoload/economia.gd", "res://src/autoload/jogo.gd"]
	for caminho in proibido:
		var arquivo := FileAccess.open(caminho, FileAccess.READ)
		ok(arquivo != null, "consegue ler %s" % caminho)
		if arquivo == null:
			continue
		var texto := arquivo.get_as_text()
		arquivo.close()
		ok(
			not texto.contains(".familia"),
			"%s nao consulta a familia de um upgrade -- ela e para leitura" % caminho,
		)


func _carregar() -> Array:
	var achados: Array = []
	var dir := DirAccess.open(PASTA_UPGRADES)
	if dir == null:
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			var dados := ResourceLoader.load(PASTA_UPGRADES + "/" + item) as DadosUpgrade
			if dados != null:
				achados.append(dados)
		item = dir.get_next()
	dir.list_dir_end()
	return achados
