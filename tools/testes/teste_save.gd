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
	_a_verificacao_rele_o_disco()
	_o_backup_carrega_a_partida()
	_save_corrompido_nao_encosta_no_backup()
	_sem_backup_nada_e_inventado()
	_a_colecao_sobrevive_a_migracao()

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
	Jogo.sala_atual = "galpao"
	Jogo.pontos_de_teorema = Grande.new(3.5, 8)
	Jogo.fragmentos = Grande.zero()
	Jogo.multiplicador_global = 2.75
	Jogo.tempo_jogado = 3661.5
	Jogo.tempo_da_run = 900.25
	Jogo.recorde_por_segundo = Grande.new(4.2, 88)
	Jogo.macacos_comprados = Grande.de_float(4321.0)
	Jogo.total_offline = Grande.new(7.7, 30)
	Jogo.prestigios = 3
	Jogo.upgrades_comprados = ["instinto_digitador", "dedos_mais_ageis"] as Array[String]
	Jogo.marcos_alcancados = ["primeira_palavra"] as Array[String]
	Jogo.descobertas = ["um_poema"] as Array[String]

	ok(Save.gravar(), "gravou")
	ok(Save.existe(), "e o arquivo esta la")

	# suja tudo antes de carregar: se carregar nao escrever, o teste passa por acidente
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.macacos = Grande.zero()
	Jogo.maquina_atual = ""
	Jogo.sala_atual = ""
	Jogo.pontos_de_teorema = Grande.zero()
	Jogo.fragmentos = Grande.de_float(999.0)
	Jogo.multiplicador_global = 1.0
	Jogo.tempo_jogado = 0.0
	Jogo.tempo_da_run = 0.0
	Jogo.recorde_por_segundo = Grande.zero()
	Jogo.macacos_comprados = Grande.zero()
	Jogo.total_offline = Grande.zero()
	Jogo.prestigios = 0
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
	igual(Jogo.sala_atual, "galpao", "e a sala tambem")
	_exato(Jogo.pontos_de_teorema, Grande.new(3.5, 8), "pontos de teorema")
	ok(Jogo.fragmentos.e_zero(), "fragmentos zerados continuam zerados")
	perto(Jogo.multiplicador_global, 2.75, 0.0, "multiplicador global")
	perto(Jogo.tempo_jogado, 3661.5, 0.0, "tempo jogado")
	perto(Jogo.tempo_da_run, 900.25, 0.0, "tempo da run")
	_exato(Jogo.recorde_por_segundo, Grande.new(4.2, 88), "recorde")
	_exato(Jogo.macacos_comprados, Grande.de_float(4321.0), "macacos comprados")
	_exato(Jogo.total_offline, Grande.new(7.7, 30), "offline acumulado")
	igual(Jogo.prestigios, 3, "prestigios")
	igual(Jogo.upgrades_comprados.size(), 2, "os dois upgrades voltaram")
	ok(Jogo.upgrades_comprados.has("dedos_mais_ageis"), "e com os ids certos")
	igual(Jogo.marcos_alcancados.size(), 1, "o marco alcancado voltou")
	igual(Jogo.descobertas.size(), 1, "a descoberta encontrada voltou")
	ok(Jogo.descobertas.has("um_poema"), "e com o id certo")


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


