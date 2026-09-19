## Quem decide O QUE vira aviso, em que FAIXA da tela ele aparece, e em que ordem (issue #69).
##
## ⚠️ AUTOLOAD, E NAO UM CAMPO DA HUD. Duas telas precisam da mesma fila: a HUD mostra o
## aviso da vez, e as Estatisticas mostram o registro do que passou. Com a fila morando
## dentro da HUD, a segunda tela so a alcancaria por caminho de no -- que e a regra 1 de
## arquitetura sendo quebrada por conveniencia.
##
## ⚠️ SAO DUAS FILAS, E A SEPARACAO E A REFORMA INTEIRA (plano §9.4).
##
##   DESTAQUE   o banner do topo. Descoberta, marco conceitual, Teorema, Universo. Grande,
##              legivel, e com tempo de leitura que cresce com a raridade.
##   RODAPE     a linha discreta embaixo. Marco de tamanho e mensagem operacional.
##
## Ate aqui havia UMA fila para tudo, e ela obrigava duas coisas incompativeis: uma descoberta
## Lendaria precisava de sete segundos para ser lida, e um marco de tamanho nao podia esperar
## sete segundos atras dela. A issue #69 resolveu o empate com prioridade -- e prioridade
## resolve QUEM VEM PRIMEIRO, nunca QUANTO TEMPO CADA UM PRECISA. Com duas faixas, as duas
## respostas passam a caber: a descoberta tem a duracao dela porque nao ha nada operacional na
## frente dela, e o autosave nunca mais apaga um texto colecionavel.
##
## ⚠️ E O REGISTRO E UM SO. Ele junta as duas faixas, ordenado do mais novo para o mais velho:
## quem perdeu um aviso nao precisa saber em que faixa ele passou -- ele precisa saber o que
## aconteceu. Duas listas na tela de Estatisticas seriam a costura da implementacao vazando
## para o jogador.
##
## E ele e o unico que sabe TRADUZIR acontecimento em prioridade, faixa e duracao. A HUD e o
## banner so desenham; as regras moram aqui, perto do dado que as sustenta -- e as de
## classificacao moram em FilaDeAvisos, estaticas, porque a regua tambem as le.
##
## ⚠️ O QUE ELE NAO FAZ: desenhar. Nao tem cena, nao tem no filho, nao sabe que a HUD
## existe. Quem quiser mostrar pergunta.
extends Node

## A marca do que nao tem raridade nem tipo de marco: os dois prestigios.
##
## ⚠️ OS DOIS USAM A MESMA, e isso nao quebra a regra de "cor + simbolo + nome" (issue #43):
## a regra existe para as SETE raridades serem distinguiveis entre si, e o banner de prestigio
## traz a rubrica escrita -- "TEOREMA PROVADO" e "UNIVERSO REESCRITO" nao se confundem. O ∞ e
## o simbolo dos dois porque os dois SAO a mesma ideia no docs/ARTE.md §5: producao infinita e
## progressao que recomeca.
const MARCA_DE_PRESTIGIO: String = "∞"

## Quando a raridade nao se aplica. ⚠️ NEGATIVO, e nao zero: zero e a categoria Comum, que e
## um valor legitimo -- sentinela que colide com valor valido some em silencio (CONVENCOES).
const SEM_CATEGORIA: int = -1

var _rodape := FilaDeAvisos.new()
var _destaque := FilaDeAvisos.new()


func _ready() -> void:
	EventBus.marco_alcancado.connect(_ao_alcancar_marco)
	EventBus.descoberta_encontrada.connect(_ao_encontrar_descoberta)
	EventBus.teorema_provado.connect(_ao_provar_teorema)
	EventBus.universo_reescrito.connect(_ao_reescrever_universo)
	# ⚠️ partida nova nao herda o registro da anterior: ele e de SESSAO, e um registro que
	# atravessa o prestigio mostraria acontecimentos de uma run que ja nao existe
	EventBus.jogo_carregado.connect(limpar)


## Anda as duas faixas e devolve quais trocaram de conteudo neste tique.
##
## ⚠️ QUEM CHAMA E UM SO. Duas telas ticando a mesma fila andariam o relogio dela duas vezes
## por quadro, e cada aviso duraria metade do que a tabela promete -- sem erro nenhum no
## console. Quem tica e a HUD, que e quem tem quadro.
func tique(delta: float) -> Dictionary:
	return {
		"rodape": _rodape.tique(delta),
		"destaque": _destaque.tique(delta),
	}


# --- a faixa do rodape ----------------------------------------------------------------

func tem_aviso() -> bool:
	return _rodape.tem_aviso()


func texto_atual() -> String:
	return _rodape.texto_atual()


func prioridade_atual() -> int:
	return _rodape.prioridade_atual()


func quanto_resta() -> float:
	return _rodape.quanto_resta()


## Quantas vezes o rodape trocou de conteudo. Ver FilaDeAvisos.sequencia().
func rodape_sequencia() -> int:
	return _rodape.sequencia()


# --- a faixa do banner ----------------------------------------------------------------

func tem_destaque() -> bool:
	return _destaque.tem_aviso()


## A carga do banner: rubrica, titulo, detalhe, marca e categoria. Vazia quando nao ha nada.
func destaque_atual() -> Dictionary:
	return _destaque.extras_atuais()


func destaque_quanto_resta() -> float:
	return _destaque.quanto_resta()


