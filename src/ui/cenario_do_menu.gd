## A mesa do menu: o cenario, a maquina, o macaco e o ∞ das estrelas (issue #46).
##
## E a primeira cena narrativa do jogo. Ate a issue #38 o menu era um rascunho feio de
## proposito; aqui ele vira o lugar onde o macaco mora.
##
## ⚠️ ESCALA INTEIRA, SEMPRE, E CALCULADA -- nao cravada. Pixel art com escala fracionaria
## nao fica "um pouco borrada": ela fica com o pixel quadrado tendo larguras diferentes na
## MESMA imagem, e isso e a unica coisa que pixel art nao pode ser (decisao 0006).
##
## A conta cobre em vez de caber: a escala e o MENOR inteiro que ainda enche a area. Com
## escala de interface em 150% a area logica e 1280x720, e 1280/384 daria 3,33 -- entao o
## cenario e desenhado a 4x e o excedente sai pelas bordas, centralizado. Sobra cortada e
## melhor que pixel torto, e infinitamente melhor que uma tarja preta na borda.
##
## ⚠️ O ∞ DAS ESTRELAS E DESENHADO AQUI, e nao esta no PNG. Duas geracoes pediram uma
## constelacao em forma de oito deitado e nenhuma entregou -- gerador de imagem nao desenha
## constelacao por encomenda (docs/ASSETS.md). Em codigo ele tem posicao exata, e e isso que
## vai permitir ele piscar na issue #48.
##
## ⚠️ E ELE E DISCRETO. ARTE.md §12 pede humor visual, nao piada explicada: se o jogador
## tiver que procurar, funcionou. Se ele aparecer antes do macaco, esta errado -- e por isso
## as estrelas dele sao do tamanho das outras, so um pouco mais claras.
##
## ⚠️ NAO COME CLIQUE NENHUM. Todo no daqui e MOUSE_FILTER_IGNORE: foi exatamente com
## mouse_filter em STOP por padrao que a fumaca da issue #7 pegou um painel comendo o clique
## de quem estava atras.
class_name CenarioDoMenu
extends Control

## Onde a maquina e o macaco ficam, em coordenadas da ARTE (384x216), e nao da tela. Assim
## eles acompanham a escala sem ninguem refazer conta nenhuma.
##
## A maquina fica na metade esquerda, sobre a mesa; o macaco ATRAS dela, no mesmo eixo. A
## metade direita fica livre para o painel de menu (docs/ASSETS.md).
##
## ⚠️ O MACACO E MAIS ALTO QUE A DISTANCIA ATE A MESA, e isso e de proposito: o rodape dele
## fica DENTRO da maquina, e a maquina o cobre da cintura para baixo. Ancorar os dois pela
## mesma linha da mesa faria o macaco pousar em cima da maquina, flutuando -- que foi
## exatamente o que a primeira captura do menu com arte mostrou.
const MAQUINA_EM_ARTE := Vector2i(120, 150)
const MACACO_EM_ARTE := Vector2i(120, 136)

## O centro do ∞, tambem em coordenadas da arte: no ceu, a DIREITA do macaco e a esquerda
## do painel. A primeira posicao ficou bem atras da cabeca dele, onde nao se ve nada.
const INFINITO_EM_ARTE := Vector2(200.0, 40.0)

## Metade da largura do ∞, em pixels de arte. Vinte e dois: grande o bastante para a forma
## se fechar, pequeno o bastante para nao virar a coisa mais visivel do ceu.
const INFINITO_RAIO: float = 26.0

## Quantas estrelas formam a lemniscata. Onze fecha a figura sem virar uma linha continua --
## constelacao e um conjunto de pontos, e o olho e que liga.
const INFINITO_ESTRELAS: int = 11

