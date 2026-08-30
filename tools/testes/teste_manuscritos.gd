## Suite dos Manuscritos (issue #35): o metadado de cada slot, lido sem abrir partida.
##
## A afirmacao que vale mais que todas as outras juntas e a de que LER OS TRES SLOTS NAO
## MEXE NO JOGO. Se ler um Manuscrito aplicasse o save, desenhar o menu carregaria tres
## partidas -- e cada uma delas creditaria producao offline por cima da anterior, dando ao
## jogador tres vezes o que ele produziu enquanto estava fora, ou nenhuma.
##
## As outras duas sao sobre o metadado NAO ser fonte: save da v0.4 (sem .meta) e .meta
## corrompido tem que abrir a partida do mesmo jeito, reconstruindo o cartao a partir do
## save. Metadado que impedisse o save de carregar seria uma conveniencia de menu que
## apaga progresso.
##
## Escreve nos arquivos DELA (Config.modelo_de_slot e Save.caminho sao variaveis para
## isso) e devolve tudo no fim.
extends TesteBase

const SLOT_DE_TESTE := "user://teste_manuscrito_%d.json"

var _modelo_original: String = ""
var _save_original: String = ""
var _guardado: Dictionary = {}


func _init() -> void:
	nome = "Manuscritos"


func executar() -> void:
	_modelo_original = Config.modelo_de_slot
	_save_original = Save.caminho
	_guardado = _guardar_o_jogo()
	Config.modelo_de_slot = SLOT_DE_TESTE
	_limpar()

	_slot_vazio()
	_tres_slots_sem_abrir_partida()
	_a_era_vem_do_total()
	_nome_e_data_de_criacao()
	_save_da_v04_sem_meta()
	_meta_corrompido_nao_impede_carregar()
	_slot_ilegivel()
	_apagar_leva_o_meta_junto()

	_limpar()
	Config.modelo_de_slot = _modelo_original
	Save.caminho = _save_original
	_devolver_o_jogo(_guardado)


func _slot_vazio() -> void:
	var manuscrito := Config.manuscrito_do_slot(1)
	ok(manuscrito.vazio(), "slot sem arquivo e VAZIO")
	ok(not manuscrito.cheio() and not manuscrito.ilegivel(), "e so isso")
	igual(manuscrito.slot, 1, "e sabe de qual slot ele e")


## ⚠️ O portao. Tres slots lidos, zero partidas abertas.
func _tres_slots_sem_abrir_partida() -> void:
	for numero in range(1, Config.SLOTS + 1):
		_gravar_no_slot(numero, Grande.new(1.5, 10 * numero), 7 * numero, "Manuscrito %d" % numero)

	# o estado sentinela: se ler metadado carregar alguma coisa, ele nao sobrevive
	Jogo.total_caracteres = Grande.new(4.2, 777)
	Jogo.prestigios = 12345
	Jogo.nome = "sentinela"

	var lidos: Array[Manuscrito] = []
	for numero in range(1, Config.SLOTS + 1):
		lidos.append(Config.manuscrito_do_slot(numero))

	igual(lidos.size(), Config.SLOTS, "leu um Manuscrito por slot")
	for i in lidos.size():
		var manuscrito := lidos[i]
		var numero := i + 1
		ok(manuscrito.cheio(), "slot %d esta CHEIO" % numero)
		igual(manuscrito.nome, "Manuscrito %d" % numero, "slot %d -- o nome veio" % numero)
		igual(
			manuscrito.total_caracteres.para_texto(), Grande.new(1.5, 10 * numero).para_texto(),
			"slot %d -- o total veio exato" % numero,
		)
		igual(manuscrito.prestigios, 7 * numero, "slot %d -- os prestigios vieram" % numero)
		ok(manuscrito.ultima_sessao > 0.0, "slot %d -- e a ultima sessao tem data" % numero)

	igual(
		Jogo.total_caracteres.para_texto(), Grande.new(4.2, 777).para_texto(),
		"⚠️ ler os tres metadados NAO abriu partida nenhuma",
	)
	igual(Jogo.prestigios, 12345, "e nao encostou nos prestigios")
	igual(Jogo.nome, "sentinela", "nem no nome")


## A era e derivada do total, e pelo mesmo catalogo que a cena usa -- duas copias da regra
## fariam o menu dizer uma era e a partida desenhar outra.
func _a_era_vem_do_total() -> void:
	var primeira := ErasCatalogo.da_producao(Grande.zero())
	var ultima := ErasCatalogo.da_producao(Grande.new(1.0, 5000))
	ok(primeira != null and ultima != null, "o catalogo de eras respondeu")
	ok(primeira.numero < ultima.numero, "e producao maior cai numa era mais avancada")

	_gravar_no_slot(1, Grande.zero(), 0, "no comeco")
	igual(Config.manuscrito_do_slot(1).era, primeira.id, "o metadado guarda a era do comeco")

	_gravar_no_slot(1, Grande.new(1.0, 5000), 0, "no fim")
	igual(Config.manuscrito_do_slot(1).era, ultima.id, "e a era do endgame quando o total sobe")

	# id e nao nome: nome e texto que muda de idioma, e o .meta atravessa as duas linguas
	ok(ErasCatalogo.por_id(ultima.id) == ultima, "o id do metadado acha a era de volta")


