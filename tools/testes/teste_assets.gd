## Suite dos assets do menu (issue #45): o disco tem que concordar com a tabela.
##
## ⚠️ O TAMANHO E DECLARADO EM CODIGO E CONFERIDO NO DISCO, e nao lido do arquivo. Ler a
## largura do PNG e chamar aquilo de "o tamanho" e um portao que aprova qualquer coisa:
## sprite gerado em 400x400 por engano passaria, e so apareceria na tela como um borrao.
##
## E o motivo de isso importar tanto: pixel art e de escala INTEIRA. O cenario e desenhado
## a 5x porque 384x216 x 5 da exatamente 1920x1080. Um cenario de 385 px de largura nao
## quebra nada, nao imprime erro, e deixa a mesa meio pixel fora do lugar para sempre.
##
## ⚠️ O QUE ESTA SUITE NAO PROVA, e esta escrito porque alguem vai supor que prova:
##
##   se a peca tem TEXTO dentro dela. Nenhuma medicao le pixel procurando letra -- quem
##   pega isso e a checagem de arte do ARTE.md §17, que e humana;
##
##   se a peca pertence a familia. "Isso nao parece do mesmo jogo" nao e mensuravel;
##
##   se a paleta e a do §6. Contar cores pegaria o caso grosseiro e reprovaria toda peca
##   com uma sombra a mais -- o portao morderia o codigo certo.
extends TesteBase


func _init() -> void:
	nome = "assets do menu"


func executar() -> void:
	_a_tabela_e_coerente()
	_o_disco_concorda_com_a_tabela()
	_a_escala_do_cenario_fecha_a_tela()


## A tabela antes do disco: id repetido ou escala zero seria um defeito que nenhuma imagem
## conserta.
func _a_tabela_e_coerente() -> void:
	ok(not AssetsDoMenu.PECAS.is_empty(), "ha peca declarada")
	var vistos := {}
	for linha in AssetsDoMenu.PECAS:
		var id := str(linha["id"])
		ok(not vistos.has(id), "o id %s nao se repete" % id)
		vistos[id] = true

		var tamanho: Vector2i = linha["tamanho"]
		ok(tamanho.x > 0 and tamanho.y > 0, "%s -- tem tamanho declarado" % id)
		ok(int(linha["escala"]) >= 1, "%s -- tem escala inteira e positiva" % id)
		ok(
			str(linha["arquivo"]).ends_with(".png"),
			"%s -- o arquivo e um .png" % id,
		)

		# ⚠️ a borda do 9-slice tem que CABER na peca duas vezes: uma de cada lado. Borda
		# maior que metade do lado faz as duas bordas se sobreporem, e o miolo -- que e o
		# que estica -- some. O NinePatchRect nao reclama: ele desenha errado.
		var borda := int(linha["borda"])
		ok(borda >= 0, "%s -- a borda nao e negativa" % id)
		if borda > 0:
			ok(
				borda * 2 < tamanho.x and borda * 2 < tamanho.y,
				"%s -- a borda de %d cabe duas vezes em %s" % [id, borda, tamanho],
			)


## ⚠️ O PORTAO. Cada peca existe, carrega, e tem EXATAMENTE o tamanho declarado.
func _o_disco_concorda_com_a_tabela() -> void:
	var conferidas := 0
	for linha in AssetsDoMenu.PECAS:
		var id := str(linha["id"])
		var caminho := AssetsDoMenu.caminho_de(id)
		if not ResourceLoader.exists(caminho):
			ok(false, "%s -- o arquivo %s existe" % [id, caminho])
			continue

		var textura := AssetsDoMenu.textura_de(id)
		# ⚠️ carregar um arquivo quebrado costuma devolver um objeto INVALIDO, e nao null:
		# por isso a afirmacao e sobre o tamanho, e nao sobre a textura ser diferente de
		# nada. Tamanho zero e a assinatura do recurso que "carregou" sem carregar.
		if textura == null:
			ok(false, "%s -- o arquivo carregou como textura" % id)
			continue
		conferidas += 1
		igual(
			textura.get_size(), Vector2(linha["tamanho"]),
			"%s -- o disco tem o tamanho declarado" % id,
		)

	# ⚠️ portao com zero verificacoes tem que REPROVAR: uma pasta assets/ vazia deixaria o
	# laco inteiro cair no `continue` e a suite imprimiria "tudo certo" sem ter medido nada
	igual(
		conferidas, AssetsDoMenu.PECAS.size(),
		"todas as %d pecas foram medidas" % AssetsDoMenu.PECAS.size(),
	)
	igual(
		AssetsDoMenu.quantas_existem(), AssetsDoMenu.PECAS.size(),
		"e a familia esta inteira no disco -- meia familia le como quebrado",
	)


## ⚠️ A CONTA QUE JUSTIFICA O TAMANHO DO CENARIO. Ele nao e 384x216 por gosto: e o unico
## tamanho que, multiplicado por uma escala INTEIRA, fecha a tela logica exatamente. Um
## cenario que nao fecha deixa uma faixa vazia numa borda, ou meio pixel fora do lugar.
func _a_escala_do_cenario_fecha_a_tela() -> void:
	var cenario := AssetsDoMenu.peca("cenario")
	ok(not cenario.is_empty(), "o cenario esta na tabela")
	var tamanho: Vector2i = cenario["tamanho"]
	var escala := int(cenario["escala"])
	igual(
		tamanho * escala, AssetsDoMenu.TELA_LOGICA,
		"o cenario a %dx fecha a tela logica exatamente" % escala,
	)

	# e as outras escalas sao inteiras de verdade, e nao 1 por omissao
	for linha in AssetsDoMenu.PECAS:
		ok(
			int(linha["escala"]) in [
				AssetsDoMenu.ESCALA_DO_CENARIO,
				AssetsDoMenu.ESCALA_DA_UI,
				AssetsDoMenu.ESCALA_DO_ICONE,
			],
			"%s -- usa a escala de uma das tres familias" % linha["id"],
		)