## O lado de cada estrela do ∞, em pixels de ARTE.
##
## ⚠️ DOIS, E NAO UM. Com um pixel elas ficam do tamanho exato das estrelas do cenario e a
## forma some no ruido: a captura do menu mostrou um ceu estrelado e nenhum infinito. Dois
## as separa o bastante para a figura existir sem virar a coisa mais brilhante da tela --
## discreto e ter que olhar, nao ser invisivel (ARTE.md §12).
const INFINITO_LADO: float = 2.0

## Quantas motas de poeira ficam no facho do abajur. Dez: o bastante para o ar parecer
## habitado, pouco o bastante para ninguem contar.
const MOTAS: int = 10

## A caixa do facho do abajur, em coordenadas de ARTE. A poeira so existe onde ha luz --
## poeira no escuro e ruido branco.
const FACHO_EM_ARTE := Rect2(22.0, 96.0, 74.0, 80.0)

## Quanto uma mota sobe por segundo, em pixels de arte. Devagar: o ar do quarto nao tem
## vento, so a conveccao do abajur.
const SUBIDA_DA_POEIRA: float = 2.2

## A folha na maquina, em coordenadas de ARTE: onde a letra que o jogador aperta aparece
## (issue #49). Sai da maquina, e nao de um palpite -- a folha e a parte do sprite que fica
## acima do corpo.
const PAPEL_EM_ARTE := Rect2(108.0, 104.0, 26.0, 14.0)

## Corpo da letra no papel, em pixels de arte.
const CORPO_NO_PAPEL: int = 4

## ⚠️ QUANTOS CARACTERES CABEM NA FOLHA. Limite de DESIGN, e nao botao: e a largura da
## folha dividida pela largura de um caractere. Ajustavel viraria doze na primeira vez que
## alguem achasse pouco, e a letra sairia pela mesa.
const LIMITE_DO_PAPEL: int = 8

## As frases que o macaco escreve sozinho (plano §24). Sao TEXTO QUE O JOGADOR LE: entram
## no CSV nas duas colunas, como qualquer outra frase do jogo.
const FRASES_RARAS: PackedStringArray = ["banana", "hello?"]

## Entre um acontecimento raro e o seguinte. Longo de proposito: raro que acontece a cada
## dez segundos nao e raro, e vira parte da decoracao.
const ESPERA_RARA_MINIMA: float = 45.0
const ESPERA_RARA_MAXIMA: float = 120.0

## Quanto tempo a folha guarda o que foi escrito antes de o macaco arrancar a pagina.
const PAPEL_VISIVEL: float = 4.0

## O periodo do piscar das estrelas do ∞, em segundos. Cada uma tem a propria fase, senao
## as onze piscam juntas e a constelacao vira um pisca-pisca.
const PERIODO_DA_PISCADA: float = 2.6

var _fundo: TextureRect = null
var _maquina: TextureRect = null
var _macaco: TextureRect = null
var _constelacao: Control = null
var _poeira: Control = null

var _escala: int = 1

## Onde cada peca pousa quando nenhum gesto esta acontecendo. O gesto SOMA a isto -- sem a
## base, cada gesto partiria de onde o anterior parou e o macaco iria andando para o lado.
var _base_maquina := Vector2.ZERO
var _base_macaco := Vector2.ZERO

var _gestos := GestosDoMenu.new()
var _relogio: float = 0.0

## A altura de cada mota, de 0 a 1. Sorteada uma vez; o que anda e a fase.
var _motas: PackedFloat32Array = PackedFloat32Array()

## ⚠️ O QUE ESTA NA FOLHA E SO DESTA CENA, E NAO ENCOSTA NO SAVE (issue #49). A brincadeira
## da tecla e visual: um bug aqui nao pode custar progresso a ninguem. Nada nesta secao
## escreve em Jogo, em Save ou em Economia -- e esse silencio e a funcionalidade.
var _papel: String = ""
var _ate_arrancar: float = 0.0
var _rotulo_do_papel: Label = null

