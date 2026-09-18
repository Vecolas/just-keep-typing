## Suite do Cenas (issue #38): o caminho Boot -> Menu -> Arquivos -> Partida -> Menu.
##
## ⚠️ A AFIRMACAO QUE IMPORTA E QUE NUNCA HA DUAS CENAS MONTADAS. Duas Partidas na arvore,
## mesmo que por um quadro so, sao dois _process chamando Economia.acumular sobre o MESMO
## autoload Jogo: a producao daquele quadro conta duas vezes, sem erro nenhum no console.
## E o jeito obvio de trocar de cena -- queue_free() na velha e add_child na nova -- cai
## exatamente nisso, porque queue_free so apaga no fim do quadro.
##
## Monta as cenas de verdade, e nao dubles. O que esta sob teste e a troca, e troca com
## cena falsa nao prova que a Partida sai do ar.
##
## Escreve nos arquivos dela (Config.caminho, modelo_de_slot e Save.caminho sao variaveis
## para isso) e devolve o estado do Jogo no fim.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_cenas_opcoes.json"
const SLOT_DE_TESTE := "user://teste_cenas_slot_%d.json"

var _raiz: Node = null


func _init() -> void:
	nome = "Cenas"


func executar() -> void:
	var caminho_original := Config.caminho
	var modelo_original := Config.modelo_de_slot
	var save_original := Save.caminho
	var slot_original := Config.slot()
	var guardado := _guardar_o_jogo()
	Config.caminho = CAMINHO_DE_TESTE
	Config.modelo_de_slot = SLOT_DE_TESTE
	_limpar()

	# o no de grupo que o Boot poe no jogo de verdade. Cenas nao sabe onde ele fica, e e
	# essa ignorancia que deixa a suite montar as cenas fora do main.tscn.
	#
	# ⚠️ Pendura no proprio Cenas, e nao na raiz da arvore: a suite roda dentro do _ready do
	# runner, e nesse instante a raiz esta "busy setting up children" -- add_child nela
	# falha com o no ficando fora da arvore e do grupo. O autoload entrou na arvore muito
	# antes e aceita filho na hora.
	_raiz = Node.new()
	_raiz.name = "RaizDeCenaDeTeste"
	_raiz.add_to_group(Cenas.GRUPO_RAIZ)
	Cenas.add_child(_raiz)

	_o_caminho()
	_nunca_duas_montadas()
	_voltar_ao_menu_grava()
	_offline_uma_vez_por_sessao()
	_a_transicao_tem_fim()

	# a ultima montada sai da arvore junto com a raiz: cena viva depois da suite
	# continuaria escutando o EventBus enquanto as outras suites rodam
	Cenas.remove_child(_raiz)
	_raiz.free()
	_limpar()
	Config.caminho = caminho_original
	Config.modelo_de_slot = modelo_original
	Config.abrir_slot(slot_original)
	Save.caminho = save_original
	Config.carregar()
	_devolver_o_jogo(guardado)


func _o_caminho() -> void:
	ok(Cenas.ir_para_menu(), "vai para o menu")
	igual(Cenas.atual(), "menu", "e o menu e a cena montada")
	igual(_raiz.get_child_count(), 1, "com uma cena montada, e nao duas")

	ok(Cenas.ir_para_arquivos(), "do menu para os Arquivos")
	igual(Cenas.atual(), "arquivos", "os Arquivos estao no ar")
	igual(_raiz.get_child_count(), 1, "e continua sendo uma so")

	ok(Cenas.comecar_partida(1), "dos Arquivos para a partida")
	igual(Cenas.atual(), "partida", "a partida esta no ar")
	igual(Config.slot(), 1, "e o slot escolhido foi o que abriu")


## ⚠️ O portao. Trocar de cena tem que tirar a anterior da ARVORE, e nao so agendar a morte
## dela para o fim do quadro.
func _nunca_duas_montadas() -> void:
	var anterior := _raiz.get_child(0)
	ok(anterior.is_inside_tree(), "a partida montada esta na arvore")

	ok(Cenas.comecar_partida(2), "abre outro Manuscrito por cima do primeiro")
	igual(_raiz.get_child_count(), 1, "⚠️ continua havendo UMA cena montada")
	ok(
		not anterior.is_inside_tree(),
		"⚠️ e a anterior saiu da arvore na hora -- nao no fim do quadro",
	)
	ok(_raiz.get_child(0) != anterior, "a montada agora e outra")
	igual(Config.slot(), 2, "e o slot acompanhou")


