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
##
## A reforma da interface trouxe uma SEGUNDA regra, e ela e o que torna o banner do topo
## possivel:
##
##     uma faixa da tela nunca atrasa a outra.
##
## Descoberta, marco conceitual e prestigio foram para uma fila propria -- o banner --, e e por
## isso que a duracao deles pode crescer para os segundos que uma frase de tres linhas exige
## sem atrasar um unico autosave. As afirmacoes de faixa abaixo existem para essa separacao nao
## se desfazer em silencio: o defeito dela seria uma descoberta voltando a piscar por 2,2
## segundos numa linha de rodape, e nenhum portao antigo reprovaria isso.
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
	_a_faixa_separa_acontecimento_de_confirmacao()
	_a_duracao_da_descoberta_sai_da_raridade()
	_a_carga_extra_atravessa_a_fila()
	_o_registro_do_autoload_junta_as_duas_faixas()


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


## ⚠️ O RODAPE E O ZERO DO ENUM, e isso e a regra do "valor zero e o neutro" (CONVENCOES):
## acontecimento esquecido cai na faixa discreta, e nunca num banner que cobre a tela.
func _a_faixa_separa_acontecimento_de_confirmacao() -> void:
	igual(
		int(FilaDeAvisos.Faixa.RODAPE), 0,
		"⚠️ RODAPE e o zero: o esquecido cai na faixa que afirma MENOS",
	)

	# toda descoberta vai para o banner, inclusive a Comum: ela e o conteudo colecionavel do
	# jogo, e nao uma confirmacao de sistema
	var conferidas := 0
	for categoria in DadosDescoberta.Categoria.values():
		var descoberta := DadosDescoberta.new()
		descoberta.categoria = categoria
		igual(
			FilaDeAvisos.faixa_de_descoberta(descoberta), FilaDeAvisos.Faixa.DESTAQUE,
			"a descoberta de categoria %d vai para o banner" % categoria,
		)
		conferidas += 1
	ok(conferidas > 0, "e houve categoria para conferir (%d)" % conferidas)

	# ⚠️ E O MARCO SEPARA, que e o outro lado do portao: se os dois tipos caissem na mesma
	# faixa, a separacao nao estaria sendo medida por ninguem
	var por_faixa := {}
	for tipo in DadosMarco.Tipo.values():
		var marco := DadosMarco.new()
		marco.tipo = tipo
		por_faixa[FilaDeAvisos.faixa_de_marco(marco)] = true
		var esperada := (
			FilaDeAvisos.Faixa.DESTAQUE if tipo == DadosMarco.Tipo.CONCEITUAL
			else FilaDeAvisos.Faixa.RODAPE
		)
		igual(
			FilaDeAvisos.faixa_de_marco(marco), esperada,
			"o marco de tipo %d cai na faixa certa" % tipo,
		)
	igual(
		por_faixa.size(), 2,
		"⚠️ e os marcos usam AS DUAS faixas -- se usassem uma so, nada estaria separado",
	)


## ⚠️ A DURACAO DO BANNER CRESCE COM A RARIDADE, e toda ela e MAIOR que a maior duracao do
## rodape. Essa desigualdade e a razao de existirem duas filas: uma descoberta Lendaria precisa
## de mais tempo do que qualquer aviso operacional pode esperar.
func _a_duracao_da_descoberta_sai_da_raridade() -> void:
	igual(
		FilaDeAvisos.SEGUNDOS_POR_CATEGORIA.size(),
		DadosDescoberta.Categoria.values().size(),
		"ha uma duracao para cada raridade -- tamanho indexado pelo enum, e nao literal",
	)

	var maior_do_rodape := 0.0
	for segundos in FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE:
		maior_do_rodape = maxf(maior_do_rodape, segundos)

	var anterior := 0.0
	for categoria in DadosDescoberta.Categoria.values():
		var segundos := FilaDeAvisos.segundos_de_descoberta(categoria)
		ok(
			segundos > maior_do_rodape,
			"a raridade %d fica mais tempo que qualquer aviso do rodape (%.1f > %.1f)" % [
				categoria, segundos, maior_do_rodape,
			],
		)
		ok(
			segundos >= anterior,
			"e a raridade %d nao fica menos tempo que a anterior" % categoria,
		)
		anterior = segundos
	# o controle: uma tabela com sete valores IGUAIS passaria em tudo acima
	ok(
		anterior > FilaDeAvisos.segundos_de_descoberta(0),
		"⚠️ e a mais rara fica ESTRITAMENTE mais tempo que a Comum (%.1f > %.1f)" % [
			anterior, FilaDeAvisos.segundos_de_descoberta(0),
		],
	)

	# categoria fora da faixa cai na Comum, e nao estoura o indice
	perto(
		FilaDeAvisos.segundos_de_descoberta(-1),
		FilaDeAvisos.SEGUNDOS_POR_CATEGORIA[0], 0.0,
		"categoria invalida cai na duracao mais CURTA",
	)
	perto(
		FilaDeAvisos.segundos_de_descoberta(999),
		FilaDeAvisos.SEGUNDOS_POR_CATEGORIA[0], 0.0,
		"e pelo outro lado tambem",
	)