## O que o macaco ainda vai escrever sozinho, letra a letra.
var _sozinho: String = ""
var _ate_a_proxima_letra: float = 0.0
var _ate_o_raro: float = 0.0
var _sorteio := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ⚠️ ...E OFFSETS, e nao so ancoras. set_anchors_preset num no que JA ESTA na arvore
	# preserva o retangulo atual: ele recalcula os offsets para o tamanho continuar o que
	# era -- e o que era, dentro do _ready, e zero. O resultado sao ancoras perfeitas
	# (0, 0, 1, 1) sobre um retangulo de tamanho zero, com clip_contents cortando o cenario
	# inteiro. Nenhum erro, nenhum aviso: a tela abre com o fundo vazio da engine.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true

	# a cor do fundo aparece por um quadro antes de a textura entrar, e no caso em que o
	# asset nao existe ela e o cenario inteiro -- menu que nao abre porque um PNG nao veio
	# e pior que menu sem arte
	var vazio := ColorRect.new()
	vazio.color = Paleta.COSMIC_NAVY
	vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vazio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vazio)

	# as pecas usam a textura AMPLIADA pela escala da familia: ampliar aqui, uma vez, e
	# melhor que deixar o TextureRect esticar a cada quadro -- e e o mesmo caminho que as
	# molduras 9-slice usam, entao o pixel sai do mesmo tamanho nos dois
	_fundo = _peca("cenario")
	_constelacao = Control.new()
	_constelacao.name = "InfinitoDasEstrelas"
	_constelacao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_constelacao.draw.connect(_desenhar_infinito)
	add_child(_constelacao)
	# ⚠️ O MACACO ENTRA ANTES DA MAQUINA, e a ordem E o desenho: no Godot, filho posterior
	# desenha por cima. Com a maquina primeiro, o macaco aparecia na frente das teclas --
	# ele estaria digitando pelo lado de fora.
	_macaco = _peca("macaco")
	_maquina = _peca("maquina")

	# a poeira fica POR CIMA da mesa e por baixo da UI: ela e ar, e ar fica na frente do
	# movel e atras de tudo que se le
	_poeira = Control.new()
	_poeira.name = "PoeiraNaLuz"
	_poeira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_poeira.draw.connect(_desenhar_poeira)
	add_child(_poeira)
	_sorteio.randomize()
	for i in MOTAS:
		_motas.append(_sorteio.randf())

	# a folha fica por cima da maquina: a letra sai NO papel, e nao atras dele
	_rotulo_do_papel = Label.new()
	_rotulo_do_papel.name = "LetraNoPapel"
	_rotulo_do_papel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_do_papel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rotulo_do_papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo_do_papel.clip_text = true
	add_child(_rotulo_do_papel)
	_ate_o_raro = _sorteio_raro()

	resized.connect(_posicionar)
	EventBus.interface_mudou.connect(_posicionar)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	# ⚠️ ADIADO, e nao so no _ready. Quando este no entra na arvore, o PAI ainda nao foi
	# dimensionado: size e (0, 0), a conta de escala sai pela guarda e clip_contents corta
	# tudo -- o menu abre com o fundo vazio da engine e nenhum erro no console. A primeira
	# captura do menu com arte saiu exatamente assim.
	call_deferred("_posicionar")
	_posicionar()


## ⚠️ O QUADRO DO MENU VIVO (issue #48), e ele para inteiro com reduzir movimento ligado.
## Nao e so o gesto que para: o _process sai do ar, e com ele o redesenho da poeira e das
## estrelas. Menu parado que continua redesenhando e bateria queimada a toa.
func _process(delta: float) -> void:
	var estado := _gestos.tique(delta)
	_aplicar_gesto(estado)
	if not _gestos.ligado():
		return
	_relogio += delta
	adiantar_o_papel(delta)
	for i in _motas.size():
		_motas[i] = fposmod(
			_motas[i] + delta * SUBIDA_DA_POEIRA / maxf(FACHO_EM_ARTE.size.y, 1.0), 1.0
		)
	_poeira.queue_redraw()
	_constelacao.queue_redraw()