## ⚠️ A MIGRACAO DA ISSUE #55 NAO PODE APAGAR COLECAO DE QUEM JA JOGA, e nao pode inventar
## data para o que ela nao sabe.
##
## O caso real: um save da versao 10 tem `descobertas` e nao tem os dois carimbos. Se a
## migracao preenchesse zero -- que e o reflexo natural para "campo numerico ausente" --,
## toda descoberta antiga passaria a dizer "encontrada em 1 de janeiro de 1970, com 1
## caractere produzido". Dado inventado que parece dado e pior que dado faltando: ninguem
## desconfia dele.
func _a_colecao_sobrevive_a_migracao() -> void:
	var antigo := {
		"versao": 10,
		"total_caracteres": "1e12",
		"descobertas": ["banana", "eu"],
	}
	var arquivo := FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(antigo))
	arquivo.close()

	Jogo.esquecer_descobertas()
	Save.carregar()

	ok(Jogo.descobertas.has("banana"), "a descoberta do save antigo sobreviveu")
	ok(Jogo.descobertas.has("eu"), "e a segunda tambem")
	ok(
		Descobertas.detalhe_de("banana").is_empty(),
		"e ela NAO ganhou data inventada -- o detalhe vem vazio",
	)

	# ⚠️ E CARIMBO ORFAO NAO PASSA. Um id com data mas sem estar na lista de encontradas e
	# lixo que o Arquivo leria como verdade -- e ele entra por caminhos que nao sao este
	# (save editado a mao, migracao futura que mexa na lista).
	var com_orfao := {
		"versao": Save.VERSAO,
		"total_caracteres": "1e12",
		"descobertas": ["banana"],
		"descobertas_quando": {"banana": 1700000000.0, "fantasma": 1700000000.0},
		"descobertas_grandeza": {"banana": 9, "fantasma": 9},
	}
	arquivo = FileAccess.open(CAMINHO_DE_TESTE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(com_orfao))
	arquivo.close()

	Jogo.esquecer_descobertas()
	Jogo.nome = "nome que tem que sumir"
	Save.carregar()

	# ⚠️ ESTE ARQUIVO ESTA NA VERSAO ATUAL E LHE FALTAM CAMPOS. Ate a issue #55 o
	# preenchimento de padrao so rodava dentro de _migrar, entao um save assim caia direto
	# em _aplicar -- que indexa `dados["nome"]` sem .get e morre ali, com a partida pela
	# metade. Foi este caso de teste que reprovou primeiro, e o reflexo teria sido
	# consertar o teste: o arquivo era JSON valido, na versao certa, e nao carregava.
	igual(Jogo.nome, "", "save da versao atual sem um campo ganha o padrao, e nao trava")

	ok(not Descobertas.detalhe_de("banana").is_empty(), "o carimbo de quem foi achado fica")
	ok(
		not Jogo.descobertas_quando.has("fantasma"),
		"e o carimbo de quem NAO esta na lista e descartado na leitura",
	)
	ok(not Jogo.descobertas_grandeza.has("fantasma"), "nos dois dicionarios")

	# ida e volta com os campos novos: gravar e carregar tem que devolver o mesmo
	Jogo.esquecer_descobertas()
	Jogo.descobertas.append("banana")
	Jogo.total_caracteres = Grande.de_float(1.0e15)
	Descobertas._carimbar("banana")
	var esperado := Descobertas.detalhe_de("banana")
	ok(Save.gravar(), "grava a colecao com carimbo")
	Jogo.esquecer_descobertas()
	Save.carregar()
	var obtido := Descobertas.detalhe_de("banana")
	ok(not obtido.is_empty(), "o carimbo sobreviveu a ida e volta")
	perto(
		float(obtido.get("quando", 0.0)), float(esperado["quando"]), 0.0,
		"e a data voltou EXATA -- e o que o floorf() no carimbo garante",
	)
	igual(int(obtido.get("grandeza", -1)), int(esperado["grandeza"]), "e a ordem de grandeza")

	Jogo.esquecer_descobertas()


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


## A verificacao e o que separa "escrevi" de "esta la" (issue #36). store_string nao
## reclama de disco cheio nem de escrita truncada -- o unico jeito de saber e reler.
func _a_verificacao_rele_o_disco() -> void:
	Jogo.total_caracteres = Grande.new(8.125, 300)
	Jogo.maquina_atual = "maquina_eletrica"
	ok(Save.gravar(), "grava para conferir")

	var esperado := {
		"versao": Save.VERSAO,
		"total_caracteres": Jogo.total_caracteres.para_texto(),
		"maquina_atual": "maquina_eletrica",
	}
	ok(Save._confere(CAMINHO_DE_TESTE, esperado), "o arquivo gravado confere com a partida")

	print("    (as linhas ERROR abaixo sao de proposito -- arquivos ruins sob teste)")
	var trocado := esperado.duplicate()
	trocado["total_caracteres"] = "1"
	ok(
		not Save._confere(CAMINHO_DE_TESTE, trocado),
		"⚠️ e reprova quando o texto do acumulador nao bate -- e ai que o progresso some",
	)

	var faltando := esperado.duplicate()
	faltando["campo_que_nao_foi_gravado"] = "x"
	ok(not Save._confere(CAMINHO_DE_TESTE, faltando), "e reprova quando falta chave")

	_escrever(CAMINHO_DE_TESTE + ".pedaco", '{"versao": 10, "total')
	ok(
		not Save._confere(CAMINHO_DE_TESTE + ".pedaco", esperado),
		"e reprova arquivo truncado, que e o que uma escrita interrompida deixa",
	)
	DirAccess.remove_absolute(CAMINHO_DE_TESTE + ".pedaco")
	ok(not Save._confere(CAMINHO_DE_TESTE + ".pedaco", esperado), "e arquivo que nem existe")


