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
## E VERIFICA ANTES DE PROMOVER (issue #36). O temporario e RELIDO do disco e conferido
## contra o que se quis gravar; so entao o save anterior vira .backup e o novo toma o lugar
## dele. Sao duas regras, e as duas existem porque a rede de protecao vira ampliador de
## dano quando falta uma:
##
##   ⚠️ backup so vale se foi lido de volta. Promover um arquivo que ninguem releu e
##   guardar duas copias do mesmo defeito.
##
##   ⚠️ e save corrompido NUNCA sobrescreve backup bom. E o caso em que a protecao apagaria
##   justamente o que ela existe para guardar.
##
## Incremental acumula centenas de horas: perder save aqui nao se parece com perder save
## num jogo de sessao curta, e e por isso que esta rede existe separada do metadado.
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
## 11: entram `descobertas_quando` e `descobertas_grandeza`, o instante e a ordem de
## grandeza da producao em que cada descoberta saiu (issue #55). ⚠️ SAVE ANTIGO NAO GANHA
## VALOR NENHUM: os dois entram VAZIOS, e o Arquivo mostra o que tem. Preencher com zero
## faria toda descoberta antiga dizer "encontrada em 1 de janeiro de 1970, com 1 caractere
## produzido" -- dado inventado que parece dado.
const VERSAO: int = 11

const CAMINHO_PADRAO := "user://save.json"

## Sufixo da copia de seguranca, ao lado do save: user://save_1.json.backup. O metadado
## dele sai de graca -- o .meta de um arquivo e sempre o caminho dele mais ".meta", entao o
## backup ganha o proprio cartao sem ninguem inventar um segundo esquema de nomes.
const SUFIXO_BACKUP := ".backup"

## Variavel e nao constante para a suite poder gravar num arquivo proprio. Sem isto ela
## sobrescreveria a partida de quem esta desenvolvendo, toda vez que rodasse.
var caminho: String = CAMINHO_PADRAO


static func caminho_do_backup(caminho_do_save: String) -> String:
	return caminho_do_save + SUFIXO_BACKUP


func existe() -> bool:
	return FileAccess.file_exists(caminho)


## Apaga o save, o metadado dele E o backup. Deixar qualquer um dos tres para tras faria o
## menu listar um Manuscrito que nao existe mais -- e o backup sozinho ressuscitaria a
## partida que o jogador acabou de mandar apagar.
func apagar() -> void:
	apagar_arquivos(caminho)


## O mesmo, para um slot que NAO e o aberto. A tela de Arquivos exclui o Manuscrito que o
## jogador apontou, e apontar nao e abrir (issue #40).
##
## ⚠️ E ELA PRECISA SER ESTA FUNCAO, e nao um apagar() com Save.caminho trocado na mao em
## volta. Trocar e devolver o caminho e uma operacao com duas metades, e a metade que
## devolve e a que se perde num `return` no meio -- deixando o jogo inteiro gravando no
## slot que a pessoa acabou de mandar apagar, sem um erro sequer.
func apagar_arquivos(caminho_do_save: String) -> void:
	if FileAccess.file_exists(caminho_do_save):
		DirAccess.remove_absolute(caminho_do_save)
	Manuscrito.apagar_de(caminho_do_save)
	var reserva := caminho_do_backup(caminho_do_save)
	if FileAccess.file_exists(reserva):
		DirAccess.remove_absolute(reserva)
	Manuscrito.apagar_de(reserva)


