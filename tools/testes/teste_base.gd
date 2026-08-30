## Base de toda suite unitaria. Nao e framework: sao quatro afirmacoes e um contador.
##
## Framework de teste em projeto solo custa mais do que ganha -- o que importa e que
## a falha diga o esperado e o obtido sem ninguem precisar abrir o teste para entender.
## Suite nova herda daqui, implementa executar() e entra em SUITES no runner.gd.
class_name TesteBase
extends RefCounted

## Nome que aparece na saida do runner. Cada suite ajusta no _init().
var nome: String = "suite sem nome"

var _falhas: PackedStringArray = PackedStringArray()
var _afirmacoes: int = 0

## Ponto de entrada da suite. Sobrescreva.
func executar() -> void:
	push_error("%s nao implementou executar()" % nome)


func ok(condicao: bool, descricao: String) -> void:
	_afirmacoes += 1
	if not condicao:
		_falhas.append("%s -- esperado verdadeiro, obtido falso" % descricao)


func igual(obtido: Variant, esperado: Variant, descricao: String) -> void:
	_afirmacoes += 1
	if obtido != esperado:
		_falhas.append("%s -- esperado %s, obtido %s" % [descricao, esperado, obtido])


func perto(obtido: float, esperado: float, tolerancia: float, descricao: String) -> void:
	_afirmacoes += 1
	if absf(obtido - esperado) > tolerancia:
		_falhas.append("%s -- esperado %s +- %s, obtido %s" % [
			descricao, esperado, tolerancia, obtido,
		])


func entre(obtido: float, minimo: float, maximo: float, descricao: String) -> void:
	_afirmacoes += 1
	if obtido < minimo or obtido > maximo:
		_falhas.append("%s -- esperado entre %s e %s, obtido %s" % [
			descricao, minimo, maximo, obtido,
		])


func falhas() -> PackedStringArray:
	return _falhas


func afirmacoes() -> int:
	return _afirmacoes
