## Suite do Autosave (issue #37): CADA GATILHO GRAVA EXATAMENTE UMA VEZ.
##
## O "exatamente" e a suite inteira. Nao gravar e o bug obvio -- o jogador perde o
## prestigio que acabou de fazer. Gravar duas vezes e o bug silencioso: o gatilho dispara
## no segundo 29,9, o cronometro de trinta segundos estoura no mesmo quadro, e o jogo
## escreve o mesmo arquivo duas vezes seguidas sem nada aparecer na tela. Por isso a
## afirmacao conta emissoes, e nao apenas verifica que o arquivo existe.
##
## Escreve num arquivo proprio e devolve Save.caminho no fim, como as outras.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_autosave.json"

var _gravacoes: int = 0
var _ouvinte: Callable


func _init() -> void:
	nome = "Autosave"


func executar() -> void:
	var caminho_original := Save.caminho
	# ⚠️ o estado do Jogo tem que voltar como estava. Gravar mexe no que esta na memoria, e
	# a suite seguinte comeca de onde esta -- um total deixado para tras aqui reprovou a
	# suite de eventos, que so sorteia acima de um requisito de producao.
	var total_original := Jogo.total_caracteres
	var criado_original := Jogo.criado_em
	Save.caminho = CAMINHO_DE_TESTE
	Save.apagar()

	_ouvinte = func() -> void: _gravacoes += 1
	EventBus.jogo_gravado.connect(_ouvinte)

	_o_cronometro()
	_os_gatilhos()
	_o_gatilho_reinicia_o_cronometro()
	_gravar_agora_e_o_ponto_de_entrada()

	EventBus.jogo_gravado.disconnect(_ouvinte)
	Save.apagar()
	Save.caminho = caminho_original
	Jogo.total_caracteres = total_original
	Jogo.criado_em = criado_original
	ok(Jogo.total_caracteres == total_original, "a suite devolveu o estado do Jogo")


## O cronometro nao encurtou nem virou "grava todo quadro": trinta segundos e o maximo de
## progresso que um desligamento na tomada custa, e tambem o minimo de escrita em disco
## que nao incomoda.
func _o_cronometro() -> void:
	_zerar()
	igual(
		Autosave.segundos_ate_gravar(), Autosave.INTERVALO,
		"o cronometro comeca cheio depois de uma gravacao",
	)

	Autosave.tique(Autosave.INTERVALO - 0.5)
	igual(_gravacoes, 0, "quase trinta segundos ainda nao gravam")

	Autosave.tique(0.6)
	igual(_gravacoes, 1, "e passados os trinta, grava uma vez")
	perto(
		Autosave.segundos_ate_gravar(), Autosave.INTERVALO, 1e-6,
		"e o cronometro volta a encher",
	)

	# o quadro seguinte nao pode gravar de novo so porque o anterior gravou
	Autosave.tique(0.016)
	igual(_gravacoes, 1, "o quadro seguinte nao grava de novo")


## ⚠️ Os tres momentos em que o jogador ESPERA que o jogo tenha guardado. Cada sinal, uma
## gravacao -- nem zero, nem duas.
func _os_gatilhos() -> void:
	var gatilhos := {
		"provar o Teorema": func() -> void: EventBus.teorema_provado.emit(Grande.um()),
		"reescrever o Universo": func() -> void: EventBus.universo_reescrito.emit(Grande.um()),
		"trocar de era": func() -> void: EventBus.era_mudou.emit(ErasCatalogo.todas()[0]),
	}
	for descricao in gatilhos:
		_zerar()
		gatilhos[descricao].call()
		igual(_gravacoes, 1, "%s grava exatamente uma vez" % descricao)


## O caso que a issue nomeia: gatilho no fim do cronometro nao pode gravar duas vezes no
## mesmo quadro. O cronometro reinicia quando um gatilho grava.
func _o_gatilho_reinicia_o_cronometro() -> void:
	_zerar()
	Autosave.tique(Autosave.INTERVALO - 0.1)
	igual(_gravacoes, 0, "o cronometro esta quase estourando")

	EventBus.teorema_provado.emit(Grande.um())
	igual(_gravacoes, 1, "o prestigio grava")

	Autosave.tique(0.2)
	igual(
		_gravacoes, 1,
		"⚠️ e o cronometro NAO grava de novo no mesmo quadro -- ele reiniciou junto",
	)


## Todo gatilho passa por aqui, inclusive os que ainda nao existem: o botao de voltar ao
## menu da issue #39 chama esta funcao, e nao Save.gravar() direto, senao ele grava sem
## reiniciar o cronometro e a duplicata volta por outra porta.
func _gravar_agora_e_o_ponto_de_entrada() -> void:
	_zerar()
	Jogo.total_caracteres = Grande.new(1.5, 40)
	ok(Autosave.gravar_agora(), "gravar_agora devolve que gravou")
	igual(_gravacoes, 1, "e gravou uma vez so")
	ok(Save.existe(), "e o arquivo esta em disco")
	perto(
		Autosave.segundos_ate_gravar(), Autosave.INTERVALO, 1e-6,
		"e o cronometro reiniciou",
	)


## Deixa o cronometro cheio e o contador zerado. Cada bloco comeca do mesmo lugar; sem
## isto, uma afirmacao passaria por causa do bloco anterior.
func _zerar() -> void:
	Autosave.gravar_agora()
	_gravacoes = 0