## Nao existe voltar ao menu sem gravar: e um dos momentos em que o jogador espera que o
## jogo tenha guardado (issue #37).
func _voltar_ao_menu_grava() -> void:
	Jogo.total_caracteres = Grande.new(4.5, 22)
	var gravacoes: Array[int] = []
	var contador := func() -> void: gravacoes.append(1)
	EventBus.jogo_gravado.connect(contador)
	ok(Cenas.voltar_ao_menu(), "volta ao menu")
	EventBus.jogo_gravado.disconnect(contador)

	igual(gravacoes.size(), 1, "e a saida gravou exatamente uma vez")
	igual(Cenas.atual(), "menu", "o menu esta no ar")
	ok(Save.existe(), "com o Manuscrito em disco")

	# e o que foi gravado abre de novo pelo CONTINUAR
	Jogo.total_caracteres = Grande.zero()
	ok(Cenas.comecar_partida(Config.slot()), "CONTINUAR abre o mesmo Manuscrito")
	igual(
		Jogo.total_caracteres.para_texto(), Grande.new(4.5, 22).para_texto(),
		"e a partida voltou como estava",
	)


## Decisao 0005: offline e o tempo em que o jogo esteve FECHADO. Sair para o menu e voltar
## nao e ausencia -- e o proprio gravado_em de um minuto atras.
func _offline_uma_vez_por_sessao() -> void:
	var creditados := Cenas.creditados_nesta_sessao()
	ok(creditados > 0, "os Manuscritos abertos ate aqui ja receberam o offline deles")

	Cenas.voltar_ao_menu()
	var antes := Jogo.total_caracteres
	Cenas.comecar_partida(Config.slot())
	igual(
		Cenas.creditados_nesta_sessao(), creditados,
		"⚠️ reentrar no mesmo Manuscrito NAO credita offline de novo",
	)
	igual(
		Jogo.total_caracteres.para_texto(), antes.para_texto(),
		"e por isso o total nao ganhou nada por ler o menu",
	)


## ⚠️ A CAPTURA DEPENDIA DA VELOCIDADE DA MAQUINA. Ela esperava dez QUADROS antes da foto,
## e a transicao dura 0,45 SEGUNDOS: numa maquina rapida dez quadros sao 0,17 s e a foto de
## `principal` saia com a maquina de escrever em voo por cima do botao DIGITAR; no runner
## do CI, mais lento, os mesmos dez quadros passavam de 0,45 s e a foto saia limpa. A MESMA
## ferramenta, no MESMO commit, com imagens diferentes -- e a galeria nao tem como
## distinguir isso de uma regressao.
##
## concluir_transicao() corta para o fim. Estas afirmacoes existem para que ela continue
## sendo um FIM: se algum dia a transicao ganhar uma terceira etapa e concluir_transicao
## esquecer dela, a foto volta a ser nao deterministica em silencio.
func _a_transicao_tem_fim() -> void:
	# o retangulo vem do menu montado; sem menu nao ha transicao, que e o caso legitimo de
	# entrar pela tela de Arquivos
	Cenas.ir_para_menu()
	Cenas.comecar_partida(1)
	# nao afirma que ELA COMECOU: reduzir_movimento desliga a transicao de proposito
	# (issue #43), e cravar "comecou" faria esta suite reprovar com a opcao ligada
	Cenas.concluir_transicao()
	ok(
		not Cenas.transicao_em_andamento(),
		"depois de concluir_transicao nao sobra nada em voo",
	)
	Cenas.concluir_transicao()
	ok(
		not Cenas.transicao_em_andamento(),
		"e concluir de novo continua sendo idempotente",
	)


func _limpar() -> void:
	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	var guardado := Save.caminho
	for numero in range(1, Config.SLOTS + 1):
		Save.caminho = Config.caminho_do_slot(numero)
		Save.apagar()
	Save.caminho = guardado


func _guardar_o_jogo() -> Dictionary:
	return {
		"nome": Jogo.nome,
		"criado_em": Jogo.criado_em,
		"total_caracteres": Jogo.total_caracteres,
		"caracteres_da_run": Jogo.caracteres_da_run,
		"dinheiro": Jogo.dinheiro,
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
	Jogo.dinheiro = guardado["dinheiro"]
	Jogo.macacos = guardado["macacos"]
	Jogo.prestigios = guardado["prestigios"]
	Jogo.tempo_jogado = guardado["tempo_jogado"]
	Jogo.upgrades_comprados = guardado["upgrades_comprados"]
	Jogo.marcos_alcancados = guardado["marcos_alcancados"]
	Jogo.descobertas = guardado["descobertas"]
