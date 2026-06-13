-- Stripe web subscriptions.
-- Mobile subscriptions continue through Apple/Google stores via RevenueCat.

ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;

CREATE INDEX IF NOT EXISTS idx_perfiles_stripe_customer_id
  ON public.perfiles (stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_perfiles_stripe_subscription_id
  ON public.perfiles (stripe_subscription_id)
  WHERE stripe_subscription_id IS NOT NULL;
