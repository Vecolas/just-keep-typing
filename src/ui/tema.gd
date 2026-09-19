## O tema de interface do jogo, montado em codigo a partir da Paleta.
##
## Em codigo e nao num .tres porque cor de identidade nao e numero de balanceamento
## (docs/ARTE.md, secao 6): ninguem vai mexer nela numa sessao de tuning, e uma paleta que
## mora em arquivo de dados e uma paleta que vai divergir entre telas.
##
## ⚠️ TODA TELA REMONTA O TEMA quando a interface muda (issue #43): a escala do texto e o
## alto contraste entram aqui, e Theme e um objeto construido -- ele nao se atualiza
## sozinho. Quem escuta EventBus.interface_mudou tem que chamar montar() de novo.
##
## Compartilhado porque theme so desce para os FILHOS de quem o recebe. A HUD e o Panorama
## sao irmaos no CanvasLayer -- deixar o tema so na HUD deu exatamente isso: um Panorama
## em fonte de sistema no meio de um jogo que a secao 8 do ARTE.md manda ser monoespacado.
class_name Tema

## Fontes monoespacadas do sistema, na ordem de preferencia. A tipografia de interface do
## docs/ARTE.md pede maquina de escrever -- monoespacada e MUITO legivel, porque este e um
## jogo de ler numero. Fonte propria entra quando houver asset; ate la o sistema resolve,
## e sem versionar arquivo binario nenhum.
const FONTES: PackedStringArray = [
	"Consolas", "Courier New", "DejaVu Sans Mono", "Liberation Mono", "monospace",
]

## Fontes SERIFADAS do sistema, na ordem de preferencia. O docs/ARTE.md §8 pede titulo
## serifado pesado e interface monoespacada -- sao DUAS tipografias, e ate a issue #46 o
## jogo usava a monoespacada para as duas coisas por omissao.
##
## ⚠️ E SAO DUAS, E NUNCA TRES. O logo nao inventa uma terceira fonte (§8): ele usa esta.
const FONTES_DE_TITULO: PackedStringArray = [
	"Georgia", "Times New Roman", "DejaVu Serif", "Liberation Serif", "serif",
]

const CORPO: int = 18
const TITULO: int = 15
const CONTADOR: int = 44
const DESTAQUE: int = 26
const BOTAO_GRANDE: int = 34

## Quanto o alto contraste clareia o que se le e escurece o que fica atras. Limite de
## design: acima disto a paleta do docs/ARTE.md deixa de ser reconhecivel, e o jogo passa a
## ser outro jogo em vez de ser o mesmo jogo mais legivel.
const REFORCO_DE_CONTRASTE: float = 0.45
const RECUO_DE_CONTRASTE: float = 0.55

## Os tres degraus de luminancia da placa (issue #46). Escolhidos separados o bastante para
## serem lidos sem matiz: 1,00 -> 1,35 -> 0,55 nao e uma variacao sutil, e nao pode ser.
const BRILHO_NORMAL: float = 1.0
const BRILHO_HOVER: float = 1.35
const BRILHO_DESABILITADO: float = 0.55

## Respiro entre o texto e as bordas da placa, somado em cima das duas bordas do 9-slice.
const FOLGA_DA_PLACA: int = 12

## Quantos pixels o rotulo desce quando o botao e apertado. Limite de design: seis e o que
## se ve sem parecer que o texto escorregou.
const DESLOCAMENTO_AO_APERTAR: int = 6


## O TAMANHO DE FONTE QUE VALE AGORA, e nunca o numero cru da constante.
##
## ⚠️ TODO add_theme_font_size_override DO PROJETO PASSA POR AQUI (issue #43). A escala do
## texto e uma opcao de acessibilidade: um unico rotulo com o numero cravado fica do
## tamanho antigo quando todo o resto cresce, e o defeito nao da erro -- ele so deixa uma
## linha ilegivel no meio de uma tela ajustada.
##
## Le o Config na hora de usar, e nunca guarda (CONVENCOES.md, regra 2).
static func fonte(base: int) -> int:
	return maxi(int(round(float(base) * Config.escala_do_texto())), 1)


## A COR DE PRIMEIRO PLANO que vale agora: o que o jogador LE.
##
## Com alto contraste ela clareia, mantendo a matiz -- a paleta continua sendo a do
## docs/ARTE.md, so que mais separada do fundo. Trocar por branco puro apagaria a
## identidade inteira (dourado e producao, ciano e automacao), e a secao 6 proibe branco
## puro justamente por isso.
static func cor(base: Color) -> Color:
	if not Config.ligado("alto_contraste"):
		return base
	return base.lightened(REFORCO_DE_CONTRASTE)


## A COR DE FUNDO que vale agora: o que fica ATRAS do que se le. Com alto contraste ela
## escurece, e a distancia entre as duas e o contraste.
static func fundo(base: Color = Paleta.INK_BROWN.darkened(0.4)) -> Color:
	if not Config.ligado("alto_contraste"):
		return base
	return base.darkened(RECUO_DE_CONTRASTE)


