# 🔮 DefiTheOdds — OpenClaw Skill

**ML-powered BTC market predictions for your OpenClaw agent.**

Turn your OpenClaw assistant into a crypto trade analyst. This skill connects to the [DefiTheOdds](https://defitheodds.xyz) API — fetching enriched OHLCV data with 40+ technical indicators, HMM-driven market regime scores, and candle pattern recognition — and produces structured medium-term market predictions via natural language.

> *"Give me your BTC market prediction"* → Full regime analysis, directional bias, expected move targets.

---

## Example Output

```
Medium-term (Next 5–10 days):

High-Volatility Breakout Imminent

Critical Signal: Expansion Probability at 89.8% — This is an extremely
strong signal that a significant price move is coming.

Directional Bias:

Bullish Breakout Likely

Reasoning:

1. Regime Score (82.45): Bullish — well above the 75 threshold,
   indicating strong upward momentum in the HMM ensemble.
2. Expansion Probability (89.8%): Extremely high — market is primed
   for a major move within 1–3 days.
3. Technical Setup:
   • Price consolidating in tight range ($63k–$69k)
   • RSI neutral at 46.3 (room to run)
   • MACD histogram positive (840.37) — bullish momentum building
   • Engulfing_Bearish detected on prior candle — watch for invalidation

Expected Move:

• Volatility-based target: ±3.02% daily = ~±$2,100 daily range
• Expansion target: Based on 89.8% probability, expect 5–8% move
  in coming days
• Direction bias: Upside (regime score >75, MACD positive)
```

---

## Key Features

| Feature | Description |
|---|---|
| **Market Regime Detection** | HMM ensemble score (0–100) classifying bullish, neutral, or bearish regimes |
| **Expansion Probability** | ML-predicted probability of an imminent significant price breakout |
| **Forward Volatility** | Predicted daily volatility % for position sizing and stop placement |
| **Candle Pattern Recognition** | Automated detection of patterns like Engulfing, Doji, Hammer, Morning/Evening Star |
| **40+ Technical Indicators** | RSI, MACD, SMA, EMA, Stochastic, Bollinger Bands, ATR and more — pre-calculated |
| **Structured Reports** | Consistent, reproducible prediction format with reasoning and targets |

---

## Installation

### Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and running
- `curl` and `jq` available on your system
- A DefiTheOdds API key (free tier available at [defitheodds.xyz/register](https://defitheodds.xyz/register))

### Option 1 — Paste the repo URL into chat

Send this message to your OpenClaw agent:

```
Install the skill from https://github.com/YOUR_USERNAME/defi-the-odds
```

OpenClaw will clone the repo and set up the skill automatically.

### Option 2 — Manual install

```bash
# Clone into your workspace skills directory
git clone https://github.com/YOUR_USERNAME/defi-the-odds.git \
  ~/.openclaw/workspace/skills/defi-the-odds
```

Then add your API key to `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "defi-the-odds": {
        "enabled": true,
        "apiKey": "dfo_YOUR_KEY_HERE",
        "env": {
          "DFO_API_KEY": "dfo_YOUR_KEY_HERE"
        }
      }
    }
  }
}
```

Refresh skills:

```
/skill refresh
```

Or restart the gateway.

### Option 3 — ClawHub

```bash
clawhub install defi-the-odds
```

---

## Usage

Once installed, just talk to your agent in natural language:

| Prompt | What happens |
|---|---|
| *"Give me a BTC market prediction"* | Full regime + expansion + volatility analysis report |
| *"What's the current market regime for Bitcoin?"* | Fetches latest regime score and interprets it |
| *"Is a breakout likely?"* | Checks expansion probability and volatility |
| *"ETH outlook for the next week"* | Same analysis for ETH-USD (Pro plan required) |
| *"Fetch the last 24 hours of BTC hourly candles"* | Raw data fetch with 24 candles |

### Slash command

```
/skill defi-the-odds BTC market prediction
```

---

## Repository Structure

```
defi-the-odds/
├── SKILL.md                      # Main skill — frontmatter + agent instructions
├── references/
│   └── api-fields.md             # Complete field reference & interpretation guide
├── scripts/
│   └── fetch_dfo.sh              # Standalone CLI script for fetching & summarizing data
└── README.md
```

| File | Purpose |
|---|---|
| `SKILL.md` | Core skill definition. Contains the YAML frontmatter (name, description, metadata, requirements) and the full analysis workflow the agent follows to produce predictions. |
| `references/api-fields.md` | Detailed field-by-field reference for all API response fields, regime score thresholds, expansion probability interpretation, volatility levels, candle patterns, rate limits, and error codes. Loaded by the agent on demand to keep `SKILL.md` lean. |
| `scripts/fetch_dfo.sh` | Bash script for standalone use outside OpenClaw. Fetches data, prints latest candle summary, recent candle table, regime trend, and price range. |

---

## API Reference (Quick)

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/v1/hourly/{ticker}/{candles}` | Hourly enriched candles |
| `GET` | `/v1/daily/{ticker}/{candles}` | Daily enriched candles |

### Authentication

```
X-API-KEY: dfo_YOUR_KEY_HERE
```

### Example Request

```bash
curl -s -H "X-API-KEY: dfo_YOUR_KEY" \
  "https://api.defitheodds.xyz/v1/hourly/BTC-USD/240" | jq '.data[-1]'
```

### Response Structure

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

### ML Signal Interpretation

| Signal | Bearish | Neutral | Bullish |
|---|---|---|---|
| `market_regime_score` | < 30 | 40 – 65 | > 75 |
| `expansion_probability` | — | < 0.40 (low) | > 0.80 (imminent move) |
| `future_vol` | — | < 2% (compressed) | > 4% (high vol expected) |

Full interpretation tables and candle pattern reference → [`references/api-fields.md`](references/api-fields.md)

---

## Standalone Script

You can use `fetch_dfo.sh` independently of OpenClaw for quick terminal checks:

```bash
export DFO_API_KEY="dfo_YOUR_KEY"

# Default: 240 hourly BTC-USD candles
./scripts/fetch_dfo.sh

# 30 daily ETH-USD candles
./scripts/fetch_dfo.sh ETH-USD daily 30

# Last 24 hours hourly
./scripts/fetch_dfo.sh BTC-USD hourly 24
```

Output includes: latest candle summary, recent 5-candle table, regime score trend (last 10), and 48-candle price range.

---

## Plans & Rate Limits

| Plan | Price | Requests/Day | Assets |
|---|---|---|---|
| **Free** | $0/mo | 100 | BTC-USD, ETH-USD |
| **Pro** | $5/mo | 10,000 | Top 50 coins |
| **AI** | $49/mo | Unlimited | All Pro features |

Get your key → [defitheodds.xyz/register](https://defitheodds.xyz/register)

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `HTTP 404` | Endpoint needs `/{candles}` — use `/hourly/BTC-USD/240`, not `/hourly/BTC-USD` |
| `HTTP 401` | Check that `DFO_API_KEY` is set and starts with `dfo_` |
| `HTTP 403` | Your plan doesn't cover this ticker — upgrade or use `BTC-USD` / `ETH-USD` |
| `HTTP 429` | Rate limit hit — wait or upgrade your plan |
| Agent doesn't trigger | Make sure the skill is in `~/.openclaw/workspace/skills/` and run `/skill refresh` |
| `jq` errors | Ensure you access `.data` not the root — response is wrapped in `{"message": ..., "data": [...]}` |

---

## Security

- API keys are injected via `skills.entries.env` in `openclaw.json` — they are scoped to the agent run and not persisted in prompts or logs.
- The skill uses only `curl` (read-only GET requests) — no write operations, no wallet access, no transaction signing.
- Review the skill source before installing. See [OpenClaw security docs](https://docs.openclaw.ai/gateway/security) for sandboxing best practices.

---

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/add-multi-asset-comparison`)
3. Commit your changes (`git commit -m 'Add multi-asset regime comparison'`)
4. Push to the branch (`git push origin feature/add-multi-asset-comparison`)
5. Open a Pull Request

Ideas for contributions: multi-asset comparison reports, alert threshold configuration, integration with TradingView webhook triggers, historical regime backtesting.

---

## Disclaimer

This skill produces market analysis based on ML-derived signals from DefiTheOdds. **It does not constitute financial advice.** Cryptocurrency trading involves significant risk. Always manage your risk and do your own research. Past model performance does not guarantee future results.

---

## License

MIT

---

## Links

- [DefiTheOdds Website](https://defitheodds.xyz)
- [DefiTheOdds API Docs](https://defitheodds.xyz/docs)
- [OpenClaw](https://github.com/openclaw/openclaw)
- [OpenClaw Skills Documentation](https://docs.openclaw.ai/tools/skills)
- [ClawHub Registry](https://clawhub.com)
