## Suite de REDACAO do conteudo (issue #51): o que os textos do jogo podem e nao podem
## afirmar.
##
## ⚠️ A REGRA QUE ESTA SUITE EXISTE PARA PROTEGER: equivalencia em caracteres NAO e ter
## escrito a obra.
##
## O texto diz "voce produziu caracteres suficientes para preencher um livro". Ele NUNCA
## diz "voce escreveu um livro". A diferenca parece preciosismo e e o conceito
## probabilistico inteiro do jogo: o macaco nao escreveu Hamlet -- ele produziu tanto
## caractere quanto Hamlet tem. No dia em que o texto afirmar autoria, o jogo deixa de ser
## sobre o Teorema do Macaco Infinito e passa a ser sobre um macaco talentoso.
##
## ⚠️ E ESTE PORTAO PEGA A CONSTRUCAO, E NAO O SENTIDO. Ele varre uma lista de construcoes
## proibidas, uma a uma, e cada uma esta escrita com o motivo dela. O que ele NAO pega:
## uma frase que afirme autoria por outras palavras, com outra sintaxe. Isso e leitura
## humana, e a checagem de design da CONVENCOES.md e quem faz.
##
## Uma regra vale para todo texto de jogo; nenhuma delas vale so para marco.
extends TesteBase

const PASTA_DE_MARCOS := "res://data/marcos"
const PASTA_DE_DESCOBERTAS := "res://data/descobertas"

## ⚠️ AS CONSTRUCOES PROIBIDAS, e o motivo de cada uma.
##
## A lista e explicita e curta de proposito. Uma expressao regular ampla -- "escrev" em
## qualquer lugar -- reprovaria "tudo que a humanidade escreveu", que e uma frase CERTA:
## ela fala do que a humanidade escreveu, e nao do que o jogador escreveu. Portao que
## morde o codigo certo e portao que alguem desliga.
const PROIBIDAS: Array[Dictionary] = [
	{
		"trecho": "você escreveu",
		"porque": "afirma autoria do jogador -- ele produziu caracteres, nao a obra",
	},
	{
		"trecho": "você já escreveu",
		"porque": "idem, com o adverbio no meio",
	},
	{
		"trecho": "voce escreveu",
		"porque": "a mesma afirmacao sem acento -- o portao nao pode depender de acento",
	},
	{
		"trecho": "você redigiu",
		"porque": "sinonimo de autoria",
	},
	{
		"trecho": "você compôs",
		"porque": "sinonimo de autoria",
	},
	{
		"trecho": "você publicou",
		"porque": "autoria mais distribuicao, que o jogo nunca afirma",
	},
	{
		"trecho": "seus macacos escreveram",
		"porque": "a autoria pelo macaco e a mesma afirmacao, com outro sujeito",
	},
	{
		"trecho": "o macaco escreveu",
		"porque": "idem -- a piada e a coincidencia, e nao o talento",
	},
]

## ⚠️ AS MESMAS CONSTRUCOES EM INGLES, e esta lista existe porque o portao quase nasceu
## protegendo metade do produto.
##
## A primeira versao varria so os .tres, que estao em portugues. O marco "Um Livro" dizia
## "Voce ja escreveu um livro" e foi pego; a linha em ingles do mesmo marco dizia "You have
## written a book" e passou inteira. Regra de redacao que vale so no idioma de origem e
## regra que o jogador em ingles nunca ve cumprida.
const PROIBIDAS_EM_INGLES: Array[Dictionary] = [
	{"trecho": "you have written", "porque": "afirma autoria do jogador"},
	{"trecho": "you wrote", "porque": "idem, no passado simples"},
	{"trecho": "you've written", "porque": "idem, contraido"},
	{"trecho": "you composed", "porque": "sinonimo de autoria"},
	{"trecho": "you published", "porque": "autoria mais distribuicao"},
	{"trecho": "the monkey wrote", "porque": "a autoria pelo macaco e a mesma afirmacao"},
	{"trecho": "your monkeys wrote", "porque": "idem, no plural"},
]

const CSV := "res://i18n/textos.csv"


## O que o jogo diz NO LUGAR daquilo. Nao e portao: e o vocabulario que o proximo texto
## deve usar, escrito onde quem for escrever vai procurar.
const CONSTRUCOES_CERTAS: PackedStringArray = [
	"caracteres suficientes para",
	"o mesmo número de",
	"em caracteres",
	"o tamanho exato",
	"já daria para",
]


func _init() -> void:
	nome = "redacao do conteudo"


func executar() -> void:
	_nenhum_texto_afirma_autoria()
	_nem_em_ingles()
	_todo_marco_tem_tipo()
	_os_tres_tipos_sao_usados()
	_o_vocabulario_certo_existe()


## ⚠️ O PORTAO. Varre marco e descoberta, os dois, porque a regra e de redacao e nao de
## sistema.
func _nenhum_texto_afirma_autoria() -> void:
	var conferidos := 0
	for pasta in [PASTA_DE_MARCOS, PASTA_DE_DESCOBERTAS]:
		for caminho in _listar(pasta):
			var conteudo := _ler(caminho).to_lower()
			conferidos += 1
			for proibida in PROIBIDAS:
				ok(
					not conteudo.contains(str(proibida["trecho"])),
					"%s -- nao diz \"%s\" (%s)" % [
						caminho.get_file(), proibida["trecho"], proibida["porque"],
					],
				)

	# ⚠️ portao com zero verificacoes tem que REPROVAR: uma pasta renomeada deixaria o laco
	# inteiro sem rodar e a suite imprimiria "tudo certo" sem ter lido um arquivo
	ok(conferidos > 0, "houve texto para conferir (%d arquivos)" % conferidos)
	igual(
		conferidos, _listar(PASTA_DE_MARCOS).size() + _listar(PASTA_DE_DESCOBERTAS).size(),
		"e foram TODOS os arquivos das duas pastas",
	)


