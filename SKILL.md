---
name: defi-the-odds
description: "Fetch enriched BTC and crypto market data from the DefiTheOdds API and generate structured market predictions. Use when the user asks for a BTC market prediction, market regime analysis, volatility forecast, expansion probability, directional bias, or trade outlook based on ML-derived indicators. Covers: (1) Fetching hourly or daily candle data with 40+ technical indicators and ML-enriched fields (market_regime_score, future_vol, expansion_probability), (2) Analyzing regime, volatility, and expansion signals for medium-term predictions, (3) Producing a formatted trade assistant report including directional bias, reasoning, and expected move targets. Triggers on: 'market prediction', 'BTC outlook', 'regime score', 'expansion probability', 'volatility forecast', 'defi the odds', 'DFO data', 'trade signal', 'candle pattern'."
version: 1.1.0
metadata: {"openclaw": {"emoji": "🔮", "requires": {"env": ["DFO_API_KEY"], "bins": ["curl", "jq"]}, "primaryEnv": "DFO_API_KEY", "homepage": "https://defitheodds.xyz"}}
---

# DefiTheOdds — ML-Enriched Crypto Market Intelligence

Use the DefiTheOdds API to fetch BTC candle data enriched with 40+ technical indicators, ML-driven Market Regime scores, and candle pattern recognition. Produce structured market predictions.

## API Basics

- **Base URL:** `https://api.defitheodds.xyz/v1`
- **Auth Header:** `X-API-KEY: $DFO_API_KEY`
- **Hourly candles:** `GET /v1/hourly/{ticker}/{candles}`
- **Daily candles:** `GET /v1/daily/{ticker}/{candles}`
- `{ticker}` = e.g. `BTC-USD`, `ETH-USD`
- `{candles}` = number of candles to retrieve (e.g. `240` for ~10 days hourly)

**Response structure:**

```json
{
  "message": "Data retrieved successfully.",
  "data": [ { ...candle objects... } ]
}
```

All candle data lives inside the `.data` array — **always use `.data` in jq queries**.

## Fetch Data

```bash
curl -s -H "X-API-KEY: $DFO_API_KEY" \
  "https://api.defitheodds.xyz/v1/hourly/BTC-USD/240" | jq '.data'
```

To fetch fewer candles (e.g. last 24 hours):

```bash
curl -s -H "X-API-KEY: $DFO_API_KEY" \
  "https://api.defitheodds.xyz/v1/hourly/BTC-USD/24" | jq '.data'
```

If the request fails, check:
1. `DFO_API_KEY` is set (`echo $DFO_API_KEY`) and starts with `dfo_`
2. The endpoint includes the candle count: `/hourly/BTC-USD/240` not `/hourly/BTC-USD`
3. The header is `X-API-KEY` (uppercase)
4. Network egress is allowed

## Key Fields

Each candle object in `.data` contains standard OHLCV plus enriched fields.

### Core ML-Derived Fields

| Field | Type | Description |
|---|---|---|
| `market_regime_score` | number (0–100) | HMM ensemble score. Bearish (<30), Neutral (40–65), Bullish (>75). |
| `future_vol` | number (%) | ML-predicted forward-looking daily volatility. |
| `expansion_probability` | number (0–1) | ML probability of an imminent significant price expansion. |

### Standard + Enriched Fields

| Field | Type | Description |
|---|---|---|
| `ticker` | string | Asset pair, e.g. `"BTC-USD"` |
| `datetime` | string (ISO 8601) | Candle timestamp, e.g. `"2025-12-05T12:00:00"` |
| `open` | number | Opening price |
| `high` | number | High price |
| `low` | number | Low price |
| `close` | number | Closing price |
| `volume` | number | Volume traded |
| `sma_50` | number | 50-period Simple Moving Average |
| `ema_20` | number | 20-period Exponential Moving Average |
| `rsi_14` | number (0–100) | 14-period RSI |
| `macd_line` | number | MACD line |
| `macd_hist` | number | MACD histogram (positive = bullish momentum) |
| `candle` | string or null | Detected candle pattern, e.g. `"Engulfing_Bearish"`, `"Doji"`, or `null` |

The API returns 40+ indicators — the above are the most commonly used. Additional fields appear in the response depending on the data available.

## Analysis Workflow

When the user asks for a market prediction, follow these steps:

