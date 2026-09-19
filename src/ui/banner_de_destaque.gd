## O BANNER DO TOPO: onde uma descoberta finalmente cabe (plano §9).
##
## ⚠️ ELE EXISTE PORQUE O CONTEUDO COLECIONAVEL DO JOGO APARECIA NUMA LINHA DE RODAPE. Sao
## setenta e tres descobertas escritas uma a uma, com raridade, texto proprio e versos -- e o
## jogador via "Descoberta: BANANA" em corpo de legenda, apagado, embaixo da tela, por 2,2
## segundos, disputando o mesmo rotulo com a gravacao automatica. Conteudo que o jogador nao
## consegue consumir nao e polimento: e conteudo inexistente (decisao 0010).
##
## O que ele mostra, e cada linha responde uma pergunta diferente:
##
##   marca      QUAO RARO -- o simbolo de raridade, que se le de relance
##   rubrica    O QUE ACONTECEU -- "NOVA DESCOBERTA", "MARCO", "TEOREMA PROVADO"
##   titulo     O QUE E -- o nome, no corpo maior da tela depois do contador
##   detalhe    O QUE ISSO SIGNIFICA -- a frase que o dado ja tem escrita
##
## ⚠️ COR + SIMBOLO + NOME, e nunca cor sozinha (issue #43, docs/ARTE.md §9). A cor da
## raridade acompanha; quem carrega a leitura sao a marca e a rubrica, que sao TEXTO.
##
## ⚠️ E ELE NAO ROUBA FOCO, NAO PARA O JOGO E NAO PEDE CLIQUE. Este e um jogo que fica aberto
## atras de outra coisa (issue #34): uma janelinha modal a cada descoberta seria motivo para
## fechar o jogo. Ele aparece, e ele sai sozinho.
##
## ⚠️ QUEM ANDA O RELOGIO E A HUD. Este no le o estado da faixa e desenha; ticar a fila aqui
## tambem faria cada aviso durar metade do que a tabela promete, sem erro nenhum no console.
##
## O texto chega JA TRADUZIDO, do autoload Avisos, porque a traducao acontece no instante do
## acontecimento -- e o mesmo que o rotulo do rodape sempre fez. Trocar de lingua com o banner
## na tela deixa os 4 segundos restantes na lingua anterior, e isso e aceito: retraduzir
## exigiria guardar o dado em vez do texto, e a fila e de texto desde a issue #69.
class_name BannerDeDestaque
extends PanelContainer

## Respiro interno. Generoso de proposito: este e o unico painel da tela cujo trabalho e ser
## lido de longe.
const FOLGA: int = 18

## O corpo da marca de raridade. Grande porque ela e o que se le primeiro, antes de qualquer
## palavra.
const CORPO_DA_MARCA: int = 40

var _marca: Label = null
var _rubrica: Label = null
var _titulo: Label = null
var _detalhe: Label = null


func _ready() -> void:
	# ⚠️ NAO COME CLIQUE NENHUM. Ele cobre a faixa de cima da tela por varios segundos, e
	# clicar no meio da tela digita (issue #7): com o mouse_filter padrao -- STOP -- cada
	# descoberta engoliria sete segundos de cliques do jogador.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var margem := MarginContainer.new()
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, FOLGA)
	add_child(margem)

	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", FOLGA)
	margem.add_child(linha)

	_marca = Label.new()
	_marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(_marca)

	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 2)
	linha.add_child(coluna)

	_rubrica = Label.new()
	_rubrica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_rubrica)

	_titulo = Label.new()
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_titulo)

	# ⚠️ AUTOWRAP. O texto de uma descoberta e uma frase inteira -- "Duas letras.
	# Filosoficamente inconvenientes." --, e cortar no meio e pior que nao mostrar: promete
	# um texto e entrega metade. Caractere nao e pixel, e em ingles a mesma frase tem outra
	# largura.
	_detalhe = Label.new()
	_detalhe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_detalhe)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_estilizar()


## O banner trocou de conteudo: a HUD chama quando a faixa de destaque muda.
func trocar() -> void:
	visible = Avisos.tem_destaque()
	if not visible:
		return
	var carga := Avisos.destaque_atual()
	_marca.text = str(carga.get("marca", "?"))
	_rubrica.text = str(carga.get("rubrica", ""))
	_titulo.text = str(carga.get("titulo", ""))
	_detalhe.text = str(carga.get("detalhe", ""))
	# ⚠️ o detalhe pode ser vazio de verdade: um marco sem frase nao e erro, e um rotulo
	# vazio ocupando uma linha inteira le como corte
	_detalhe.visible = not _detalhe.text.strip_edges().is_empty()

	var cor := _cor_da_carga(carga)
	_marca.add_theme_color_override("font_color", Tema.cor(cor))
	_titulo.add_theme_color_override("font_color", Tema.cor(cor))
	add_theme_stylebox_override("panel", Tema.painel(cor, true))
	modulate.a = 1.0


## O desvanecimento, por quadro. A HUD passa o quanto resta.
##
## ⚠️ DESAPARECE NOS ULTIMOS SEGUNDOS em vez de sumir num quadro: banner que pisca vira
## ruido, e o jogador passa a nao ler nenhum deles.
func andar() -> void:
	visible = Avisos.tem_destaque()
	if visible:
		modulate.a = Avisos.destaque_quanto_resta()


## A cor da raridade, ou o dourado de sempre quando o acontecimento nao tem raridade -- marco
## e prestigio nao sao raros, eles sao grandes.
##
## ⚠️ Categoria fora da faixa cai no creme, e nao estoura o indice: um banner sem cor ainda se
## le, um quadro derrubado nao.
func _cor_da_carga(carga: Dictionary) -> Color:
	var categoria := int(carga.get("categoria", Avisos.SEM_CATEGORIA))
	if categoria < 0:
		return Paleta.BANANA_GOLD
	if categoria >= Paleta.RARIDADES.size():
		return Paleta.PAPER_CREAM
	return Paleta.RARIDADES[categoria]


## ⚠️ O TITULO USA A FONTE SERIFADA (docs/ARTE.md §8): titulo serifado pesado e interface
## monoespacada sao DUAS tipografias, e este e o maior titulo da partida.
func _estilizar() -> void:
	_marca.add_theme_font_size_override("font_size", Tema.fonte(CORPO_DA_MARCA))

	_rubrica.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	_rubrica.add_theme_color_override(
		"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.35))
	)

	_titulo.add_theme_font_override("font", Tema.fonte_de_titulo())
	_titulo.add_theme_font_size_override("font_size", Tema.fonte(Tema.DESTAQUE))

	_detalhe.add_theme_font_size_override("font_size", Tema.fonte(Tema.CORPO))
	_detalhe.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))


## ⚠️ REMONTA OS OVERRIDES, e nao so repinta. A escala do texto e o alto contraste entram
## dentro deles, e override nao se atualiza sozinho quando a opcao muda (issue #43).
func _ao_mudar_interface() -> void:
	_estilizar()
	if Avisos.tem_destaque():
		trocar()


## ⚠️ ARIDADE EXATA, e por isso sao dois metodos e nao um. `idioma_mudou` leva o codigo e
## `interface_mudou` nao leva nada: ligar os dois no mesmo metodo de zero argumentos derruba a
## chamada no primeiro sinal emitido -- e derruba em runtime, nao ao conectar.
func _ao_mudar_idioma(_codigo: String) -> void:
	_ao_mudar_interface()
