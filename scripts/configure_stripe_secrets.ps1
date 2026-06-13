param(
  [string]$SupabaseCli = "supabase"
)

$ErrorActionPreference = "Stop"

function Read-SecretValue([string]$Prompt) {
  $secure = Read-Host $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Read-PlainValue([string]$Prompt, [string]$DefaultValue = "") {
  $suffix = if ($DefaultValue) { " [$DefaultValue]" } else { "" }
  $value = Read-Host "$Prompt$suffix"
  if ([string]::IsNullOrWhiteSpace($value) -and $DefaultValue) {
    return $DefaultValue
  }
  return $value.Trim()
}

$stripeSecretKey = Read-SecretValue "STRIPE_SECRET_KEY"
$stripePriceMonthly = Read-PlainValue "STRIPE_PRICE_MONTHLY"
$stripePriceAnnual = Read-PlainValue "STRIPE_PRICE_ANNUAL"
$stripeWebhookSecret = Read-SecretValue "STRIPE_WEBHOOK_SECRET"
$appBaseUrl = Read-PlainValue "APP_BASE_URL" "https://www.oposiwork.com"

if (-not $stripeSecretKey.StartsWith("sk_")) {
  throw "STRIPE_SECRET_KEY debe empezar por sk_test_ o sk_live_."
}
if (-not $stripePriceMonthly.StartsWith("price_")) {
  throw "STRIPE_PRICE_MONTHLY debe empezar por price_."
}
if (-not $stripePriceAnnual.StartsWith("price_")) {
  throw "STRIPE_PRICE_ANNUAL debe empezar por price_."
}
if (-not $stripeWebhookSecret.StartsWith("whsec_")) {
  throw "STRIPE_WEBHOOK_SECRET debe empezar por whsec_."
}

& $SupabaseCli secrets set `
  "STRIPE_SECRET_KEY=$stripeSecretKey" `
  "STRIPE_PRICE_MONTHLY=$stripePriceMonthly" `
  "STRIPE_PRICE_ANNUAL=$stripePriceAnnual" `
  "STRIPE_WEBHOOK_SECRET=$stripeWebhookSecret" `
  "APP_BASE_URL=$appBaseUrl"

Write-Host "Stripe configurado en Supabase Functions." -ForegroundColor Green
