## A cena das eras e a camera que se afasta (GDD §6 e §27).
##
## A CAMERA AFASTANDO E O EFEITO INTEIRO. Num genero em que so o numero cresce, ver a mesa
## virar sala, a sala virar fabrica e a fabrica virar planeta e a unica coisa que da
## sensacao de evolucao sem depender de o jogador ler o contador. A mesma maquina aparece
## repetida numa grade que cresce, em escala que encolhe -- e literalmente a camera subindo.
##
## ⚠️ O MACACO CONTINUA LEGIVEL EM TODA ESCALA. Quando ele sumir, o jogo perdeu a piada:
## o Teorema do Macaco Infinito sem o macaco vira uma planilha. Por isso a maquina da
## frente NAO encolhe junto com as outras -- ela fica no tamanho de sempre, e o que muda
## atras dela e o mundo.
##
## A TRANSICAO E RECOMPENSA E NAO CORTE SECO: a escala caminha ate o alvo em vez de pular,
## e o nome da era aparece e some. Trocar de era no meio de um clique tem que parecer
## conquista, e conquista que acontece num quadro nao e percebida.
##
## ⚠️ Headless nao renderiza: a prova desta issue e captura, e nao afirmacao. Ver
## tools/gerar_galeria.tscn.
##
## A era nao muda conta nenhuma. Producao, custo e chance atravessam qualquer uma delas
## iguais -- era que mexe em numero virou upgrade disfarcado de cenario.
extends Control

## O desenho que se repete. Vem do mesmo alfabeto do docs/ARTE.md: maquina de escrever,
## papel e o infinito.
const MAQUINA := "  .-----------.\n /  _______  /|\n/  /  ∞    / / \n|__________|/ "

## O macaco. Ele nunca encolhe, e e isso que mantem a piada de pe em qualquer escala.
const MACACO := " @@ \n(o o)\n /^\\ "

## O que a grade desenha quando a metafora troca (GDD §6, era 12 em diante). Nao e maquina
## nem predio: e probabilidade, informacao e possibilidade -- as tres coisas que o jogador
## passa a manipular. A banana some do desenho, mas o macaco nao: o docs/ARTE.md secao 10 e
## categorico -- no fim do universo ainda existe um macaco digitando.
##
## ⚠️ SO GLIFOS QUE A FONTE MONOESPACADA TEM. A primeira versao usava ∑, Ω, ◇ e ✦, e a
## regua medir_quadro mediu 22 ms de tempo de processo na era 14 contra 14 ms na era 7 --
## que tem SEIS VEZES mais rotulos. Glifo que falta na fonte faz o Godot percorrer a
## cadeia de fallback a cada desenho, e a busca custa mais que o desenho.
const SIMBOLOS: PackedStringArray = ["∞", "?", "%", "+", "~", "=", "()"]

const QUADROS_DE_TRANSICAO: float = 1.4
const AVISO_VISIVEL: float = 3.0

var _eras: Array[DadosEra] = []
var _atual: DadosEra = null
var _escala: float = 1.0
var _escala_alvo: float = 1.0
var _ate_esconder: float = 0.0
## As maquinas de fundo vivem dentro de um no so, e e ELE que a transicao escala.
##
## A primeira versao escalava e reposicionava cada rotulo por quadro, e a regua
## medir_quadro achou o preco na hora: quarenta quadros perdidos de duzentos e quarenta,
## todos dentro do 1,4 s da transicao. E o pior lugar possivel para engasgar -- a troca de
## era e o momento de recompensa. Agora a transicao mexe em UM transform.
## Se a grade ja esta desenhada no modo abstrato. Guardado para a troca de era nao
## reaplicar estilo em rotulo que nao mudou de modo.
var _abstrata: bool = false

