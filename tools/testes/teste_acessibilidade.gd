## Suite de interface e acessibilidade (issue #43).
##
## A afirmacao que vale a issue: ⚠️ RARIDADE IDENTIFICAVEL SEM COR NENHUMA. Sao sete
## categorias, com dois roxos e dois azuis entre elas -- quem nao distingue as sete cores
## nao le a raridade de nada. A regra e cor + simbolo + nome, e o que esta sob teste aqui e
## que, APAGANDO A COR, as sete continuam diferentes umas das outras.
##
## A segunda e sobre o custo do simbolo: ⚠️ GLIFO QUE FALTA NA FONTE CUSTA MAIS QUE O
## DESENHO. A era 14 usava ∑ Ω ◇ ✦ e media 22 ms com dezesseis rotulos contra 14 ms da era
## 7 com seis vezes mais (TUNING.md) -- glifo ausente faz o Godot percorrer a cadeia de
## fallback a cada desenho, sem erro nenhum. Aqui a fonte de verdade e consultada.
##
## E a terceira e de contabilidade, e morde dos dois lados: opcao declarada tem que ter o
## que ligar e desligar, e nome na lista de divida tem que continuar SEM campo.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_acessibilidade_opcoes.json"

## Um caractere que toda fonte do mundo tem. Se nem ele existir, nao ha fonte carregada e
## a medicao de glifo nao vale -- o que e o caso do ambiente sem janela.
const GLIFO_DE_CONTROLE := "A"


func _init() -> void:
	nome = "acessibilidade"


func executar() -> void:
	var caminho_original := Config.caminho
	Config.caminho = CAMINHO_DE_TESTE
	_o_digitar_nunca_some()

	_raridade_sem_cor()
	_tipo_de_marco_sem_cor()
	_os_simbolos_existem_na_fonte()
	_escala_do_texto()
	_alto_contraste_separa()
	_reduzir_movimento_alcanca_as_letras()
	_divida_declarada()

	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	Config.caminho = caminho_original
	Config.carregar()
	Config.aplicar()


## ⚠️ E OS TRES TIPOS DE MARCO TAMBEM (issue #51). A mesma regra, o mesmo motivo: quem nao
## distingue matiz tem que ler o tipo do mesmo jeito.
func _tipo_de_marco_sem_cor() -> void:
	var marcas := {}
	var nomes := {}
	for tipo in [
		DadosMarco.Tipo.QUANTITATIVO, DadosMarco.Tipo.HUMANO, DadosMarco.Tipo.CONCEITUAL
	]:
		var marca := Panorama.marca_de(tipo)
		var nome_do_tipo := Panorama.nome_do_tipo(tipo)
		ok(not marca.strip_edges().is_empty(), "o tipo %d tem marca" % tipo)
		ok(not marcas.has(marca), "a marca %s nao se repete" % marca)
		ok(not nomes.has(nome_do_tipo), "o nome %s nao se repete" % nome_do_tipo)
		marcas[marca] = true
		nomes[nome_do_tipo] = true
	igual(marcas.size(), 3, "os tres tipos sao distinguiveis SO pela marca")
	igual(nomes.size(), 3, "e SO pelo nome tambem")

	ok(not Panorama.marca_de(-1).is_empty(), "tipo invalido ainda tem marca")
	ok(not Panorama.nome_do_tipo(99).is_empty(), "e ainda tem nome")


## ⚠️ O PORTAO. Apaga a cor e conta: sete leituras diferentes.
func _raridade_sem_cor() -> void:
	var quantas := Paleta.RARIDADES.size()
	igual(
		Paleta.SIMBOLOS_DE_RARIDADE.size(), quantas,
		"ha um simbolo para cada cor de raridade",
	)

	var vistos := {}
	for categoria in quantas:
		var simbolo := DescobertasTela.simbolo_de(categoria)
		ok(not simbolo.strip_edges().is_empty(), "categoria %d tem simbolo" % categoria)
		ok(not vistos.has(simbolo), "o simbolo %s nao se repete" % simbolo)
		vistos[simbolo] = true
	igual(vistos.size(), quantas, "as sete raridades sao distinguiveis SO pelo simbolo")

	# o controle: sem ele, uma lista de sete cores IGUAIS passaria em tudo acima -- o que
	# se mede aqui e que o simbolo acrescenta leitura, e nao que ele existe
	var cores := {}
	for categoria in quantas:
		cores[Paleta.RARIDADES[categoria]] = true
	igual(cores.size(), quantas, "e as sete cores tambem sao distintas entre si")

	# categoria fora da faixa nao devolve texto vazio: rotulo vazio na tela parece defeito
	ok(not DescobertasTela.simbolo_de(-1).is_empty(), "categoria invalida ainda tem marca")
	ok(not DescobertasTela.simbolo_de(999).is_empty(), "e pelo outro lado tambem")


