## A fila de avisos (issue #69).
##
## A regra que esta suite existe para defender e uma so:
##
##     uma mensagem de prioridade menor NUNCA apaga uma maior.
##
## Ate a issue #69 a HUD tinha um slot unico, e o defeito era medivel: em trinta minutos de
## partida, 16 dos 82 avisos (20%) eram apagados antes de completar o tempo minimo de
## leitura. Um em cada cinco textos que o jogo escreve era fisicamente ilegivel.
##
## ⚠️ E a fila e logica PURA, sem no e sem cena. E por isso que estas afirmacoes existem
## sem subir a HUD -- e por isso que elas conseguem afirmar a ORDEM, que e a coisa que a
## captura nao pega.
extends TesteBase


func _init() -> void:
	nome = "fila de avisos"


func executar() -> void:
	_o_primeiro_aparece_na_hora()
	_a_menor_nunca_apaga_a_maior()
	_nada_interrompe_o_que_esta_na_tela()
	_a_ordem_e_estavel_dentro_da_prioridade()
	_a_fila_tem_teto_e_descarta_o_menos_importante()
	_a_duracao_sai_da_prioridade()
	_o_registro_guarda_o_que_passou()
	_o_texto_vazio_nao_entra()


func _o_primeiro_aparece_na_hora() -> void:
	var fila := FilaDeAvisos.new()
	ok(not fila.tem_aviso(), "a fila comeca vazia")
	fila.acrescentar("primeiro", FilaDeAvisos.Prioridade.NORMAL)
	ok(fila.tem_aviso(), "o primeiro aviso aparece sem esperar")
	igual(fila.texto_atual(), "primeiro", "e e ele que esta na tela")


## A afirmacao central da issue.
func _a_menor_nunca_apaga_a_maior() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("na tela", FilaDeAvisos.Prioridade.NORMAL)
	fila.acrescentar("operacional", FilaDeAvisos.Prioridade.BAIXA)
	fila.acrescentar("descoberta rara", FilaDeAvisos.Prioridade.CRITICA)
	fila.acrescentar("descoberta", FilaDeAvisos.Prioridade.ALTA)

	# ⚠️ o teste avanca MUITO tempo de uma vez de proposito: assim ele afirma a ORDEM da
	# fila, e nao o relogio de cada aviso
	fila.tique(99.0)
	igual(fila.texto_atual(), "descoberta rara", "a CRITICA sai antes de todas")
	fila.tique(99.0)
	igual(fila.texto_atual(), "descoberta", "depois a ALTA")
	fila.tique(99.0)
	igual(fila.texto_atual(), "operacional", "e a BAIXA por ultimo")
	fila.tique(99.0)
	ok(not fila.tem_aviso(), "e ai a fila esvazia")


## ⚠️ NEM UMA CRITICA INTERROMPE O QUE JA ESTA SENDO LIDO. Trocar no meio da leitura e
## exatamente o defeito que esta issue conserta -- a prioridade fura a FILA, e nao a tela.
func _nada_interrompe_o_que_esta_na_tela() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("operacional", FilaDeAvisos.Prioridade.BAIXA)
	fila.acrescentar("rara", FilaDeAvisos.Prioridade.CRITICA)
	igual(
		fila.texto_atual(), "operacional",
		"a CRITICA espera a vez em vez de apagar o que esta sendo lido",
	)
	fila.tique(0.1)
	igual(fila.texto_atual(), "operacional", "e continua la enquanto o tempo dela corre")


func _a_ordem_e_estavel_dentro_da_prioridade() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("ocupa a tela", FilaDeAvisos.Prioridade.NORMAL)
	fila.acrescentar("a", FilaDeAvisos.Prioridade.ALTA)
	fila.acrescentar("b", FilaDeAvisos.Prioridade.ALTA)
	fila.acrescentar("c", FilaDeAvisos.Prioridade.ALTA)
	fila.tique(99.0)
	igual(fila.texto_atual(), "a", "dentro da mesma prioridade, quem chegou antes sai antes")
	fila.tique(99.0)
	igual(fila.texto_atual(), "b", "e depois o seguinte")


