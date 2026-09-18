## O combo de digitacao (issue #54).
##
## A regra que esta suite existe para defender nao e "o combo funciona" -- e:
##
##   atividade -> ACELERA      ✅
##   atividade -> OBRIGATORIA  ❌
##
## Tres afirmacoes aqui sao sobre a SEGUNDA linha, e sao as que importam: o combo decai
## ate ZERO sozinho, ele nao encosta na producao automatica, e a progressao anda igual sem
## ele. Um combo que subisse e nunca descesse continuaria passando em qualquer teste de
## "o multiplicador multiplica".
extends TesteBase

const CAMINHO := "res://data/combo.tres"


func _init() -> void:
	nome = "combo de digitacao"


func executar() -> void:
	_o_tres_e_valido()
	_os_padroes_reprovam()
	_sobe_com_a_atividade_e_tem_teto()
	_decai_ate_zero_sozinho()
	_o_decaimento_nao_depende_do_tamanho_do_tique()
	_o_multiplicador_e_lido_na_hora()
	_digitar_rende_mais_com_combo()
	_o_combo_nao_encosta_na_producao_automatica()
	_zera_ao_recomecar_a_partida()
	_limpar()


func _o_tres_e_valido() -> void:
	var dados := ResourceLoader.load(CAMINHO) as DadosCombo
	ok(dados != null, "%s carrega como DadosCombo" % CAMINHO)
	if dados == null:
		return

	ok(dados.teto > 1.0, "o teto %s multiplica alguma coisa" % dados.teto)

	# ⚠️ "PEQUENO" E O ADJETIVO MAIS IMPORTANTE DA ISSUE. Esta afirmacao cobra a REGRA
	# ("o combo e um bonus, e nao um imposto") com um limite frouxo de proposito: ela nao
	# esta escolhendo o numero por quem for ajustar, so impedindo que o ajuste atravesse a
	# fronteira onde o combo vira obrigacao. O valor de hoje esta ao lado, como nota.
	ok(dados.teto <= 2.0, "o teto %s continua pequeno (valor de hoje: 1,5)" % dados.teto)

	ok(dados.ganho_por_tecla > 0.0, "o ganho por tecla faz o combo subir")
	ok(
		dados.decaimento_por_segundo > 0.0,
		"o decaimento e maior que zero -- e a metade que impede a obrigacao",
	)
	ok(dados.segundos_de_graca >= 0.0, "a carencia nao e negativa")

	# derivados: existem para ninguem precisar fazer a conta de cabeca numa sessao de
	# tuning, e por isso precisam continuar batendo com os campos
	ok(
		dados.teclas_ate_o_teto() > 1,
		"leva %d teclas ate o teto -- uma so seria um interruptor" % dados.teclas_ate_o_teto(),
	)
	ok(
		dados.segundos_ate_zerar() > 0.0,
		"um combo cheio zera em %.1f s parado" % dados.segundos_ate_zerar(),
	)


## ⚠️ Os padrao da classe sao invalidos de proposito, e decaimento zero e o grave: um
## combo que nunca desce nao parece defeito, ele so fica ligado para sempre -- e "deixar o
## dedo no teclado" vira a jogada dominante.
func _os_padroes_reprovam() -> void:
	var vazio := DadosCombo.new()
	ok(vazio.teto <= 1.0, "DadosCombo nasce sem multiplicar nada")
	ok(vazio.ganho_por_tecla <= 0.0, "DadosCombo nasce sem subir")
	ok(vazio.decaimento_por_segundo <= 0.0, "DadosCombo nasce SEM DECAIR, e a suite reprova isso")
	igual(vazio.teclas_ate_o_teto(), 0, "sem ganho, o derivado devolve zero em vez de dividir por zero")
	perto(vazio.segundos_ate_zerar(), 0.0, 0.0, "sem decaimento, o derivado nao inventa um prazo")


