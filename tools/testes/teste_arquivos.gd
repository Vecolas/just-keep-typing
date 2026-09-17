## Suite da tela de Arquivos (issue #40): excluir, e o nome que o jogador escreve.
##
## Duas afirmacoes valem por todas as outras, e as duas sao sobre coisas que nao tem
## desfazer:
##
##   ⚠️ EXCLUIR APAGA OS TRES ARQUIVOS DO SLOT -- e SO os dele. Deixar o .meta para tras
##   faria o cartao continuar na tela descrevendo uma partida que nao existe; deixar o
##   .backup ressuscitaria, na gravacao seguinte, exatamente o que o jogador mandou apagar.
##   E encostar no vizinho e apagar o save errado, que e a pior coisa que este jogo pode
##   fazer com alguem.
##
##   ⚠️ O NOME NUNCA VIRA CAMINHO DE ARQUIVO. O que o jogador digita vai para DENTRO do
##   save. Se um dia ele passar a compor o caminho, "../../opcoes" apaga o que ele nomear
##   -- e o sintoma nao e um erro, e um arquivo sumindo. Esta suite escreve um nome hostil
##   de proposito e afirma que o caminho do slot nao mudou uma letra.
##
## Escreve nos arquivos dela (Config.modelo_de_slot e Save.caminho sao variaveis para isso)
## e devolve tudo no fim.
extends TesteBase

const SLOT_DE_TESTE := "user://teste_arquivos_%d.json"

## Um nome que, num desenho errado, sairia do diretorio de saves. Nao e paranoia: o campo
## de nome e a unica entrada de texto livre do jogo inteiro.
const NOME_HOSTIL := "../../opcoes"

var _modelo_original: String = ""
var _save_original: String = ""
var _guardado: Dictionary = {}


func _init() -> void:
	nome = "arquivos"


func executar() -> void:
	_modelo_original = Config.modelo_de_slot
	_save_original = Save.caminho
	_guardado = _guardar_o_jogo()
	Config.modelo_de_slot = SLOT_DE_TESTE
	_limpar()

	_excluir_leva_os_tres_e_so_os_tres()
	_o_nome_nao_escolhe_o_caminho()
	_limpar_o_nome()
	_a_sugestao_evita_o_que_ja_existe()

	_limpar()
	Config.modelo_de_slot = _modelo_original
	Save.caminho = _save_original
	_devolver_o_jogo(_guardado)


## ⚠️ O PORTAO. Tres arquivos de um slot somem; os dos outros dois continuam inteiros.
func _excluir_leva_os_tres_e_so_os_tres() -> void:
	for numero in range(1, Config.SLOTS + 1):
		_gravar_no_slot(numero, Grande.de_float(100.0 * float(numero)))
		# a segunda gravacao e o que CRIA o backup: a primeira nao tem o que promover
		_gravar_no_slot(numero, Grande.de_float(200.0 * float(numero)))

	var alvo := Config.caminho_do_slot(2)
	for caminho in _os_tres_de(alvo):
		ok(FileAccess.file_exists(caminho), "antes de excluir, existe %s" % caminho)

	Save.apagar_arquivos(alvo)

	for caminho in _os_tres_de(alvo):
		ok(not FileAccess.file_exists(caminho), "excluir apagou %s" % caminho)
	ok(Config.manuscrito_do_slot(2).vazio(), "e o cartao do slot 2 volta a ser VAZIO")

	# o controle: sem ele, um apagar_arquivos que varresse a pasta inteira passaria em
	# tudo acima. Regua que so confere o que devia sumir nao mede o que devia FICAR.
	for vizinho in [1, 3]:
		for caminho in _os_tres_de(Config.caminho_do_slot(vizinho)):
			ok(FileAccess.file_exists(caminho), "e nao encostou em %s" % caminho)
		ok(Config.manuscrito_do_slot(vizinho).cheio(), "o slot %d continua cheio" % vizinho)


## ⚠️ O SEGUNDO PORTAO. O nome vai para dentro do save; o caminho vem do NUMERO do slot.
func _o_nome_nao_escolhe_o_caminho() -> void:
	var esperado := SLOT_DE_TESTE % 1
	igual(
		Config.caminho_do_slot(1), esperado,
		"o caminho do slot sai do modelo e do numero, e de mais nada",
	)

	Save.caminho = Config.caminho_do_slot(1)
	Jogo.nome = NOME_HOSTIL
	ok(Save.gravar(), "grava um Manuscrito com nome hostil")

	igual(
		Config.caminho_do_slot(1), esperado,
		"e o caminho do slot continua o mesmo depois de gravar",
	)
	ok(FileAccess.file_exists(esperado), "o save foi para o lugar dele")
	igual(
		Config.manuscrito_do_slot(1).nome, NOME_HOSTIL,
		"e o nome hostil e so texto dentro do arquivo",
	)
	ok(
		not FileAccess.file_exists("user://opcoes.json.tmp"),
		"nada foi escrito fora do caminho do slot",
	)

	# e a tela nunca deixaria esse nome entrar inteiro de qualquer forma
	ok(NomesDeManuscrito.cabe(NOME_HOSTIL), "o nome hostil cabe no limite -- nao e por ai que se barra")


