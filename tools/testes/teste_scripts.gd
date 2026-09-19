## Suite zero: todo .gd de src/ E DE tools/ tem que carregar e instanciar.
##
## Existe por causa do falso verde: rodar o jogo so carrega o que a cena principal
## alcanca, entao um script quebrado em src/ sem referencia na cena passa com exit 0
## e zero diagnosticos. Enquanto o jogo tiver pouca coisa ligada na cena -- que e agora --
## esta suite e praticamente a unica coisa que enxerga esse codigo.
##
## ⚠️ E `tools/` ENTROU DEPOIS, PORQUE FALTAVA. As reguas e as capturas leem constantes do
## jogo -- `preload("res://src/ui/hud.gd").PERTO_O_BASTANTE` e o caso tipico --, e uma
## constante que muda de casa quebra a regua sem quebrar nada que a suite olhasse. Foi o que
## aconteceu: a reforma da interface moveu o limiar de alcance para outra classe, as 7 mil
## afirmacoes ficaram verdes, e `observar.gd` so falhou quando alguem o rodou a mao.
##
## ⚠️ E ISSO E O PIOR TIPO DE QUEBRA, porque regua nao e rodada toda hora: ela e rodada no dia
## em que alguem precisa decidir um numero. O conserto chegaria no pior momento possivel.
##
## Os `.tscn` de tools/ nao sao montados aqui -- so os scripts sao carregados. O que esta
## suite prova e "compila", e nao "funciona": quem prova que a regua mede e roda-la.
##
## can_instantiate() e o detector confiavel. Os dois jeitos obvios nao servem:
## load() nunca devolve null em script com erro de parse (os erros so vao para o stderr),
## e reload() devolve 22 (ERR_UNAVAILABLE) em qualquer script com instancia viva, o que
## inclui todo autoload. Ver CONVENCOES.md, "A armadilha do falso verde".
extends TesteBase

const RAIZES: PackedStringArray = ["res://src", "res://tools"]

## ⚠️ A PASTA DAS PROPRIAS SUITES FICA DE FORA, e isso nao e ponto cego: elas sao carregadas e
## EXECUTADAS pelo runner alguns milissegundos depois, entao uma suite quebrada reprova por si
## -- com mais informacao do que esta linha daria.
##
## E carrega-las aqui trava: `runner.gd` esta em execucao neste instante, e recarrega-lo com
## CACHE_MODE_IGNORE poe a engine para reabrir o script que a esta chamando. A suite nao deu
## erro; ela parou de terminar.
const SEM_VARRER: PackedStringArray = ["res://tools/testes"]

func _init() -> void:
	nome = "scripts compilam"


func executar() -> void:
	for raiz in RAIZES:
		var caminhos := _listar_gd(raiz)
		ok(not caminhos.is_empty(), "encontrou algum .gd em %s" % raiz)
		for caminho in caminhos:
			var recurso := ResourceLoader.load(
				caminho, "Script", ResourceLoader.CACHE_MODE_IGNORE
			)
			var script := recurso as Script
			ok(script != null and script.can_instantiate(), "%s compila" % caminho)


func _listar_gd(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		return achados
	if pasta in SEM_VARRER:
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		var caminho := pasta.path_join(item)
		if dir.current_is_dir():
			achados.append_array(_listar_gd(caminho))
		elif item.ends_with(".gd"):
			achados.append(caminho)
		item = dir.get_next()
	dir.list_dir_end()
	return achados