## Poe o gesto em cima da posicao base. Giro em torno do RODAPE da peca: girar pelo centro
## faz o macaco flutuar meio pixel, e girar pelo topo o faz varrer a mesa.
func _aplicar_gesto(estado: Dictionary) -> void:
	_assentar_com_gesto(_macaco, _base_macaco, estado.get("macaco", {}))
	_assentar_com_gesto(_maquina, _base_maquina, estado.get("maquina", {}))


func _assentar_com_gesto(no: TextureRect, base: Vector2, gesto: Dictionary) -> void:
	if no == null or no.texture == null:
		return
	var desloca: Vector2 = gesto.get("desloca", Vector2.ZERO)
	no.position = base + desloca * float(_escala)
	no.pivot_offset = Vector2(no.size.x * 0.5, no.size.y)
	no.rotation = float(gesto.get("gira", 0.0))


# ------------------------------------------------------------------------ o papel e a tecla

## O jogador apertou uma tecla: o macaco bate AQUELA tecla e a letra aparece na folha
## (issue #49, plano §37).
##
## ⚠️ SO VISUAL. Nada aqui toca em Jogo, Save ou Economia. Esta e a unica brincadeira do
## projeto que nao tem consequencia nenhuma, e ela so pode existir porque nao tem.
func datilografar(letra: String) -> void:
	if letra.is_empty() or not _gestos.ligado():
		return
	_papel += letra
	if _papel.length() > LIMITE_DO_PAPEL:
		# a folha nao rola: ela mostra o FIM do que foi escrito, como uma maquina de
		# escrever de verdade mostra a linha em que se esta
		_papel = _papel.substr(_papel.length() - LIMITE_DO_PAPEL)
	_ate_arrancar = PAPEL_VISIVEL
	Audio.tocar_clack()
	_pintar_o_papel()


## Faz o macaco escrever uma frase sozinho, letra a letra. Publica porque a fumaca dispara
## o acontecimento raro em vez de esperar por ele -- esperar dois minutos para provar dois
## minutos e o motivo de isso nunca ser testado em lugar nenhum.
func escrever_sozinho(frase: String) -> void:
	if frase.is_empty():
		return
	_papel = ""
	_sozinho = frase
	_ate_a_proxima_letra = 0.0
	_pintar_o_papel()


## O que esta escrito na folha agora. A suite e a fumaca leem daqui.
func escrito_no_papel() -> String:
	return _papel


## Faz o relogio da folha andar. Publica porque a fumaca DISPARA o acontecimento raro em vez
## de esperar por ele: esperar dois minutos para provar dois minutos e o motivo de isso
## nunca ser testado em lugar nenhum. E o mesmo principio das quatro horas de offline.
func adiantar_o_papel(delta: float) -> void:
	# o macaco escrevendo sozinho tem prioridade: a mao dele esta ocupada
	if not _sozinho.is_empty():
		_ate_a_proxima_letra -= delta
		if _ate_a_proxima_letra <= 0.0:
			_ate_a_proxima_letra = GestosDoMenu.ESPERA_MINIMA * 0.08
			datilografar(_sozinho.substr(0, 1))
			_sozinho = _sozinho.substr(1)
		return

	if _ate_arrancar > 0.0:
		_ate_arrancar -= delta
		if _ate_arrancar <= 0.0:
			_papel = ""
			_pintar_o_papel()
		return

	# ⚠️ O RARO SO E SORTEADO COM A FOLHA VAZIA. Comecar "banana" por cima do que o jogador
	# estava escrevendo e roubar o teclado dele -- e o easter egg vira interrupcao.
	_ate_o_raro -= delta
	if _ate_o_raro <= 0.0:
		_ate_o_raro = _sorteio_raro()
		# o tr() aqui, e nao na tabela: a frase e escolhida agora e escrita na lingua de
		# agora. Traduzir na constante congelaria a lingua do carregamento do script.
		escrever_sozinho(
			tr(FRASES_RARAS[_sorteio.randi_range(0, FRASES_RARAS.size() - 1)])
		)


