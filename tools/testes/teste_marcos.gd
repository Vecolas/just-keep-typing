## Suite dos marcos: os .tres, a ordem e o portao de texto.
##
## Duas familias de erro que nenhuma outra suite ve:
##
## 1. REQUISITO NAO CRESCENTE. Dois marcos com o mesmo numero, ou um fora de ordem, nao e
##    erro de sintaxe -- e um Panorama que mostra "Uma Biblioteca" antes de "Uma Pagina" e
##    faz o jogador achar que o jogo esta quebrado. Com 90 marcos na issue #19, e a unica
##    coisa que segura a lista.
## 2. TEXTO SEM LINHA NO CSV. A frase aparece em portugues no meio de uma interface em
##    ingles, sem quebrar nada e sem imprimir erro. Este e o portao que a issue #10 pede,
##    limitado aos marcos; o portao geral e a issue #23.
extends TesteBase

const PASTA := "res://data/marcos"
const CSV := "res://i18n/textos.csv"
const PADRAO_DE_ID := "^[a-z][a-z0-9_]*$"

## Quantas vezes um marco tem que ser maior que o anterior. Nao e regra de gosto: abaixo
## disto os dois caem no mesmo segundo de jogo e o segundo nao existe para o jogador.
## Ver TUNING.md, sessao da issue #20.
const DISTANCIA_MINIMA: float = 1.15

func _init() -> void:
	nome = "marcos"


func executar() -> void:
	_catalogo()
	_ordem_estritamente_crescente()
	_portao_de_texto()
	_cruzar()


func _catalogo() -> void:
	var marcos := Marcos.todos()
	ok(not marcos.is_empty(), "o autoload Marcos carregou algum .tres de %s" % PASTA)
	igual(marcos.size(), _quantos_arquivos(), "carregou todos os arquivos da pasta")

	var expressao := RegEx.new()
	expressao.compile(PADRAO_DE_ID)
	var ids := {}
	for marco in marcos:
		ok(not marco.id.is_empty(), "marco com id preenchido")
		ok(expressao.search(marco.id) != null, "%s -- id e snake_case sem acento" % marco.id)
		ok(not ids.has(marco.id), "%s -- id nao repete" % marco.id)
		ids[marco.id] = true

		ok(marco.requisito_grande().sinal() > 0, "%s -- requisito positivo" % marco.id)
		ok(not marco.titulo.strip_edges().is_empty(), "%s -- titulo preenchido" % marco.id)
		ok(not marco.texto.strip_edges().is_empty(), "%s -- texto preenchido" % marco.id)
		ok(marco.era >= 1 and marco.era <= 8, "%s -- era entre 1 e 8" % marco.id)
		ok(
			marco.categoria in DadosMarco.Categoria.values(),
			"%s -- categoria e um valor do enum" % marco.id,
		)
		ok(Marcos.de(marco.id) == marco, "%s -- e achado por id" % marco.id)


## Estritamente crescente: dois marcos empatados sao dois marcos cruzando no mesmo
## caractere, e o Panorama nao tem como decidir qual mostrar em destaque.
func _ordem_estritamente_crescente() -> void:
	var marcos := Marcos.todos()
	var anterior: DadosMarco = null
	for marco in marcos:
		if anterior != null:
			ok(
				marco.requisito_grande().maior_que(anterior.requisito_grande()),
				"%s exige mais que %s" % [marco.id, anterior.id],
			)
			# e nao so maior: DISTANTE o bastante para nao passar despercebido. Dois
			# marcos a 1,02x de distancia caem no mesmo segundo de jogo, e o segundo nao
			# existe para o jogador -- a regua medir_ritmo mostrou vinte e um deles caindo
			# no mesmo segundo antes desta regra existir (issue #20).
			var razao := marco.requisito_grande().dividido(anterior.requisito_grande())
			ok(
				not razao.menor_que(Grande.de_float(DISTANCIA_MINIMA)),
				"%s esta longe o bastante de %s (%sx)" % [
					marco.id, anterior.id, Formatador.formatar(razao),
				],
			)
		anterior = marco