## ⚠️ O portao da issue: corromper o principal e a partida voltar inteira do backup.
func _o_backup_carrega_a_partida() -> void:
	Save.apagar()
	var reserva := Save.caminho_do_backup(CAMINHO_DE_TESTE)

	Jogo.total_caracteres = Grande.new(3.75, 500)
	Jogo.macacos = Grande.de_float(64.0)
	Jogo.prestigios = 5
	Jogo.upgrades_comprados = ["instinto_digitador"] as Array[String]
	ok(Save.gravar(), "a primeira gravacao")
	ok(not FileAccess.file_exists(reserva), "ainda nao ha backup -- nao havia o que promover")

	# a segunda gravacao promove a primeira: o backup guarda o estado ANTERIOR, ja lido de
	# volta uma vez. Promover sem reler seria guardar duas copias do mesmo defeito.
	Jogo.total_caracteres = Grande.new(9.5, 600)
	ok(Save.gravar(), "a segunda gravacao")
	ok(FileAccess.file_exists(reserva), "agora ha backup")
	ok(
		FileAccess.file_exists(Manuscrito.caminho_do_meta(reserva)),
		"e o .meta dele foi junto -- senao o menu descreveria o backup com outro cartao",
	)

	print("    (a linha ERROR abaixo e de proposito -- principal corrompido sob teste)")
	_escrever(CAMINHO_DE_TESTE, "isto aqui nao abre")

	Jogo.total_caracteres = Grande.zero()
	Jogo.macacos = Grande.zero()
	Jogo.prestigios = 0
	Jogo.upgrades_comprados = [] as Array[String]
	var gravado_em := Save.carregar()
	ok(gravado_em > 0.0, "carregar achou a partida mesmo com o principal quebrado")
	_exato(Jogo.total_caracteres, Grande.new(3.75, 500), "o total do backup")
	_exato(Jogo.macacos, Grande.de_float(64.0), "os macacos")
	igual(Jogo.prestigios, 5, "os prestigios")
	ok(Jogo.upgrades_comprados.has("instinto_digitador"), "e o upgrade comprado")

	# e o menu concorda com o Save: slot que carrega do backup esta CHEIO, e nao ilegivel
	var manuscrito := Manuscrito.de_arquivo(CAMINHO_DE_TESTE, reserva)
	ok(manuscrito.cheio(), "e o menu mostra o slot como CHEIO, e nao como ilegivel")
	_exato(manuscrito.total_caracteres, Grande.new(3.75, 500), "com o total do backup")


## ⚠️ O outro portao, e o que transforma rede de protecao em ampliador de dano: gravar por
## cima de um principal quebrado NAO pode levar o backup bom junto.
func _save_corrompido_nao_encosta_no_backup() -> void:
	Save.apagar()
	var reserva := Save.caminho_do_backup(CAMINHO_DE_TESTE)

	Jogo.total_caracteres = Grande.new(2.5, 80)
	ok(Save.gravar(), "grava a primeira")
	Jogo.total_caracteres = Grande.new(2.5, 81)
	ok(Save.gravar(), "grava a segunda, que promove a primeira a backup")
	var backup_bom := _ler(reserva)
	ok(backup_bom.contains("2.5e80"), "o backup guarda a partida anterior")

	print("    (as linhas WARNING/ERROR abaixo sao de proposito -- principal corrompido)")
	_escrever(CAMINHO_DE_TESTE, "nem isto abre")
	Jogo.total_caracteres = Grande.new(7.0, 90)
	ok(Save.gravar(), "grava por cima do principal corrompido")

	igual(
		_ler(reserva), backup_bom,
		"⚠️ o backup bom continua exatamente como estava -- lixo nao vira copia de seguranca",
	)
	# e o principal foi consertado pela gravacao nova
	Jogo.total_caracteres = Grande.zero()
	Save.carregar()
	_exato(Jogo.total_caracteres, Grande.new(7.0, 90), "e o principal voltou a abrir")

	# a gravacao seguinte ja pode promover, porque agora ha o que promover
	Jogo.total_caracteres = Grande.new(7.0, 91)
	ok(Save.gravar(), "grava de novo")
	ok(_ler(reserva).contains("7e90"), "e ai sim o backup avanca")


