## UM UPGRADE COMO CARTAO: nome, o que ele faz, quanto rende e quanto custa -- tudo VISIVEL,
## sem passar o mouse em nada.
##
## ⚠️ ELE SUBSTITUI UMA LINHA COMPRAVEL, e a troca e o conteudo inteiro. "Dedos Mais Ageis
## — 124" e um preco; o cartao e uma escolha informada. A descricao e o efeito sairam do
## tooltip porque tooltip nao alcanca teclado, nao alcanca toque e nao alcanca quem le a tela
## de relance -- e a issue #43 ja decidiu que informacao essencial nao mora no hover.
##
## ⚠️ NAO HA PAINEL DE DETALHE, E ISSO E DECISAO. O plano previa lista curta + painel de
## detalhe embaixo, para o caso de existirem duas descricoes: uma curta na lista e uma longa
## no detalhe. `DadosUpgrade` tem UMA (`descricao`), entao o painel mostraria exatamente o
## mesmo texto do cartao -- duas fontes para a mesma verdade, sem uma linha de informacao
## nova, e mais um clique para chegar nela. O cartao carrega tudo.
##
## ⚠️ E ELE REPINTA A SI MESMO (portao de idioma). Quem monta texto em codigo escuta
## idioma_mudou e interface_mudou: a lista so e REMONTADA quando a composicao dela muda --
## upgrade comprado, requisito cruzado --, e uma troca de lingua nao muda composicao
## nenhuma. Sem esta conexao o nome ficaria em portugues no meio de uma interface em ingles,
## sem quebrar nada e sem imprimir erro.
##
## Nao guarda numero nenhum: le o dado e o saldo no quadro em que desenha (regra 2 de
## arquitetura). Quem decide se da para comprar e o Alcance, que e a fonte unica dos tres
## estados -- este cartao nao reimplementa nenhum deles.
class_name CartaoDeUpgrade
extends PanelContainer

## Quanto brilho sobra num cartao que ainda nem apareceu na loja.
##
## ⚠️ MAIS APAGADO QUE O "LONGE" DO Alcance, e tem que ser: o futuro e promessa, e promessa
## nao pode competir com um item que ja da para comprar. Limite de design.
const BRILHO_BLOQUEADO: float = 0.6

## Respiro interno do cartao.
const FOLGA: int = 12

## O "estado" de um cartao futuro. ⚠️ Fora da faixa do enum Alcance.Estado de proposito: ele
## nao e um alcance -- o cartao futuro nao consulta saldo nenhum --, e usar um valor do enum
## aqui faria um cartao futuro e um cartao LONGE terem o mesmo estado desenhado.
const ESTADO_BLOQUEADO: int = 100

var _dados: DadosUpgrade = null

## Se este cartao e do que ja esta na loja ou do que ainda vem. O futuro nao tem botao: ele
## mostra o que falta para aparecer.
var _futuro: bool = false

## Quem compra. Vazio no cartao futuro, que nao tem botao.
var _ao_comprar: Callable = Callable()

## O ESTADO E A PORCENTAGEM JA DESENHADOS. Guardados para o quadro nao refazer trabalho que
## nao mudou.
##
## ⚠️ ISTO NAO E OTIMIZACAO PREMATURA -- E UMA REGRESSAO MEDIDA. A primeira versao chamava
## add_theme_stylebox_override() em todo cartao, todo quadro, e cada chamada aloca um
## StyleBoxFlat novo E invalida o cache de tema do no. A regua medir_quadro pulou de 1,6 ms
## para 4,0 ms na era mais barata. E exatamente o mesmo preco que a cena das eras ja tinha
## pagado com 675 overrides num quadro (TUNING.md), chegando por outra porta.
##
## ⚠️ E O TEXTO TAMBEM SO MUDA QUANDO MUDA. Escrever o mesmo rotulo de novo refaz a
## conformacao do texto: sessenta vezes por segundo, em oito cartoes, para escrever "Comprar"
## por cima de "Comprar".
##
## -1 e o "nunca desenhado": nenhum estado e -1, entao o primeiro quadro sempre pinta.
var _estado_na_tela: int = -1
var _porcentagem_na_tela: int = -1

