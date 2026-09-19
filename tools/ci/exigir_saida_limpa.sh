#!/usr/bin/env bash
#
# Lê a saída de um portão pela entrada padrão e REPROVA se ela contiver erro que ninguém
# pediu.
#
#   comando 2>&1 | ./tools/ci/exigir_saida_limpa.sh "suíte unitária"
#
# ⚠️ POR QUE ELE EXISTE. A suíte imprimiu isto, e continuou imprimindo `PASSOU`:
#
#     ERROR: Node not found: "%EspacoFuturos" (relative to ".../HUD").
#     SCRIPT ERROR: Invalid assignment of property 'visible' on a base object of type 'null'.
#     ...
#     PASSOU (6800 afirmacoes em 27 suites)
#
# A HUD lançava erro a cada montagem e nenhuma afirmação olhava aquilo — as suítes afirmam
# **lógica**, e o que quebrou foi **montagem**. É o falso verde uma camada acima do
# `exit 0`: o resumo verde de uma suíte vale tão pouco quanto o código de saída, se ninguém
# olhar o que ela cuspiu pelo caminho.
#
# E ele já se pagou duas vezes no mesmo dia em que nasceu:
#
#   1. `teste_acessibilidade` lia `campo("escala_do_texto")["valores"]` — chave que aquele
#      campo não tem. O erro ABORTAVA a função na primeira linha, e as **dez** afirmações
#      seguintes, inclusive a de controle, nunca rodaram. A suíte imprimia `PASSOU` com a
#      contagem a menos, e ninguém compara contagem entre duas corridas.
#   2. `call_deferred("grab_focus")` em nó que já tinha saído da árvore — cinco vezes por
#      corrida, em três telas diferentes.
#
# ⚠️ E ELE NÃO REPROVA POR QUALQUER `ERROR:`, DE PROPÓSITO. `push_error` é como este projeto
# grita, e metade das suítes alimenta o código com entrada inválida **para vê-lo gritar**:
#
#     ERROR: Grande.dividido: divisao por zero          ← sob teste, é o comportamento certo
#     ERROR: Config: nao existe slot 4                  ← sob teste
#     ERROR: Parse JSON failed ... got 'isto'           ← save corrompido sob teste
#
# Reprovar nessas linhas seria um portão que morde o código certo — e portão que morde o
# código certo é portão que alguém desliga (CONVENCOES.md). A lista abaixo é de padrões que
# **ninguém pede**: nenhum deles tem versão legítima.
set -uo pipefail

if [ "$#" -lt 1 ]; then
	echo "uso: $0 <nome do portão>  (a saída vem pela entrada padrão)" >&2
	exit 2
fi

nome="$1"
saida="$(cat)"

# ⚠️ UM PADRÃO POR LINHA, COM O MOTIVO. Padrão sem motivo escrito é padrão que a próxima
# pessoa remove por não saber o que ele protegia.
declare -a FATAIS=(
	# erro de execução do GDScript: acesso inválido, chamada inexistente, tipo errado.
	# Nenhum é intencional -- push_error não passa por aqui, ele imprime "ERROR:".
	'SCRIPT ERROR:'
	# script que não compila. O jogo sobe assim mesmo, com o nó quebrado silenciosamente
	'Parse Error:'
	'Compile Error:'
	'Failed to load script'
	# caminho de nó que não existe: cena renomeada, `unique_name_in_owner` esquecido
	'Node not found:'
	# asserção da engine. Foi assim que `grab_focus` fora da árvore apareceu
	'ERROR: Condition "'
	# sinal ligado a método de aridade errada: só falha quando o sinal é emitido
	'Error calling from signal'
	# recurso que o import não gerou, e a cena sobe sem ele
	'Failed loading resource'
)

achados=""
for padrao in "${FATAIS[@]}"; do
	linhas="$(printf '%s\n' "$saida" | grep -F "$padrao" || true)"
	if [ -n "$linhas" ]; then
		achados="$achados$linhas"$'\n'
	fi
done

if [ -n "$achados" ]; then
	echo "::error::$nome imprimiu erro que ninguém pediu -- ver tools/ci/exigir_saida_limpa.sh"
	printf '%s' "$achados" | sed 's/^/    /' >&2
	exit 1
fi

echo "✓ $nome: saída limpa"
