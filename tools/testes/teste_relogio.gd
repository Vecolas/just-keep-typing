## Suite do Relogio (issue #39): "Hoje as 14:32", "Ontem as 09:05", "28/08/2026".
##
## A afirmacao que vale por todas as outras e a VIRADA DO DIA. Gravar as 23h50 e abrir o
## jogo as 00h10 e ontem, e a conta obvia -- diferenca de segundos menor que vinte e quatro
## horas -- diria "Hoje", calada. Quem joga todo dia le essa linha todo dia, e ela estaria
## errada exatamente nas sessoes que atravessam a meia-noite.
##
## Os instantes sao montados a partir da MEIA-NOITE LOCAL de hoje, e nao de um timestamp
## cravado: numero fixo torna a suite verde so no fuso de quem a escreveu.
##
## A convencao de escrita vem da tabela do Config, e a suite troca o idioma DE VERDADE para
## provar isso -- se um dia alguem puser um `if idioma == "en"` dentro do Relogio, esta
## suite continua verde e o portao perde o sentido. Por isso ela tambem afirma que as duas
## linguas produzem saidas DIFERENTES: teste que so confere o portugues nao percebe uma
## tabela que parou de ser lida.
extends TesteBase

const CAMINHO_DE_TESTE := "user://teste_relogio_opcoes.json"

const HORA_TARDE := 23
const MINUTO_TARDE := 50
const HORA_CEDO := 0
const MINUTO_CEDO := 10


func _init() -> void:
	nome = "relogio"


func executar() -> void:
	# ⚠️ O LOCALE VOLTA NO FIM, e nao so o campo do Config. Esta suite troca de idioma DE
	# VERDADE (e o unico jeito de provar que a tabela manda), e escolher("idioma") aplica
	# no TranslationServer. Sem devolver o locale que o runner fixou, todas as suites
	# DEPOIS desta rodariam na lingua de quem desenvolve -- e as afirmacoes de texto delas
	# quebrariam sem nada ter mudado no codigo.
	var locale_original := TranslationServer.get_locale()
	var caminho_original := Config.caminho
	var idioma_original := Config.indice_de("idioma")
	Config.caminho = CAMINHO_DE_TESTE
	Config.escolher("idioma", 0)

	_a_virada_do_dia()
	_nunca_e_futuro()
	_a_tabela_do_idioma_manda()

	Config.escolher("idioma", idioma_original)
	if FileAccess.file_exists(CAMINHO_DE_TESTE):
		DirAccess.remove_absolute(CAMINHO_DE_TESTE)
	Config.caminho = caminho_original
	Config.carregar()
	TranslationServer.set_locale(locale_original)


## ⚠️ O PORTAO. Vinte minutos separam os dois instantes, e eles estao em dias diferentes.
## A versao por diferenca de segundos chamaria os dois de "hoje".
func _a_virada_do_dia() -> void:
	var ontem_a_noite := _instante(-1, HORA_TARDE, MINUTO_TARDE)
	var hoje_de_madrugada := _instante(0, HORA_CEDO, MINUTO_CEDO)
	igual(
		Relogio.dias_entre(ontem_a_noite, hoje_de_madrugada), 1,
		"23h50 e 00h10 do dia seguinte sao vinte minutos e UM dia de calendario",
	)
	igual(
		Relogio.quando(ontem_a_noite, hoje_de_madrugada),
		tr("Ontem às %s") % Relogio.hora(ontem_a_noite),
		"e o texto disso e Ontem, e nao Hoje",
	)

	# e o controle: sem ele a afirmacao acima passaria com um Relogio que dissesse SEMPRE
	# "ontem" -- regua que reprova tudo esta medindo a si mesma
	var manha := _instante(0, 8, 0)
	var noite := _instante(0, 22, 0)
	igual(Relogio.dias_entre(manha, noite), 0, "catorze horas DENTRO do mesmo dia sao zero")
	igual(
		Relogio.quando(manha, noite), tr("Hoje às %s") % Relogio.hora(manha),
		"e o texto disso e Hoje",
	)

	# tres dias atras nao e nem hoje nem ontem: e data
	var antes := _instante(-3, 12, 0)
	igual(Relogio.dias_entre(antes, manha), 3, "tres dias atras sao tres dias")
	igual(
		Relogio.quando(antes, manha), Relogio.data(antes),
		"e o que se mostra e a data, sem hora",
	)


## Save nunca gravado e "nunca", e nao 01/01/1970 -- data da Epoca no menu parece defeito
## do jogo, porque e. E relogio do sistema atrasado depois de uma gravacao nao pode
## devolver "amanha": amanha nao e coisa que um Manuscrito possa ser.
func _nunca_e_futuro() -> void:
	igual(Relogio.quando(0.0, _instante(0, 12, 0)), tr("nunca"), "instante zero e nunca")
	igual(
		Relogio.dias_entre(_instante(1, 12, 0), _instante(0, 12, 0)), 0,
		"instante no futuro nao devolve dia negativo",
	)


## A mesma informacao escrita pelas duas convencoes. O que se prova aqui nao e o texto de
## uma lingua: e que TROCAR a lingua troca a escrita -- que e o unico jeito de perceber
## que a tabela parou de ser consultada.
func _a_tabela_do_idioma_manda() -> void:
	var tarde := _instante(0, 15, 30)
	var dia := _instante(0, 3, 0)

	Config.escolher("idioma", 0)
	var hora_pt := Relogio.hora(tarde)
	var data_pt := Relogio.data(dia)
	igual(hora_pt, "15:30", "em pt_BR o relogio e de 24 h")

	Config.escolher("idioma", 1)
	var hora_en := Relogio.hora(tarde)
	var data_en := Relogio.data(dia)
	igual(hora_en, "3:30 PM", "em en o relogio e de 12 h")

	ok(data_pt != data_en, "e a ordem da data muda junto: %s contra %s" % [data_pt, data_en])
	igual(
		data_pt.split("/")[0], data_en.split("/")[1],
		"o dia em pt_BR e o mesmo campo que em en aparece no meio",
	)

	# meio-dia e meia-noite sao onde o relogio de 12 h erra: 12h vira "0 PM" e 0h vira
	# "0 AM" em toda implementacao que esquece o resto doze
	igual(Relogio.hora(_instante(0, 12, 0)), "12:00 PM", "meio-dia em 12 h e 12 PM")
	igual(Relogio.hora(_instante(0, 0, 0)), "12:00 AM", "meia-noite em 12 h e 12 AM")

	Config.escolher("idioma", 0)


## Um instante de HOJE, deslocado por dias, montado a partir da meia-noite LOCAL. Assim a
## suite vale em qualquer fuso -- inclusive no do servidor de integracao, que costuma ser
## UTC e nao e o de ninguem.
func _instante(dias: int, hora: int, minuto: int) -> float:
	var agora := Time.get_unix_time_from_system()
	var desvio := float(int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	var meia_noite := floorf((agora + desvio) / 86400.0) * 86400.0 - desvio
	return meia_noite + float(dias * 86400 + hora * 3600 + minuto * 60)
