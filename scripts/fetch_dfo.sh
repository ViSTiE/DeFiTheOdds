#!/usr/bin/env bash
# fetch_dfo.sh — Fetch DefiTheOdds candle data and print a quick summary.
# Usage: DFO_API_KEY=dfo_xxx ./fetch_dfo.sh [PAIR] [TIMEFRAME] [CANDLES]
#   PAIR       e.g. BTC-USD (default), ETH-USD
#   TIMEFRAME  hourly (default) or daily
#   CANDLES    number of candles to fetch (default: 240 for hourly, 30 for daily)

set -euo pipefail

PAIR="${1:-BTC-USD}"
TF="${2:-hourly}"

if [[ "$TF" == "daily" ]]; then
  CANDLES="${3:-30}"
else
  CANDLES="${3:-240}"
fi

BASE_URL="https://api.defitheodds.xyz/v1/${TF}/${PAIR}/${CANDLES}"

if [[ -z "${DFO_API_KEY:-}" ]]; then
  echo "ERROR: DFO_API_KEY is not set." >&2
  echo "Usage: DFO_API_KEY=dfo_xxx $0 [PAIR] [TIMEFRAME] [CANDLES]" >&2
  exit 1
fi

echo "Fetching ${CANDLES} ${TF} candles for ${PAIR}..."
echo "URL: ${BASE_URL}"
echo ""

RESPONSE=$(curl -sf -H "X-API-KEY: ${DFO_API_KEY}" "${BASE_URL}" 2>&1) || {
  echo "ERROR: API request failed." >&2
  echo "Response: ${RESPONSE}" >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Check DFO_API_KEY starts with dfo_" >&2
  echo "  2. Endpoint needs /{ticker}/{candles} — e.g. /hourly/BTC-USD/240" >&2
  echo "  3. Header must be X-API-KEY (uppercase)" >&2
  exit 1
}

MSG=$(echo "$RESPONSE" | jq -r '.message // "unknown"')
TOTAL=$(echo "$RESPONSE" | jq '.data | length')
echo "Status: ${MSG}"
echo "Received: ${TOTAL} candles"
echo ""

# Latest candle summary
echo "=== Latest Candle ==="
echo "$RESPONSE" | jq -r '.data[-1] | "Datetime:             \(.datetime)
Ticker:               \(.ticker)
Close:                $\(.close)
Market Regime Score:  \(.market_regime_score)
Future Vol:           \(.future_vol // "n/a")%
Expansion Prob:       \(.expansion_probability // "n/a")
RSI (14):             \(.rsi_14)
MACD Histogram:       \(.macd_hist)
MACD Line:            \(.macd_line)
SMA 50:               \(.sma_50)
EMA 20:               \(.ema_20)
Candle Pattern:       \(.candle // "none")
Volume:               \(.volume)"'

echo ""
echo "=== Recent 5 Candles (key fields) ==="
echo "$RESPONSE" | jq -r '
  .data[-5:] | .[] |
  "\(.datetime) | Close: $\(.close) | Regime: \(.market_regime_score) | ExpProb: \(.expansion_probability // "n/a") | FutVol: \(.future_vol // "n/a")% | Pattern: \(.candle // "none")"
'

echo ""
echo "=== Regime Trend (last 10 candles) ==="
echo "$RESPONSE" | jq -r '
  .data[-10:] | [.[].market_regime_score] |
  "Scores: \(map(tostring) | join(", "))
Min:    \(min)
Max:    \(max)
Avg:    \((add / length) * 100 | floor / 100)"
'

echo ""
echo "=== Price Range (last 48 candles) ==="
echo "$RESPONSE" | jq -r '
  .data[-48:] |
  "Low:     $\([.[].low] | min)
High:    $\([.[].high] | max)
Current: $\(.[-1].close)
Range:   \(( ([.[].high] | max) - ([.[].low] | min) ) / .[-1].close * 100 * 100 | floor / 100)%"
'
