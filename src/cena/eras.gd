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

const PASTA := "res://data/eras"

## O desenho que se repete. Vem do mesmo alfabeto do docs/ARTE.md: maquina de escrever,
## papel e o infinito.
const MAQUINA := "  .-----------.\n /  _______  /|\n/  /  ∞    / / \n|__________|/ "

## O macaco. Ele nunca encolhe, e e isso que mantem a piada de pe em qualquer escala.
const MACACO := " @@ \n(o o)\n /^\\ "

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

	for caminho in _listar_tres(PASTA):
		var era := ResourceLoader.load(caminho) as DadosEra
		if era != null:
			_eras.append(era)
	_eras.sort_custom(func(a: DadosEra, b: DadosEra) -> bool: return a.numero < b.numero)

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
	_trocar(_da_producao(), true)


func _process(delta: float) -> void:
	var alvo := _da_producao()
	if alvo != _atual:
		_trocar(alvo, false)

	if not is_equal_approx(_escala, _escala_alvo):
		_escala = move_toward(_escala, _escala_alvo, delta / QUADROS_DE_TRANSICAO)
		_ajustar_grade()

	if _ate_esconder > 0.0:
		_ate_esconder -= delta
		_aviso.modulate.a = clampf(_ate_esconder, 0.0, 1.0)
		if _ate_esconder <= 0.0:
			_aviso.visible = false


## A era atual pela producao. Percorre do fim para o comeco: a primeira que couber e a
## mais avancada que couber.
func _da_producao() -> DadosEra:
	var escolhida: DadosEra = null
	for era in _eras:
		if not era.requisito_grande().maior_que(Jogo.total_caracteres):
			escolhida = era
	return escolhida


func era_atual() -> DadosEra:
	return _atual


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

	for i in _fundo.size():
		_fundo[i].visible = i < era.maquinas_visiveis
		_fundo[i].text = MAQUINA

	if not primeira:
		_aviso.visible = true
		_aviso.modulate.a = 1.0
		_ate_esconder = AVISO_VISIVEL
		EventBus.era_mudou.emit(era)
	_pintar_aviso()
	_posicionar()


func _pintar_aviso() -> void:
	if _atual != null:
		_aviso.text = tr(_atual.nome)


func _ao_mudar_idioma(_codigo: String) -> void:
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
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", corpo)
	(pai if pai != null else self).add_child(rotulo)
	return rotulo


static func _listar_tres(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		push_error("Eras: pasta %s nao abriu" % pasta)
		return achados
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir() and item.ends_with(".tres"):
			achados.append(pasta.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
	return achados