### Step 1 — Fetch the latest candles

```bash
DATA=$(curl -s -H "X-API-KEY: $DFO_API_KEY" "https://api.defitheodds.xyz/v1/hourly/BTC-USD/240")
echo "$DATA" | jq '.data[-5:]'
```

Pull the **most recent 5 candles** for the prediction summary. Use up to 240 candles for trend context.

### Step 2 — Extract the latest values

```bash
echo "$DATA" | jq '.data[-1] | {
  datetime,
  close,
  market_regime_score,
  future_vol,
  expansion_probability,
  rsi_14,
  macd_hist,
  macd_line,
  sma_50,
  ema_20,
  candle,
  volume
}'
```

### Step 3 — Determine regime and bias

Apply this decision framework to the **most recent** candle values:

**Regime Classification (from API docs):**
- `market_regime_score` > 75 → **Bullish** regime
- `market_regime_score` 40–65 → **Neutral** / transitional
- `market_regime_score` < 30 → **Bearish** regime
- 30–40 and 65–75 are transition zones — lean toward the nearest defined zone

**Expansion Signal Strength:**
- `expansion_probability` > 0.80 → Extremely high — significant move imminent
- `expansion_probability` 0.60–0.80 → Elevated — move likely within days
- `expansion_probability` 0.40–0.60 → Moderate — consolidation may continue
- `expansion_probability` < 0.40 → Low — range-bound expected

**Volatility Assessment:**
- `future_vol` > 4% → High volatility expected
- `future_vol` 2–4% → Moderate volatility
- `future_vol` < 2% → Low / compressed volatility

### Step 4 — Compute price range context

```bash
echo "$DATA" | jq '{
  recent_low:  [.data[-48:][].low]  | min,
  recent_high: [.data[-48:][].high] | max,
  current:     .data[-1].close,
  range_pct:   (([.data[-48:][].high] | max) - ([.data[-48:][].low] | min)) / .data[-1].close * 100
}'
```

### Step 5 — Build the prediction report

Produce the report in **exactly** this format:

---

**Medium-term (Next 5–10 days):**

**[Headline: e.g. "High-Volatility Breakout Imminent" or "Consolidation Expected"]**

**Critical Signal:** Expansion Probability at [X]% — [interpret the signal strength and what it implies for upcoming price action].

**Directional Bias:**

**[e.g. "Bullish Breakout Likely" / "Bearish Breakdown Risk" / "Neutral — No Clear Edge"]**

**Reasoning:**

1. **Regime Score ([value]):** [Interpret — bullish (>75) / neutral (40–65) / bearish (<30) and what it means]
2. **Expansion Probability ([value]%):** [Interpret — how primed the market is for a move]
3. **Technical Setup:**
   - Price consolidating in [range derived from recent highs/lows]
   - RSI at [rsi_14 value] ([interpret — overbought/neutral/oversold, room to run?])
   - MACD histogram [macd_hist value] — [positive = bullish momentum / negative = bearish momentum]
   - [Candle pattern if `candle` field is not null, e.g. "Engulfing_Bearish detected — reversal signal"]

**Expected Move:**

- **Volatility-based target:** ±[future_vol]% daily = ~±$[dollar amount] daily range
- **Expansion target:** Based on [expansion_probability]% probability, expect [estimated % move] move in coming days
- **Direction bias:** [Upside/Downside/Neutral] (regime score [value], MACD [positive/negative])

---

### Important Guidelines

- **Always fetch live data** — never fabricate or assume values. If the API call fails, tell the user and show the HTTP response.
- **Be precise** with numbers — report exact values from the `.data` array in the API response.
- **Candle patterns:** If the `candle` field is not null, always mention the detected pattern in the Technical Setup section.
- **Disclaimer:** End every prediction with: *"This analysis is based on ML-derived signals from DefiTheOdds and does not constitute financial advice. Always manage risk and do your own research."*
- When the user provides their own API key inline, use it for that request only.
- If the user asks for a different asset (e.g. ETH), swap `BTC-USD` for the requested ticker.
- Default candle count: use `240` for hourly (≈10 days), `30` for daily (≈1 month).

## Quick Reference

See `{baseDir}/references/api-fields.md` for the full field reference and interpretation guide.
See `{baseDir}/scripts/fetch_dfo.sh` for a standalone fetch + summary script.