var _grade: Control = null
var _fundo: Array[Label] = []
var _macaco: Label = null
var _frente: Label = null
var _aviso: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade = Control.new()
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grade)

	# o catalogo vem de ErasCatalogo, e nao de uma leitura propria: o metadado do
	# Manuscrito responde a mesma pergunta ("qual era e esta producao?") longe daqui, e
	# duas copias da regra divergiriam na primeira era nova (issue #35)
	_eras = ErasCatalogo.todas()

	# a piscina nasce inteira, do tamanho da era mais cheia: alocar Label no meio de uma
	# transicao seria alocar exatamente no quadro que precisa estar liso
	var maior := 1
	for era in _eras:
		maior = maxi(maior, era.maquinas_visiveis)
	for i in maior:
		# claro o bastante para a grade ser lida como mundo, e apagado o bastante para nao
		# competir com a maquina da frente: o fundo e escala, e nao informacao
		var rotulo := _rotulo(Paleta.MONKEY_BROWN.lightened(0.05), 11, _grade)
		rotulo.visible = false
		_fundo.append(rotulo)

	_frente = _rotulo(Paleta.MONKEY_BROWN.lightened(0.15), 18)
	_frente.text = MAQUINA
	_macaco = _rotulo(Paleta.BANANA_GOLD, 18)
	_macaco.text = MACACO
	_aviso = _rotulo(Paleta.BANANA_GOLD, 24)
	_aviso.visible = false

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_trocar(_da_producao(), true)


func _process(delta: float) -> void:
	var alvo := _da_producao()
	if alvo != _atual:
		_trocar(alvo, false)

	if not is_equal_approx(_escala, _escala_alvo):
		# ⚠️ REDUZIR MOVIMENTO CHEGA NA CAMERA (issue #43). Este e um dos dois lugares que
		# se mexem sozinhos -- o outro sao as letras --, e e o mais longo dos dois: a
		# camera se afastando dura varios segundos. Com a opcao ligada a era troca NUM
		# QUADRO, e nao deixa de trocar: o destino e o mesmo, o caminho e que some.
		if Config.ligado("reduzir_movimento"):
			_escala = _escala_alvo
		else:
			_escala = move_toward(_escala, _escala_alvo, delta / QUADROS_DE_TRANSICAO)
		_ajustar_grade()

	if _ate_esconder > 0.0:
		_ate_esconder -= delta
		_aviso.modulate.a = clampf(_ate_esconder, 0.0, 1.0)
		if _ate_esconder <= 0.0:
			_aviso.visible = false


## A era atual pela producao -- a mais avancada que couber. A regra mora no catalogo.
func _da_producao() -> DadosEra:
	return ErasCatalogo.da_producao(Jogo.total_caracteres)


func era_atual() -> DadosEra:
	return _atual


## Como a era chama a unidade que o jogador acumula. A HUD le daqui: na era 14 a contagem
## de macacos deixa de fazer sentido, e trocar so o fundo nao contaria essa historia.
func unidade() -> String:
	return _atual.unidade if _atual != null else "macacos"


## Quantas maquinas de fundo estao desenhadas. A regua medir_quadro le isto.
func visiveis() -> int:
	return _atual.maquinas_visiveis if _atual != null else 0


func _trocar(era: DadosEra, imediato: bool) -> void:
	if era == null:
		return
	var primeira := _atual == null
	_atual = era
	# a grade cresce com a raiz do numero de maquinas, e a escala cai junto: e assim que
	# a camera parece subir em vez de a maquina parecer encolher
	_escala_alvo = 1.0 / sqrt(float(era.maquinas_visiveis))
	if imediato:
		_escala = _escala_alvo

	# ⚠️ SO A VISIBILIDADE MUDA A CADA ERA. O texto e os dois overrides de tema dependem
	# apenas de `abstrata`, e reaplicar os tres em duzentos e vinte e cinco rotulos a cada
	# troca custou caro: a regua medir_quadro mediu 30 ms de tempo de processo exatamente
	# nas faixas de producao que atravessam era durante a medicao, e 8 ms nas que nao
	# atravessam. Override de tema invalida cache; fazer isso 675 vezes num quadro e o
	# preco disso.
	for i in _fundo.size():
		_fundo[i].visible = i < era.maquinas_visiveis

	if primeira or era.abstrata != _abstrata:
		_abstrata = era.abstrata
		_reestilizar()

	# a maquina da frente some quando nao ha mais maquina; o macaco NUNCA some
	_frente.visible = not era.abstrata

	if not primeira:
		_aviso.visible = true
		_aviso.modulate.a = 1.0
		_ate_esconder = AVISO_VISIVEL
		EventBus.era_mudou.emit(era)
	_pintar_aviso()
	_posicionar()