## Corta o que desmonta o cartao, e nao o que o jogador quis dizer.
func _limpar_o_nome() -> void:
	igual(NomesDeManuscrito.limpar("  Hamlet  "), "Hamlet", "tira o espaco das pontas")
	igual(
		NomesDeManuscrito.limpar("Ato I\nAto II"), "Ato IAto II",
		"quebra de linha sai: ela nao aparece no cartao, ela o desmonta",
	)
	igual(NomesDeManuscrito.limpar(""), "", "vazio continua vazio -- e um estado legitimo")
	igual(
		NomesDeManuscrito.limpar("   ").length(), 0,
		"e so espaco tambem: o cartao se apresenta pelo numero do slot",
	)

	var comprido := "a".repeat(NomesDeManuscrito.LIMITE + 20)
	igual(
		NomesDeManuscrito.limpar(comprido).length(), NomesDeManuscrito.LIMITE,
		"nome comprido e cortado no limite",
	)
	ok(not NomesDeManuscrito.cabe(comprido), "⚠️ e cabe() RECUSA antes de cortar calado")
	ok(NomesDeManuscrito.cabe("Hamlet Talvez"), "e aceita o que cabe")
	ok(not NomesDeManuscrito.cabe("   "), "e recusa o que nao sobra nada")


## A sugestao e deterministica e nao repete o que ja esta em uso. Sem as duas, criar o
## terceiro Manuscrito proporia o nome do primeiro -- e duas capturas do mesmo commit
## dariam imagens diferentes.
func _a_sugestao_evita_o_que_ja_existe() -> void:
	var vazio := PackedStringArray()
	igual(
		NomesDeManuscrito.sugerir(1, vazio), NomesDeManuscrito.sugerir(1, vazio),
		"a mesma pergunta duas vezes da a mesma resposta",
	)
	ok(
		NomesDeManuscrito.sugerir(1, vazio) != NomesDeManuscrito.sugerir(2, vazio),
		"e dois cartoes nao propoem o mesmo nome",
	)

	var primeira := NomesDeManuscrito.sugerir(1, vazio)
	var em_uso := PackedStringArray([primeira])
	ok(
		NomesDeManuscrito.sugerir(1, em_uso) != primeira,
		"nome ja em uso nao e sugerido de novo",
	)

	# todas em uso nao pode devolver vazio: campo em branco sem motivo aparente
	var todas := PackedStringArray()
	for chave in NomesDeManuscrito.SUGESTOES:
		todas.append(tr(chave))
	ok(
		not NomesDeManuscrito.sugerir(2, todas).is_empty(),
		"com todas em uso ainda sai uma sugestao",
	)


# -------------------------------------------------------------------------------- apoio

## Os tres arquivos que um slot tem no disco: o save, o metadado dele e a copia de
## seguranca. O .meta do backup entra junto -- ele tambem e do slot, e orfao ele mente.
func _os_tres_de(caminho_do_save: String) -> PackedStringArray:
	return PackedStringArray([
		caminho_do_save,
		Manuscrito.caminho_do_meta(caminho_do_save),
		Save.caminho_do_backup(caminho_do_save),
	])


func _gravar_no_slot(numero: int, total: Grande) -> void:
	Save.caminho = Config.caminho_do_slot(numero)
	Jogo.total_caracteres = total
	Jogo.nome = "Manuscrito %d" % numero
	Save.gravar()


func _limpar() -> void:
	for numero in range(1, Config.SLOTS + 1):
		Save.apagar_arquivos(Config.caminho_do_slot(numero))


func _guardar_o_jogo() -> Dictionary:
	return {
		"total": Jogo.total_caracteres,
		"nome": Jogo.nome,
		"criado_em": Jogo.criado_em,
		"prestigios": Jogo.prestigios,
	}


func _devolver_o_jogo(guardado: Dictionary) -> void:
	Jogo.total_caracteres = guardado["total"]
	Jogo.nome = guardado["nome"]
	Jogo.criado_em = guardado["criado_em"]
	Jogo.prestigios = guardado["prestigios"]
