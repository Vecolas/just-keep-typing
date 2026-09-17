## Escreve um instante do relogio do sistema para o jogador ler: "Hoje as 14:32",
## "Ontem as 09:05", "28/08/2026".
##
## Existe porque o menu precisa dizer de onde o jogador esta voltando (issue #39) e a tela
## de Arquivos precisa datar cada Manuscrito (issue #40). Duas copias da mesma conta
## divergiriam na primeira vez que alguem mexesse numa delas -- e a divergencia apareceria
## como duas datas diferentes para o MESMO save, em duas telas do mesmo jogo.
##
## Logica pura, so metodos estaticos, sem estado. Mora em src/nucleo/ pelo mesmo motivo do
## Formatador: e testavel headless, sem cena nenhuma.
##
## ⚠️ HOJE E UM DIA DO CALENDARIO, E NAO "HA MENOS DE VINTE E QUATRO HORAS". Gravar as
## 23h50 e abrir o jogo as 00h10 e ONTEM, e nao hoje -- e a conta por diferenca de segundos
## diria hoje, calada. Quem joga todo dia le essa linha todo dia.
##
## ⚠️ E O CALENDARIO E O LOCAL, nao o UTC. Time.get_datetime_dict_from_unix_time devolve
## UTC; sem somar o fuso, metade do planeta ve a virada do dia na hora errada -- e no lado
## de ca ela cairia as 21h.
##
## A convencao de escrita -- ordem dos campos da data e relogio de 12 h -- vem da TABELA
## de idiomas do Config, nunca de um `if` por lingua. Idioma novo e uma linha la, e
## nenhuma linha daqui muda. Ver CONVENCOES.md, "Idioma traz as convencoes junto".
##
## Nao escuta EventBus.idioma_mudou de proposito: e sem estado e nao tem rotulo para
## repintar. Quem monta texto e guarda na tela e que precisa escutar.
class_name Relogio
extends RefCounted

const SEGUNDOS_POR_MINUTO: int = 60
const SEGUNDOS_POR_DIA: int = 86_400

## Marca de formato, nao texto: "14:32" e igual em toda lingua que use relogio de 24 h.
const MOLDE_24H := "%02d:%02d"

## O texto de um instante, relativo a AGORA. E o que o menu e os Arquivos mostram.
##
## `agora` entra por parametro e nao e lido aqui dentro para a suite poder afirmar a
## virada do dia sem esperar a meia-noite.
static func quando(instante: float, agora: float) -> String:
	if instante <= 0.0:
		return _traduzir("nunca")
	var dias := dias_entre(instante, agora)
	if dias == 0:
		return _traduzir("Hoje às %s") % hora(instante)
	if dias == 1:
		return _traduzir("Ontem às %s") % hora(instante)
	return data(instante)


## Quantos dias de CALENDARIO separam os dois instantes. Zero e o mesmo dia; um e ontem.
## Negativo nao existe: relogio do sistema atrasado depois de uma gravacao devolveria
## "amanha", e amanha nao e coisa que um save possa ser.
static func dias_entre(instante: float, agora: float) -> int:
	var de := _dia_local(instante)
	var ate := _dia_local(agora)
	return maxi(ate - de, 0)


## A data escrita por extenso, na ordem que o idioma pede. Os separadores sao barra em
## todo idioma que o jogo fala; quando um deles pedir outro, ele vira campo da tabela.
static func data(instante: float) -> String:
	var local := Time.get_datetime_dict_from_unix_time(int(_local(instante)))
	if bool(_convencao().get("data_dia_primeiro", true)):
		return "%02d/%02d/%04d" % [local["day"], local["month"], local["year"]]
	return "%02d/%02d/%04d" % [local["month"], local["day"], local["year"]]


## A hora, de 24 h ou de 12 h conforme o idioma. O "AM"/"PM" e marca de formato e nao
## texto: ele nao existe na outra lingua, e quem o usa escreve igual em qualquer pais.
static func hora(instante: float) -> String:
	var local := Time.get_datetime_dict_from_unix_time(int(_local(instante)))
	var h := int(local["hour"])
	var m := int(local["minute"])
	if not bool(_convencao().get("relogio_12h", false)):
		return MOLDE_24H % [h, m]
	var sufixo := "AM" if h < 12 else "PM"
	var doze := h % 12
	if doze == 0:
		doze = 12
	return "%d:%02d %s" % [doze, m, sufixo]


## Quantos dias inteiros desde a Epoca, no fuso de quem esta jogando.
static func _dia_local(instante: float) -> int:
	return floori(_local(instante) / float(SEGUNDOS_POR_DIA))


## O mesmo instante, deslocado para o fuso do sistema. O bias vem em MINUTOS e ja e
## assinado -- somar e o certo, e a primeira versao que subtraiu errou o dia por duas
## horas em toda a America.
static func _local(instante: float) -> float:
	var fuso := Time.get_time_zone_from_system()
	return instante + float(int(fuso.get("bias", 0))) * float(SEGUNDOS_POR_MINUTO)


## A tabela do idioma em uso. Pergunta ao Config, que e quem sabe qual lingua esta ligada.
static func _convencao() -> Dictionary:
	return Config.convencoes()


## Equivale ao tr() das cenas. Classe estatica nao tem self, entao chama o servidor direto
## -- e a mesma busca que o tr() faz por baixo. A traducao vem ANTES do %s: traduz-se o
## molde, nunca o resultado (CONVENCOES.md, regra 2 de idioma).
##
## ⚠️ O NOME E CONTRATO COM O PORTAO DE TEXTO. O teste_texto varre os literais que vem
## depois das duas chamadas de traducao que o projeto usa, e esta e uma delas; literal
## traduzido por um terceiro nome sai da conta do portao e some do CSV sem ninguem ver --
## que e a falha exata que aquele portao existe para pegar.
##
## E o portao e uma VARREDURA e nao um parser: comentario que cite a chamada com o
## parentese e as aspas vira um literal inventado na conta dele. Ele reprovou este arquivo
## uma vez, por este motivo, o que e a prova barata de que ele morde.
static func _traduzir(molde: String) -> String:
	return String(TranslationServer.translate(molde))
