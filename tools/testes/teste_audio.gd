## Suite do audio (issue #42): os cinco barramentos e o teto do som de digitacao.
##
## Duas afirmacoes valem por todas as outras:
##
##   ⚠️ O TETO DO CLACK NAO DEPENDE DA PRODUCAO. No fim do jogo sao 10^50 caracteres por
##   segundo. Uma taxa proporcional -- ou "proporcional com um limite generoso" -- e um som
##   por caractere disfarcado, e a diferenca entre as duas so aparece com o jogo na era 14,
##   onde ninguem testa. Aqui ela aparece em milissegundos.
##
##   ⚠️ VOLUME ZERO MUTA, e nao so abaixa. Em -80 dB o barramento continua sendo processado
##   a cada quadro: e trabalho que ninguem ouve, todo quadro, para sempre.
##
## E uma terceira, que e de contabilidade e por isso morde dos dois lados: barramento sem
## fonte NAO ganha barra de volume, e barramento com fonte TEM que ganhar. Sem a segunda
## metade, a lista de divida passaria a esconder o dia em que a musica chegasse e ninguem
## pudesse controla-la.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_audio_opcoes.json"

## Producoes que cobrem a curva inteira, do primeiro caractere ao fim do jogo.
const PRODUCOES: Array[String] = ["1", "1e3", "1e6", "1e12", "1e50", "1e300"]


func _init() -> void:
	nome = "audio"


func executar() -> void:
	var caminho_original := Config.caminho
	Config.caminho = CAMINHO_DE_TESTE

	_os_cinco_barramentos()
	_barramento_sem_fonte_nao_tem_barra()
	_zero_muta()
	_o_teto_do_clack()
	_o_timbre_vem_da_opcao()
	_a_onda_tem_forma()

	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	Config.caminho = caminho_original
	Config.carregar()
	Config.aplicar()


## Os cinco existem, e todos desaguam no Master: sao controles separados, e nao saidas
## separadas -- quatro saidas independentes seriam quatro jeitos de o jogo ficar mudo.
func _os_cinco_barramentos() -> void:
	ok(Audio.BARRAMENTOS.size() == 5, "sao cinco barramentos (plano do menu §18)")
	for barramento in Audio.BARRAMENTOS:
		var indice := AudioServer.get_bus_index(barramento["nome"])
		ok(indice >= 0, "o barramento %s existe" % barramento["nome"])
		if indice <= 0:
			# o Master e o indice 0 e nao manda para lugar nenhum
			continue
		igual(
			str(AudioServer.get_bus_send(indice)), "Master",
			"%s desagua no Master" % barramento["nome"],
		)


## ⚠️ A LISTA DE DIVIDA MORDE DOS DOIS LADOS.
func _barramento_sem_fonte_nao_tem_barra() -> void:
	var campos := Config.nomes_de_campo()
	var conferidos := 0
	for barramento in Audio.BARRAMENTOS:
		conferidos += 1
		var nome_do_barramento: StringName = barramento["nome"]
		var campo := str(barramento["campo"])
		if Audio.SEM_FONTE_AINDA.has(nome_do_barramento):
			ok(
				campo.is_empty(),
				"%s esta na divida e NAO tem barra de volume" % nome_do_barramento,
			)
			continue
		ok(not campo.is_empty(), "%s tem barra de volume" % nome_do_barramento)
		ok(campos.has(campo), "%s -- e o campo %s existe no Config" % [nome_do_barramento, campo])
		igual(
			Config.tipo_de(campo), Config.Tipo.FAIXA,
			"%s -- e o campo dele e uma barra, e nao uma lista" % nome_do_barramento,
		)
	igual(conferidos, Audio.BARRAMENTOS.size(), "o portao mediu todos os barramentos")

	# e o outro sentido: nao ha campo de volume orfao, apontando para barramento nenhum
	for campo in campos:
		if not campo.begins_with("volume"):
			continue
		var achou := false
		for barramento in Audio.BARRAMENTOS:
			if str(barramento["campo"]) == campo:
				achou = true
		ok(achou, "%s controla algum barramento de verdade" % campo)


## ⚠️ O PORTAO. Zero muta; qualquer coisa acima de zero nao muta.
func _zero_muta() -> void:
	for barramento in Audio.BARRAMENTOS:
		var campo := str(barramento["campo"])
		if campo.is_empty():
			continue
		var nome_do_barramento: StringName = barramento["nome"]
		var indice := AudioServer.get_bus_index(nome_do_barramento)

		Config.definir(campo, 0.0)
		ok(AudioServer.is_bus_mute(indice), "%s -- volume zero MUTA" % nome_do_barramento)

		# o controle: sem ele, um barramento mutado para sempre passaria na linha acima
		Config.definir(campo, 1.0)
		ok(
			not AudioServer.is_bus_mute(indice),
			"%s -- e volume cheio desmuta" % nome_do_barramento,
		)
		perto(
			db_to_linear(AudioServer.get_bus_volume_db(indice)), 1.0, 1e-3,
			"%s -- e o volume aplicado e o escolhido" % nome_do_barramento,
		)

		Config.definir(campo, 0.5)
		perto(
			db_to_linear(AudioServer.get_bus_volume_db(indice)), 0.5, 1e-3,
			"%s -- e meio caminho tambem" % nome_do_barramento,
		)
		Config.definir(campo, float(Config.PADRAO[campo]))