func _sorteio_raro() -> float:
	return _sorteio.randf_range(ESPERA_RARA_MINIMA, ESPERA_RARA_MAXIMA)


## ⚠️ TROCAR DE LINGUA ARRANCA A PAGINA, e e o mesmo remedio das letras subindo (issue #22):
## a folha pode estar no meio de uma frase da lingua anterior, e reescreve-la no meio seria
## uma palavra metade em cada idioma. Arrancar nao devolve caractere nenhum ao jogador --
## nada disto encosta no save.
func _ao_mudar_idioma(_codigo: String) -> void:
	_papel = ""
	_sozinho = ""
	_ate_arrancar = 0.0
	_pintar_o_papel()


func _pintar_o_papel() -> void:
	if _rotulo_do_papel == null or _escala <= 0:
		return
	_rotulo_do_papel.text = _papel
	_rotulo_do_papel.add_theme_font_size_override(
		"font_size", maxi(CORPO_NO_PAPEL * _escala, 1)
	)
	_rotulo_do_papel.add_theme_color_override("font_color", Tema.cor(Paleta.INK_BROWN))
	_rotulo_do_papel.size = PAPEL_EM_ARTE.size * float(_escala)


## A escala inteira em uso agora. A issue #48 le isto para a camera da transicao andar em
## passos de pixel, e a suite le para afirmar que ela nunca e fracionaria.
func escala() -> int:
	return _escala


## O retangulo da maquina de escrever na tela, em pixels logicos. E onde a transicao para a
## partida termina (issue #48): a camera aproxima DELA, e e isso que faz o jogador entender
## que a mesa do menu e a mesa da partida.
func retangulo_da_maquina() -> Rect2:
	if _maquina == null:
		return Rect2()
	return Rect2(_maquina.position, _maquina.size)


# ----------------------------------------------------------------------------- montagem

func _peca(id: String) -> TextureRect:
	var textura := AssetsDoMenu.textura_de(id)
	var no := TextureRect.new()
	no.name = id.capitalize()
	no.texture = textura
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ⚠️ IGNORE_SIZE + SCALE: o tamanho e ditado por nos, e a textura obedece. Com o modo
	# padrao o TextureRect toma o tamanho da textura e a escala vira assunto do container
	no.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	no.stretch_mode = TextureRect.STRETCH_SCALE
	AssetsDoMenu.aplicar_filtro(no)
	no.visible = textura != null
	add_child(no)
	return no


## ⚠️ A CONTA QUE MANTEM O PIXEL QUADRADO. A escala e o MENOR inteiro que ainda cobre a
## area; o que sobrar sai pelas bordas, centralizado.
func _posicionar() -> void:
	var area := size
	if area.x <= 0.0 or area.y <= 0.0:
		return

	var arte := Vector2(AssetsDoMenu.peca("cenario")["tamanho"])
	_escala = maxi(int(ceil(maxf(area.x / arte.x, area.y / arte.y))), 1)

	var tamanho := arte * float(_escala)
	var canto := ((area - tamanho) * 0.5).floor()
	if _fundo != null:
		_fundo.position = canto
		_fundo.size = tamanho

	_base_macaco = _assentar(_macaco, "macaco", canto, MACACO_EM_ARTE)
	_base_maquina = _assentar(_maquina, "maquina", canto, MAQUINA_EM_ARTE)
	if _constelacao != null:
		_constelacao.position = canto
		_constelacao.size = tamanho
		_constelacao.queue_redraw()
	if _poeira != null:
		_poeira.position = canto
		_poeira.size = tamanho
		_poeira.queue_redraw()
	if _rotulo_do_papel != null:
		_rotulo_do_papel.position = canto + PAPEL_EM_ARTE.position * float(_escala)
		_pintar_o_papel()