var _nome: Label = null
var _custo: Label = null
var _descricao: Label = null
var _efeito: Label = null
var _comprar: Button = null
var _desbloqueio: Label = null


## O cartao de um upgrade que JA esta na loja. `ao_comprar` recebe o id.
static func disponivel(dados: DadosUpgrade, ao_comprar: Callable) -> CartaoDeUpgrade:
	var cartao := CartaoDeUpgrade.new()
	cartao._dados = dados
	cartao._futuro = false
	cartao._ao_comprar = ao_comprar
	return cartao


## O cartao de um upgrade que ainda nao desbloqueou (plano §8).
static func futuro(dados: DadosUpgrade) -> CartaoDeUpgrade:
	var cartao := CartaoDeUpgrade.new()
	cartao._dados = dados
	cartao._futuro = true
	return cartao


func _ready() -> void:
	# ⚠️ O CARTAO NAO COME CLIQUE. A HUD cobre a tela inteira e clicar no meio dela digita
	# (issue #7): um PanelContainer com o mouse_filter padrao -- STOP -- transformaria cada
	# cartao num buraco morto na tela. Quem para o clique e so o botao de comprar.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _dados != null:
		set_meta("id", _dados.id)

	var margem := MarginContainer.new()
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, FOLGA)
	add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_theme_constant_override("separation", 8)
	coluna.add_child(topo)

	_nome = _rotulo()
	_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(_nome)

	_custo = _rotulo()
	_custo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	topo.add_child(_custo)

	# ⚠️ AUTOWRAP, e nao clip. Descricao cortada no meio e pior que descricao ausente: ela
	# promete um texto e entrega meio. E caractere nao e pixel -- a mesma frase em ingles
	# ocupa outra largura, e e por isso que a quebra e do container e nao um tamanho cravado.
	_descricao = _rotulo()
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_descricao)

	_efeito = _rotulo()
	_efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_efeito)

	if _futuro:
		_desbloqueio = _rotulo()
		coluna.add_child(_desbloqueio)
	else:
		_comprar = Button.new()
		# nenhum botao da HUD pega foco: com foco, a barra de espaco aciona o botao focado
		# em vez de digitar (issue #6)
		_comprar.focus_mode = Control.FOCUS_NONE
		if _ao_comprar.is_valid():
			_comprar.pressed.connect(_ao_comprar.bind(_dados.id))
		coluna.add_child(_comprar)

	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	_pintar()
	atualizar()


## O id do upgrade deste cartao. A HUD le para saber a quem o cartao pertence sem guardar
## uma segunda lista paralela.
func id() -> String:
	return _dados.id if _dados != null else ""


## Texto, corpo e cor -- tudo que muda com a lingua e com as opcoes de interface, e nada que
## muda com o saldo. O saldo e assunto de atualizar(), que roda por quadro.
func _pintar() -> void:
	if _dados == null:
		return
	_nome.text = tr(_dados.nome)
	_nome.add_theme_font_size_override("font_size", Tema.fonte(Tema.CORPO))
	_nome.add_theme_color_override("font_color", Tema.cor(Paleta.PAPER_CREAM))

	_custo.text = Formatador.formatar(Grande.de_float(_dados.custo))
	_custo.add_theme_font_size_override("font_size", Tema.fonte(Tema.CORPO))
	_custo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))

	_descricao.text = tr(_dados.descricao)
	_descricao.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	_descricao.add_theme_color_override(
		"font_color", Tema.cor(Paleta.MONKEY_BROWN.lightened(0.35))
	)

	_efeito.text = VitrineDeUpgrades.efeito_em_texto(_dados)
	_efeito.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
	# ⚠️ O EFEITO E DOURADO: dourado e producao e compra, e o codigo de cores do
	# docs/ARTE.md §6 e ensinado por repeticao. Um efeito em creme leria como mais uma linha
	# de descricao.
	_efeito.add_theme_color_override("font_color", Tema.cor(Paleta.MECHANICAL_GOLD))

	if _futuro:
		_desbloqueio.text = VitrineDeUpgrades.desbloqueio_em_texto(_dados)
		_desbloqueio.add_theme_font_size_override("font_size", Tema.fonte(Tema.TITULO))
		_desbloqueio.add_theme_color_override(
			"font_color", Tema.cor(Paleta.INFINITY_CYAN.darkened(0.2))
		)


