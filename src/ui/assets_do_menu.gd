## A tabela dos assets do menu: caminho, tamanho de origem e escala (issues #45 e #46).
##
## ⚠️ ESTA TABELA E A FONTE. O briefing de cada peca -- o que ela e, o que a separa das
## vizinhas, o que foi preenchido pela convencao -- mora em docs/ASSETS.md, que EXPLICA
## estas linhas. Quando os dois discordarem, este arquivo ganha e o texto se atualiza.
##
## ⚠️ O TAMANHO E DECLARADO, E NAO LIDO DO ARQUIVO. Ler a largura do PNG e dizer "e esse o
## tamanho" e um portao que aprova qualquer coisa: sprite gerado em 400x400 por engano
## passaria, e so apareceria na tela como um borrao. O numero e dito aqui, e o teste_assets
## exige que o disco concorde.
##
## ⚠️ A ESCALA E INTEIRA, E POR FAMILIA. Cenario a 5x (384x216 vira exatamente 1920x1080),
## UI a 4x, icones a 2x. Duas escalas dentro da mesma familia dariam dois tamanhos de pixel
## quadrado na mesma imagem -- que e o defeito que a decisao 0006 se compromete a evitar.
##
## O que a escala NAO garante esta escrito em docs/ASSETS.md: janela diferente da tela
## logica reamostra tudo, e escala de interface acima de 100% move a UI junto.
class_name AssetsDoMenu
extends RefCounted

const PASTA := "res://assets/menu"

## A tela logica do jogo. O cenario e desenhado para caber nela EXATAMENTE.
const TELA_LOGICA := Vector2i(1920, 1080)

const ESCALA_DO_CENARIO: int = 5
const ESCALA_DA_UI: int = 4
const ESCALA_DO_ICONE: int = 2

