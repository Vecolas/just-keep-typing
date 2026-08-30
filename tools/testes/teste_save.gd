## Suite do Save: gravar, carregar, migrar e nao corromper.
##
## Grava num arquivo PROPRIO (user://teste_save.json) e apaga no fim. Sem isso a suite
## sobrescreveria a partida de quem esta desenvolvendo toda vez que rodasse -- e o save
## e o unico arquivo do projeto cujo estrago nao da para desfazer com git.
##
## As duas afirmacoes que a issue pede:
##
##   gravar -> carregar -> estado identico
##   save de versao anterior migra sem perder progresso
##
## A primeira e exata, e nao aproximada: o save guarda Grande como texto justamente para a
## ida e volta nao perder digito (decisao 0001). Aproximado aqui seria aceitar que o
## jogador perde um pedaco do progresso a cada vez que fecha o jogo.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_save.json"

func _init() -> void:
	nome = "Save"


func executar() -> void:
	var guardado := _guardar_o_jogo()
	var caminho_original := Save.caminho
	Save.caminho = CAMINHO_DE_TESTE
	Save.apagar()

	_partida_nova()
	_ida_e_volta()
	_migracao()
	_recusa_versao_do_futuro()
	_temporario_nao_sobra()

	Save.apagar()
	Save.caminho = caminho_original
	_devolver_o_jogo(guardado)
	ok(Jogo.macacos == guardado["macacos"], "a suite devolveu o estado do Jogo")


func _partida_nova() -> void:
	ok(not Save.existe(), "sem arquivo, nao existe save")
	perto(Save.carregar(), 0.0, 0.0, "carregar sem save devolve 0 e nao explode")


func _ida_e_volta() -> void:
	# numeros que nao caberiam em float, de proposito: e o caso que o save existe para
	# aguentar, e o unico jeito de pegar alguem trocando Grande por float aqui
	Jogo.total_caracteres = Grande.new(5.28, 4321)
	Jogo.caracteres_da_run = Grande.new(1.25, 12)
	Jogo.dinheiro = Grande.new(9.87654321, 140)
	Jogo.macacos = Grande.de_float(1234.0)
	Jogo.maquina_atual = "maquina_eletrica"
	Jogo.pontos_de_teorema = Grande.new(3.5, 8)
	Jogo.fragmentos = Grande.zero()
	Jogo.multiplicador_global = 2.75
	Jogo.tempo_jogado = 3661.5
	Jogo.upgrades_comprados = ["instinto_digitador", "dedos_mais_ageis"] as Array[String]
	Jogo.marcos_alcancados = ["primeira_palavra"] as Array[String]

	ok(Save.gravar(), "gravou")
	ok(Save.existe(), "e o arquivo esta la")

	# suja tudo antes de carregar: se carregar nao escrever, o teste passa por acidente
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.zero()
	Jogo.maquina_atual = ""
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.fragmentos = Grande.de_float(999.0)
	Jogo.multiplicador_global = 1.0
	Jogo.tempo_jogado = 0.0
	Jogo.upgrades_comprados = [] as Array[String]
	Jogo.marcos_alcancados = [] as Array[String]

	var gravado_em := Save.carregar()
	ok(gravado_em > 0.0, "carregar devolve o timestamp da gravacao")

	# exato, digito a digito: o Grande vai como texto para a ida e volta nao perder nada
	_exato(Jogo.total_caracteres, Grande.new(5.28, 4321), "total de caracteres")
	_exato(Jogo.caracteres_da_run, Grande.new(1.25, 12), "caracteres da run")
	_exato(Jogo.dinheiro, Grande.new(9.87654321, 140), "dinheiro")
	_exato(Jogo.macacos, Grande.de_float(1234.0), "macacos")
	igual(Jogo.maquina_atual, "maquina_eletrica", "o tier de maquina voltou")
	_exato(Jogo.pontos_de_teorema, Grande.new(3.5, 8), "pontos de teorema")
	ok(Jogo.fragmentos.e_zero(), "fragmentos zerados continuam zerados")
	perto(Jogo.multiplicador_global, 2.75, 0.0, "multiplicador global")
	perto(Jogo.tempo_jogado, 3661.5, 0.0, "tempo jogado")
	igual(Jogo.upgrades_comprados.size(), 2, "os dois upgrades voltaram")
	ok(Jogo.upgrades_comprados.has("dedos_mais_ageis"), "e com os ids certos")
	igual(Jogo.marcos_alcancados.size(), 1, "o marco alcancado voltou")


