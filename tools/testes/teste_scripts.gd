## Suite zero: todo .gd de src/ tem que carregar e instanciar.
##
## Existe por causa do falso verde: rodar o jogo so carrega o que a cena principal
## alcanca, entao um script quebrado em src/ sem referencia na cena passa com exit 0
## e zero diagnosticos. Enquanto o jogo tiver pouca coisa ligada na cena -- que e agora --
## esta suite e praticamente a unica coisa que enxerga esse codigo.
##
## can_instantiate() e o detector confiavel. Os dois jeitos obvios nao servem:
## load() nunca devolve null em script com erro de parse (os erros so vao para o stderr),
## e reload() devolve 22 (ERR_UNAVAILABLE) em qualquer script com instancia viva, o que
## inclui todo autoload. Ver CONVENCOES.md, "A armadilha do falso verde".
extends TesteBase

const RAIZ := "res://src"

func _init() -> void:
	nome = "scripts de src/ compilam"


func executar() -> void:
	var caminhos := _listar_gd(RAIZ)
	ok(not caminhos.is_empty(), "encontrou algum .gd em %s" % RAIZ)
	for caminho in caminhos:
		var recurso := ResourceLoader.load(caminho, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		var script := recurso as Script
		ok(script != null and script.can_instantiate(), "%s compila" % caminho)


func _listar_gd(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
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