## O que muda por quadro: o estado economico do cartao.
##
## ⚠️ O CARTAO FUTURO NAO CONSULTA O SALDO. Ele esta bloqueado por REQUISITO, e mostrar "72%"
## do preco de algo que nem apareceu na loja e uma porcentagem que nao leva a lugar nenhum.
## O que ele mostra e quanto falta para APARECER, que e a informacao que existe.
func atualizar() -> void:
	if _dados == null:
		return
	if _futuro:
		# o que falta muda a cada caractere produzido: este e o unico rotulo do cartao futuro
		# que precisa do quadro
		_desbloqueio.text = VitrineDeUpgrades.desbloqueio_em_texto(_dados)
		if _estado_na_tela == ESTADO_BLOQUEADO:
			return
		_estado_na_tela = ESTADO_BLOQUEADO
		modulate.a = BRILHO_BLOQUEADO
		add_theme_stylebox_override("panel", Tema.painel(Paleta.MONKEY_BROWN.darkened(0.2)))
		return

	var custo := Grande.de_float(_dados.custo)
	var estado := Alcance.de(custo)
	# ⚠️ A PORCENTAGEM E TEXTO, e nao cor (issue #43). "72%" se le em qualquer monitor e em
	# qualquer daltonismo; o brilho so acompanha.
	var porcentagem := (
		int(Alcance.fracao(custo) * 100.0) if estado == Alcance.Estado.PERTO else -1
	)
	if estado == _estado_na_tela and porcentagem == _porcentagem_na_tela:
		return
	_estado_na_tela = estado
	_porcentagem_na_tela = porcentagem

	modulate.a = Alcance.brilho_de(estado)
	_comprar.disabled = estado != Alcance.Estado.ALCANCAVEL
	add_theme_stylebox_override("panel", Tema.painel(
		Paleta.MECHANICAL_GOLD if estado == Alcance.Estado.ALCANCAVEL
		else Paleta.MONKEY_BROWN.darkened(0.2)
	))
	if porcentagem >= 0:
		# "%s  %d%%" e marca de formato, nao texto: nao passa por traducao
		_comprar.text = "%s  %d%%" % [tr("Comprar"), porcentagem]
		return
	_comprar.text = tr("Comprar")


func _rotulo() -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


func _ao_mudar_idioma(_codigo: String) -> void:
	_repintar_tudo()


## ⚠️ O CORPO DA FONTE ENTRA NO OVERRIDE, e override nao se atualiza sozinho quando a opcao
## muda: sem isto o cartao ficaria no tamanho antigo com o resto da tela ajustado (issue #43).
func _ao_mudar_interface() -> void:
	_repintar_tudo()


## ⚠️ ESQUECE O QUE ESTA NA TELA ANTES DE REPINTAR. `atualizar()` so trabalha quando o estado
## MUDA, e a lingua e a escala do texto nao mudam estado nenhum: sem esta linha o rotulo do
## botao de comprar ficaria na lingua anterior, e o stylebox continuaria com as cores do
## contraste anterior -- as duas coisas sem erro nenhum no console.
func _repintar_tudo() -> void:
	_estado_na_tela = -1
	_porcentagem_na_tela = -1
	_pintar()
	atualizar()
