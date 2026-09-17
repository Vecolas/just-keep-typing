## Os dois portoes de idioma da CONVENCOES.md. Fecha o que a v0.1 e a v0.2 acumularam.
##
## PORTAO 1 -- TEXTO SEM LINHA NO CSV. O bug que ele pega nao quebra nada e nao imprime
## erro: a frase simplesmente aparece em portugues no meio de uma interface em ingles, e
## some sozinha na proxima vez que alguem mexe naquele rotulo. E por isso que ele e portao
## e nao recomendacao -- ninguem descobre isso jogando em portugues.
##
## Varre as tres origens de texto que existem no projeto:
##
##   .tscn de src/   o text de cada Control, menos os marcados como nao traduziveis
##   .tres de data/  nome, descricao, titulo e texto de todo dado
##   .gd de src/     todo tr("...") e todo _traduzir("...") com literal dentro
##
## PORTAO 2 -- TELA QUE FORMATA SEM ESCUTAR. Arquivo de src/ que escreve num .text usando
## Formatador ou tr() com % tem que conectar EventBus.idioma_mudou. O Godot retraduz
## sozinho apenas o text que veio da CENA; o que foi montado em codigo fica exatamente
## como estava ate outra coisa mexer nele.
##
## ⚠️ Caractere nao e pixel: texto que estoura botao em ingles nao aparece aqui. Isso e
## assunto de captura, e por isso a issue #23 pede uma captura em en.
extends TesteBase

const CSV := "res://i18n/textos.csv"
const RAIZ_CODIGO := "res://src"
const RAIZ_DADOS := "res://data"

## Campos de .tres que o jogador le. Nota nao entra: ela e nota de rodape para quem
## balanceia, e nao texto de jogo.
const CAMPOS_DE_TEXTO: PackedStringArray = ["nome", "descricao", "titulo", "texto"]

## Marca de formato nao e texto: nao passa por traducao e nao precisa de linha no CSV.
## A lista e explicita de proposito -- "esqueci de traduzir" e "isto nao se traduz" se
## parecem demais para ficarem implicitos.
const SEM_TRADUCAO: PackedStringArray = [
	"×", "10^", "e", "? ? ?", "+%s", "%s — %s", "%s  x%s", "%s  %s", "x%s",
	"%02d:%02d:%02d", "0", "1", "",
]

var _chaves: Dictionary = {}

func _init() -> void:
	nome = "portao de texto"


func executar() -> void:
	_chaves = _ler_csv()
	ok(not _chaves.is_empty(), "o CSV de traducao foi lido")
	_coluna_en_preenchida()
	_texto_das_cenas()
	_texto_dos_dados()
	_texto_do_codigo()
	_moldes_em_constante()
	_telas_escutam_idioma()
	_a_traducao_traduz()


## Chave sem coluna en e chave que so existe em portugues, e a tela em ingles mostra o
## portugues sem avisar ninguem.
func _coluna_en_preenchida() -> void:
	var vazias := PackedStringArray()
	for chave in _chaves:
		if str(_chaves[chave]).strip_edges().is_empty():
			vazias.append(chave)
	ok(vazias.is_empty(), "toda linha do CSV tem a coluna en preenchida (%d vazias: %s)" % [
		vazias.size(), ", ".join(vazias.slice(0, 3)),
	])


func _texto_das_cenas() -> void:
	for caminho in _listar(RAIZ_CODIGO, ".tscn"):
		var conteudo := _ler(caminho)
		for bloco in conteudo.split("[node "):
			# auto_translate_mode = 2 e DISABLED: o autor disse que aquilo nao e texto
			if bloco.contains("auto_translate_mode = 2"):
				continue
			for texto in _textos_de(bloco, "text = \""):
				_exigir(texto, caminho)


func _texto_dos_dados() -> void:
	for caminho in _listar(RAIZ_DADOS, ".tres"):
		var conteudo := _ler(caminho)
		for campo in CAMPOS_DE_TEXTO:
			for texto in _textos_de(conteudo, campo + " = \""):
				_exigir(texto, caminho)


## ⚠️ DUAS CHAMADAS, E NAO UMA. Classe estatica nao tem self e por isso nao tem tr(): o
## Formatador e o Relogio traduzem por _traduzir(), que e o mesmo TranslationServer por
## baixo. Varrer so `tr("` deixaria todo literal de classe estatica fora da conta deste
## portao -- e fora da conta e exatamente onde o texto sem linha no CSV se esconde.
func _texto_do_codigo() -> void:
	for caminho in _listar(RAIZ_CODIGO, ".gd"):
		var conteudo := _ler(caminho)
		for texto in _textos_de(conteudo, "tr(\""):
			_exigir(texto, caminho)
		for texto in _textos_de(conteudo, "_traduzir(\""):
			_exigir(texto, caminho)


