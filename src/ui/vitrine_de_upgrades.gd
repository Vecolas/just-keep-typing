## O QUE A LOJA DE UPGRADES MOSTRA: o que da para comprar agora, o que vem depois, e o que
## cada linha SIGNIFICA em uma frase.
##
## ⚠️ ELA EXISTE PORQUE UPGRADE NAO ERA CONTEUDO, E SIM UMA LINHA COMPRAVEL. Ate aqui a loja
## escrevia "Dedos Mais Ageis — 124" e escondia o resto no tooltip. Duas consequencias, e as
## duas medidas na tela:
##
##   1. quem nao passa o mouse nunca sabe o que comprou. Tooltip nao alcanca teclado, nao
##      alcanca toque e nao alcanca quem le a tela de relance -- e a issue #43 ja decidiu que
##      informacao essencial nao mora no hover.
##   2. a loja nao tinha FUTURO. Um incremental sem "o que vem depois" nao da motivo para
##      continuar: o jogador compra o que esta aceso e a tela volta a ser uma lista de precos.
##
## ⚠️ E O EFEITO EM TEXTO NAO E DECORACAO -- ele e o unico lugar do jogo que le o par
## (tipo_de_efeito, valor) e diz em portugues o que ele faz. Sem ele, "x1,8" e "+0,35" sao o
## mesmo borrao para quem nunca abriu um .tres.
##
## ⚠️ NENHUMA REGRA DE GAMEPLAY MORA AQUI. Quem decide quanto o upgrade rende continua sendo
## a Economia, perguntando pelo TIPO de efeito; esta classe so LE o dado para escrever. No
## dia em que aparecer uma conta aqui, ela sera a segunda fonte do multiplicador.
##
## Logica pura, sem no e sem cena: a suite afirma a vitrine inteira sem subir a HUD.
class_name VitrineDeUpgrades

## Quantos upgrades futuros a coluna mostra.
##
## ⚠️ Limite de DESIGN, e nao botao de tuning. Ele responde "quanto do futuro revelar", e a
## resposta tem dois lados: menos que isto nao cria antecipacao, e mais que isto vira a
## arvore inteira exposta -- que e spoiler, e tambem uma coluna que ninguem le ate o fim.
const FUTUROS_NA_TELA: int = 4

## O lado do icone de familia, em pixels logicos.
##
## ⚠️ IGUAL AO TAMANHO EM QUE A PECA FOI DESENHADA -- os icones de docs/ASSETS.md sao 32x32 --,
## ou seja escala 1. Pixel art so e exata em escala INTEIRA (decisao 0006), e 32 e o unico
## numero que nao reamostra nada aqui. Ele nao cresce com a escala do texto de proposito: o
## icone e decoracao, quem carrega a leitura e o nome escrito ao lado, e um 1,25x em pixel art
## seria o borrao que a decisao 0006 se compromete a evitar.
const LADO_DO_ICONE: int = 32

## O icone de cada familia, na ordem do enum DadosUpgrade.Familia.
##
## ⚠️ REUSA A FAMILIA DE ASSETS QUE JA EXISTE, e nao pede peca nova. Os quatro icones do menu
## respondem exatamente as quatro familias -- banana e o macaco, engrenagem e a maquina, papel
## e a organizacao, infinito e o conhecimento --, e pedir quatro pecas novas para o mesmo
## significado seria criar um segundo conjunto que vai divergir do primeiro no proximo lote
## (CONVENCOES: "derive em vez de duplicar").
##
## ⚠️ A ENTRADA DE SEM_FAMILIA E VAZIA, e ela existe para o indice bater. Nenhuma tela chega a
## mostra-la porque a suite nao deixa upgrade nenhum ficar nessa familia -- e string vazia
## aqui significa "sem icone", que e o mesmo tratamento que uma peca ausente no disco recebe.
const ICONES_DE_FAMILIA: PackedStringArray = [
	"",
	"icone_banana",
	"icone_engrenagem",
	"icone_papel",
	"icone_infinito",
]

## A frase de cada tipo de efeito. ⚠️ INDEXADA PELO ENUM DE Efeito, e o portao exige uma
## entrada para CADA valor dele: tipo de efeito novo sem frase apareceria como um cartao com
## a linha de efeito VAZIA -- sem erro, sem aviso, e exatamente no lugar que esta classe
## existe para preencher.
##
## ⚠️ E ELAS SAO MOLDES EM CONSTANTE, ou seja o ponto cego do portao de texto: ele varre
## literal, e literal em constante chega ao jogador por variavel. Por isso esta tabela e
## lida DA FONTE pelo teste_texto, como a do Formatador ja e.
const FRASES_DE_EFEITO: Dictionary = {
	DadosUpgrade.Efeito.VELOCIDADE_DO_MACACO: "×%s na velocidade de cada macaco",
	DadosUpgrade.Efeito.PRODUCAO_GLOBAL: "×%s em toda a produção",
	DadosUpgrade.Efeito.LIGA_PRODUCAO_AUTOMATICA: "o macaco passa a digitar sozinho",
	DadosUpgrade.Efeito.CAPACIDADE: "×%s na capacidade da sala",
	DadosUpgrade.Efeito.VELOCIDADE_SOMADA: "+%s por segundo em cada macaco",
	DadosUpgrade.Efeito.CUSTO_DE_MACACO: "custo do macaco ×%s",
}


