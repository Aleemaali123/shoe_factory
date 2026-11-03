import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';

dotenv.config({
  path: path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../.env'),
});

export const env = {
  port: Number(process.env.PORT || 4000),
  jwtSecret: process.env.JWT_SECRET || 'shoe-factory-dev-secret',
  databasePath: process.env.DATABASE_PATH || 'data/shop.db',
  notifyChannel: process.env.NOTIFY_CHANNEL || 'both',
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
  twilioSmsFrom: process.env.TWILIO_SMS_FROM || '',
  // Admin WhatsApp number (India). Override with TWILIO_WHATSAPP_FROM if needed.
  twilioWhatsappFrom: process.env.TWILIO_WHATSAPP_FROM || 'whatsapp:+918075090160',
  adminWhatsapp: process.env.ADMIN_WHATSAPP || '8075090160',
  // Used in WhatsApp / SMS tracking links (web shop order page).
  shopPublicUrl: process.env.PUBLIC_SHOP_URL || 'https://shoefactory-shop.web.app',
  // Razorpay — Key Id is public to clients; Key Secret stays server-side only.
  razorpayKeyId: String(process.env.RAZORPAY_KEY_ID || '').trim(),
  razorpayKeySecret: String(process.env.RAZORPAY_KEY_SECRET || '').trim(),
};
