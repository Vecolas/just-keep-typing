## As letras subindo da máquina (GDD §26).
##
## Tres regimes, e a troca entre eles e o efeito inteiro:
##
##   letra solta   no comeco, quando cada caractere ainda e um evento
##   +42 mil       quando um caractere sozinho deixou de significar alguma coisa
##   +38 milhões   quando nem o milhar significa
##
## O EFEITO DIMINUI SOZINHO. O GDD e explicito sobre nao tentar representar tudo: com
## 10^18 caracteres por segundo nao ha tela que caiba, e tentar seria transformar a
## assinatura visual do jogo no motivo de ele travar. O numero de rotulos por segundo e
## FIXO; o que cresce e o que cada um diz.
##
## ⚠️ A DEGRADACAO E POR PRODUCAO, E NAO POR FPS. Cair de qualidade quando o quadro ja
## esta travando e tarde: o jogador ja viu a travada. Aqui o regime muda quando a
## PRODUCAO passa do limiar, antes de qualquer engasgo.
##
## ⚠️ As letras soltas sao DECORACAO, e nao texto produzido. Elas saem de um alfabeto fixo
## e ninguem as le nem as conta -- o GDD §10 proibe gerar o texto do macaco, e este efeito
## nao gera: ele desenha. E a mesma distincao entre a moldura e o quadro.
##
## Tem class_name para a suite poder perguntar a REGRA (desenhando(), GLIFOS) sem subir
## cena nenhuma: copiar as duas condicoes para dentro do teste criaria uma segunda copia
## delas, e a segunda e a que mente.
class_name Letras
extends Control

## Alfabeto de decoracao do docs/ARTE.md, secao 9: letras, interrogacao e o infinito.
const GLIFOS: PackedStringArray = [
	"A", "B", "C", "E", "K", "M", "R", "T", "a", "e", "g", "k", "o", "r", "?", "∞",
]

## Teto de rotulos vivos ao mesmo tempo. MEDIDO com tools/medir_quadro.tscn -- ver
## TUNING.md para a tabela.
##
## O regime permanente fica em POR_SEGUNDO x DURACAO, ou seja catorze rotulos: e ai que o
## jogo vive. O teto existe como margem, e a regua mede a piscina CHEIA de proposito, para
## que ele nao seja um numero que se diz medido sem nunca ter sido tocado.
const TETO: int = 64

## Quantos rotulos nascem por segundo. Fixo de proposito -- e o que faz o efeito diminuir
## sozinho quando a producao explode.
const POR_SEGUNDO: float = 9.0

## Acima desta producao por rotulo, ele deixa de ser uma letra e vira um numero.
const LIMIAR_DE_NUMERO: float = 8.0

const SUBIDA: float = 90.0
const DURACAO: float = 1.6
const ESPALHAMENTO: float = 150.0

var _gerador := RandomNumberGenerator.new()
var _livres: Array[Label] = []
var _vivos: Array[Label] = []
var _ate_nascer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gerador.randomize()
	# a piscina nasce inteira: criar Label no meio da producao e alocar no pior momento,
	# que e exatamente quando o efeito esta mais denso
	EventBus.idioma_mudou.connect(_ao_mudar_idioma)
	EventBus.interface_mudou.connect(_ao_mudar_interface)
	for i in TETO:
		var rotulo := Label.new()
		rotulo.visible = false
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rotulo.add_theme_color_override("font_color", Tema.cor(Paleta.BANANA_GOLD))
		add_child(rotulo)
		_livres.append(rotulo)


func _process(delta: float) -> void:
	_avancar(delta)

	# ⚠️ AS DUAS OPCOES LIDAS NO QUADRO, e nunca guardadas (issue #43). Desligar particulas
	# e um gosto; reduzir movimento e acessibilidade -- e as duas param o EFEITO, nunca a
	# producao. Letra que para de subir nao e caractere que deixa de ser digitado: opcao de
	# interface que mexesse em progressao seria dificuldade disfarcada de conforto.
	if not desenhando():
		return

	_ate_nascer -= delta
	if _ate_nascer > 0.0:
		return
	_ate_nascer = 1.0 / POR_SEGUNDO
	_nascer(Jogo.caracteres_por_segundo.vezes(Grande.de_float(1.0 / POR_SEGUNDO)))