## Quantas vezes o banner trocou de conteudo. Ver FilaDeAvisos.sequencia().
func destaque_sequencia() -> int:
	return _destaque.sequencia()


# --- o que as duas faixas compartilham ------------------------------------------------

## O que passou nas DUAS faixas, do mais recente para o mais antigo.
##
## ⚠️ ORDENADO PELO INSTANTE DE JOGO, e nao concatenado. Emendar as duas listas mostraria
## todas as descobertas e depois todos os marcos, o que le como duas telas e nao como um
## registro -- e o registro existe justamente para reconstruir a ORDEM do que aconteceu.
func registro() -> Array[Dictionary]:
	var tudo: Array[Dictionary] = []
	tudo.append_array(_rodape.registro())
	tudo.append_array(_destaque.registro())
	tudo.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["instante"]) > float(b["instante"]))
	if tudo.size() > FilaDeAvisos.REGISTRO_MAXIMO:
		tudo.resize(FilaDeAvisos.REGISTRO_MAXIMO)
	return tudo


func limpar() -> void:
	_rodape.limpar()
	_destaque.limpar()


# --- de acontecimento a aviso ---------------------------------------------------------

## ⚠️ AS DUAS OPCOES SAO LIDAS NO INSTANTE DO AVISO, e nunca guardadas (issue #41): o
## jogador desliga no meio da partida e vale na hora. E elas so calam o AVISO -- o marco
## continua caindo e a descoberta continua valendo bonus, porque opcao de interface que
## mexesse em progressao seria dificuldade disfarcada de conforto.
func _ao_alcancar_marco(marco: DadosMarco) -> void:
	if not Config.ligado("aviso_de_marco"):
		return
	var prioridade := FilaDeAvisos.prioridade_de_marco(marco)
	if FilaDeAvisos.faixa_de_marco(marco) == FilaDeAvisos.Faixa.RODAPE:
		# o tr() vem ANTES da substituicao: traduz-se o molde, nunca o resultado
		_rodape.acrescentar(
			tr("Marco: %s") % tr(marco.titulo), prioridade, Jogo.tempo_jogado
		)
		return
	_destaque.acrescentar(
		tr("Marco: %s") % tr(marco.titulo), prioridade, Jogo.tempo_jogado, {
			"rubrica": tr("MARCO"),
			"titulo": tr(marco.titulo),
			"detalhe": tr(marco.texto),
			"marca": Panorama.marca_de(marco.tipo),
			"categoria": SEM_CATEGORIA,
		}
	)


func _ao_encontrar_descoberta(descoberta: DadosDescoberta) -> void:
	if not Config.ligado("aviso_de_descoberta"):
		return
	_destaque.acrescentar(
		tr("Descoberta: %s") % tr(descoberta.nome),
		FilaDeAvisos.prioridade_de_descoberta(descoberta),
		Jogo.tempo_jogado,
		{
			"rubrica": tr("NOVA DESCOBERTA"),
			"titulo": tr(descoberta.nome),
			"detalhe": tr(descoberta.texto),
			"marca": DescobertasTela.simbolo_de(descoberta.categoria),
			"categoria": int(descoberta.categoria),
			"segundos": FilaDeAvisos.segundos_de_descoberta(descoberta.categoria),
		}
	)


## ⚠️ O PRESTIGIO NAO TINHA AVISO NENHUM ATE AQUI, e ele e o maior acontecimento do jogo: a
## run reinicia, o multiplicador troca e a tela inteira volta ao comeco. O unico sinal disso
## era o contador zerar -- que le como perda, e nao como conquista.
##
## ⚠️ E ELE NAO PASSA PELAS OPCOES DE AVISO. "aviso_de_marco" e "aviso_de_descoberta" existem
## porque marco e descoberta acontecem centenas de vezes; prestigio acontece quando o jogador
## APERTA o botao de prestigiar. Calar a confirmacao de um gesto que a pessoa acabou de fazer
## nao e reduzir ruido, e esconder o resultado da acao dela.
func _ao_provar_teorema(pontos: Grande) -> void:
	_destaque.acrescentar(
		tr("Teorema provado"), FilaDeAvisos.Prioridade.CRITICA, Jogo.tempo_jogado, {
			"rubrica": tr("TEOREMA PROVADO"),
			"titulo": tr("Teorema provado"),
			"detalhe": tr("+%s em pontos de Teorema") % Formatador.formatar(pontos),
			"marca": MARCA_DE_PRESTIGIO,
			"categoria": SEM_CATEGORIA,
			"segundos": FilaDeAvisos.SEGUNDOS_POR_CATEGORIA[
				FilaDeAvisos.SEGUNDOS_POR_CATEGORIA.size() - 1
			],
		}
	)


func _ao_reescrever_universo(fragmentos: Grande) -> void:
	_destaque.acrescentar(
		tr("Universo reescrito"), FilaDeAvisos.Prioridade.CRITICA, Jogo.tempo_jogado, {
			"rubrica": tr("UNIVERSO REESCRITO"),
			"titulo": tr("Universo reescrito"),
			"detalhe": tr("+%s em Fragmentos") % Formatador.formatar(fragmentos),
			"marca": MARCA_DE_PRESTIGIO,
			"categoria": SEM_CATEGORIA,
			"segundos": FilaDeAvisos.SEGUNDOS_POR_CATEGORIA[
				FilaDeAvisos.SEGUNDOS_POR_CATEGORIA.size() - 1
			],
		}
	)
