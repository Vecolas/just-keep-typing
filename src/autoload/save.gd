## Grava e carrega a partida. Nome traduzido do SaveManager do GDD §37 -- ver
## docs/decisoes/0002-codigo-em-portugues.md.
##
## CAMPO DE VERSAO DESDE A PRIMEIRA GRAVACAO. Save sem versao e divida que so aparece
## quando ja existe jogador em campo: na hora em que um campo novo entra, nao ha como
## distinguir "arquivo antigo" de "arquivo corrompido", e a unica saida honesta vira
## apagar o progresso de quem estava jogando.
##
## GRAVA EM TEMPORARIO E RENOMEIA. Escrever direto no arquivo final significa que fechar o
## jogo no meio da gravacao deixa um save pela metade -- que e pior que save nenhum,
## porque o jogador acha que tem progresso salvo.
##
## Os acumuladores vao como TEXTO de Grande (mantissa e expoente), nunca como float: o
## float satura em 10^308 e o jogo passa disso na v0.4. Ver decisao 0001.
##
## Opcoes -- idioma, video, resolucao -- NAO entram aqui. Elas sao da INSTALACAO e nao da
## partida, e moram em user://opcoes.json: trocar de slot de save nao pode mudar a
## resolucao de quem joga. Ver CONVENCOES.md, "Video e opcoes".
extends Node

## Sobe quando a forma do arquivo muda. Save mais antigo passa por _migrar antes de ser
## aplicado; save mais NOVO que o jogo e recusado, porque adivinhar campo do futuro e como
## se perde progresso de verdade.
## 2: `maquinas`, que era contagem e nunca chegou a ser escrita por ninguem, virou
## `maquina_atual`, que e o id do tier em uso (issue #14).
## 3: entra `sala_atual`, o id da sala em uso (issue #15).
## 4: entra `descobertas`, os ids ja encontrados (issue #16).
## 5: entram os campos de estatistica -- recorde, macacos comprados, offline
## acumulado, prestigios e tempo da run (issue #21).
## 6: entram os Pontos de Teorema ganhos na vida, os niveis da Arvore e o recorde
## de total (issues #24 e #25).
## 7: entram as automacoes compradas e o estado ligado de cada uma (issue #28).
## 8: entra o contador de Universos reescritos (issue #31). Os Fragmentos ja existiam
## desde a versao 1, guardados e nunca usados -- o campo estava la esperando o sistema.
## 9: entra o instante da ultima descoberta rara, que espaca uma Lendaria da seguinte
## (issue #32). Negativo significa "nenhuma ainda".
## 10: entram o nome do Manuscrito, a data de criacao e a producao por segundo do instante
## da gravacao (issue #35). Os tres existem para o .meta poder ser DERIVADO do save: numero
## que so morasse no metadado divergiria do save e ninguem notaria.
const VERSAO: int = 10

const CAMINHO_PADRAO := "user://save.json"

## Variavel e nao constante para a suite poder gravar num arquivo proprio. Sem isto ela
## sobrescreveria a partida de quem esta desenvolvendo, toda vez que rodasse.
var caminho: String = CAMINHO_PADRAO


func existe() -> bool:
	return FileAccess.file_exists(caminho)


## Apaga o save E o metadado dele. Deixar o .meta para tras faria o menu listar um
## Manuscrito que nao existe mais -- e oferecer "continuar" para um arquivo apagado.
func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(caminho)
	Manuscrito.apagar_de(caminho)


