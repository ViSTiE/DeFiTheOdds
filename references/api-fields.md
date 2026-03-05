# DefiTheOdds API — Field Reference & Interpretation Guide

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/v1/hourly/{ticker}/{candles}` | Hourly enriched candles |
| GET | `/v1/daily/{ticker}/{candles}` | Daily enriched candles |

**Parameters:**
- `{ticker}` — Asset pair, e.g. `BTC-USD`, `ETH-USD`
- `{candles}` — Number of candles to return (integer, e.g. `240`)

**Supported pairs (Free tier):** `BTC-USD`, `ETH-USD`
**Supported pairs (Pro tier):** Top 50 coins (e.g. `SOL-USD`, `DOGE-USD`)

## Authentication

Pass the API key as a header:

```
X-API-KEY: dfo_YOUR_KEY_HERE
```

Keys are prefixed with `dfo_`. Obtain one at https://defitheodds.xyz/register.

**Important:** The header name is `X-API-KEY` (uppercase). Using lowercase `x-api-key` may work but the spec defines uppercase.

## Response Format

The API returns a JSON object with a `message` field and a `data` array:

```json
{
  "message": "Data retrieved successfully.",
  "data": [
    {
      "ticker": "BTC-USD",
      "datetime": "2025-12-05T12:00:00",
      "open": 91381.80,
      "high": 91422.66,
      "low": 91155.39,
      "close": 91252.57,
      "volume": 3207249920,
      "sma_50": 92652.77,
      "ema_20": 92005.51,
      "rsi_14": 37.899,
      "macd_line": -325.09,
      "macd_hist": -96.53,
      "candle": "Engulfing_Bearish",
      "market_regime_score": 82.45,
      "future_vol": 3.02,
      "expansion_probability": 0.898
    }
  ]
}
```

**Critical:** Candle data is inside `.data` — always use `.data` in jq queries, not the root object.

## Field Descriptions

### Standard OHLCV

| Field | Type | Description |
|---|---|---|
| `ticker` | string | Asset pair identifier |
| `datetime` | string (ISO 8601) | Candle open time (no timezone, assume UTC) |
| `open` | number | Opening price (USD) |
| `high` | number | Highest price in period |
| `low` | number | Lowest price in period |
| `close` | number | Closing price (USD) |
| `volume` | number | Volume traded in period |

### Technical Indicators

| Field | Type | Description |
|---|---|---|
| `sma_50` | number | 50-period Simple Moving Average |
| `ema_20` | number | 20-period Exponential Moving Average |
| `rsi_14` | number (0–100) | 14-period Relative Strength Index |
| `macd_line` | number | MACD line (fast EMA − slow EMA) |
| `macd_hist` | number | MACD histogram (MACD line − signal). Positive = bullish momentum |
| `candle` | string / null | Detected candle pattern name or `null` if none detected |

**Note:** The API advertises 40+ indicators. Additional fields beyond those listed here may appear in the response. Process them if present, ignore gracefully if absent.

### ML-Derived Fields (Core Intelligence)

| Field | Type | Range | Description |
|---|---|---|---|
| `market_regime_score` | number | 0–100 | HMM ensemble classifying the current market regime. Trained on years of BTC price data. |
| `future_vol` | number | 0+ (%) | ML-predicted forward-looking daily volatility percentage. |
| `expansion_probability` | number | 0–1 | ML probability of a significant price expansion occurring in the near term. |

## Interpretation Cheat Sheet

### market_regime_score (official thresholds from API docs)

| Score | Regime | Action Bias |
|---|---|---|
| > 75 | **Bullish** | Look for long entries on pullbacks |
| 65–75 | Transition (lean bullish) | Cautious longs, wait for confirmation |
| 40–65 | **Neutral** | Reduced sizing, no directional edge |
| 30–40 | Transition (lean bearish) | Cautious shorts or hedges |
| < 30 | **Bearish** | Look for short entries on bounces |

### expansion_probability

| Probability | Signal | Interpretation |
|---|---|---|
| > 0.85 | Extreme | Major move very likely within 1–3 days |
| 0.70–0.85 | High | Significant move probable within 3–5 days |
| 0.50–0.70 | Moderate | Breakout possible but not imminent |
| 0.30–0.50 | Low-moderate | Consolidation likely to continue |
| < 0.30 | Low | Range-bound, low urgency |

### future_vol

| Vol (%) | Level | Implication |
|---|---|---|
| > 5% | Very high | Expect violent swings; widen stops significantly |
| 3–5% | High | Large intraday moves; active risk management |
| 2–3% | Moderate | Normal trading conditions |
| 1–2% | Low | Tight ranges, compression building |
| < 1% | Very low | Extreme compression — breakout setup |

### candle (Pattern Recognition)

Common values returned by the API:

| Pattern | Signal |
|---|---|
| `Engulfing_Bullish` | Strong bullish reversal |
| `Engulfing_Bearish` | Strong bearish reversal |
| `Doji` | Indecision — potential reversal |
| `Hammer` | Bullish reversal at support |
| `Shooting_Star` | Bearish reversal at resistance |
| `Morning_Star` | Bullish reversal (3-candle) |
| `Evening_Star` | Bearish reversal (3-candle) |
| `null` | No pattern detected |

## Combining Signals

The strongest prediction comes from confluence:

- **Bullish breakout setup:** Regime > 75 AND expansion_probability > 0.75 AND macd_hist positive AND rsi_14 < 70 (room to run)
- **Bearish breakdown setup:** Regime < 30 AND expansion_probability > 0.75 AND macd_hist negative AND rsi_14 > 30 (room to fall)
- **High-vol neutral:** Regime 40–65 AND expansion_probability > 0.80 → direction unclear but move is coming; trade the breakout
- **Candle confirmation:** A candle pattern aligned with the regime adds conviction (e.g. `Engulfing_Bullish` with regime > 75)

## Rate Limits

| Plan | Requests/Day | Pairs |
|---|---|---|
| Free | 100 | BTC-USD, ETH-USD |
| Pro ($5/mo) | 10,000 | Top 50 coins |
| AI ($49/mo) | Unlimited | All Pro features |

## Error Codes

| HTTP Code | Meaning |
|---|---|
| 200 | Success |
| 401 | Invalid or missing API key |
| 403 | Plan does not cover this pair |
| 404 | Invalid endpoint path (check `/{ticker}/{candles}` format) |
| 429 | Rate limit exceeded |
| 500 | Server error — retry after a few seconds |