## Sem principal e sem backup nao ha partida -- e isso e "comecar do zero", nao um estado
## meio carregado. O estado do Jogo nao pode ser tocado no caminho.
func _sem_backup_nada_e_inventado() -> void:
	Save.apagar()
	print("    (a linha ERROR abaixo e de proposito -- principal corrompido sem backup)")
	_escrever(CAMINHO_DE_TESTE, "so lixo, e nada mais")

	Jogo.total_caracteres = Grande.de_float(4242.0)
	perto(Save.carregar(), 0.0, 0.0, "sem backup, carregar devolve 0")
	_exato(Jogo.total_caracteres, Grande.de_float(4242.0), "e nao encosta no estado atual")

	var manuscrito := Manuscrito.de_arquivo(
		CAMINHO_DE_TESTE, Save.caminho_do_backup(CAMINHO_DE_TESTE)
	)
	ok(manuscrito.ilegivel(), "e o menu chama o slot de ILEGIVEL, que nao e vazio")

	Save.apagar()
	ok(
		Manuscrito.de_arquivo(
			CAMINHO_DE_TESTE, Save.caminho_do_backup(CAMINHO_DE_TESTE)
		).vazio(),
		"apagar leva principal, .meta e backup, e o slot volta a ser VAZIO",
	)


static func _escrever(caminho: String, conteudo: String) -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		return
	arquivo.store_string(conteudo)
	arquivo.close()


static func _ler(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	return arquivo.get_as_text() if arquivo != null else ""


func _exato(obtido: Grande, esperado: Grande, descricao: String) -> void:
	igual(obtido.para_texto(), esperado.para_texto(), "%s voltou exato" % descricao)


func _guardar_o_jogo() -> Dictionary:
	return {
		"total_caracteres": Jogo.total_caracteres,
		"caracteres_da_run": Jogo.caracteres_da_run,
		"dinheiro": Jogo.dinheiro,
		"macacos": Jogo.macacos,
		"maquina_atual": Jogo.maquina_atual,
		"sala_atual": Jogo.sala_atual,
		"pontos_de_teorema": Jogo.pontos_de_teorema,
		"fragmentos": Jogo.fragmentos,
		"multiplicador_global": Jogo.multiplicador_global,
		"tempo_jogado": Jogo.tempo_jogado,
		"tempo_da_run": Jogo.tempo_da_run,
		"recorde_por_segundo": Jogo.recorde_por_segundo,
		"macacos_comprados": Jogo.macacos_comprados,
		"total_offline": Jogo.total_offline,
		"prestigios": Jogo.prestigios,
		"upgrades_comprados": Jogo.upgrades_comprados.duplicate(),
		"marcos_alcancados": Jogo.marcos_alcancados.duplicate(),
		"descobertas": Jogo.descobertas.duplicate(),
	}


func _devolver_o_jogo(guardado: Dictionary) -> void:
	Jogo.total_caracteres = guardado["total_caracteres"]
	Jogo.caracteres_da_run = guardado["caracteres_da_run"]
	Jogo.dinheiro = guardado["dinheiro"]
	Jogo.macacos = guardado["macacos"]
	Jogo.maquina_atual = guardado["maquina_atual"]
	Jogo.sala_atual = guardado["sala_atual"]
	Jogo.pontos_de_teorema = guardado["pontos_de_teorema"]
	Jogo.fragmentos = guardado["fragmentos"]
	Jogo.multiplicador_global = guardado["multiplicador_global"]
	Jogo.tempo_jogado = guardado["tempo_jogado"]
	Jogo.tempo_da_run = guardado["tempo_da_run"]
	Jogo.recorde_por_segundo = guardado["recorde_por_segundo"]
	Jogo.macacos_comprados = guardado["macacos_comprados"]
	Jogo.total_offline = guardado["total_offline"]
	Jogo.prestigios = guardado["prestigios"]
	Jogo.upgrades_comprados = guardado["upgrades_comprados"]
	Jogo.marcos_alcancados = guardado["marcos_alcancados"]
	Jogo.descobertas = guardado["descobertas"]