## Poe uma peca no lugar dela. A posicao e o RODAPE CENTRAL da peca em coordenadas de arte:
## a maquina e o macaco pousam sobre a mesa, e ancorar pelo canto superior faria os dois
## flutuarem quando o tamanho da arte mudasse.
## Devolve a posicao BASE -- e dela que os gestos partem.
func _assentar(no: TextureRect, id: String, canto: Vector2, base: Vector2i) -> Vector2:
	if no == null or no.texture == null:
		return Vector2.ZERO
	var arte := Vector2(AssetsDoMenu.peca(id)["tamanho"])
	var tamanho := arte * float(_escala)
	no.size = tamanho
	var onde := canto + Vector2(base) * float(_escala) - Vector2(tamanho.x * 0.5, tamanho.y)
	no.position = onde
	return onde


# --------------------------------------------------------------------------- o infinito

## A lemniscata de Bernoulli, ponto a ponto. Em coordenadas de ARTE, multiplicadas pela
## escala na hora de desenhar -- assim as estrelas caem sempre na grade de pixel.
##
## ⚠️ O PASSO EVITA A EMENDA. Com t percorrendo 0..TAU em N passos, o primeiro e o ultimo
## ponto caem no mesmo lugar e a figura ganha uma estrela dobrada no meio -- que e onde a
## forma e mais fragil. O laco vai ate N e nao inclui o fim.
func _desenhar_infinito() -> void:
	if _constelacao == null or _escala <= 0:
		return
	var lado := INFINITO_LADO * float(_escala)
	for i in INFINITO_ESTRELAS:
		var t := TAU * float(i) / float(INFINITO_ESTRELAS)
		var divisor := 1.0 + sin(t) * sin(t)
		var ponto := INFINITO_EM_ARTE + Vector2(
			INFINITO_RAIO * cos(t) / divisor,
			INFINITO_RAIO * sin(t) * cos(t) / divisor,
		)
		var canto := (ponto * float(_escala)).floor()
		# ⚠️ CADA ESTRELA COM A PROPRIA FASE. Com fase igual as onze piscam juntas, e a
		# constelacao deixa de ser um ceu e vira um pisca-pisca de arvore de Natal.
		var brilho := 0.75 + 0.25 * sin(
			TAU * (_relogio / PERIODO_DA_PISCADA + float(i) / float(INFINITO_ESTRELAS))
		)
		var cor := Tema.cor(Paleta.PAPER_CREAM)
		cor.a = brilho
		_constelacao.draw_rect(Rect2(canto, Vector2(lado, lado)), cor)


## A poeira subindo no facho do abajur. Desenhada, e nao instanciada: dez motas sao dez
## retangulos por quadro, e um sistema de particulas aqui alocaria por mota (issue #42
## aprendeu isso no audio, e a conta e a mesma).
func _desenhar_poeira() -> void:
	if _poeira == null or _escala <= 0 or not _gestos.ligado():
		return
	var lado := float(_escala)
	for i in _motas.size():
		# x fixo por mota, y subindo: poeira em coluna, e nao em enxame
		var x := FACHO_EM_ARTE.position.x + FACHO_EM_ARTE.size.x * fmod(
			float(i) * 0.37 + 0.11, 1.0
		)
		var y := FACHO_EM_ARTE.position.y + FACHO_EM_ARTE.size.y * (1.0 - _motas[i])
		# some nas pontas do percurso: mota que aparece e desaparece de uma vez pisca
		var cor := Tema.cor(Paleta.BANANA_GOLD)
		cor.a = 0.30 * sin(PI * _motas[i])
		_poeira.draw_rect(
			Rect2((Vector2(x, y) * float(_escala)).floor(), Vector2(lado, lado)), cor
		)
