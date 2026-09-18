## A tela de creditos (issue #39).
##
## O conteudo e uma TABELA e nao uma sequencia de Labels montados na mao: credito novo --
## a arte da issue #45, a trilha que vier depois -- e uma linha em CREDITOS, e nenhuma
## linha de codigo muda. Cinco blocos soltos e o desenho em que o quinto sai com outra
## fonte, e ninguem percebe ate a captura.
##
## ⚠️ PAPEL SE TRADUZ, NOME NAO. "Motor" vira "Engine" em ingles; "Godot Engine" e
## "Vecolas" sao nomes proprios e atravessam as duas linguas iguais -- traduzir nome
## proprio e como o portao de texto da issue #23 comeca a acusar linha que nao devia
## existir no CSV.
##
## ⚠️ SO CREDITA O QUE JA EXISTE. Linha para asset que ainda nao foi gerado e credito
## falso, e credito falso nao da erro nenhum: ele so fica la, dizendo uma coisa que nao e
## verdade, ate alguem ler. A arte entra nesta lista na issue #45, junto com os arquivos.
extends TelaSobreposta

const TITULO_TELA: int = 22
const NOME_DO_JOGO: int = 34
const PAPEL: int = 14
const NOME: int = 18
const EPIGRAFE: int = 16

## Uma linha de credito: o papel (texto de jogo) e quem o cumpriu (nome proprio).
const CREDITOS: Array[Dictionary] = [
	{"papel": "Jogo e código", "nome": "Vecolas"},
	{"papel": "Motor", "nome": "Godot Engine 4.7"},
]


func _ready() -> void:
	theme = Tema.montar()
	%Cortina.color = Tema.fundo()
	%Cortina.color.a = 0.96
	%Painel.add_theme_stylebox_override("panel", Tema.painel())
	%Titulo.add_theme_font_size_override("font_size", Tema.fonte(TITULO_TELA))
	%Titulo.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))
	%BotaoFechar.focus_mode = Control.FOCUS_ALL
	%BotaoFechar.pressed.connect(fechar)

	EventBus.creditos_pedidos.connect(abrir)
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)


func abrir() -> void:
	_montar()
	super()


func _primeiro_foco() -> Control:
	return %BotaoFechar


func _ao_mudar_idioma(_codigo: String) -> void:
	if visible:
		_montar()


func _montar() -> void:
	for antigo in %Lista.get_children():
		%Lista.remove_child(antigo)
		antigo.queue_free()

	%Titulo.text = tr("CRÉDITOS")
	%BotaoFechar.text = tr("Fechar")

	%Lista.add_child(_rotulo(tr("JUST KEEP TYPING"), NOME_DO_JOGO, Paleta.BANANA_GOLD))
	%Lista.add_child(_rotulo(
		tr("Um incremental sobre o Teorema do Macaco Infinito."),
		NOME, Paleta.PAPER_CREAM,
	))
	%Lista.add_child(_respiro())

	for credito in CREDITOS:
		%Lista.add_child(_linha(str(credito["papel"]), str(credito["nome"])))

	%Lista.add_child(_respiro())
	var epigrafe := _rotulo(
		tr("Tempo infinito, uma máquina de escrever, e nenhuma pressa."),
		EPIGRAFE, Paleta.MONKEY_BROWN.lightened(0.35),
	)
	epigrafe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	%Lista.add_child(epigrafe)


## Papel em cima, pequeno; nome embaixo, grande. Duas colunas lado a lado quebrariam em
## ingles, onde "Jogo e código" e "Game and code" nao tem a mesma largura -- e o alinhamento
## por coluna fixa e exatamente o que a captura em `en` da issue #23 existe para pegar.
func _linha(papel: String, nome: String) -> Control:
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	coluna.add_child(_rotulo(tr(papel), PAPEL, Paleta.MONKEY_BROWN.lightened(0.2)))
	# nome proprio nao passa por tr(): ver o aviso no topo do arquivo
	coluna.add_child(_rotulo(nome, NOME, Paleta.PAPER_CREAM))
	return coluna


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", Tema.fonte(tamanho))
	rotulo.add_theme_color_override("font_color", Tema.cor(cor))
	return rotulo


func _respiro() -> Control:
	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 12)
	return espaco


## ⚠️ REMONTA O TEMA, e nao so repinta (issue #43). A escala do texto e o alto contraste
## entram dentro do Theme, e Theme e um objeto CONSTRUIDO: ele nao se atualiza sozinho
## quando a opcao muda. Repintar sem remontar deixaria a tela com os tamanhos antigos e
## nenhum erro no console.
func _ao_mudar_interface() -> void:
	theme = Tema.montar()
	if visible:
		_montar()
