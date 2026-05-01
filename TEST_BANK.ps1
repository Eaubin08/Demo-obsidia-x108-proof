Set-Location $PSScriptRoot

$Body = @{
  domain = "bank"
  data = @{
    transaction_type = "transfer"
    amount = 219.10
    channel = "mobile"
    counterparty_known = $false
    counterparty_age_days = 0
    account_balance = 1000
    available_cash = 1000
    historical_avg_amount = 80
    behavior_shift_score = 0.8
    fraud_score = 0.9
    policy_limit = 500
    affordability_score = 0.7
    urgency_score = 0.9
    identity_mismatch_score = 0.4
    narrative_conflict_score = 0.4
    device_trust_score = 0.4
    recent_failed_attempts = 2
    elapsed_s = 1
    min_required_elapsed_s = 108
  }
} | ConvertTo-Json -Depth 10 -Compress

Invoke-RestMethod `
  -Uri "http://localhost:3018/kernel/ragnarok" `
  -Method Post `
  -ContentType "application/json" `
  -Body $Body |
  Select-Object domain, market_verdict, x108_gate, confidence_integrity, confidence_governance, confidence_readiness, severity, reason_code