func _sobe_com_a_atividade_e_tem_teto() -> void:
	Combo._zerar()
	perto(Combo.multiplicador(), 1.0, 0.0001, "parado, o combo nao multiplica nada")

	Combo.marcar(1)
	ok(Combo.multiplicador() > 1.0, "uma tecla ja acelera")

	var depois_de_uma := Combo.multiplicador()
	Combo.marcar(1)
	ok(Combo.multiplicador() > depois_de_uma, "a segunda tecla acelera mais que a primeira")

	# muito acima do necessario: o teto tem que segurar por clamp, e nao por sorte
	Combo.marcar(10_000)
	perto(Combo.intensidade(), 1.0, 0.0001, "a intensidade para em 1,0")
	perto(Combo.multiplicador(), Combo.teto(), 0.0001, "e o multiplicador para no teto")

	Combo.marcar(10_000)
	perto(Combo.multiplicador(), Combo.teto(), 0.0001, "martelar depois do teto nao passa dele")


## A afirmacao central da issue: parar devolve o jogo ao estado de quem nunca digitou.
func _decai_ate_zero_sozinho() -> void:
	var dados := ResourceLoader.load(CAMINHO) as DadosCombo
	if dados == null:
		return

	Combo._zerar()
	Combo.marcar(10_000)

	# dentro da carencia, nada cai -- senao a cadencia humana normal, que tem pausa para
	# pensar e para clicar na loja, seria lida como parar
	if dados.segundos_de_graca > 0.0:
		Combo.decair(dados.segundos_de_graca * 0.5)
		perto(Combo.multiplicador(), Combo.teto(), 0.0001, "dentro da carencia o combo segura")

	# e passada a carencia, ele cai
	Combo.decair(dados.segundos_de_graca + 0.2)
	ok(Combo.multiplicador() < Combo.teto(), "passada a carencia, o combo comeca a cair")

	# ⚠️ ATE ZERO, e nao ate um piso. Um combo que estacionasse em 1,1 seria um imposto
	# permanente sobre quem nao digita, so que pequeno -- e pequeno demais para alguem
	# notar lendo o codigo.
	Combo.decair(dados.segundos_ate_zerar() * 2.0)
	perto(Combo.intensidade(), 0.0, 0.0, "parado o bastante, a intensidade chega a ZERO")
	perto(Combo.multiplicador(), 1.0, 0.0, "e o multiplicador volta a 1,0 exato")

	# e continua zero: decair no zero nao pode virar negativo, que passaria a REDUZIR
	Combo.decair(100.0)
	perto(Combo.intensidade(), 0.0, 0.0, "decair no zero nao deixa a intensidade negativa")
	ok(Combo.multiplicador() >= 1.0, "e o combo nunca multiplica por menos de 1")


## ⚠️ O tique de 60 quadros por segundo e o de 30 tem que cobrar o mesmo decaimento. Se a
## sobra do delta depois da carencia fosse descartada, um tique grande custaria menos que
## dois pequenos -- e o combo duraria mais para quem joga com a taxa de quadros baixa, sem
## nada em lugar nenhum dizendo por que.
func _o_decaimento_nao_depende_do_tamanho_do_tique() -> void:
	var dados := ResourceLoader.load(CAMINHO) as DadosCombo
	if dados == null:
		return
	var total := dados.segundos_de_graca + 0.5

	Combo._zerar()
	Combo.marcar(10_000)
	Combo.decair(total)
	var de_uma_vez := Combo.intensidade()

	Combo._zerar()
	Combo.marcar(10_000)
	for i in range(20):
		Combo.decair(total / 20.0)
	var em_vinte := Combo.intensidade()

	perto(em_vinte, de_uma_vez, 0.0001, "um tique grande derruba o mesmo que vinte pequenos")


