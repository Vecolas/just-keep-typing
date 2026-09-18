## Barramento de sinais do jogo. Quem faz algo emite aqui; quem se importa conecta.
##
## Existe para que nenhum script precise saber ONDE outro no mora na arvore:
## get_node("../../Player") quebra assim que alguem reorganiza uma cena, e cena
## reorganizada e coisa que acontece toda semana. A unica excecao aceita a esta
## regra e procurar por grupo. Ver CONVENCOES.md, secao Arquitetura.
##
## Sinal novo entra aqui com tipo declarado nos argumentos e nome no passado
## (algo aconteceu), nunca no imperativo (faca algo) -- imperativo e chamada de
## metodo disfarcada de sinal, e reintroduz o acoplamento que este arquivo evita.
extends Node

## Emitido quando a lingua muda. Toda tela que MONTA texto em codigo (com %,
## formatador de numero ou catalogo em constante) tem que escutar: o Godot
## retraduz sozinho apenas o text que veio da cena.
signal idioma_mudou(codigo: String)

## O jogador trocou de slot de save: a partida na memoria agora e outra.
signal slot_mudou(numero: int)

## A tela de opcoes foi pedida.
signal opcoes_pedidas

## A tela de creditos foi pedida (issue #39).
signal creditos_pedidos

## Alguma opcao de INTERFACE ou ACESSIBILIDADE mudou (issue #43): escala do texto, alto
## contraste, formato de numero, particulas, reduzir movimento ou reduzir flashes.
##
## ⚠️ Toda tela que escuta idioma_mudou tem que escutar este tambem, e o portao de texto
## exige os dois. Sao dois sinais e nao um porque emitir "a lingua mudou" quando a lingua
## nao mudou e uma afirmacao falsa dentro do barramento -- e o barramento e o unico lugar
## do projeto onde todo mundo acredita no que le.
signal interface_mudou

## Emitido depois que a compra ja aconteceu -- o dinheiro saiu e o id ja esta em
## Jogo.upgrades_comprados. Quem escuta repinta; ninguem precisa perguntar de volta se
## deu certo.
signal upgrade_comprado(id: String)

## Emitido depois da compra, com quantos macacos entraram de verdade -- que pode ser menos
## do que o botao pediu, se o saldo nao cobriu o lote inteiro.
signal macacos_comprados(quantos: int)

## Emitido depois de a partida ser gravada em disco com sucesso.
signal jogo_gravado()

## Emitido depois de um save ja ter sido aplicado no Jogo. Quem escuta pode ler o estado
## novo direto, sem receber nada por argumento.
signal jogo_carregado()

## Emitido na abertura, depois de a producao offline ja ter sido creditada. Vem com o
## quanto e com quantos segundos contaram de fato -- que pode ser menos do que o jogador
## ficou fora, por causa do teto.
signal voltou_do_offline(produzido: Grande, segundos: float)

## Emitido quando o total cruza o requisito de um marco, depois de o id ja estar em
## Jogo.marcos_alcancados. Marco nao da bonus: quem escuta mostra, nao concede nada.
signal marco_alcancado(marco: DadosMarco)

## Pedido de abrir o Panorama. Imperativo seria chamada de metodo disfarcada de sinal --
## este e no passado porque o que aconteceu foi o jogador PEDIR, e quem decide o que fazer
## com o pedido e a tela.
signal panorama_pedido()

## Emitido depois de a maquina ja ter sido trocada, com o id do tier novo.
signal maquina_trocada(id: String)

## Emitido depois de a sala ja ter sido trocada, com o id da nova.
signal sala_expandida(id: String)

## Emitido quando uma descoberta sai, depois de o id ja estar em Jogo.descobertas.
## Diferente do marco, esta traz bonus junto -- quem escuta mostra, e o bonus ja vale.
signal descoberta_encontrada(descoberta: DadosDescoberta)

## Pedido de abrir a tela de Descobertas.
signal descobertas_pedidas()

## Pedido de abrir a tela de Estatisticas.
signal estatisticas_pedidas()

## Emitido depois de o Teorema ja ter sido provado, com quantos pontos foram ganhos.
## A run ja esta reiniciada quando isto chega.
signal teorema_provado(pontos: Grande)

## Emitido depois de um no da Arvore de Teoremas subir de nivel.
signal teorema_comprado(id: String)

## Emitido depois de o Universo ja ter sido reescrito, com quantos Fragmentos foram
## ganhos (GDD §20). A partida ja esta reiniciada quando isto chega.
signal universo_reescrito(fragmentos: Grande)

## Pedido de abrir a tela de Teoremas.
signal teoremas_pedidos()

## Emitido quando a producao cruza para a era visual seguinte (GDD §6). A era nao muda
## conta nenhuma -- quem escuta so desenha.
signal era_mudou(era: DadosEra)

## Emitido quando um evento aleatorio comeca (GDD §22).
signal evento_comecou(evento: DadosEvento)

## Emitido quando um evento termina, por tempo ou porque o jogador resolveu.
signal evento_terminou(id: String)

## Emitido quando uma automacao e comprada (GDD §16).
signal automacao_comprada(id: String)

## Emitido quando o jogador liga ou desliga uma automacao. Ela e sempre desligavel.
signal automacao_alternada(id: String, ligada: bool)
