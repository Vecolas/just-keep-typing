#!/usr/bin/env bash
#
# Roda um portão e EXIGE A PALAVRA `PASSOU` na saída dele.
#
#   ./tools/ci/exigir_passou.sh "suíte unitária" godot --headless --path . tools/testes/runner.tscn
#
# ⚠️ POR QUE NÃO BASTA O CÓDIGO DE SAÍDA. O Godot sai 0 em situações em que a suíte não
# chegou a rodar: cena principal que não carrega, autoload que não sobe, caminho errado no
# argumento. Um CI que confiasse em `exit 0` ficaria verde para sempre a partir do dia em
# que alguém renomeasse `runner.tscn` -- e ninguém procura defeito num job verde.
#
# É o falso verde uma camada acima do código. Ver CONVENCOES.md.
#
# As TRÊS metades importam:
#
#   sem `PASSOU`        -> reprova, mesmo com exit 0
#   com `FALHOU`        -> reprova, mesmo que `PASSOU` apareça em algum lugar da saída
#   com erro no stderr  -> reprova, mesmo com `PASSOU` e sem `FALHOU`
#
# ⚠️ A TERCEIRA É A MAIS NOVA, E NASCEU DE UM CASO REAL. A HUD lançava `Node not found` a
# cada montagem enquanto a suíte imprimia `PASSOU (6800 afirmacoes)`: as suítes afirmam
# **lógica**, e o que quebrou foi **montagem**. Quem decide o que é erro de verdade é
# `exigir_saida_limpa.sh`, que tem a lista e o motivo de cada padrão.
set -uo pipefail

if [ "$#" -lt 2 ]; then
	echo "uso: $0 <nome do portão> <comando...>" >&2
	exit 2
fi

nome="$1"
shift

echo "──────── $nome ────────"

# a saída inteira é guardada E impressa: guardada para ser conferida, impressa para quem
# lê o log do CI não precisar adivinhar o que aconteceu
saida="$("$@" 2>&1)"
codigo=$?
printf '%s\n' "$saida"

if printf '%s' "$saida" | grep -q "FALHOU"; then
	echo "::error::$nome imprimiu FALHOU"
	exit 1
fi

if ! printf '%s' "$saida" | grep -q "PASSOU"; then
	echo "::error::$nome não imprimiu PASSOU (código de saída: $codigo)"
	echo "::error::exit 0 não significa que o portão rodou -- ver tools/ci/exigir_passou.sh"
	exit 1
fi

# ⚠️ E A SAÍDA TEM QUE ESTAR LIMPA. `PASSOU` diz que as afirmações passaram; ele não diz
# nada sobre o que a engine cuspiu enquanto elas rodavam.
aqui="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! printf '%s' "$saida" | "$aqui/exigir_saida_limpa.sh" "$nome"; then
	exit 1
fi

echo "✓ $nome: PASSOU"
