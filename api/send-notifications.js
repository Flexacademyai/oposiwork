const SUPABASE_SEND_NOTIFICATIONS_URL =
  process.env.SUPABASE_SEND_NOTIFICATIONS_URL ||
  'https://gklwylkqykjjxwutfehw.supabase.co/functions/v1/send-notifications';

function setSecurityHeaders(res) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'; base-uri 'none'");
}

module.exports = async function handler(req, res) {
  setSecurityHeaders(res);
  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ error: 'Metodo no permitido' });
  }

  const cronSecret = process.env.CRON_SECRET;
  const authorization = req.headers.authorization;

  if (!cronSecret || authorization !== `Bearer ${cronSecret}`) {
    return res.status(401).json({ error: 'No autorizado' });
  }

  try {
    const response = await fetch(SUPABASE_SEND_NOTIFICATIONS_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-cron-secret': cronSecret,
      },
    });

    const text = await response.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch (_) {
      body = { raw: text };
    }

    return res.status(response.status).json(body);
  } catch (_) {
    return res.status(500).json({
      error: 'No se pudo ejecutar el envio de notificaciones',
    });
  }
};