## Se as letras devem nascer agora. Publica porque a suite le daqui: afirmar a regra
## copiando as duas condicoes para dentro do teste criaria uma segunda copia dela.
##
## ⚠️ A regua medir_quadro nao passa por aqui -- ela chama nascer() direto, que e o que
## permite SATURAR a piscina mesmo com o efeito desligado.
static func desenhando() -> bool:
	return Config.ligado("particulas_de_letra") and not Config.ligado("reduzir_movimento")


## Rotulo vivo carrega numero ja formatado, e a virgula decimal muda com a lingua. Em vez
## de reescrever cada um, apaga: eles vivem 1,6 s e a proxima leva nasce na lingua nova.
## Repintar nao e reexecutar -- apagar nao devolve caractere nenhum ao jogador.
func _ao_mudar_idioma(_codigo: String) -> void:
	limpar()


## O mesmo, e pelo mesmo motivo: rotulo vivo carrega numero ja formatado, e o FORMATO muda
## com a opcao tanto quanto a virgula muda com a lingua. E se o efeito acabou de ser
## desligado, os que estao no ar tem que sumir -- desligar e ver letra subindo por mais um
## segundo e meio parece que o jogo ignorou a escolha.
func _ao_mudar_interface() -> void:
	limpar()


## Quantos rotulos estao vivos agora. A regua medir_quadro le isto.
func vivos() -> int:
	return _vivos.size()


## Devolve a piscina inteira. Publica para a regua medir_quadro comecar cada linha do
## zero -- sem isto os rotulos de uma linha morrem dentro da amostra da seguinte, e a
## linha reporta custo que nao e dela.
func limpar() -> void:
	for rotulo in _vivos:
		rotulo.visible = false
		_livres.append(rotulo)
	_vivos.clear()


## Publica para a regua medir_quadro conseguir SATURAR a piscina. O jogo nunca chama --
## ele so deixa o _process nascer no ritmo de POR_SEGUNDO. Sem isto o teto seria um numero
## que se diz medido sem nunca ter sido tocado por uma medicao.
func nascer(producao: Grande) -> void:
	_nascer(producao)


func _nascer(producao: Grande) -> void:
	if producao.sinal() <= 0 or _livres.is_empty():
		return
	var rotulo: Label = _livres.pop_back()
	_vivos.append(rotulo)

	if producao.menor_que(Grande.de_float(LIMIAR_DE_NUMERO)):
		rotulo.text = GLIFOS[_gerador.randi_range(0, GLIFOS.size() - 1)]
		rotulo.add_theme_font_size_override("font_size", Tema.fonte(26))
	else:
		# "+%s" e marca de formato, nao texto
		rotulo.text = "+%s" % Formatador.formatar(producao)
		rotulo.add_theme_font_size_override("font_size", Tema.fonte(20))

	rotulo.position = Vector2(
		size.x * 0.5 + _gerador.randf_range(-ESPALHAMENTO, ESPALHAMENTO),
		size.y * 0.5,
	)
	rotulo.modulate.a = 1.0
	rotulo.visible = true
	rotulo.set_meta("vida", DURACAO)


func _avancar(delta: float) -> void:
	var i := _vivos.size() - 1
	while i >= 0:
		var rotulo: Label = _vivos[i]
		var vida: float = float(rotulo.get_meta("vida")) - delta
		if vida <= 0.0:
			rotulo.visible = false
			_vivos.remove_at(i)
			_livres.append(rotulo)
		else:
			rotulo.set_meta("vida", vida)
			rotulo.position.y -= SUBIDA * delta
			rotulo.modulate.a = vida / DURACAO
		i -= 1