## ⚠️ O PORTAO QUE VALE A ISSUE. A taxa sobe com a producao, satura, e o valor em que ela
## satura e o MESMO para 10^6 e para 10^300 -- que e o que "o teto nao depende da producao"
## quer dizer.
func _o_teto_do_clack() -> void:
	var anterior := -1.0
	for texto in PRODUCOES:
		var taxa := Audio.clacks_por_segundo(Grande.de_texto(texto))
		ok(
			taxa <= Audio.CLACKS_POR_SEGUNDO_NO_TETO + 1e-9,
			"%s por segundo nao passa do teto (%.2f)" % [texto, taxa],
		)
		ok(taxa >= anterior - 1e-9, "%s -- a taxa nunca desce quando a producao sobe" % texto)
		anterior = taxa

	# o teto e CONSTANTE: tres ordens de grandeza absurdamente diferentes dao o MESMO
	# numero. Uma taxa proporcional passaria em tudo acima e reprovaria aqui.
	var no_teto := Audio.clacks_por_segundo(Grande.de_texto("1e50"))
	perto(
		Audio.clacks_por_segundo(Grande.de_texto("1e300")), no_teto, 1e-9,
		"10^50 e 10^300 clacam na MESMA taxa",
	)
	perto(no_teto, Audio.CLACKS_POR_SEGUNDO_NO_TETO, 1e-9, "e essa taxa e o teto declarado")

	# o controle: sem producao nao ha som nenhum. Sem esta linha, uma taxa cravada no teto
	# passaria em todas as afirmacoes acima.
	perto(Audio.clacks_por_segundo(Grande.zero()), 0.0, 1e-9, "producao zero nao clacka")
	ok(
		Audio.clacks_por_segundo(Grande.de_texto("1e3")) < no_teto,
		"⚠️ e a curva sobe de verdade no meio do caminho -- nao e teto desde o primeiro",
	)


## O timbre sai da opcao, e "desligado" cala. Lido na hora, e nunca guardado.
func _o_timbre_vem_da_opcao() -> void:
	var valores: Array = Config.campo("som_de_digitacao")["valores"]
	for i in valores.size():
		Config.escolher("som_de_digitacao", i)
		var escolhido := str(valores[i])
		if escolhido == "desligado":
			ok(Audio.timbre_atual().is_empty(), "desligado nao tem timbre nenhum")
			continue
		igual(Audio.timbre_atual(), escolhido, "%s -- e o timbre em uso" % escolhido)
		ok(Audio.TIMBRES.has(escolhido), "%s -- tem forma de onda declarada" % escolhido)

	# valor que nao existe na tabela nao vira timbre invalido: ele cala, e nao quebra
	Config._opcoes["som_de_digitacao"] = "nao_existe"
	ok(Audio.timbre_atual().is_empty(), "timbre desconhecido no arquivo nao quebra a tela")
	Config.escolher("som_de_digitacao", 0)


## A onda e construida de verdade, e com a forma que o tocador espera. Sem isto, um timbre
## com duracao zero daria um AudioStreamWAV vazio que nao toca e nao reclama.
func _a_onda_tem_forma() -> void:
	for nome in Audio.TIMBRES:
		var onda := Audio.onda(Audio.TIMBRES[nome])
		ok(onda != null, "%s -- a onda foi construida" % nome)
		igual(onda.format, AudioStreamWAV.FORMAT_16_BITS, "%s -- 16 bits" % nome)
		igual(onda.mix_rate, Audio.AMOSTRAGEM, "%s -- na amostragem declarada" % nome)
		var esperadas := int(float(Audio.TIMBRES[nome]["duracao"]) * float(Audio.AMOSTRAGEM))
		igual(
			onda.data.size(), esperadas * 2,
			"%s -- dois bytes por amostra, e a duracao declarada" % nome,
		)
		ok(onda.data.size() > 0, "%s -- e nao esta vazia" % nome)

	# ⚠️ SEMENTE FIXA: duas construcoes do mesmo timbre dao bytes IDENTICOS. Com semente do
	# relogio, duas aberturas do jogo teriam CLACKs diferentes e nenhuma medicao futura
	# seria comparavel consigo mesma.
	ok(
		Audio.onda(Audio.TIMBRES["normal"]).data == Audio.onda(Audio.TIMBRES["normal"]).data,
		"a mesma onda construida duas vezes da os mesmos bytes",
	)
	ok(
		Audio.onda(Audio.TIMBRES["normal"]).data != Audio.onda(Audio.TIMBRES["mecanico"]).data,
		"e timbres diferentes dao ondas diferentes",
	)
