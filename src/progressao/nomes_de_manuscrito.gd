## O nome de um Manuscrito: o que ele pode ser, e o que o jogo sugere quando o jogador nao
## quer escolher (issue #40).
##
## ⚠️ O NOME NUNCA ESCOLHE O CAMINHO DO ARQUIVO. Quem decide onde um slot mora e
## Config.caminho_do_slot, e so ele: o nome e texto que vai para DENTRO do save e para a
## tela, nunca para o nome do arquivo. Um "../../opcoes" digitado no campo seria, no
## desenho errado, permissao de escrever onde o jogador quisesse -- e o sintoma nao seria
## um erro, seria um arquivo sumindo.
##
## Ainda assim o texto e limpo antes de entrar: nao pelo caminho, que ja esta protegido,
## mas pela TELA. Quebra de linha, tabulacao e caractere de controle nao aparecem no
## cartao, eles o DESMONTAM -- e um nome de duzentos caracteres empurra a era, o total e o
## tempo jogado para fora da moldura sem uma linha no console.
##
## ⚠️ LIMITE E DE DESIGN, e nao botao de tuning (CONVENCOES.md). Vinte e quatro caracteres
## e o que cabe na linha do cartao na menor resolucao da lista; numero ajustavel seria
## ajustado para trinta na primeira vez que alguem achasse que faltava espaco, e o cartao
## quebraria em outra tela.
##
## As sugestoes SAO TEXTO DE JOGO: entram no CSV nas duas colunas, e a piada tem que
## sobreviver ao ingles. Elas moram numa constante, entao nenhuma varredura de literal as
## alcanca -- quem as cobra e o teste_texto, lendo esta lista pela FONTE.
class_name NomesDeManuscrito
extends RefCounted

const LIMITE: int = 24

## O que o jogo propoe quando o jogador cria um Manuscrito. Nomes tematicos, e nao
## "Save 1": o cartao existe para a pessoa reconhecer a propria partida entre tres.
const SUGESTOES: PackedStringArray = [
	"Hamlet Talvez",
	"Operação Banana",
	"Quase Shakespeare",
	"Rascunho Infinito",
	"Obra Sem Título",
	"O Primeiro Capítulo",
]


## O texto que pode virar nome. Devolve vazio quando nao sobra nada -- e vazio e um estado
## legitimo: o cartao de um Manuscrito sem nome se apresenta pelo numero do slot.
static func limpar(texto: String) -> String:
	var limpo := ""
	for caractere in texto:
		# caractere de controle nao e letra: ele quebra a linha do cartao em vez de aparecer
		if caractere.unicode_at(0) < 32:
			continue
		limpo += caractere
	limpo = limpo.strip_edges()
	if limpo.length() > LIMITE:
		limpo = limpo.substr(0, LIMITE).strip_edges()
	return limpo


## Se o texto cabe como esta, sem o jogo ter que cortar nada. E o que a tela usa para
## RECUSAR em vez de aceitar em silencio: nome cortado calado e o jogador achando que
## escreveu uma coisa e lendo outra no cartao.
static func cabe(texto: String) -> bool:
	return limpar(texto) == texto.strip_edges() and not texto.strip_edges().is_empty()


## Uma sugestao para este slot, JA TRADUZIDA, evitando as que ja estao em uso nos outros.
##
## ⚠️ DEVOLVE O TEXTO E NAO A CHAVE, e isso e decisao. O nome vira dado do jogador no
## instante em que ele aperta CRIAR: escolher "Hamlet Talvez" e trocar o jogo para ingles
## depois nao pode renomear o Manuscrito dele sozinho. Quem le o CSV e este momento, uma
## vez -- dali em diante e texto que a pessoa escreveu.
##
## Deterministica de proposito: com sorteio, duas capturas do mesmo commit dariam imagens
## diferentes e o diff da galeria versionada deixaria de valer. O slot desloca o inicio da
## busca para os tres cartoes nao proporem todos o mesmo nome.
static func sugerir(slot: int, em_uso: PackedStringArray) -> String:
	var quantas := SUGESTOES.size()
	for passo in quantas:
		var candidata := _traduzir(SUGESTOES[(maxi(slot, 1) - 1 + passo) % quantas])
		if not em_uso.has(candidata):
			return candidata
	# todas em uso: o jogador renomeou tudo com os proprios nomes do jogo, e ai o slot
	# desempata. Devolver vazio aqui deixaria o campo em branco sem motivo aparente.
	return _traduzir(SUGESTOES[(maxi(slot, 1) - 1) % quantas])


## Equivale ao tr() das cenas -- classe estatica nao tem self. O nome e contrato com o
## portao de texto: ver o aviso em src/nucleo/relogio.gd.
static func _traduzir(chave: String) -> String:
	return String(TranslationServer.translate(chave))