## Texto, corpo e cor da grade inteira. So roda quando a metafora troca -- uma vez por
## partida, e nao uma vez por era.
func _reestilizar() -> void:
	for i in _fundo.size():
		_fundo[i].text = SIMBOLOS[i % SIMBOLOS.size()] if _abstrata else MAQUINA
		_fundo[i].add_theme_font_size_override("font_size", Tema.fonte(30 if _abstrata else 11))
		_fundo[i].add_theme_color_override(
			"font_color",
			Tema.cor(
				Paleta.INFINITY_CYAN.darkened(0.15) if _abstrata
				else Paleta.MONKEY_BROWN.lightened(0.05)
			),
		)


func _pintar_aviso() -> void:
	if _atual != null:
		_aviso.text = tr(_atual.nome)


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar_aviso()


## A escala do texto entra nos rotulos de fundo, e eles so sao reestilizados quando a
## METAFORA troca -- uma vez por partida. Sem esta linha, mexer na escala deixaria a cena
## das eras no tamanho antigo ate o jogador cruzar uma era (issue #43).
func _ao_mudar_interface() -> void:
	_reestilizar()
	_pintar_aviso()


func _posicionar() -> void:
	if _atual == null or size.x <= 0.0:
		return
	var colunas := maxi(int(ceil(sqrt(float(_atual.maquinas_visiveis)))), 1)
	var passo := Vector2(size.x, size.y) / float(colunas + 1)

	# a grade e montada UMA VEZ por era, em coordenadas de tamanho cheio. Quem encolhe e o
	# no pai, todo quadro, num transform so.
	var i := 0
	for rotulo in _fundo:
		if not rotulo.visible:
			continue
		rotulo.position = Vector2(
			passo.x * float(i % colunas + 1) - 60.0,
			passo.y * float(i / colunas + 1) - 30.0,
		)
		i += 1
	_ajustar_grade()

	# a maquina da frente e o macaco NAO encolhem: e o que mantem os dois legiveis em
	# qualquer era, e e o unico jeito de o planeta continuar tendo um macaco visivel
	_frente.position = Vector2(size.x * 0.5 - 70.0, size.y * 0.5 - 20.0)
	_macaco.position = Vector2(size.x * 0.5 - 130.0, size.y * 0.5 - 24.0)
	_aviso.position = Vector2(size.x * 0.5 - 100.0, size.y * 0.18)


## O unico trabalho por quadro durante a transicao: um transform, e nao cem.
func _ajustar_grade() -> void:
	if _grade == null:
		return
	_grade.scale = Vector2(_escala, _escala)
	# ancorar no centro para a grade encolher em direcao ao meio da tela, e nao para o
	# canto superior esquerdo -- encolher para o canto le como "sumindo", e nao como
	# "camera subindo"
	_grade.position = Vector2(size.x, size.y) * 0.5 * (1.0 - _escala)


func _rotulo(cor: Color, corpo: int, pai: Node = null) -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_color_override("font_color", Tema.cor(cor))
	rotulo.add_theme_font_size_override("font_size", Tema.fonte(corpo))
	(pai if pai != null else self).add_child(rotulo)
	return rotulo