## ⚠️ A FONTE DE VERDADE E CONSULTADA, e nao o olho de quem escreveu.
func _os_simbolos_existem_na_fonte() -> void:
	var fonte := SystemFont.new()
	fonte.font_names = Tema.FONTES

	if not fonte.has_char(GLIFO_DE_CONTROLE.unicode_at(0)):
		# ponto cego DECLARADO: sem fonte carregada nao ha o que medir, e afirmar qualquer
		# coisa aqui seria um carimbo. Quem cobre isto e a captura.
		ok(
			true,
			"⚠️ sem fonte do sistema carregada: a cobertura de glifo NAO foi medida",
		)
		return

	for simbolo in Paleta.SIMBOLOS_DE_RARIDADE:
		for i in simbolo.length():
			ok(
				fonte.has_char(simbolo.unicode_at(i)),
				"a fonte monoespacada tem o glifo %s" % simbolo,
			)
	# e o alfabeto do efeito de letras, pelo mesmo motivo -- ele ja custou 22 ms uma vez
	for glifo in Letras.GLIFOS:
		ok(fonte.has_char(glifo.unicode_at(0)), "a fonte tem o glifo de letra %s" % glifo)

	# e as marcas de tipo de marco (issue #51), que entraram pelo mesmo caminho
	for marca in Panorama.MARCAS_DE_TIPO:
		for i in marca.length():
			ok(
				fonte.has_char(marca.unicode_at(i)),
				"a fonte tem o glifo de tipo de marco %s" % marca,
			)


## A escala do texto cresce o que se le, e nunca devolve tamanho invalido.
func _escala_do_texto() -> void:
	var valores: Array = Config.campo("escala_do_texto")["valores"]
	var anterior := 0
	for i in valores.size():
		Config.escolher("escala_do_texto", i)
		var tamanho := Tema.fonte(Tema.CORPO)
		ok(tamanho >= anterior, "escala %s nao encolhe o texto" % str(valores[i]))
		ok(tamanho >= 1, "e nunca devolve tamanho invalido")
		anterior = tamanho

	# ⚠️ e ela cresce DE VERDADE: sem esta linha, um Tema.fonte que ignorasse a opcao
	# passaria em tudo acima -- regua sem controle inventa a propria escala
	Config.escolher("escala_do_texto", 0)
	var em_cem := Tema.fonte(Tema.CORPO)
	Config.escolher("escala_do_texto", valores.size() - 1)
	ok(
		Tema.fonte(Tema.CORPO) > em_cem,
		"a maior escala da um texto MAIOR que a de 100%% (%d contra %d)" % [
			Tema.fonte(Tema.CORPO), em_cem,
		],
	)
	Config.escolher("escala_do_texto", 0)


## ⚠️ ALTO CONTRASTE SEPARA, e esta e a unica coisa que ele precisa fazer. O que se mede e
## a DISTANCIA de luminancia entre o que se le e o que fica atras -- afirmar "a cor mudou"
## passaria com uma troca que deixasse os dois mais parecidos.
func _alto_contraste_separa() -> void:
	var texto := Paleta.PAPER_CREAM
	var atras := Paleta.INK_BROWN

	Config.escolher("alto_contraste", 0)
	var normal := absf(Tema.cor(texto).get_luminance() - Tema.fundo(atras).get_luminance())
	igual(Tema.cor(texto), texto, "desligado, a cor nao e tocada")
	igual(Tema.fundo(atras), atras, "nem o fundo")

	Config.escolher("alto_contraste", 1)
	var reforcado := absf(
		Tema.cor(texto).get_luminance() - Tema.fundo(atras).get_luminance()
	)
	ok(
		reforcado > normal,
		"ligado, a distancia entre texto e fundo CRESCE (%.3f contra %.3f)" % [
			reforcado, normal,
		],
	)

	# e a matiz sobrevive: a paleta continua sendo a do docs/ARTE.md, so mais separada.
	# Trocar por branco puro apagaria "dourado e producao, ciano e automacao".
	var dourado := Paleta.BANANA_GOLD
	ok(
		absf(Tema.cor(dourado).h - dourado.h) < 0.05,
		"e o dourado continua dourado, e nao vira branco",
	)
	Config.escolher("alto_contraste", 0)