## O que da para ver na loja agora: nao comprado e com o requisito ja cruzado.
##
## A ordem e a da Economia -- do mais barato para o mais caro --, e isso preserva a escada
## dentro de cada familia sem ordenar de novo.
static func disponiveis() -> Array[DadosUpgrade]:
	var lista: Array[DadosUpgrade] = []
	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue
		lista.append(dados)
	return lista


## O que vem depois: ainda bloqueado pelo requisito, do mais PROXIMO de desbloquear para o
## mais distante.
##
## ⚠️ ORDENADO POR REQUISITO, E NAO POR CUSTO. Economia.upgrades() vem por custo, e custo e a
## pergunta de quem ja pode comprar. Aqui a pergunta e outra -- "o que aparece primeiro?" --,
## e responder com o preco poria um upgrade barato de requisito distante na frente de um caro
## que desbloqueia no minuto seguinte.
static func futuros(quantos: int = FUTUROS_NA_TELA) -> Array[DadosUpgrade]:
	var lista: Array[DadosUpgrade] = []
	for dados in Economia.upgrades():
		if Jogo.upgrades_comprados.has(dados.id):
			continue
		if not Grande.de_float(dados.requisito).maior_que(Jogo.total_caracteres):
			continue
		lista.append(dados)
	return ordenar_por_requisito(lista).slice(0, maxi(quantos, 0))


## Ordena uma lista de upgrades do requisito MENOR para o MAIOR, no lugar.
##
## ⚠️ E UMA FUNCAO SEPARADA PORQUE O PORTAO NAO CONSEGUE MEDI-LA DE OUTRO JEITO. No catalogo de
## hoje, custo e requisito sobem juntos: ordenar por um ou pelo outro da a mesma lista, e uma
## afirmacao sobre `futuros()` passa igual com a regra certa e com a errada -- ou seja, e um
## carimbo. Com a ordenacao exposta, a suite alimenta uma lista em que as duas ordens DIFEREM e
## a afirmacao volta a morder.
##
## No dia em que um upgrade barato tiver requisito distante -- que e conteudo perfeitamente
## legitimo --, e esta funcao que impede a coluna "proximas melhorias" de mentir.
static func ordenar_por_requisito(lista: Array[DadosUpgrade]) -> Array[DadosUpgrade]:
	lista.sort_custom(func(a: DadosUpgrade, b: DadosUpgrade) -> bool:
		return a.requisito < b.requisito)
	return lista


## Separa uma lista por familia. Dicionario de Familia -> Array[DadosUpgrade], preservando
## a ordem em que a lista chegou dentro de cada familia.
static func por_familia(lista: Array[DadosUpgrade]) -> Dictionary:
	var mapa := {}
	for dados in lista:
		if not mapa.has(dados.familia):
			mapa[dados.familia] = [] as Array[DadosUpgrade]
		mapa[dados.familia].append(dados)
	return mapa


## Quantos caracteres ainda faltam para o upgrade aparecer na loja. Nunca negativo: o que
## ja desbloqueou falta zero, e nao "menos trezentos".
static func falta_para(dados: DadosUpgrade) -> Grande:
	var requisito := Grande.de_float(dados.requisito)
	if not requisito.maior_que(Jogo.total_caracteres):
		return Grande.zero()
	return requisito.menos(Jogo.total_caracteres)


## O EFEITO EM UMA FRASE. Nunca vazia: tipo sem frase na tabela devolve o nome do proprio
## tipo em vez de nada, porque rotulo vazio na tela le como defeito e nao como "sem efeito".
static func efeito_em_texto(dados: DadosUpgrade) -> String:
	if not FRASES_DE_EFEITO.has(dados.tipo_de_efeito):
		# ⚠️ nao e um caminho morto: ele e o que faz tipo novo sem frase aparecer COMO
		# PENDENCIA na tela em vez de virar uma linha em branco. O portao reprova antes.
		return _traduzir("efeito sem descrição")
	var molde: String = FRASES_DE_EFEITO[dados.tipo_de_efeito]
	if not molde.contains("%s"):
		return _traduzir(molde)
	# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
	return _traduzir(molde) % Formatador.formatar(Grande.de_float(dados.valor))


## O que falta para o upgrade futuro aparecer, em uma frase.
static func desbloqueio_em_texto(dados: DadosUpgrade) -> String:
	return _traduzir("faltam %s caracteres") % Formatador.formatar(falta_para(dados))


## O id do asset do icone de uma familia, ou vazio quando ela nao tem.
##
## ⚠️ Familia fora da faixa devolve vazio em vez de estourar o indice: cabecalho sem icone
## ainda se le, quadro derrubado nao.
static func icone_de_familia(familia: int) -> String:
	if familia < 0 or familia >= ICONES_DE_FAMILIA.size():
		return ""
	return ICONES_DE_FAMILIA[familia]


## Equivale ao tr() das cenas. Uma classe estatica nao tem self, entao chama direto o
## servidor -- e a mesma busca que o tr() faz por baixo. Ver Formatador._traduzir.
static func _traduzir(molde: String) -> String:
	return String(TranslationServer.translate(molde))