## O nome e a data de criacao moram no SAVE. Se vivessem so no .meta, apagar o metadado
## apagaria o nome escolhido pelo jogador sem ninguem ver.
func _nome_e_data_de_criacao() -> void:
	Save.caminho = Config.caminho_do_slot(1)
	Save.apagar()

	Jogo.nome = "O Primeiro Rascunho"
	Jogo.criado_em = 0.0
	ok(Save.gravar(), "grava um Manuscrito novo")
	var nascimento := Jogo.criado_em
	ok(nascimento > 0.0, "a primeira gravacao carimba a data de criacao")

	Jogo.total_caracteres = Grande.de_float(999.0)
	ok(Save.gravar(), "grava de novo")
	perto(Jogo.criado_em, nascimento, 0.0, "e a data de criacao NAO muda na segunda")

	Jogo.nome = ""
	Jogo.criado_em = 0.0
	Save.carregar()
	igual(Jogo.nome, "O Primeiro Rascunho", "o nome sobreviveu a ida e volta pelo save")
	perto(Jogo.criado_em, nascimento, 0.0, "e a data de criacao tambem")

	var manuscrito := Config.manuscrito_do_slot(1)
	igual(manuscrito.nome, "O Primeiro Rascunho", "e o metadado diz o mesmo nome")
	perto(manuscrito.criado_em, nascimento, 0.0, "e a mesma data")


## Save gravado antes desta issue: sem .meta, sem nome, sem data de criacao. Ele abre, e
## ganha o metadado na gravacao seguinte -- o jogador nao ve diferenca nenhuma.
func _save_da_v04_sem_meta() -> void:
	var caminho := Config.caminho_do_slot(2)
	Save.caminho = caminho
	Save.apagar()
	_escrever(caminho, JSON.stringify({
		"versao": 9,
		"gravado_em": 1700000000.0,
		"total_caracteres": "3.5e42",
		"caracteres_da_run": "3.5e42",
		"macacos": "88",
		"tempo_jogado": 7200.0,
		"prestigios": 4,
	}))
	ok(
		not FileAccess.file_exists(Manuscrito.caminho_do_meta(caminho)),
		"o save da v0.4 nao tem .meta",
	)

	var manuscrito := Config.manuscrito_do_slot(2)
	ok(manuscrito.cheio(), "e mesmo assim o slot aparece CHEIO no menu")
	igual(
		manuscrito.total_caracteres.para_texto(), Grande.new(3.5, 42).para_texto(),
		"com o total lido do proprio save",
	)
	igual(manuscrito.prestigios, 4, "e os prestigios")
	perto(manuscrito.tempo_jogado, 7200.0, 0.0, "e o tempo jogado")
	perto(manuscrito.ultima_sessao, 1700000000.0, 0.0, "a ultima sessao e o gravado_em")
	igual(manuscrito.nome, "", "sem nome, porque a v0.4 nao tinha onde guardar um")
	ok(not manuscrito.era.is_empty(), "e a era foi calculada do total")

	# abrir e gravar de volta cria o metadado, ja na versao nova
	Save.carregar()
	igual(
		Jogo.total_caracteres.para_texto(), Grande.new(3.5, 42).para_texto(),
		"o save antigo carregou inteiro",
	)
	ok(Save.gravar(), "e a gravacao seguinte")
	ok(
		FileAccess.file_exists(Manuscrito.caminho_do_meta(caminho)),
		"escreveu o .meta que faltava",
	)
	igual(
		Config.manuscrito_do_slot(2).total_caracteres.para_texto(), Grande.new(3.5, 42).para_texto(),
		"e o metadado novo concorda com o save",
	)