## Uma peca: o arquivo, o tamanho em que ela foi desenhada, a escala com que e desenhada e
## -- para as molduras -- a borda que o 9-slice nao estica.
##
## `borda` zero significa "nao e 9-slice".
const PECAS: Array[Dictionary] = [
	{
		"id": "cenario", "arquivo": "cenario_mesa.png",
		"tamanho": Vector2i(384, 216), "escala": ESCALA_DO_CENARIO, "borda": 0,
	},
	{
		"id": "maquina", "arquivo": "maquina.png",
		"tamanho": Vector2i(64, 48), "escala": ESCALA_DO_CENARIO, "borda": 0,
	},
	{
		"id": "macaco", "arquivo": "macaco.png",
		"tamanho": Vector2i(48, 56), "escala": ESCALA_DO_CENARIO, "borda": 0,
	},
	{
		"id": "emblema", "arquivo": "emblema.png",
		"tamanho": Vector2i(64, 64), "escala": ESCALA_DA_UI, "borda": 0,
	},
	{
		"id": "painel", "arquivo": "painel_papel.png",
		"tamanho": Vector2i(48, 48), "escala": ESCALA_DA_UI, "borda": 12,
	},
	{
		"id": "placa", "arquivo": "placa_normal.png",
		"tamanho": Vector2i(48, 24), "escala": ESCALA_DA_UI, "borda": 8,
	},
	{
		"id": "placa_afundada", "arquivo": "placa_afundada.png",
		"tamanho": Vector2i(48, 24), "escala": ESCALA_DA_UI, "borda": 8,
	},
	{
		"id": "moldura_manuscrito", "arquivo": "moldura_manuscrito.png",
		"tamanho": Vector2i(48, 32), "escala": ESCALA_DA_UI, "borda": 10,
	},
	{
		"id": "icone_infinito", "arquivo": "icone_infinito.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
	{
		"id": "icone_banana", "arquivo": "icone_banana.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
	{
		"id": "icone_engrenagem", "arquivo": "icone_engrenagem.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
	{
		"id": "icone_papel", "arquivo": "icone_papel.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
	{
		"id": "icone_excluir", "arquivo": "icone_excluir.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
	{
		"id": "icone_voltar", "arquivo": "icone_voltar.png",
		"tamanho": Vector2i(32, 32), "escala": ESCALA_DO_ICONE, "borda": 0,
	},
]


## A linha de uma peca, ou vazia quando ela nao existe.
static func peca(id: String) -> Dictionary:
	for linha in PECAS:
		if linha["id"] == id:
			return linha
	return {}


static func caminho_de(id: String) -> String:
	var linha := peca(id)
	if linha.is_empty():
		return ""
	return PASTA.path_join(str(linha["arquivo"]))


## A textura de uma peca, ou null quando ela ainda nao existe no disco.
##
## ⚠️ NULL E UM ESTADO LEGITIMO ENQUANTO A ARTE NAO CHEGA. A issue #46 monta o menu com o
## que existir e cai no desenho tipografico para o que faltar -- menu que nao abre porque um
## PNG nao veio e pior que menu feio.
##
## ⚠️ E O FILTRO E NEAREST, sempre. Pixel art com interpolacao vira borrao, e borrao e a
## unica coisa que pixel art nao pode ser (decisao 0006). O filtro e propriedade do NO que
## desenha, e nao da textura -- quem monta e que precisa lembrar; por isso existe
## aplicar_filtro().
static func textura_de(id: String) -> Texture2D:
	var caminho := caminho_de(id)
	if caminho.is_empty() or not ResourceLoader.exists(caminho):
		return null
	return ResourceLoader.load(caminho) as Texture2D


## Poe o filtro de pixel art no no que desenha. Um lugar so, para nenhuma peca nascer
## borrada por esquecimento.
static func aplicar_filtro(no: CanvasItem) -> void:
	no.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## A textura de uma peca JA AMPLIADA pela escala declarada, com vizinho mais proximo.
##
## ⚠️ ISTO EXISTE POR CAUSA DO 9-SLICE, e a razao e cirurgica: patch_margin e texture_margin
## sao medidos em pixels da TEXTURA, e nao na tela. Uma placa de 48x24 com borda de 8 pede
## margem 8 -- que desenha uma borda de 8 pixels de tela, minuscula em 1920 logicos. Pedir
## 32 (8 x 4) numa textura de 48 faz as duas margens somarem 64 e se sobreporem: o Godot
## nao reclama, ele desenha o papel repetido para fora do painel. Foi exatamente isso que a
## primeira captura do menu mostrou.
##
## Ampliar a textura ANTES resolve os dois lados: a borda vira 32 pixels de verdade e a
## margem continua sendo 32 na textura ampliada.
##
## ⚠️ E A AMPLIACAO E POR VIZINHO MAIS PROXIMO. Qualquer interpolacao aqui e o borrao que a
## decisao 0006 se compromete a evitar -- e ele entraria no proprio arquivo, e nao no
## desenho, onde o filtro do no nao alcanca mais.
##
## Cache em static var e cache COM MOTIVO: sao catorze pecas ampliadas uma vez, e o menu
## remonta o tema a cada mudanca de interface (issue #43). Sem ele, cada remontagem
## reescalaria todas as texturas.
static var _ampliadas: Dictionary = {}

static func textura_ampliada(id: String) -> Texture2D:
	if _ampliadas.has(id):
		return _ampliadas[id]
	var original := textura_de(id)
	if original == null:
		return null
	var linha := peca(id)
	var escala := maxi(int(linha["escala"]), 1)
	var imagem := original.get_image()
	imagem.resize(
		imagem.get_width() * escala, imagem.get_height() * escala,
		Image.INTERPOLATE_NEAREST,
	)
	var ampliada := ImageTexture.create_from_image(imagem)
	_ampliadas[id] = ampliada
	return ampliada


## A borda do 9-slice NA TEXTURA AMPLIADA. Zero quando a peca nao e 9-slice.
static func borda_ampliada(id: String) -> int:
	var linha := peca(id)
	if linha.is_empty():
		return 0
	return int(linha["borda"]) * maxi(int(linha["escala"]), 1)


## Quantas pecas ja existem no disco. A suite le isto para nao aprovar uma pasta vazia.
static func quantas_existem() -> int:
	var quantas := 0
	for linha in PECAS:
		if ResourceLoader.exists(PASTA.path_join(str(linha["arquivo"]))):
			quantas += 1
	return quantas