## ⚠️ QUANDO A FILA ESTOURA, SAI O MENOS IMPORTANTE -- nunca o mais recente. A issue #32 ja
## ensinou que seis avisos empilhados nao sao seis momentos: sao um so, e barulhento.
func _a_fila_tem_teto_e_descarta_o_menos_importante() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("ocupa a tela", FilaDeAvisos.Prioridade.NORMAL)
	for i in FilaDeAvisos.CABEM + 3:
		fila.acrescentar("baixa %d" % i, FilaDeAvisos.Prioridade.BAIXA)
	igual(
		fila.quantos_esperando(), FilaDeAvisos.CABEM,
		"a fila nao passa do teto de %d" % FilaDeAvisos.CABEM,
	)

	fila.acrescentar("a que importa", FilaDeAvisos.Prioridade.CRITICA)
	igual(fila.quantos_esperando(), FilaDeAvisos.CABEM, "e continua no teto")
	fila.tique(99.0)
	igual(
		fila.texto_atual(), "a que importa",
		"a CRITICA entrou mesmo com a fila cheia -- quem saiu foi uma BAIXA",
	)


func _a_duracao_sai_da_prioridade() -> void:
	igual(
		FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE.size(),
		FilaDeAvisos.Prioridade.values().size(),
		"ha uma duracao para cada prioridade -- tamanho indexado pelo enum, e nao literal",
	)
	var anterior := 0.0
	for prioridade in FilaDeAvisos.Prioridade.values():
		var segundos: float = FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE[prioridade]
		ok(segundos > 0.0, "a prioridade %d fica na tela por algum tempo" % prioridade)
		# ⚠️ mais importante fica MAIS tempo: uma critica que durasse menos que uma
		# operacional inverteria o sentido da fila sem ninguem notar
		ok(
			segundos >= anterior,
			"a prioridade %d nao fica menos tempo que a anterior" % prioridade,
		)
		anterior = segundos

	var fila := FilaDeAvisos.new()
	fila.acrescentar("critica", FilaDeAvisos.Prioridade.CRITICA)
	var da_critica: float = FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE[
		FilaDeAvisos.Prioridade.CRITICA
	]
	fila.tique(da_critica - 0.1)
	ok(fila.tem_aviso(), "a critica ainda esta na tela um pouco antes do fim")
	fila.tique(0.2)
	ok(not fila.tem_aviso(), "e sai quando o tempo dela acaba")


## ⚠️ SE O JOGADOR PERDEU O AVISO, ELE NAO SOME DO UNIVERSO. E o que reduz a ansiedade de
## leitura -- e o que tira do aviso a obrigacao de ser grande e demorado.
func _o_registro_guarda_o_que_passou() -> void:
	var fila := FilaDeAvisos.new()
	for i in FilaDeAvisos.REGISTRO_MAXIMO + 5:
		fila.acrescentar("aviso %d" % i, FilaDeAvisos.Prioridade.NORMAL, float(i))
	var registro := fila.registro()
	igual(
		registro.size(), FilaDeAvisos.REGISTRO_MAXIMO,
		"o registro para no maximo de %d" % FilaDeAvisos.REGISTRO_MAXIMO,
	)
	igual(
		str(registro[0]["texto"]),
		"aviso %d" % (FilaDeAvisos.REGISTRO_MAXIMO + 4),
		"e o primeiro da lista e o MAIS RECENTE",
	)
	perto(
		float(registro[0]["instante"]), float(FilaDeAvisos.REGISTRO_MAXIMO + 4), 0.0,
		"o registro guarda o instante junto do texto",
	)

	fila.limpar()
	ok(fila.registro().is_empty(), "limpar esvazia o registro")
	ok(not fila.tem_aviso(), "e a tela")


## Texto vazio na fila e um aviso que aparece em branco: o jogador ve a caixa acender e nao
## ha o que ler.
func _o_texto_vazio_nao_entra() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("", FilaDeAvisos.Prioridade.CRITICA)
	fila.acrescentar("   ", FilaDeAvisos.Prioridade.CRITICA)
	ok(not fila.tem_aviso(), "texto vazio ou so com espaco nao vira aviso")
	ok(fila.registro().is_empty(), "e nem entra no registro")
