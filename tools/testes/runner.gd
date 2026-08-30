## Runner das suites unitarias. Roda headless em segundos e imprime PASSOU ou FALHOU.
##
##   godot --headless --path . tools/testes/runner.tscn
##
## Fixa o locale em pt_BR e devolve o original no fim: as opcoes moram em
## user://opcoes.json, que e da INSTALACAO, entao sem isso a suite rodaria no idioma
## em que o jogo foi deixado -- uma volta na tela de opcoes e as asserções de texto
## quebrariam sem nada ter mudado no codigo. Portugues porque a chave da tabela de
## traducao E o texto em portugues.
extends Node

const SUITES: Array = [
	preload("res://tools/testes/teste_scripts.gd"),
	preload("res://tools/testes/teste_grande.gd"),
]

func _ready() -> void:
	var locale_original := TranslationServer.get_locale()
	TranslationServer.set_locale("pt_BR")

	var total := 0
	var falhas := PackedStringArray()
	for suite_script in SUITES:
		var suite: TesteBase = suite_script.new()
		suite.executar()
		total += suite.afirmacoes()
		for falha in suite.falhas():
			falhas.append("%s: %s" % [suite.nome, falha])
		print("  %-32s %3d afirmacoes, %d falhas" % [
			suite.nome, suite.afirmacoes(), suite.falhas().size(),
		])

	TranslationServer.set_locale(locale_original)

	if falhas.is_empty():
		print("PASSOU (%d afirmacoes em %d suites)" % [total, SUITES.size()])
		_sair(0)
		return

	for falha in falhas:
		printerr("FALHA  %s" % falha)
	print("FALHOU (%d falhas em %d afirmacoes)" % [falhas.size(), total])
	_sair(1)


func _sair(codigo: int) -> void:
	get_tree().quit(codigo)
