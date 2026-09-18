## A abertura datilografada (issue #47).
##
## Tela preta. CLACK. `J`. CLACK. `U`. CLACK CLACK CLACK. `JUST KEEP TYPING_` com o cursor
## piscando, e entao a mesa aparece.
##
## ⚠️ QUEM JA ABRIU O JOGO ANTES PULA NA HORA, e essa e a regra que faz a abertura valer a
## pena existir. Uma animacao de tres segundos e encantadora na primeira vez e e PEDAGIO na
## decima -- e este e um jogo que a pessoa abre todo dia. Quem decide isso e o Cenas, antes
## de montar esta cena: aqui dentro nao ha ramo de "ja viu", porque a cena nem chega a
## existir nesse caso.
##
## ⚠️ E O "JA VIU" E DA INSTALACAO, e nao do save. Ele mora no Config, pelo mesmo motivo que
## a resolucao mora: trocar de Manuscrito nao pode fazer a abertura voltar.
##
## ⚠️ MARCA COMO VISTA NO COMECO, e nao no fim. Marcar no fim significa que fechar o jogo
## durante a abertura faz ela voltar na proxima vez -- e quem fechou durante a abertura foi,
## muito provavelmente, alguem incomodado com ela.
##
## ⚠️ PULAR E QUALQUER TECLA, e nao so o ESC. A pessoa que quer pular nao esta procurando a
## tecla certa; ela esta batendo em alguma. Mouse e controle contam igual.
##
## ⚠️ REDUZIR MOVIMENTO (issue #43) DESLIGA A REVELACAO, e a abertura continua fazendo
## sentido: as letras aparecem, o CLACK toca e a mesa entra sem se mover. O que some e o
## movimento, e nao a cena.
extends Control

## Entre uma tecla e a seguinte. Cento e trinta milesimos e ritmo de quem digita com dois
## dedos -- que e exatamente quem esta digitando.
const INTERVALO: float = 0.13

## Quanto dura a revelacao da mesa depois da ultima letra.
const REVELACAO: float = 1.2

## O quanto a camera esta "perto" no comeco da revelacao. 1,12 e um passo de camera, e nao
## um salto: acima disso a mesa entra deformada.
const APROXIMACAO: float = 1.12

## Quanto tempo o cursor fica aceso, e apagado. Meio segundo e o piscar de cursor de
## terminal, que e a referencia.
const PISCADA: float = 0.5

## Marca de formato, e nao texto: o cursor de uma maquina de escrever nao muda de idioma.
const CURSOR := "_"

const TITULO: int = 76

var _fundo: ColorRect = null
var _cenario: CenarioDoMenu = null
var _titulo: Label = null

var _decorrido: float = 0.0
var _saiu: bool = false

## Quantas letras ja tocaram CLACK. Contador e nao "tocou neste quadro": e ele que impede
## sessenta CLACKs por segundo.
var _letras_tocadas: int = 0


func _ready() -> void:
	theme = Tema.montar()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ⚠️ MARCADA AQUI, no comeco -- ver o aviso no topo do arquivo
	Config.marcar_abertura_vista()

	_cenario = CenarioDoMenu.new()
	_cenario.name = "Cenario"
	_cenario.modulate.a = 0.0
	add_child(_cenario)

	# o preto fica POR CIMA do cenario e vai embora; comecar com o cenario invisivel e
	# clarea-lo daria o mesmo resultado, mas o preto por cima e o que permite a mesa ja
	# estar montada e posicionada antes de aparecer -- sem um quadro de layout visivel
	_fundo = ColorRect.new()
	_fundo.name = "Cortina"
	_fundo.color = Color.BLACK
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fundo)

	_titulo = Label.new()
	_titulo.name = "TituloDatilografado"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_titulo.add_theme_font_override("font", Tema.fonte_de_titulo())
	_titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO))
	_titulo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
	add_child(_titulo)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_pintar()


## Quantos segundos a abertura inteira dura. Publica porque a suite e a fumaca leem daqui:
## copiar a conta para dentro do teste criaria uma segunda definicao de "dois a quatro
## segundos", e a segunda e a que envelhece.
func duracao() -> float:
	return float(_letras().length()) * INTERVALO + REVELACAO


## Se a revelacao de camera esta ligada. Lida na hora de usar, e nunca guardada.
func revelando() -> bool:
	return not Config.ligado("reduzir_movimento")


func _process(delta: float) -> void:
	adiantar(delta)


## Faz a abertura andar. Publica porque a captura ADIANTA o relogio em vez de esperar por
## ele: fotografar "o segundo 2,4" esperando dois segundos e meio daria uma foto diferente
## a cada execucao, e o diff da galeria versionada deixaria de valer.
##
## E o mesmo principio das quatro horas de offline na fumaca: o relogio e argumento.
func adiantar(delta: float) -> void:
	_decorrido += delta
	_pintar()
	if _decorrido >= duracao():
		_sair()


## Pular e QUALQUER entrada. Nada de procurar a tecla certa.
##
## ⚠️ `is_pressed()` e nao `is_released()`: soltar a tecla que abriu o jogo pularia a
## abertura antes de o primeiro CLACK tocar.
func _unhandled_input(evento: InputEvent) -> void:
	var apertou := (
		(evento is InputEventKey and evento.is_pressed() and not evento.is_echo())
		or (evento is InputEventMouseButton and evento.is_pressed())
		or (evento is InputEventJoypadButton and evento.is_pressed())
		or (evento is InputEventAction and evento.is_pressed())
	)
	if not apertou:
		return
	get_viewport().set_input_as_handled()
	_sair()


# ------------------------------------------------------------------------------- pintura

func _pintar() -> void:
	var letras := _letras()
	var quantas := clampi(int(_decorrido / INTERVALO), 0, letras.length())

	# ⚠️ UM CLACK POR LETRA NOVA, e nao um por quadro. Contar as letras ja escritas e
	# comparar e o que impede sessenta CLACKs por segundo -- o audio e representacao da
	# atividade, nunca um contador (issue #42).
	if quantas > _letras_tocadas:
		_letras_tocadas = quantas
		Audio.tocar_clack()

	var cursor := CURSOR if fmod(_decorrido, PISCADA * 2.0) < PISCADA else " "
	_titulo.text = letras.substr(0, quantas) + cursor

	var da_revelacao := clampf(
		(_decorrido - float(letras.length()) * INTERVALO) / REVELACAO, 0.0, 1.0
	)
	_fundo.color.a = 1.0 - da_revelacao
	_cenario.modulate.a = da_revelacao
	if revelando():
		# a camera "afasta": o cenario entra um pouco maior e assenta no tamanho dele
		var perto := lerpf(APROXIMACAO, 1.0, da_revelacao)
		_cenario.pivot_offset = _cenario.size * 0.5
		_cenario.scale = Vector2(perto, perto)
	else:
		_cenario.scale = Vector2.ONE


## As letras que a abertura digita. Passa por tr() como o titulo do menu: a linha existe no
## CSV nas duas colunas.
func _letras() -> String:
	return tr("JUST KEEP TYPING")



## ⚠️ SO SAI UMA VEZ. Sem a trava, o ultimo quadro da abertura e uma tecla apertada no mesmo
## instante pedem o menu duas vezes -- e a segunda monta um segundo menu por cima do
## primeiro, com dois nos escutando o mesmo EventBus.
func _sair() -> void:
	if _saiu:
		return
	_saiu = true
	set_process(false)
	Cenas.ir_para_menu()


func _ao_mudar_idioma(_codigo: String) -> void:
	_pintar()


func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	_titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO))
	_titulo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
	_pintar()