## Reduzir movimento e desligar particulas param o EFEITO -- nunca a producao.
func _reduzir_movimento_alcanca_as_letras() -> void:
	Config.escolher("particulas_de_letra", 1)
	Config.escolher("reduzir_movimento", 0)
	ok(Letras.desenhando(), "com tudo ligado, as letras sobem")

	Config.escolher("reduzir_movimento", 1)
	ok(not Letras.desenhando(), "⚠️ reduzir movimento alcanca as letras (issue #22)")

	Config.escolher("reduzir_movimento", 0)
	Config.escolher("particulas_de_letra", 0)
	ok(not Letras.desenhando(), "e desligar particulas tambem")

	Config.escolher("particulas_de_letra", 1)
	ok(Letras.desenhando(), "e religar as duas devolve o efeito")


## ⚠️ A LISTA DE DIVIDA MORDE DOS DOIS LADOS. Nome nela tem que continuar SEM campo; sem
## esta metade, a linha passaria a esconder o dia em que o sistema chegasse e a opcao
## ficasse para tras.
func _divida_declarada() -> void:
	var campos := Config.nomes_de_campo()
	ok(not Config.SEM_SISTEMA_AINDA.is_empty(), "ha divida de interface declarada")
	for pendente in Config.SEM_SISTEMA_AINDA:
		ok(
			not campos.has(pendente),
			"%s esta na divida e NAO e uma opcao da tela" % pendente,
		)

	# e as duas abas novas existem de verdade, com campo dentro
	for aba in ["INTERFACE", "ACESSIBILIDADE"]:
		ok(
			not Config.campos_da_aba(aba).is_empty(),
			"a aba %s tem campo para desenhar" % aba,
		)


## ⚠️ O BOTAO DIGITAR ENCOLHE, MAS NUNCA SOME (issue #68).
##
## Ele envelhece junto com o papel do jogador -- aos trinta minutos ele dava +1 contra 37,7
## milhoes por segundo, e continuava sendo o maior elemento da tela. Mas quem nao pode usar
## o mouse depende da tecla, e a issue #54 e explicita: atividade acelera, nunca obriga.
##
## A fase mais tardia ainda precisa ser um alvo clicavel de verdade.
func _o_digitar_nunca_some() -> void:
	var alturas: Array[float] = preload("res://src/ui/hud.gd").ALTURAS_DO_DIGITAR
	var fronteiras: Array[float] = preload("res://src/ui/hud.gd").SEGUNDOS_QUE_O_CLIQUE_VALE

	ok(not alturas.is_empty(), "o botao tem pelo menos uma fase")
	igual(
		fronteiras.size(), alturas.size() - 1,
		"ha uma fronteira a menos que fases -- N fases, N-1 cortes",
	)

	var anterior := 99999.0
	for i in alturas.size():
		# ⚠️ o minimo alvo de toque: um botao mais baixo que isto e um alvo que a mao erra,
		# e erro de clique num botao que produz recurso e progresso perdido em silencio
		ok(
			alturas[i] >= 32.0,
			"a fase %d tem %.0f px de altura -- alvo clicavel de verdade" % [i, alturas[i]],
		)
		ok(alturas[i] <= anterior, "a fase %d nao e maior que a anterior" % i)
		anterior = alturas[i]

	var caindo := true
	for i in range(1, fronteiras.size()):
		if fronteiras[i] >= fronteiras[i - 1]:
			caindo = false
	ok(caindo, "as fronteiras caem: cada fase exige o clique valendo MENOS que a anterior")