## A carga que a tela le -- rubrica, titulo, marca -- atravessa a fila sem ser interpretada.
##
## ⚠️ E `segundos` AUSENTE E DIFERENTE DE `segundos` ZERO. Zero significaria "sai no mesmo
## quadro em que entrou": sentinela que colide com valor valido transforma um ajuste legitimo em
## "nao faz nada", em silencio (CONVENCOES).
func _a_carga_extra_atravessa_a_fila() -> void:
	var fila := FilaDeAvisos.new()
	fila.acrescentar("com carga", FilaDeAvisos.Prioridade.ALTA, 0.0, {
		"rubrica": "NOVA DESCOBERTA", "marca": "@",
	})
	igual(
		str(fila.extras_atuais().get("rubrica", "")), "NOVA DESCOBERTA",
		"a rubrica chega intacta do outro lado da fila",
	)
	igual(str(fila.extras_atuais().get("marca", "")), "@", "e a marca tambem")

	# sem carga, a duracao vem da tabela de prioridade
	var padrao := FilaDeAvisos.new()
	padrao.acrescentar("sem carga", FilaDeAvisos.Prioridade.NORMAL)
	ok(padrao.extras_atuais().is_empty(), "aviso sem carga tem carga vazia, e nao nula")
	padrao.tique(FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE[FilaDeAvisos.Prioridade.NORMAL] - 0.1)
	ok(padrao.tem_aviso(), "e ele dura o que a prioridade manda")
	padrao.tique(0.2)
	ok(not padrao.tem_aviso(), "e sai quando esse tempo acaba")

	# com carga, a duracao pedida VENCE a tabela
	var longa := FilaDeAvisos.new()
	longa.acrescentar("longa", FilaDeAvisos.Prioridade.BAIXA, 0.0, {"segundos": 9.0})
	longa.tique(FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE[FilaDeAvisos.Prioridade.BAIXA] + 1.0)
	ok(
		longa.tem_aviso(),
		"⚠️ a duracao da carga vence a da prioridade: uma BAIXA de 9 s nao sai em 1,2 s",
	)
	longa.tique(9.0)
	ok(not longa.tem_aviso(), "e sai nos 9 s pedidos")

	# ⚠️ E TEM PISO. Duracao invalida vinda de fora nao pode virar um aviso que nunca aparece:
	# o jogador veria a caixa piscar e nada para ler.
	var invalida := FilaDeAvisos.new()
	invalida.acrescentar("invalida", FilaDeAvisos.Prioridade.ALTA, 0.0, {"segundos": 0.0})
	ok(invalida.tem_aviso(), "duracao zero na carga nao faz o aviso sumir no mesmo quadro")
	invalida.tique(FilaDeAvisos.SEGUNDOS_POR_PRIORIDADE[FilaDeAvisos.Prioridade.BAIXA] + 0.01)
	ok(not invalida.tem_aviso(), "e ela cai no piso, que e a menor duracao que existe")


## ⚠️ O REGISTRO E UM SO PARA AS DUAS FAIXAS, ORDENADO PELO INSTANTE. Quem perdeu um aviso nao
## precisa saber em que faixa ele passou -- ele precisa saber o que aconteceu, e em que ordem.
## Emendar as duas listas mostraria todas as descobertas e depois todos os marcos, o que le como
## duas telas e nao como um registro.
##
## ⚠️ ESTE BLOCO MEXE NO AUTOLOAD Avisos, que e estado de sessao vivo, e limpa no fim.
func _o_registro_do_autoload_junta_as_duas_faixas() -> void:
	Avisos.limpar()
	var tempo := Jogo.tempo_jogado

	# um marco de tamanho (rodape) no instante 10, uma descoberta (banner) no instante 20
	var marco := DadosMarco.new()
	marco.id = "marco_de_teste"
	marco.titulo = "Marco de teste"
	marco.tipo = DadosMarco.Tipo.QUANTITATIVO
	var descoberta := DadosDescoberta.new()
	descoberta.id = "descoberta_de_teste"
	descoberta.nome = "Descoberta de teste"
	descoberta.categoria = DadosDescoberta.Categoria.COMUM

	Jogo.tempo_jogado = 10.0
	EventBus.marco_alcancado.emit(marco)
	Jogo.tempo_jogado = 20.0
	EventBus.descoberta_encontrada.emit(descoberta)

	ok(Avisos.tem_aviso(), "o marco de tamanho acendeu o rodape")
	ok(Avisos.tem_destaque(), "e a descoberta acendeu o banner -- as duas ao mesmo tempo")
	ok(not Avisos.destaque_atual().is_empty(), "e o banner recebeu a carga que a tela le")

	var registro := Avisos.registro()
	igual(registro.size(), 2, "o registro junta as duas faixas")
	perto(
		float(registro[0]["instante"]), 20.0, 0.0,
		"e o mais RECENTE vem primeiro, mesmo vindo da outra faixa",
	)
	perto(float(registro[1]["instante"]), 10.0, 0.0, "com o mais antigo depois")

	Avisos.limpar()
	ok(Avisos.registro().is_empty(), "limpar esvazia as duas faixas")
	ok(not Avisos.tem_aviso() and not Avisos.tem_destaque(), "e as duas telas")
	Jogo.tempo_jogado = tempo