## Save escrito a mao, sem versao e sem metade dos campos -- e o formato de um jogo mais
## antigo. Tem que carregar o que existe e preencher o resto, nunca zerar o que veio.
func _migracao() -> void:
	var antigo := {
		"total_caracteres": "7.5e30",
		"caracteres_da_run": "7.5e30",
		"macacos": "42",
		"upgrades_comprados": ["instinto_digitador"],
	}
	var arquivo := FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(antigo))
	arquivo.close()

	Jogo.total_caracteres = Grande.zero()
	Jogo.macacos = Grande.zero()
	Jogo.multiplicador_global = 99.0
	Jogo.upgrades_comprados = [] as Array[String]

	Save.carregar()
	_exato(Jogo.total_caracteres, Grande.new(7.5, 30), "o progresso do save antigo sobreviveu")
	_exato(Jogo.macacos, Grande.de_float(42.0), "e a contagem de macacos tambem")
	ok(Jogo.upgrades_comprados.has("instinto_digitador"), "e o upgrade comprado")
	# campo que nao existia no arquivo ganha o padrao de partida nova, nunca lixo
	perto(Jogo.multiplicador_global, 1.0, 0.0, "campo ausente ganha o padrao")
	ok(Jogo.dinheiro.e_zero(), "dinheiro ausente vira zero e nao INF")
	ok(Jogo.marcos_alcancados.is_empty(), "lista ausente vira lista vazia")

	# e o arquivo migrado, ao ser gravado de novo, ja sai na versao nova
	ok(Save.gravar(), "grava por cima do migrado")
	var relido = JSON.parse_string(FileAccess.open(CAMINHO_DE_TESTE, FileAccess.READ).get_as_text())
	igual(int(relido["versao"]), Save.VERSAO, "o arquivo regravado esta na versao atual")


## Save de um jogo mais NOVO nao pode ser aplicado pela metade: adivinhar o que um campo
## desconhecido significa e como se apaga progresso de verdade. Recusa e mantem o estado.
##
## A linha ERROR no stderr durante a suite e esperada.
func _recusa_versao_do_futuro() -> void:
	print("    (a linha ERROR abaixo e de proposito -- save do futuro sob teste)")
	var futuro := {"versao": Save.VERSAO + 99, "total_caracteres": "1e5"}
	var arquivo := FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(futuro))
	arquivo.close()

	Jogo.total_caracteres = Grande.de_float(777.0)
	perto(Save.carregar(), 0.0, 0.0, "save do futuro devolve 0")
	_exato(Jogo.total_caracteres, Grande.de_float(777.0), "e nao encosta no estado atual")


## O temporario e o que impede save pela metade: se ele sobrar no disco depois de uma
## gravacao boa, alguma coisa nao renomeou, e a proxima gravacao pode achar lixo la.
func _temporario_nao_sobra() -> void:
	ok(Save.gravar(), "grava de novo")
	ok(
		not FileAccess.file_exists(CAMINHO_DE_TESTE + ".tmp"),
		"o arquivo temporario nao sobrou depois da gravacao",
	)


func _exato(obtido: Grande, esperado: Grande, descricao: String) -> void:
	igual(obtido.para_texto(), esperado.para_texto(), "%s voltou exato" % descricao)


func _guardar_o_jogo() -> Dictionary:
	return {
		"total_caracteres": Jogo.total_caracteres,
		"caracteres_da_run": Jogo.caracteres_da_run,
		"dinheiro": Jogo.dinheiro,
		"macacos": Jogo.macacos,
		"maquina_atual": Jogo.maquina_atual,
		"pontos_de_teorema": Jogo.pontos_de_teorema,
		"fragmentos": Jogo.fragmentos,
		"multiplicador_global": Jogo.multiplicador_global,
		"tempo_jogado": Jogo.tempo_jogado,
		"upgrades_comprados": Jogo.upgrades_comprados.duplicate(),
		"marcos_alcancados": Jogo.marcos_alcancados.duplicate(),
	}


func _devolver_o_jogo(guardado: Dictionary) -> void:
	Jogo.total_caracteres = guardado["total_caracteres"]
	Jogo.caracteres_da_run = guardado["caracteres_da_run"]
	Jogo.dinheiro = guardado["dinheiro"]
	Jogo.macacos = guardado["macacos"]
	Jogo.maquina_atual = guardado["maquina_atual"]
	Jogo.pontos_de_teorema = guardado["pontos_de_teorema"]
	Jogo.fragmentos = guardado["fragmentos"]
	Jogo.multiplicador_global = guardado["multiplicador_global"]
	Jogo.tempo_jogado = guardado["tempo_jogado"]
	Jogo.upgrades_comprados = guardado["upgrades_comprados"]
	Jogo.marcos_alcancados = guardado["marcos_alcancados"]
