#!/usr/bin/env bash
#
# As capturas do CI: 1080p e duas escalas de interface, em `capturas/`.
#
# ⚠️ CAPTURA PRECISA DE JANELA. Headless não renderiza -- `DisplayServer.get_name()`
# devolve "headless" e a imagem sairia vazia. No CI isso é `xvfb-run`, e se ele não
# estiver disponível este script FALHA em vez de pular: captura pulada em silêncio é a
# galeria envelhecendo sem ninguém saber.
#
# ⚠️ E CADA CAPTURA É CONFERIDA. O `capturar.tscn` imprime "capturou" quando dá certo;
# sem essa conferência, um cenário que parasse de funcionar deixaria o artefato menor e o
# job verde -- e "faltou uma foto" é exatamente o tipo de coisa que ninguém nota.
set -euo pipefail

if ! command -v xvfb-run >/dev/null 2>&1; then
	echo "::error::xvfb-run não está disponível; captura precisa de janela" >&2
	exit 1
fi

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
destino="$raiz/capturas"
mkdir -p "$destino"

quantas=0

# roda uma captura e exige que ela tenha dito "capturou"
capturar() {
	local descricao="$1"
	shift
	echo "── $descricao"
	local saida
	saida="$(xvfb-run -a godot --path "$raiz" tools/capturar.tscn "$@" 2>&1)" || true
	printf '%s\n' "$saida"
	if ! printf '%s' "$saida" | grep -q "capturou"; then
		echo "::error::a captura \"$descricao\" não produziu imagem" >&2
		exit 1
	fi
	quantas=$((quantas + 1))
}

# ── 1080p, os cenários que contam a campanha ────────────────────────────────────────────
# ⚠️ `descobertas_fim` NAO E REDUNDANTE com `descobertas`. A primeira foto mostra a
# primeira faixa; o que a issue #55 precisa provar mora no FIM da rolagem -- faixas vazias
# e a paradoxal escondendo o proprio total com `0/?`.
#
# ⚠️ `banner` E O UNICO JEITO DE O CI VER A FAIXA DO TOPO. Ela so existe por alguns segundos
# durante o jogo, entao ela nao aparece em nenhuma outra captura -- e o que ela pode quebrar
# (nao caber, nao contrastar, nao quebrar linha) so se ve numa foto parada.
for cenario in menu_cheio arquivos_cheio principal banner panorama descobertas descobertas_fim estatisticas; do
	capturar "$cenario em 1080p" --resolution 1920x1080 -- "cenario=$cenario"
done

# ── e em inglês, que é o único jeito de ver texto estourando botão ──────────────────────
# caractere não é pixel: "CONFIGURAÇÕES" e "SETTINGS" não ocupam a mesma largura
for cenario in menu_cheio arquivos_cheio banner descobertas descobertas_fim; do
	capturar "$cenario em inglês" --resolution 1920x1080 -- "cenario=$cenario" "idioma=en"
done

# ── AS DUAS ESCALAS DE INTERFACE ────────────────────────────────────────────────────────
# ⚠️ Escala acima de 100% na menor resolução é o caso que estoura tudo (issue #43). Ela
# entra pelo Config, que é a porta do jogador.
capturar "partida a 100% em 1280x720" -- cenario=principal largura=1280 altura=720 escala=1.0
capturar "partida a 125% em 1280x720" -- cenario=principal largura=1280 altura=720 escala=1.25

# ── recolher o que saiu em user:// ──────────────────────────────────────────────────────
# o caminho de user:// no Linux é ~/.local/share/godot/app_userdata/<nome do projeto>/
origem=""
for candidato in "$HOME"/.local/share/godot/app_userdata/*/capturas; do
	if [ -d "$candidato" ]; then
		origem="$candidato"
	fi
done

if [ -z "$origem" ]; then
	echo "::error::não achei a pasta de capturas em user://" >&2
	exit 1
fi

cp "$origem"/*.png "$destino"/
achadas="$(find "$destino" -name '*.png' | wc -l)"

echo "──────── $quantas capturas pedidas, $achadas imagens em capturas/ ────────"

# ⚠️ portão com zero verificações tem que REPROVAR: uma pasta vazia não é aprovação
if [ "$achadas" -lt "$quantas" ]; then
	echo "::error::saíram $achadas imagens para $quantas capturas pedidas" >&2
	exit 1
fi