## Metadado e conveniencia, e conveniencia quebrada nao pode custar uma partida.
func _meta_corrompido_nao_impede_carregar() -> void:
	var caminho := Config.caminho_do_slot(3)
	Save.caminho = caminho
	Save.apagar()
	Jogo.total_caracteres = Grande.new(6.25, 120)
	Jogo.macacos = Grande.de_float(31.0)
	Jogo.prestigios = 9
	ok(Save.gravar(), "grava um slot bom")

	print("    (as linhas ERROR de JSON abaixo sao de proposito -- .meta corrompido sob teste)")
	_escrever(Manuscrito.caminho_do_meta(caminho), "{isto nao e JSON")

	var manuscrito := Config.manuscrito_do_slot(3)
	ok(manuscrito.cheio(), "com o .meta corrompido o slot continua CHEIO")
	igual(
		manuscrito.total_caracteres.para_texto(), Grande.new(6.25, 120).para_texto(),
		"porque o cartao foi reconstruido do save, que e a fonte",
	)
	igual(manuscrito.prestigios, 9, "e os prestigios vieram de la tambem")

	Jogo.total_caracteres = Grande.zero()
	Jogo.macacos = Grande.zero()
	Save.carregar()
	igual(
		Jogo.total_caracteres.para_texto(), Grande.new(6.25, 120).para_texto(),
		"⚠️ e a partida carrega inteira, apesar do metadado quebrado",
	)
	igual(Jogo.macacos.para_texto(), Grande.de_float(31.0).para_texto(), "com os macacos")

	# e a gravacao seguinte conserta o metadado, sem ninguem pedir
	ok(Save.gravar(), "grava de novo")
	igual(
		Config.manuscrito_do_slot(3).total_caracteres.para_texto(), Grande.new(6.25, 120).para_texto(),
		"o .meta quebrado foi reescrito certo",
	)


## ⚠️ Ilegivel nao e vazio. Tratar os dois igual ofereceria "comecar aqui" em cima de
## centenas de horas que so estao dificeis de ler.
func _slot_ilegivel() -> void:
	var caminho := Config.caminho_do_slot(1)
	Save.caminho = caminho
	Save.apagar()
	print("    (a linha ERROR de JSON abaixo e de proposito -- save ilegivel sob teste)")
	_escrever(caminho, "isto nao e um save")

	var manuscrito := Config.manuscrito_do_slot(1)
	ok(manuscrito.ilegivel(), "save que nao abre e ILEGIVEL")
	ok(not manuscrito.vazio(), "⚠️ e NAO vazio -- o arquivo esta la")
	ok(not manuscrito.cheio(), "e nao cheio -- nao ha o que mostrar")


func _apagar_leva_o_meta_junto() -> void:
	var caminho := Config.caminho_do_slot(1)
	Save.caminho = caminho
	Jogo.total_caracteres = Grande.de_float(500.0)
	ok(Save.gravar(), "grava para depois apagar")
	ok(FileAccess.file_exists(Manuscrito.caminho_do_meta(caminho)), "o .meta existe")

	Save.apagar()
	ok(not FileAccess.file_exists(caminho), "o save foi apagado")
	ok(
		not FileAccess.file_exists(Manuscrito.caminho_do_meta(caminho)),
		"e o .meta foi junto -- orfao faria o menu listar o que nao existe",
	)
	ok(Config.manuscrito_do_slot(1).vazio(), "e o slot volta a ser VAZIO")


# ------------------------------------------------------------------------------ apoio

func _gravar_no_slot(numero: int, total: Grande, prestigios: int, nome_do_slot: String) -> void:
	Save.caminho = Config.caminho_do_slot(numero)
	Jogo.total_caracteres = total
	Jogo.prestigios = prestigios
	Jogo.nome = nome_do_slot
	Jogo.criado_em = 0.0
	Save.gravar()


static func _escrever(caminho: String, conteudo: String) -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		return
	arquivo.store_string(conteudo)
	arquivo.close()


func _limpar() -> void:
	for numero in range(1, Config.SLOTS + 1):
		var caminho := Config.caminho_do_slot(numero)
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)
		Manuscrito.apagar_de(caminho)


func _guardar_o_jogo() -> Dictionary:
	return {
		"nome": Jogo.nome,
		"criado_em": Jogo.criado_em,
		"total_caracteres": Jogo.total_caracteres,
		"caracteres_da_run": Jogo.caracteres_da_run,
		"caracteres_por_segundo": Jogo.caracteres_por_segundo,
		"macacos": Jogo.macacos,
		"prestigios": Jogo.prestigios,
		"tempo_jogado": Jogo.tempo_jogado,
		"upgrades_comprados": Jogo.upgrades_comprados.duplicate(),
		"marcos_alcancados": Jogo.marcos_alcancados.duplicate(),
		"descobertas": Jogo.descobertas.duplicate(),
	}


func _devolver_o_jogo(guardado: Dictionary) -> void:
	Jogo.nome = guardado["nome"]
	Jogo.criado_em = guardado["criado_em"]
	Jogo.total_caracteres = guardado["total_caracteres"]
	Jogo.caracteres_da_run = guardado["caracteres_da_run"]
	Jogo.caracteres_por_segundo = guardado["caracteres_por_segundo"]
	Jogo.macacos = guardado["macacos"]
	Jogo.prestigios = guardado["prestigios"]
	Jogo.tempo_jogado = guardado["tempo_jogado"]
	Jogo.upgrades_comprados = guardado["upgrades_comprados"]
	Jogo.marcos_alcancados = guardado["marcos_alcancados"]
	Jogo.descobertas = guardado["descobertas"]
