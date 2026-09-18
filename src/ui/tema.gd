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
