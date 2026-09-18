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

var _fundo: TextureRect = null
var _maquina: TextureRect = null
var _macaco: TextureRect = null
var _constelacao: Control = null

var _escala: int = 1


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

	resized.connect(_posicionar)
	EventBus.interface_mudou.connect(_posicionar)
	# ⚠️ ADIADO, e nao so no _ready. Quando este no entra na arvore, o PAI ainda nao foi
	# dimensionado: size e (0, 0), a conta de escala sai pela guarda e clip_contents corta
	# tudo -- o menu abre com o fundo vazio da engine e nenhum erro no console. A primeira
	# captura do menu com arte saiu exatamente assim.
	call_deferred("_posicionar")
	_posicionar()


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

	_assentar(_macaco, "macaco", canto, MACACO_EM_ARTE)
	_assentar(_maquina, "maquina", canto, MAQUINA_EM_ARTE)
	if _constelacao != null:
		_constelacao.position = canto
		_constelacao.size = tamanho
		_constelacao.queue_redraw()


## Poe uma peca no lugar dela. A posicao e o RODAPE CENTRAL da peca em coordenadas de arte:
## a maquina e o macaco pousam sobre a mesa, e ancorar pelo canto superior faria os dois
## flutuarem quando o tamanho da arte mudasse.
func _assentar(no: TextureRect, id: String, canto: Vector2, base: Vector2i) -> void:
	if no == null or no.texture == null:
		return
	var arte := Vector2(AssetsDoMenu.peca(id)["tamanho"])
	var tamanho := arte * float(_escala)
	no.size = tamanho
	no.position = canto + Vector2(base) * float(_escala) - Vector2(tamanho.x * 0.5, tamanho.y)


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
		_constelacao.draw_rect(Rect2(canto, Vector2(lado, lado)), Tema.cor(Paleta.PAPER_CREAM))
