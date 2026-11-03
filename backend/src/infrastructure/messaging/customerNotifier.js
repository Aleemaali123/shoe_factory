const channels = new Set(['whatsapp', 'sms', 'both']);

export function createCustomerNotifier({
  channel = 'both',
  accountSid = '',
  authToken = '',
  smsFrom = '',
  whatsappFrom = '',
  shopPublicUrl = '',
  fetchImpl = globalThis.fetch,
  logger = console,
} = {}) {
  const selected = channels.has(channel) ? channel : 'both';
  const baseUrl = String(shopPublicUrl || '').trim().replace(/\/$/, '');

  return {
    trackingUrl(order) {
      return orderTrackingUrl(order, baseUrl);
    },

    composeWhatsapp(order, { includeTracking = true } = {}) {
      const phone = toE164(order.contactPhone);
      if (!phone) return null;
      const text = messageText(order, {
        includeTracking,
        trackingUrl: includeTracking ? orderTrackingUrl(order, baseUrl) : '',
      });
      return {
        phone,
        text,
        url: `https://wa.me/${phone.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`,
      };
    },

    async orderConfirmed(order) {
      const paid = isPaid(order);
      // Auto WhatsApp/SMS fires for every placed order; paid copy includes payment + tracking.
      return notify(order, {
        includeTracking: true,
        preferWhatsapp: paid,
      });
    },

    async sendWhatsapp(order, { includeTracking = true } = {}) {
      return notify(order, {
        includeTracking,
        channelOverride: 'whatsapp',
      });
    },
  };

  async function notify(order, { includeTracking = true, channelOverride = '', preferWhatsapp = false } = {}) {
    const phone = toE164(order.contactPhone);
    const tracking = includeTracking ? orderTrackingUrl(order, baseUrl) : '';
    const text = messageText(order, { includeTracking, trackingUrl: tracking });
    if (!phone) {
      logger.warn('[notify] skipped: phone is not a 10-digit mobile');
      return {
        customerMessage: 'Add a 10-digit mobile number next time for WhatsApp updates.',
        deskMessage: 'This order has no 10-digit mobile number, so WhatsApp could not be prepared.',
        trackingUrl: tracking || null,
        whatsappComposeUrl: null,
      };
    }

    const compose = {
      phone,
      text,
      url: `https://wa.me/${phone.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`,
    };

    const wanted = wantedChannels(channelOverride || selected);
    // Paid orders always try WhatsApp first even if channel is sms-only.
    if (preferWhatsapp && !wanted.includes('whatsapp')) {
      wanted.unshift('whatsapp');
    }

    if (!accountSid || !authToken) {
      logger.info(`[notify] ${wanted.join(' + ')} not sent (Twilio is not configured). ${phone}: ${text}`);
      return {
        customerMessage: `We'll keep you updated at ${maskPhone(phone)}.`,
        deskMessage: `Connect WhatsApp or SMS (Twilio) in the server settings to deliver this message to ${maskPhone(phone)}. Open the compose link from the desk until then.`,
        trackingUrl: tracking || null,
        whatsappComposeUrl: compose.url,
      };
    }

    const jobs = [];
    if (wanted.includes('whatsapp')) {
      jobs.push(deliver({
        name: 'whatsapp',
        from: whatsappAddress(whatsappFrom),
        to: `whatsapp:${phone}`,
        body: text,
        missing: 'TWILIO_WHATSAPP_FROM',
      }));
    }
    if (wanted.includes('sms') && !channelOverride) {
      jobs.push(deliver({
        name: 'sms',
        from: String(smsFrom || '').trim(),
        to: phone,
        body: text,
        missing: 'TWILIO_SMS_FROM',
      }));
    }

    const results = await Promise.all(jobs);
    const sent = results.filter((item) => item.ok).map((item) => item.name);
    const failed = results.filter((item) => !item.ok);

    for (const item of failed) {
      logger.error(`[notify] ${item.name} failed for ${phone}: ${item.reason}`);
    }
    if (sent.length) {
      logger.info(`[notify] ${sent.join(' + ')} sent to ${phone} for ${order.id}`);
    }

    const report = summary(phone, sent, failed.map((item) => item.name));
    return {
      customerMessage: report.customerMessage,
      deskMessage: report.deskMessage,
      trackingUrl: tracking || null,
      whatsappComposeUrl: compose.url,
    };
  }

  function deliver({ name, from, to, body, missing }) {
    if (!from) {
      return Promise.resolve({ name, ok: false, reason: `${missing} is empty` });
    }
    return sendTwilio({
      accountSid,
      authToken,
      from,
      to,
      body,
      fetchImpl,
    }).then(
      () => ({ name, ok: true }),
      (error) => ({ name, ok: false, reason: error.message }),
    );
  }
}