## O PONTO CEGO QUE SOBRA, e por isso ele e cobrado pela FONTE e nao pela varredura.
##
## Texto que mora numa constante -- "%s mil", "Hamlet Talvez" -- chega ao jogador por uma
## VARIAVEL, e nenhuma varredura de literal alcanca variavel. Estas duas tabelas sao lidas
## direto da fonte: tabela nova entra nesta lista junto, e o dia em que alguem acrescentar
## "%s trilhoes" ou um nome tematico novo sem traduzir, o portao morde.
##
## ⚠️ E A LISTA E DIVIDA DECLARADA: constante de texto que NAO estiver aqui nao e cobrada
## por ninguem. Ao criar uma, acrescente a linha -- ou o texto dela some do CSV em silencio,
## que e a familia de bug que este arquivo inteiro existe para pegar.
func _moldes_em_constante() -> void:
	for escala in Formatador.ESCALAS:
		_exigir(str(escala["singular"]), "Formatador.ESCALAS")
		_exigir(str(escala["plural"]), "Formatador.ESCALAS")
	ok(
		not NomesDeManuscrito.SUGESTOES.is_empty(),
		"ha nome tematico sugerido para Manuscrito novo",
	)
	for sugestao in NomesDeManuscrito.SUGESTOES:
		_exigir(sugestao, "NomesDeManuscrito.SUGESTOES")
		# ⚠️ E A PIADA TEM QUE SOBREVIVER AO INGLES. Nome tematico com a coluna en igual a
		# pt nao e traducao: e a linha que alguem preencheu copiando, e o jogo em ingles
		# passa a ter um "Operação Banana" no meio de uma tela em ingles.
		ok(
			str(_chaves.get(sugestao, "")) != sugestao,
			"%s tem versao propria em ingles, e nao uma copia do portugues" % sugestao,
		)


## O segundo portao. Quem escreve num .text usando Formatador ou tr() precisa escutar
## idioma_mudou -- senao o rotulo montado em codigo sobrevive a troca de lingua.
func _telas_escutam_idioma() -> void:
	for caminho in _listar(RAIZ_CODIGO, ".gd"):
		var conteudo := _ler(caminho)
		var monta_texto := (
			conteudo.contains(".text = ")
			and (conteudo.contains("Formatador.formatar") or conteudo.contains("tr("))
		)
		if not monta_texto:
			continue
		ok(
			conteudo.contains("EventBus.idioma_mudou"),
			"%s monta texto em codigo e escuta EventBus.idioma_mudou" % caminho,
		)


## A prova de que as traducoes estao REGISTRADAS no project.godot, e nao so escritas no
## CSV. Sem o registro, tr() devolve a chave e o jogo fica em portugues em qualquer lingua
## -- sem quebrar nada e sem imprimir erro, que e a assinatura desta familia de bug.
func _a_traducao_traduz() -> void:
	var locale_original := TranslationServer.get_locale()

	TranslationServer.set_locale("en")
	igual(tr("Comprar 1"), "Buy 1", "com locale en, o botao da loja fala ingles")
	igual(tr("PANORAMA"), "PANORAMA", "chave igual nas duas linguas continua igual")
	igual(
		tr("Um Livro"), "One Book",
		"e o titulo de marco tambem -- .tres passa pela mesma tabela que a cena",
	)

	TranslationServer.set_locale("pt_BR")
	igual(tr("Comprar 1"), "Comprar 1", "e em pt_BR a chave E o texto")

	TranslationServer.set_locale(locale_original)
	igual(TranslationServer.get_locale(), locale_original, "a suite devolveu o locale")


func _exigir(texto: String, caminho: String) -> void:
	var limpo := texto.strip_edges()
	if limpo.is_empty() or limpo in SEM_TRADUCAO:
		return
	# marca de formato pura -- so %s, numero e pontuacao -- nao e frase
	if limpo.replace("%s", "").replace("%d", "").strip_edges().length() <= 1:
		return
	ok(_chaves.has(limpo), "%s -- \"%s\" tem linha no CSV" % [caminho, limpo])


## Pega os literais entre aspas depois de um prefixo. Nao e um parser: e uma varredura, e
## e o bastante porque texto de interface deste projeto nao tem aspas dentro.
static func _textos_de(conteudo: String, prefixo: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var de := conteudo.find(prefixo)
	while de >= 0:
		var inicio := de + prefixo.length()
		var fim := conteudo.find("\"", inicio)
		if fim < 0:
			break
		achados.append(conteudo.substr(inicio, fim - inicio))
		de = conteudo.find(prefixo, fim)
	return achados


static func _ler(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	return arquivo.get_as_text() if arquivo != null else ""


func _ler_csv() -> Dictionary:
	var chaves := {}
	var arquivo := FileAccess.open(CSV, FileAccess.READ)
	if arquivo == null:
		return chaves
	arquivo.get_csv_line()
	while not arquivo.eof_reached():
		var linha := arquivo.get_csv_line()
		if linha.size() >= 3 and not linha[0].is_empty():
			chaves[linha[0]] = linha[2]
	arquivo.close()
	return chaves


static func _listar(pasta: String, extensao: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		var caminho := pasta.path_join(item)
		if dir.current_is_dir():
			achados.append_array(_listar(caminho, extensao))
		elif item.ends_with(extensao):
			achados.append(caminho)
		item = dir.get_next()
	dir.list_dir_end()
	return achados
