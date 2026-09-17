## O tema de interface do jogo, montado em codigo a partir da Paleta.
##
## Em codigo e nao num .tres porque cor de identidade nao e numero de balanceamento
## (docs/ARTE.md, secao 6): ninguem vai mexer nela numa sessao de tuning, e uma paleta que
## mora em arquivo de dados e uma paleta que vai divergir entre telas.
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

const CORPO: int = 18
const TITULO: int = 15
const CONTADOR: int = 44
const DESTAQUE: int = 26
const BOTAO_GRANDE: int = 34


static func montar() -> Theme:
	var fonte := SystemFont.new()
	fonte.font_names = FONTES

	var tema := Theme.new()
	tema.default_font = fonte
	tema.default_font_size = CORPO
	tema.set_color("font_color", "Label", Paleta.PAPER_CREAM)
	tema.set_stylebox("panel", "PanelContainer", painel())

	# botao secundario: marrom com borda de bronze (docs/ARTE.md, secao 9)
	tema.set_color("font_color", "Button", Paleta.PAPER_CREAM)
	tema.set_color("font_hover_color", "Button", Paleta.BANANA_GOLD)
	tema.set_color("font_disabled_color", "Button", Paleta.MONKEY_BROWN)
	tema.set_stylebox("normal", "Button", botao(Paleta.MONKEY_BROWN.darkened(0.55)))
	tema.set_stylebox("hover", "Button", botao(Paleta.MONKEY_BROWN.darkened(0.35)))
	tema.set_stylebox("pressed", "Button", botao(Paleta.MONKEY_BROWN.darkened(0.7)))
	tema.set_stylebox("disabled", "Button", botao(Paleta.INK_BROWN, Paleta.MONKEY_BROWN))
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
	estilo.border_color = Paleta.BANANA_GOLD
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.set_expand_margin_all(2)
	return estilo


static func painel(
	borda: Color = Paleta.MECHANICAL_GOLD.darkened(0.35), preenchido: bool = false
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Paleta.INK_BROWN.lightened(0.06) if preenchido else Paleta.INK_BROWN
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(0)
	return estilo


static func botao(
	fundo: Color, borda: Color = Paleta.MECHANICAL_GOLD.darkened(0.2)
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	return estilo