## Devolve se gravou. O timestamp sai daqui e nao do Jogo: e o relogio do sistema no
## instante da gravacao, e a producao offline da issue #9 e a diferenca entre ele e o
## relogio da proxima abertura.
func gravar() -> bool:
	var agora := Time.get_unix_time_from_system()
	# a data de nascimento do Manuscrito e carimbada na PRIMEIRA gravacao e nao muda mais.
	# Partida nova comeca com zero porque ate gravar ela ainda nao aconteceu em disco.
	if Jogo.criado_em <= 0.0:
		Jogo.criado_em = agora

	var dados := {
		"versao": VERSAO,
		"gravado_em": agora,
		"nome": Jogo.nome,
		"criado_em": Jogo.criado_em,
		"total_caracteres": Jogo.total_caracteres.para_texto(),
		"caracteres_da_run": Jogo.caracteres_da_run.para_texto(),
		"dinheiro": Jogo.dinheiro.para_texto(),
		"macacos": Jogo.macacos.para_texto(),
		"maquina_atual": Jogo.maquina_atual,
		"sala_atual": Jogo.sala_atual,
		"pontos_de_teorema": Jogo.pontos_de_teorema.para_texto(),
		"pontos_totais": Jogo.pontos_totais.para_texto(),
		"recorde_de_total": Jogo.recorde_de_total.para_texto(),
		"teoremas": Jogo.teoremas,
		"automacoes": Jogo.automacoes,
		"fragmentos": Jogo.fragmentos.para_texto(),
		"multiplicador_global": Jogo.multiplicador_global,
		"tempo_jogado": Jogo.tempo_jogado,
		"tempo_da_ultima_rara": Jogo.tempo_da_ultima_rara,
		"tempo_da_run": Jogo.tempo_da_run,
		"caracteres_por_segundo": Jogo.caracteres_por_segundo.para_texto(),
		"recorde_por_segundo": Jogo.recorde_por_segundo.para_texto(),
		"macacos_comprados": Jogo.macacos_comprados.para_texto(),
		"total_offline": Jogo.total_offline.para_texto(),
		"prestigios": Jogo.prestigios,
		"reescritas": Jogo.reescritas,
		"upgrades_comprados": Jogo.upgrades_comprados,
		"marcos_alcancados": Jogo.marcos_alcancados,
		"descobertas": Jogo.descobertas,
	}

	var temporario := caminho + ".tmp"
	var arquivo := FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		push_error("Save: nao abriu %s para escrita (erro %d)" % [
			temporario, FileAccess.get_open_error(),
		])
		return false
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()

	# so agora o arquivo final deixa de ser o antigo. Ate esta linha, um desligamento
	# perde a gravacao nova e MANTEM a anterior, que e o comportamento certo.
	if existe():
		DirAccess.remove_absolute(caminho)
	var erro := DirAccess.rename_absolute(temporario, caminho)
	if erro != OK:
		push_error("Save: nao renomeou %s para %s (erro %d)" % [temporario, caminho, erro])
		return false

	# o metadado vai DEPOIS do save e com o mesmo instante: e uma copia adiantada do que
	# acabou de ser gravado, e o menu so pode ler adiantado o que ja esta em disco. Falhar
	# aqui nao invalida a gravacao -- o slot abre igual, reconstruindo o metadado do save.
	var manuscrito := Manuscrito.do_jogo()
	manuscrito.ultima_sessao = agora
	manuscrito.gravar_em(caminho)

	EventBus.jogo_gravado.emit()
	return true


## Devolve o timestamp da gravacao, ou 0.0 quando nao havia save para carregar. E esse
## numero que a producao offline usa; devolver 0.0 e o jeito de dizer "partida nova".
## Partida nova, sem tocar em arquivo nenhum. Sai do MESMO dicionario que a migracao usa
## para preencher campo que falta: duas definicoes de "partida nova" divergiriam na
## primeira issue que acrescentasse um campo.
##
## Existe para o slot vazio (issue #34) -- o jogo nunca chamava isto porque abrir sem save
## era so nao carregar nada.
func recomecar() -> void:
	_aplicar(_PADROES.duplicate(true))
	EventBus.jogo_carregado.emit()


func carregar() -> float:
	if not existe():
		return 0.0

	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Save: nao abriu %s para leitura" % caminho)
		return 0.0
	var cru = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()

	if typeof(cru) != TYPE_DICTIONARY:
		push_error("Save: %s nao contem um objeto JSON" % caminho)
		return 0.0

	var dados: Dictionary = cru
	var versao := int(dados.get("versao", 0))
	if versao > VERSAO:
		# save de um jogo mais novo. Adivinhar o que os campos desconhecidos significam e
		# como se apaga progresso de verdade -- melhor nao tocar em nada.
		push_error("Save: arquivo e da versao %d e o jogo le ate a %d" % [versao, VERSAO])
		return 0.0
	if versao < VERSAO:
		dados = _migrar(dados, versao)

	_aplicar(dados)
	EventBus.jogo_carregado.emit()
	return float(dados.get("gravado_em", 0.0))


## Traz um save antigo para a forma atual. Campo que nao existia ganha o padrao de partida
## nova -- nunca zero em cima do que ja estava la, que seria perder progresso calado.
##
## Enquanto so existe a versao 1, migrar e preencher o que falta. Quando a issue #16
## acrescentar descobertas, e aqui que o ramo dela entra.
func _migrar(dados: Dictionary, de_versao: int) -> Dictionary:
	var migrado := dados.duplicate(true)
	for campo in _PADROES:
		if not migrado.has(campo):
			migrado[campo] = _PADROES[campo]
	migrado["versao"] = VERSAO
	print("Save: migrado da versao %d para a %d" % [de_versao, VERSAO])
	return migrado