## Todo titulo e todo texto tem linha no CSV, nas duas colunas. O tom e canone nas duas
## linguas: quem escreve o ingles raramente rele o personagem, e e ali que ele se perde.
func _portao_de_texto() -> void:
	var chaves := _chaves_do_csv()
	ok(not chaves.is_empty(), "o CSV de traducao foi lido")
	for marco in Marcos.todos():
		ok(chaves.has(marco.titulo), "o titulo de %s tem linha no CSV" % marco.id)
		ok(chaves.has(marco.texto), "o texto de %s tem linha no CSV" % marco.id)
		if chaves.has(marco.texto):
			ok(
				not str(chaves[marco.texto]).strip_edges().is_empty(),
				"e a coluna en de %s esta preenchida" % marco.id,
			)


func _cruzar() -> void:
	var total_original := Jogo.total_caracteres
	var alcancados_originais := Jogo.marcos_alcancados.duplicate()

	Jogo.marcos_alcancados = [] as Array[String]
	Jogo.total_caracteres = Grande.zero()

	var avisados: Array[String] = []
	var ouvinte := func(marco: DadosMarco) -> void: avisados.append(marco.id)
	EventBus.marco_alcancado.connect(ouvinte)

	Marcos.verificar()
	igual(avisados.size(), 0, "com zero caractere nao cruza nada")
	ok(Marcos.atual() == null, "e nao ha marco atual")

	var primeiro := Marcos.todos()[0]
	ok(Marcos.proximo() == primeiro, "o proximo e o mais barato de todos")

	# um caractere abaixo do requisito ainda nao cruza
	Jogo.total_caracteres = primeiro.requisito_grande().menos(Grande.um())
	Marcos.verificar()
	igual(avisados.size(), 0, "um caractere abaixo do requisito nao cruza")

	# exatamente o requisito cruza: um > trocado por >= aqui atrasaria todo marco do jogo
	Jogo.total_caracteres = primeiro.requisito_grande()
	Marcos.verificar()
	igual(avisados.size(), 1, "exatamente o requisito cruza")
	ok(Marcos.alcancado(primeiro.id), "e o id entra na lista do save")
	ok(Marcos.atual() == primeiro, "e ele vira o marco atual")

	Marcos.verificar()
	igual(avisados.size(), 1, "verificar de novo nao avisa duas vezes")

	# a producao offline pula varios de uma vez: voltar depois de quatro horas e
	# atravessar tres faixas de escala e o caso comum, nao o raro.
	#
	# o alvo sai do ULTIMO marco e nao de um 1e100 fixo: a lista cresceu de cinco para
	# noventa na issue #19 e passou de 10^10000, e um numero cravado aqui envelheceria
	# em silencio -- passaria a testar "cruza os primeiros oitenta" achando que testa
	# "cruza todos"
	Jogo.total_caracteres = Marcos.todos()[-1].requisito_grande()
	Marcos.verificar()
	igual(avisados.size(), Marcos.todos().size(), "um salto grande cruza todos de uma vez")
	ok(Marcos.proximo() == null, "e nao sobra proximo")

	EventBus.marco_alcancado.disconnect(ouvinte)
	Jogo.total_caracteres = total_original
	Jogo.marcos_alcancados = alcancados_originais


func _chaves_do_csv() -> Dictionary:
	var chaves := {}
	var arquivo := FileAccess.open(CSV, FileAccess.READ)
	if arquivo == null:
		return chaves
	arquivo.get_csv_line()  # cabecalho
	while not arquivo.eof_reached():
		var linha := arquivo.get_csv_line()
		if linha.size() >= 3 and not linha[0].is_empty():
			chaves[linha[0]] = linha[2]
	arquivo.close()
	return chaves


func _quantos_arquivos() -> int:
	var dir := DirAccess.open(PASTA)
	if dir == null:
		return 0
	var quantos := 0
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			quantos += 1
		item = dir.get_next()
	dir.list_dir_end()
	return quantos