## A fonte serifada de titulo, criada POR CHAMADA.
##
## ⚠️ Recurso declarado uma vez e usado por varias instancias e estado global disfarcado
## (CONVENCOES.md): duas telas compartilhando o mesmo SystemFont e uma tela mexendo no
## tamanho da outra.
static func fonte_de_titulo() -> SystemFont:
	var fonte := SystemFont.new()
	fonte.font_names = FONTES_DE_TITULO
	return fonte


## O estilo de um botao de PLACA de maquina (issue #46), ou null quando o asset nao existe
## -- e ai quem manda e o StyleBoxFlat do tema, e o menu continua utilizavel.
##
## ⚠️ OS QUATRO ESTADOS PRECISAM SER DISTINGUIVEIS SEM COR. Aqui eles sao:
##
##   normal        a placa, como ela e
##   hover         a MESMA placa, claramente mais clara
##   pressionado   a placa AFUNDADA -- outro desenho, com a sombra em cima em vez de
##                 embaixo. Este difere por FORMA, e nao por valor
##   desabilitado  a placa, claramente mais escura
##
## Tres degraus de luminancia mais uma diferenca de forma: quem nao distingue matiz
## continua lendo os quatro. Matiz nenhuma carrega informacao aqui.
static func placa(id: String, brilho: float, desce: int = 0) -> StyleBoxTexture:
	# ⚠️ A TEXTURA AMPLIADA, e nao a original: texture_margin e medido em pixels da TEXTURA.
	# Ver o aviso em AssetsDoMenu.textura_ampliada.
	var textura := AssetsDoMenu.textura_ampliada(id)
	if textura == null:
		return null
	var estilo := StyleBoxTexture.new()
	estilo.texture = textura
	# a borda nao estica; o miolo sim. Sem isto a placa inteira deforma e os rebites viram
	# ovais no botao largo
	estilo.set_texture_margin_all(float(AssetsDoMenu.borda_ampliada(id)))
	estilo.set_expand_margin_all(0.0)
	estilo.modulate_color = Color(brilho, brilho, brilho, 1.0)
	estilo.content_margin_left = 16.0
	estilo.content_margin_right = 16.0
	# ⚠️ `desce` E O ESTADO PRESSIONADO SE VENDO SEM COR. A placa afundada ja e outro
	# desenho, mas o que o olho pega primeiro e o RÓTULO DESCENDO junto com ela -- e
	# movimento nao tem matiz. Sem isto, quem nao distingue os dois marrons vê dois botões
	# iguais.
	estilo.content_margin_top = 10.0 + float(desce)
	estilo.content_margin_bottom = maxf(10.0 - float(desce), 2.0)
	return estilo


## Poe os quatro estados de placa num botao, e liga o filtro de pixel art. Devolve se a
## placa foi aplicada -- false significa "nao ha asset", e nao "deu erro".
##
## ⚠️ O FILTRO E DO NO QUE DESENHA, e nao da textura. Botao com placa e sem nearest e um
## botao borrado no meio de um menu nitido, e nada no console diz isso.
## Uma moldura 9-slice de pixel art como StyleBox, ou null quando o asset nao existe.
##
## ⚠️ MOLDURA E OCA. Ao contrario da placa, ela NAO desenha o miolo -- quem desenha o fundo
## do cartao e o cartao. Por isso ela nao ganha content_margin proprio: o conteudo respira
## pela margem que o cartao ja tem, e somar as duas empurraria o texto para o meio da folha.
static func moldura(id: String, brilho: float) -> StyleBoxTexture:
	var textura := AssetsDoMenu.textura_ampliada(id)
	if textura == null:
		return null
	var estilo := StyleBoxTexture.new()
	estilo.texture = textura
	estilo.set_texture_margin_all(float(AssetsDoMenu.borda_ampliada(id)))
	estilo.modulate_color = Color(brilho, brilho, brilho, 1.0)
	return estilo


## ⚠️ E ELE DITA A ALTURA MINIMA DO BOTAO. As duas bordas do 9-slice nao esticam: num botao
## mais baixo que a soma delas, o Godot desenha a borda de cima por cima da de baixo e o
## rotulo sai cortado -- foi assim que a captura dos quatro estados mostrou "CRÉDITOS" pela
## metade. O numero sai da PECA, e nao de um palpite de layout.
static func vestir_de_placa(botao: Button) -> bool:
	var normal := placa("placa", BRILHO_NORMAL)
	if normal == null:
		return false
	var altura := float(AssetsDoMenu.borda_ampliada("placa") * 2 + fonte(CORPO) + FOLGA_DA_PLACA)
	botao.custom_minimum_size.y = maxf(botao.custom_minimum_size.y, altura)
	AssetsDoMenu.aplicar_filtro(botao)
	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", placa("placa", BRILHO_HOVER))
	botao.add_theme_stylebox_override(
		"pressed", placa("placa_afundada", BRILHO_NORMAL, DESLOCAMENTO_AO_APERTAR)
	)
	botao.add_theme_stylebox_override("disabled", placa("placa", BRILHO_DESABILITADO))
	botao.add_theme_stylebox_override("focus", foco())
	return true