const _PADROES := {
	"gravado_em": 0.0,
	"nome": "",
	"criado_em": 0.0,
	"caracteres_por_segundo": "0",
	"total_caracteres": "0",
	"caracteres_da_run": "0",
	"dinheiro": "0",
	"macacos": "1",
	"maquina_atual": "",
	"sala_atual": "",
	"pontos_de_teorema": "0",
	"pontos_totais": "0",
	"recorde_de_total": "0",
	"teoremas": {},
	"automacoes": {},
	"fragmentos": "0",
	"multiplicador_global": 1.0,
	"tempo_jogado": 0.0,
	"tempo_da_ultima_rara": -1.0,
	"tempo_da_run": 0.0,
	"recorde_por_segundo": "0",
	"macacos_comprados": "0",
	"total_offline": "0",
	"prestigios": 0,
	"reescritas": 0,
	"upgrades_comprados": [],
	"marcos_alcancados": [],
	"descobertas": [],
}


func _aplicar(dados: Dictionary) -> void:
	Jogo.nome = str(dados["nome"])
	Jogo.criado_em = float(dados["criado_em"])
	# a producao volta como estava para o primeiro quadro nao mostrar zero. Economia
	# reescreve isto no tique seguinte -- guardar aqui e sobre a tela, e nao sobre a conta.
	Jogo.caracteres_por_segundo = Grande.de_texto(str(dados["caracteres_por_segundo"]))
	Jogo.total_caracteres = Grande.de_texto(str(dados["total_caracteres"]))
	Jogo.caracteres_da_run = Grande.de_texto(str(dados["caracteres_da_run"]))
	Jogo.dinheiro = Grande.de_texto(str(dados["dinheiro"]))
	Jogo.macacos = Grande.de_texto(str(dados["macacos"]))
	Jogo.maquina_atual = str(dados["maquina_atual"])
	Jogo.sala_atual = str(dados["sala_atual"])
	Jogo.pontos_de_teorema = Grande.de_texto(str(dados["pontos_de_teorema"]))
	Jogo.pontos_totais = Grande.de_texto(str(dados["pontos_totais"]))
	Jogo.recorde_de_total = Grande.de_texto(str(dados["recorde_de_total"]))
	Jogo.teoremas = _niveis_de(dados["teoremas"])
	Jogo.automacoes = _ligadas_de(dados["automacoes"])
	Jogo.fragmentos = Grande.de_texto(str(dados["fragmentos"]))
	Jogo.multiplicador_global = float(dados["multiplicador_global"])
	Jogo.tempo_jogado = float(dados["tempo_jogado"])
	Jogo.tempo_da_ultima_rara = float(dados["tempo_da_ultima_rara"])
	Jogo.tempo_da_run = float(dados["tempo_da_run"])
	Jogo.recorde_por_segundo = Grande.de_texto(str(dados["recorde_por_segundo"]))
	Jogo.macacos_comprados = Grande.de_texto(str(dados["macacos_comprados"]))
	Jogo.total_offline = Grande.de_texto(str(dados["total_offline"]))
	Jogo.prestigios = int(dados["prestigios"])
	Jogo.reescritas = int(dados["reescritas"])
	Jogo.upgrades_comprados = _lista_de_texto(dados["upgrades_comprados"])
	Jogo.marcos_alcancados = _lista_de_texto(dados["marcos_alcancados"])
	Jogo.descobertas = _lista_de_texto(dados["descobertas"])


## A chave existir significa comprada; o valor diz se esta ligada.
static func _ligadas_de(cru: Variant) -> Dictionary:
	var ligadas := {}
	if typeof(cru) != TYPE_DICTIONARY:
		return ligadas
	for chave in cru:
		ligadas[str(chave)] = bool(cru[chave])
	return ligadas


## O JSON devolve numero como float e nivel e int. Converter aqui e o que impede um
## nivel virar 3.0000000001 depois de uma ida e volta pelo save.
static func _niveis_de(cru: Variant) -> Dictionary:
	var niveis := {}
	if typeof(cru) != TYPE_DICTIONARY:
		return niveis
	for chave in cru:
		niveis[str(chave)] = int(cru[chave])
	return niveis


## O JSON devolve Array solto; o Jogo guarda Array[String]. Converter aqui e o que impede
## um id virar float por causa de um save escrito a mao.
static func _lista_de_texto(cru: Variant) -> Array[String]:
	var lista: Array[String] = []
	if typeof(cru) != TYPE_ARRAY:
		return lista
	for item in cru:
		lista.append(str(item))
	return lista