## Devolve se gravou. O timestamp sai daqui e nao do Jogo: e o relogio do sistema no
## instante da gravacao, e a producao offline da issue #9 e a diferenca entre ele e o
## relogio da proxima abertura.
func gravar() -> bool:
	var agora := Time.get_unix_time_from_system()
	# a data de nascimento do Manuscrito e carimbada na PRIMEIRA gravacao e nao muda mais.
	# Partida nova comeca com zero porque ate gravar ela ainda nao aconteceu em disco.
	#
	# ⚠️ EM SEGUNDOS INTEIROS, E O floori() NAO E COSMETICO. O JSON do Godot guarda 15
	# digitos significativos, e um horario unix ja gasta 10 antes da virgula: sobram cinco
	# casas, e o resto e descartado na serializacao. Guardar aqui uma precisao que o
	# formato nao carrega cria um campo que MUDA SOZINHO ao ir e voltar do disco.
	#
	# Medido no 4.7.2: 1789699053,5935123 volta como 1789699053,5935099 -- 2,4 microssegundos.
	# A perda acontece UMA vez e nao acumula (a segunda ida e volta devolve identico).
	#
	# Isso passou despercebido por um motivo que vale escrever: o relogio do Windows
	# entrega ~1 ms de resolucao, e 1789699701,936 cabe inteiro nos 15 digitos. A suite
	# ficou verde na maquina de quem escreveu e reprovou no CI em Linux, onde o mesmo
	# relogio entrega microssegundos. Foi a primeira coisa que o CI da issue #50 pegou.
	#
	# Segundo inteiro basta porque os dois unicos consumidores -- a tela de Arquivos e o
	# cartao do menu -- passam este numero por Relogio.quando(), que mostra DATA. Precisao
	# que ninguem consegue ver e precisao que so serve para mentir.
	if Jogo.criado_em <= 0.0:
		Jogo.criado_em = floorf(agora)

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
		"descobertas_quando": Jogo.descobertas_quando,
		"descobertas_grandeza": Jogo.descobertas_grandeza,
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

	# ⚠️ RELE O QUE ACABOU DE ESCREVER. Disco cheio, escrita truncada e arquivo intacto com
	# conteudo errado passam pelo store_string sem reclamar; o unico jeito de saber que a
	# partida esta la e abrindo o arquivo. Gravacao que nao passa daqui nao encosta no save
	# final nem no backup -- o jogador continua com a partida anterior inteira.
	if not _confere(temporario, dados):
		push_error("Save: o arquivo gravado nao confere com a partida; nada foi trocado")
		DirAccess.remove_absolute(temporario)
		return false

	_promover_a_backup()

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


## O principal primeiro; o backup quando ele nao serve. Devolver 0.0 continua significando
## "nao havia partida", e nao "deu erro" -- os dois casos levam ao mesmo lugar, que e
## comecar do zero, e so um deles imprime motivo.
func carregar() -> float:
	var lido = _ler_cru(caminho)
	if _e_do_futuro(lido):
		# ⚠️ SAVE DO FUTURO NAO CAI NO BACKUP. Adivinhar campo desconhecido ja apagaria
		# progresso; carregar um backup antigo por cima de uma partida mais nova apagaria
		# mais ainda, porque a gravacao seguinte escreveria o velho em cima do novo. O
		# backup existe contra corrupcao, e nao contra troca de versao.
		push_error("Save: %s e da versao %d e o jogo le ate a %d" % [
			caminho, int((lido as Dictionary).get("versao", 0)), VERSAO,
		])
		return 0.0

	if lido == null:
		lido = _ler_cru(caminho_do_backup(caminho))
		if lido == null or _e_do_futuro(lido):
			return 0.0
		# o jogador precisa saber que a partida veio da copia: o que ele produziu entre a
		# ultima gravacao boa e a quebra nao esta aqui
		print("Save: o principal nao abriu -- a partida veio do backup")

	var dados: Dictionary = lido
	var versao := int(dados.get("versao", 0))
	if versao < VERSAO:
		dados = _migrar(dados, versao)
	else:
		# ⚠️ O PADRAO VALE PARA TODO SAVE, e nao so para o que veio de uma versao antiga.
		# Ate a issue #55 o preenchimento so rodava dentro de _migrar, entao um arquivo NA
		# VERSAO ATUAL sem algum campo caia direto em _aplicar -- que indexa `dados["nome"]`
		# sem .get e morre ali, com a partida pela metade.
		#
		# Nao e hipotetico: foi exatamente assim que o primeiro caso de teste da colecao
		# reprovou, e o reflexo teria sido "consertar o teste". O arquivo de teste era
		# JSON valido, na versao certa, e mesmo assim nao carregava.
		dados = _completar(dados.duplicate(true))

	_aplicar(dados)
	EventBus.jogo_carregado.emit()
	return float(dados.get("gravado_em", 0.0))


## O conteudo de um arquivo de save, ou null quando ele nao abre. NAO julga versao de
## proposito: quem decide o que fazer com um save do futuro e carregar(), porque a decisao
## e sobre recorrer ou nao ao backup, e essa escolha nao cabe a um leitor de arquivo.
func _ler_cru(alvo: String) -> Variant:
	if not FileAccess.file_exists(alvo):
		return null
	var arquivo := FileAccess.open(alvo, FileAccess.READ)
	if arquivo == null:
		push_error("Save: nao abriu %s para leitura" % alvo)
		return null
	var cru = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()

	if typeof(cru) != TYPE_DICTIONARY:
		push_error("Save: %s nao contem um objeto JSON" % alvo)
		return null
	return cru