## ⚠️ E A REGRA VALE NAS DUAS LINGUAS. Varre a coluna `en` do CSV inteiro -- nao so a dos
## marcos, porque a regra e de redacao e qualquer texto do jogo pode quebra-la.
func _nem_em_ingles() -> void:
	var arquivo := FileAccess.open(CSV, FileAccess.READ)
	ok(arquivo != null, "o CSV abriu para a conferencia de redacao")
	if arquivo == null:
		return

	arquivo.get_csv_line()
	var conferidas := 0
	var quebradas := PackedStringArray()
	while not arquivo.eof_reached():
		var linha := arquivo.get_csv_line()
		if linha.size() < 3 or linha[2].is_empty():
			continue
		conferidas += 1
		var em_ingles := linha[2].to_lower()
		for proibida in PROIBIDAS_EM_INGLES:
			if em_ingles.contains(str(proibida["trecho"])):
				quebradas.append("\"%s\" em: %s" % [proibida["trecho"], linha[2]])
	arquivo.close()

	ok(
		quebradas.is_empty(),
		"nenhuma linha em ingles afirma autoria (%d quebradas: %s)" % [
			quebradas.size(), ", ".join(quebradas.slice(0, 2)),
		],
	)
	# ⚠️ zero linhas conferidas nao e aprovacao: CSV que nao abrisse passaria acima
	ok(conferidas > 0, "e houve o que conferir (%d linhas em ingles)" % conferidas)


## Todo marco declara um tipo valido. Campo ausente vira zero, e zero e QUANTITATIVO -- o
## neutro. O que esta linha pega e o arquivo que nem chegou a ser tocado.
func _todo_marco_tem_tipo() -> void:
	var quantos := 0
	for caminho in _listar(PASTA_DE_MARCOS):
		var conteudo := _ler(caminho)
		ok(conteudo.contains("tipo = "), "%s -- declara tipo" % caminho.get_file())
		var marco := ResourceLoader.load(caminho) as DadosMarco
		if marco == null:
			ok(false, "%s -- carrega como DadosMarco" % caminho.get_file())
			continue
		quantos += 1
		ok(
			marco.tipo >= 0 and marco.tipo <= DadosMarco.Tipo.CONCEITUAL,
			"%s -- o tipo esta na faixa do enum" % caminho.get_file(),
		)
	ok(quantos > 0, "houve marco para conferir (%d)" % quantos)


## ⚠️ OS TRES TIPOS SAO USADOS DE VERDADE. Sem esta linha, um campo em que todo marco
## ficasse QUANTITATIVO passaria em tudo acima -- e o eixo novo seria uma coluna morta que
## a tela desenha sempre igual.
##
## E os CONCEITUAIS sao o motivo da issue: eles preparam a transicao para o endgame, e
## precisam existir em quantidade que se perceba jogando.
func _os_tres_tipos_sao_usados() -> void:
	var por_tipo := {}
	for marco in Marcos.todos():
		por_tipo[marco.tipo] = int(por_tipo.get(marco.tipo, 0)) + 1

	for tipo in [
		DadosMarco.Tipo.QUANTITATIVO, DadosMarco.Tipo.HUMANO, DadosMarco.Tipo.CONCEITUAL
	]:
		ok(
			int(por_tipo.get(tipo, 0)) > 0,
			"o tipo %d e usado por algum marco (%d marcos)" % [tipo, por_tipo.get(tipo, 0)],
		)

	# ⚠️ E O ULTIMO MARCO DO JOGO E CONCEITUAL. O fecho do Panorama nao pode ser um numero:
	# ele e a frase que diz o que tudo aquilo era.
	var ultimo := Marcos.todos()[-1]
	igual(
		ultimo.tipo, DadosMarco.Tipo.CONCEITUAL,
		"o ultimo marco (%s) e conceitual" % ultimo.id,
	)

	# os conceituais moram no FIM: um "as comparacoes acabaram" no meio da primeira hora
	# seria o jogo desistindo antes de comecar
	var primeiro_conceitual := -1
	var todos := Marcos.todos()
	for i in todos.size():
		if todos[i].tipo == DadosMarco.Tipo.CONCEITUAL and primeiro_conceitual < 0:
			primeiro_conceitual = i
	ok(
		primeiro_conceitual > todos.size() / 2,
		"o primeiro conceitual (indice %d de %d) cai na metade final do Panorama" % [
			primeiro_conceitual, todos.size(),
		],
	)


## O vocabulario certo nao e portao -- e a metade positiva da regra. Se NENHUM texto usar a
## construcao correta, a lista de proibidas esta protegendo um vocabulario que ninguem usa.
func _o_vocabulario_certo_existe() -> void:
	var usos := 0
	for caminho in _listar(PASTA_DE_MARCOS):
		var conteudo := _ler(caminho).to_lower()
		for certa in CONSTRUCOES_CERTAS:
			if conteudo.contains(certa):
				usos += 1
				break
	ok(
		usos > 0,
		"o vocabulario de equivalencia e usado de verdade (%d marcos)" % usos,
	)


static func _ler(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	return arquivo.get_as_text() if arquivo != null else ""


static func _listar(pasta: String) -> PackedStringArray:
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