static func montar() -> Theme:
	var fonte_do_sistema := SystemFont.new()
	fonte_do_sistema.font_names = FONTES

	var tema := Theme.new()
	tema.default_font = fonte_do_sistema
	tema.default_font_size = fonte(CORPO)
	tema.set_color("font_color", "Label", cor(Paleta.PAPER_CREAM))
	tema.set_stylebox("panel", "PanelContainer", painel())

	# botao secundario: marrom com borda de bronze (docs/ARTE.md, secao 9)
	tema.set_font_size("font_size", "Button", fonte(CORPO))
	tema.set_color("font_color", "Button", cor(Paleta.PAPER_CREAM))
	tema.set_color("font_hover_color", "Button", cor(Paleta.BANANA_GOLD))
	tema.set_color("font_disabled_color", "Button", cor(Paleta.MONKEY_BROWN))
	tema.set_stylebox("normal", "Button", botao(fundo(Paleta.MONKEY_BROWN.darkened(0.55))))
	tema.set_stylebox("hover", "Button", botao(fundo(Paleta.MONKEY_BROWN.darkened(0.35))))
	tema.set_stylebox("pressed", "Button", botao(fundo(Paleta.MONKEY_BROWN.darkened(0.7))))
	tema.set_stylebox("disabled", "Button", botao(
		fundo(Paleta.INK_BROWN), cor(Paleta.MONKEY_BROWN)
	))
	# ⚠️ O FOCO PRECISA APARECER. Ele ja esteve vazio aqui, e por um bom motivo: na HUD todo
	# botao e FOCUS_NONE (o espaco digita, issue #6) e a moldura nunca chegava a desenhar.
	# No menu ela desenha, e e a UNICA coisa que diz onde o cursor do teclado esta -- sem
	# ela, "navegavel sem mouse" vira navegar as cegas (issue #39).
	tema.set_stylebox("focus", "Button", foco())
	return tema


## A moldura do foco: so borda, sem preenchimento, para nao apagar o estado do botao que
## ela emoldura. Dourado claro porque ela tem que vencer o hover -- botao focado E sob o
## mouse continua sendo um so, e quem manda e o teclado.
static func foco() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.border_color = cor(Paleta.BANANA_GOLD)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.set_expand_margin_all(2)
	return estilo


static func painel(
	borda: Color = Paleta.MECHANICAL_GOLD.darkened(0.35), preenchido: bool = false
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo(
		Paleta.INK_BROWN.lightened(0.06) if preenchido else Paleta.INK_BROWN
	)
	estilo.border_color = cor(borda)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(0)
	return estilo


## A ALTURA DE UMA BARRA DE PROGRESSO, em pixels logicos.
##
## ⚠️ Limite de DESIGN, e nao botao de tuning: seis pixels e o que se ve de relance sem a barra
## virar um segundo bloco de conteudo. Ela e apoio ao numero que esta escrito ao lado, e nunca
## a informacao principal -- por isso ela e fina, e por isso ela nao mostra porcentagem.
const ALTURA_DA_BARRA: int = 6


## Poe a barra de progresso no estilo do jogo: trilho escuro, preenchimento na cor pedida.
##
## ⚠️ A PORCENTAGEM ESCRITA FICA DESLIGADA, e isso e a issue #43 aplicada: o numero que
## importa ja esta no rotulo ao lado, em texto de tamanho legivel. Uma porcentagem dentro de
## uma barra de seis pixels e texto que ninguem le -- e texto ilegivel e pior que texto
## ausente, porque ocupa o lugar de algo que seria lido.
##
## ⚠️ E ELA NUNCA E A UNICA LEITURA. Toda barra desta interface tem um rotulo do lado dizendo
## o mesmo em numero: forma sem texto nao alcanca quem nao distingue a cor do preenchimento do
## trilho, e nao alcanca ninguem que precise do valor exato.
static func vestir_de_barra(barra: ProgressBar, tinta: Color) -> void:
	barra.show_percentage = false
	barra.custom_minimum_size.y = float(ALTURA_DA_BARRA)
	barra.min_value = 0.0
	barra.max_value = 100.0

	var trilho := StyleBoxFlat.new()
	trilho.bg_color = fundo(Paleta.INK_BROWN.lightened(0.1))
	trilho.set_corner_radius_all(3)
	barra.add_theme_stylebox_override("background", trilho)

	var preenchimento := StyleBoxFlat.new()
	# ⚠️ o parametro se chama `tinta` e nao `cor` porque `cor()` e a funcao estatica deste
	# arquivo: um parametro com o mesmo nome a esconde, e o alto contraste deixaria de valer
	# para toda barra do jogo sem uma linha no console
	preenchimento.bg_color = cor(tinta)
	preenchimento.set_corner_radius_all(3)
	barra.add_theme_stylebox_override("fill", preenchimento)


static func botao(
	preenchimento: Color, borda: Color = Paleta.MECHANICAL_GOLD.darkened(0.2)
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = preenchimento
	estilo.border_color = cor(borda)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	return estilo