static func _e_do_futuro(lido: Variant) -> bool:
	return lido != null and int((lido as Dictionary).get("versao", 0)) > VERSAO


## Rele o arquivo e compara com o que se quis gravar. Confere as chaves todas e o valor de
## cada campo de TEXTO -- que e onde moram os acumuladores, gravados como texto de Grande
## justamente para a ida e volta ser identidade (decisao 0001). Numero solto fica de fora
## da comparacao: o JSON devolve int como float, e um 3 que volta 3.0 nao e defeito.
func _confere(alvo: String, esperado: Dictionary) -> bool:
	var lido = _ler_cru(alvo)
	if lido == null:
		return false
	var dados: Dictionary = lido
	for campo in esperado:
		if not dados.has(campo):
			return false
		if typeof(esperado[campo]) == TYPE_STRING and str(dados[campo]) != str(esperado[campo]):
			return false
	return int(dados.get("versao", 0)) == VERSAO


## O save atual vira a copia de seguranca -- e so ele, e so se ABRIR.
##
## ⚠️ As duas guardas sao a issue inteira. Sem a primeira, um principal corrompido
## sobrescreveria um backup bom, e a rede de protecao viraria o ampliador do dano. Sem a
## segunda -- copiar em temporario e renomear -- um desligamento no meio da copia deixaria
## um backup pela metade, o mesmo defeito que a gravacao em temporario existe para evitar.
func _promover_a_backup() -> void:
	if not existe():
		return
	if _ler_cru(caminho) == null:
		push_warning("Save: o principal nao abre; o backup fica como esta")
		return

	var destino := caminho_do_backup(caminho)
	if not _copiar_com_seguranca(caminho, destino):
		push_error("Save: nao consegui promover %s a backup" % caminho)
		return
	# o metadado vai junto, senao o menu descreveria o backup com o cartao de outra coisa
	var metadado := Manuscrito.caminho_do_meta(caminho)
	if FileAccess.file_exists(metadado):
		_copiar_com_seguranca(metadado, Manuscrito.caminho_do_meta(destino))


static func _copiar_com_seguranca(de: String, para: String) -> bool:
	var temporario := para + ".tmp"
	if DirAccess.copy_absolute(de, temporario) != OK:
		return false
	if FileAccess.file_exists(para):
		DirAccess.remove_absolute(para)
	return DirAccess.rename_absolute(temporario, para) == OK


## Traz um save antigo para a forma atual. Campo que nao existia ganha o padrao de partida
## nova -- nunca zero em cima do que ja estava la, que seria perder progresso calado.
##
## Enquanto so existe a versao 1, migrar e preencher o que falta. Quando a issue #16
## acrescentar descobertas, e aqui que o ramo dela entra.
## Deixa passar so o que tem id na lista de descobertas encontradas.
func _so_dos_encontrados(lido: Variant) -> Dictionary:
	var limpo := {}
	if lido is Dictionary:
		for id in (lido as Dictionary):
			if Jogo.descobertas.has(str(id)):
				limpo[str(id)] = (lido as Dictionary)[id]
	return limpo


## Campo ausente ganha o padrao de partida nova -- nunca zero em cima do que ja estava la.
func _completar(dados: Dictionary) -> Dictionary:
	for campo in _PADROES:
		if not dados.has(campo):
			dados[campo] = _PADROES[campo]
	return dados


func _migrar(dados: Dictionary, de_versao: int) -> Dictionary:
	var migrado := _completar(dados.duplicate(true))
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
	# ⚠️ vazios, e nao zerados: ver o comentario da versao 11 em VERSAO
	"descobertas_quando": {},
	"descobertas_grandeza": {},
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
	# ⚠️ CHAVE SOLTA E CHAVE PERDIDA. Um carimbo cujo id nao esta mais na lista de
	# encontradas e lixo que o Arquivo leria como verdade -- e ele entra por caminhos que
	# nao passam por aqui (save editado a mao, migracao de versao futura). Filtrar na
	# leitura custa um laco e fecha a familia inteira.
	Jogo.descobertas_quando = _so_dos_encontrados(dados.get("descobertas_quando", {}))
	Jogo.descobertas_grandeza = _so_dos_encontrados(dados.get("descobertas_grandeza", {}))


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