export function orderTrackingUrl(order, shopPublicUrl = '') {
  const base = String(shopPublicUrl || '').trim().replace(/\/$/, '');
  const id = String(order?.id ?? '').trim();
  if (!base || !id) return '';
  return `${base}/orders/${encodeURIComponent(id)}`;
}

export function confirmationText(order, trackingUrl = '') {
  return messageText(order, {
    includeTracking: Boolean(trackingUrl),
    trackingUrl,
  });
}

export function messageText(order, { includeTracking = false, trackingUrl = '' } = {}) {
  const total = formatRupees(order.total);
  const paid = isPaid(order);
  let text;
  if (paid) {
    text = `Shoe Factory: Payment received. Order ${order.id} is confirmed for ${total}. We will start packing it now.`;
  } else {
    text = `Shoe Factory: Order ${order.id} is confirmed for ${total}. Pay on delivery. We will start packing it now.`;
  }
  if (includeTracking && trackingUrl) {
    text += ` Track your order: ${trackingUrl}`;
  }
  return text;
}

export function toE164(value) {
  const digits = String(value ?? '').replace(/\D/g, '');
  const local = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
  if (!/^[6-9]\d{9}$/.test(local)) return '';
  return `+91${local}`;
}

function isPaid(order) {
  return order.paymentMethod === 'razorpay' && String(order.paymentReference ?? '').trim();
}

function wantedChannels(channel) {
  if (channel === 'both') return ['whatsapp', 'sms'];
  if (channel === 'whatsapp' || channel === 'sms') return [channel];
  return ['whatsapp', 'sms'];
}

function whatsappAddress(value) {
  const from = String(value ?? '').trim();
  if (!from) return '';
  return from.startsWith('whatsapp:') ? from : `whatsapp:${from}`;
}

function maskPhone(phone) {
  return `${phone.slice(0, 3)}••••${phone.slice(-4)}`;
}

function summary(phone, sent, failed) {
  const masked = maskPhone(phone);
  const label = {
    whatsapp: 'WhatsApp',
    sms: 'text message',
  };
  if (sent.length === 1 && failed.length === 0) {
    const message = `Confirmation sent to ${masked} on ${label[sent[0]]}.`;
    return { customerMessage: message, deskMessage: message };
  }
  if (sent.length === 2) {
    const message = `Confirmation sent to ${masked} on WhatsApp and by text message.`;
    return { customerMessage: message, deskMessage: message };
  }
  if (sent.length === 1) {
    return {
      customerMessage: `Confirmation sent to ${masked} on ${label[sent[0]]}.`,
      deskMessage: `Confirmation sent to ${masked} on ${label[sent[0]]}. ${label[failed[0]] || 'The other channel'} could not be reached.`,
    };
  }
  return {
    customerMessage: `We'll keep you updated at ${masked}.`,
    deskMessage: `Could not send WhatsApp or SMS to ${masked}. Check Twilio credentials and from-numbers.`,
  };
}

function formatRupees(amount) {
  const value = Math.round(Number(amount) || 0);
  return `Rs ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(value)}`;
}

async function sendTwilio({ accountSid, authToken, from, to, body, fetchImpl }) {
  const url = `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(accountSid)}/Messages.json`;
  const response = await fetchImpl(url, {
    method: 'POST',
    headers: {
      authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ From: from, To: to, Body: body }).toString(),
  });
  if (response.ok) return;
  const detail = await response.text();
  throw new Error(`Twilio returned ${response.status}: ${detail.slice(0, 300)}`);
}