## ⚠️ Regra 2 de arquitetura: quem le o multiplicador le no instante em que usa. Se algum
## dia ele for guardado ja calculado, esta afirmacao e a que acusa.
func _o_multiplicador_e_lido_na_hora() -> void:
	Combo._zerar()
	var parado := Combo.multiplicador()
	Combo.marcar(10_000)
	var cheio := Combo.multiplicador()
	ok(cheio > parado, "o mesmo chamador ve outro numero depois da atividade mudar")

	Combo._zerar()
	perto(Combo.multiplicador(), parado, 0.0001, "e ve o numero de volta quando ela zera")


func _digitar_rende_mais_com_combo() -> void:
	var quantos := 40

	Combo._zerar()
	Jogo.total_caracteres = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	for i in range(quantos):
		Economia.digitar(1)
	var com_combo := Jogo.total_caracteres

	# ⚠️ E O CONTROLE: os mesmos cliques sem o combo. Sem esta metade, a afirmacao acima
	# nao prova nada -- qualquer numero maior que zero passaria.
	Combo._zerar()
	Jogo.total_caracteres = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	for i in range(quantos):
		Economia.digitar(1)
		Combo._zerar()
	var sem_combo := Jogo.total_caracteres

	ok(
		com_combo.maior_que(sem_combo),
		"%d cliques em sequencia rendem mais que %d cliques isolados" % [quantos, quantos],
	)

	# ⚠️ A ARMADILHA DO PERCENTUAL SOBRE INTEIRO. Um clique vale 1, e 1 x 1,2 truncado
	# volta a ser 1: se digitar() arredondasse, o combo apareceria na tela, existiria no
	# codigo e NAO FARIA NADA ate o teto passar de 2,0. A afirmacao de cima pega isso, mas
	# so porque sao 40 cliques -- esta aqui pega no primeiro.
	Combo._zerar()
	Combo.marcar(10_000)
	Jogo.total_caracteres = Grande.zero()
	Jogo.dinheiro = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Economia.digitar(1)
	ok(
		Jogo.total_caracteres.maior_que(Grande.um()),
		"UM clique com o combo cheio rende mais que 1 -- a fracao nao e truncada",
	)


## ⚠️ A GARANTIA DE ACESSIBILIDADE, escrita como afirmacao. Quem nao pode digitar rapido
## nao pode ficar preso atras do combo: a producao automatica -- que e por onde a
## progressao inteira anda -- tem que ser exatamente a mesma com e sem combo.
##
## E e tambem o que faz o combo ENVELHECER sozinho: preso ao clique, ele se apaga quando a
## automacao cresce, sem ninguem ter desligado nada.
func _o_combo_nao_encosta_na_producao_automatica() -> void:
	Combo._zerar()
	var parado := Economia.producao_por_segundo()
	var mult_parado := Economia.multiplicador_total()

	Combo.marcar(10_000)
	var cheio := Economia.producao_por_segundo()
	var mult_cheio := Economia.multiplicador_total()

	perto(mult_cheio, mult_parado, 0.0, "o combo NAO entra no multiplicador global")
	ok(
		parado.para_texto() == cheio.para_texto(),
		"a producao automatica e a mesma com e sem combo (%s)" % parado.para_texto(),
	)


func _zera_ao_recomecar_a_partida() -> void:
	Combo._zerar()
	Combo.marcar(10_000)
	EventBus.jogo_carregado.emit()
	perto(Combo.intensidade(), 0.0, 0.0, "carregar um save zera o combo da sessao anterior")

	Combo.marcar(10_000)
	EventBus.teorema_provado.emit(Grande.um())
	perto(Combo.intensidade(), 0.0, 0.0, "provar um teorema zera o combo")

	Combo.marcar(10_000)
	EventBus.universo_reescrito.emit(Grande.um())
	perto(Combo.intensidade(), 0.0, 0.0, "reescrever o universo tambem zera")


## A suite mexeu em Jogo e no Combo: devolve os dois ao estado neutro para a proxima nao
## herdar o que esta deixou.
func _limpar() -> void:
	Combo._zerar()
	Jogo.total_caracteres = Grande.zero()
	Jogo.caracteres_da_run = Grande.zero()
	Jogo.dinheiro = Grande.zero()
