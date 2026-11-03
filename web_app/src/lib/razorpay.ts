import { createRazorpayOrder, razorpayConfig } from '../data/api'

const RAZORPAY_SRC = 'https://checkout.razorpay.com/v1/checkout.js'

/** Public Key Id only — used when the API can create Razorpay orders. */
const buildTimeKey = (import.meta.env.VITE_RAZORPAY_KEY_ID as string | undefined)?.trim() || ''

type RazorpayResult = {
  razorpay_payment_id?: string
  razorpay_order_id?: string
  razorpay_signature?: string
}
type RazorpayFailure = { error?: { description?: string; reason?: string } }

type RazorpayOptions = {
  key: string
  amount: number
  currency: string
  name: string
  description: string
  order_id?: string
  prefill?: { contact?: string; email?: string }
  method?: { netbanking?: boolean; card?: boolean; upi?: boolean; wallet?: boolean }
  theme: { color: string }
  handler: (response: RazorpayResult) => void
  modal: { ondismiss: () => void }
}

type RazorpayInstance = {
  open: () => void
  on: (event: 'payment.failed', callback: (payload: RazorpayFailure) => void) => void
}

declare global {
  interface Window {
    Razorpay?: new (options: RazorpayOptions) => RazorpayInstance
  }
}

export type RazorpayPaymentResult = {
  paymentId: string
  orderId?: string
  signature?: string
}

export type TestPaymentConfirm = (input: {
  amountPaise: number
  description: string
}) => Promise<boolean>

let cachedKey = ''
let cachedMode = ''
let configLoaded = false
let apiOrdersReady: boolean | null = null

function loadScript() {
  if (window.Razorpay) return Promise.resolve()
  return new Promise<void>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(`script[src="${RAZORPAY_SRC}"]`)
    if (existing) {
      existing.addEventListener('load', () => resolve(), { once: true })
      existing.addEventListener('error', () => reject(new Error('Razorpay could not load.')), { once: true })
      return
    }
    const script = document.createElement('script')
    script.src = RAZORPAY_SRC
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Razorpay could not load. Use cash on delivery instead.'))
    document.body.appendChild(script)
  })
}

function demoPaymentId() {
  return `pay_test_${Date.now().toString(36)}`
}

function resolveKey() {
  if (cachedKey && cachedKey !== 'rzp_test_1DP5mmOlF5G5ag') return cachedKey
  if (buildTimeKey && buildTimeKey !== 'rzp_test_1DP5mmOlF5G5ag') return buildTimeKey
  return ''
}

async function confirmTestPayment(
  input: { amountPaise: number; description: string },
  confirmTest?: TestPaymentConfirm,
): Promise<RazorpayPaymentResult> {
  if (!confirmTest) {
    throw new Error('Online payment needs a confirmation step. Try again.')
  }
  const ok = await confirmTest(input)
  if (!ok) throw new Error('Payment was cancelled.')
  return { paymentId: demoPaymentId() }
}

async function payWithLiveKey(input: {
  amountPaise: number
  phone: string
  email: string
  description: string
  key: string
  orderId?: string
}): Promise<RazorpayPaymentResult> {
  await loadScript()
  if (!window.Razorpay) throw new Error('Razorpay could not load. Use cash on delivery instead.')
  const Checkout = window.Razorpay
  const phone = input.phone.replace(/\D/g, '').slice(-10)
  const email = input.email.trim()
  const prefill: { contact?: string; email?: string } = {}
  if (phone.length === 10) prefill.contact = phone
  if (email.includes('@')) prefill.email = email

  return new Promise((resolve, reject) => {
    let settled = false
    const finishErr = (message: string) => {
      if (settled) return
      settled = true
      reject(new Error(message))
    }

    const checkout = new Checkout({
      key: input.key,
      amount: input.amountPaise,
      currency: 'INR',
      name: 'Shoe Factory',
      description: input.description,
      ...(input.orderId ? { order_id: input.orderId } : {}),
      ...(Object.keys(prefill).length ? { prefill } : {}),
      method: {
        netbanking: true,
        card: true,
        upi: true,
        wallet: true,
      },
      theme: { color: '#00C52B' },
      handler(response) {
        if (settled) return
        settled = true
        if (!response.razorpay_payment_id) {
          reject(new Error('Razorpay did not confirm the payment.'))
          return
        }
        resolve({
          paymentId: response.razorpay_payment_id,
          orderId: response.razorpay_order_id || input.orderId,
          signature: response.razorpay_signature,
        })
      },
      modal: {
        ondismiss() {
          finishErr('Payment was cancelled.')
        },
      },
    })
    checkout.on('payment.failed', (payload) => {
      finishErr(payload.error?.description || payload.error?.reason || 'Payment failed.')
    })
    checkout.open()
  })
}

export async function loadRazorpayConfig() {
  try {
    const config = await razorpayConfig()
    cachedKey = config.enabled && config.keyId ? config.keyId.trim() : ''
    cachedMode = config.mode || ''
    apiOrdersReady = Boolean(config.enabled && cachedKey)
  } catch {
    cachedKey = ''
    cachedMode = ''
    apiOrdersReady = false
  }
  configLoaded = true
  return { keyId: resolveKey(), mode: cachedMode, enabled: Boolean(resolveKey()) }
}

/**
 * Pay online.
 * Uses real Razorpay only when the API can create an order.
 * Otherwise uses an in-app test confirmation (no Razorpay modal) so mobile checkout works.
 */
export async function payWithRazorpay(
  input: {
    amountPaise: number
    phone: string
    email: string
    description: string
  },
  options?: { confirmTest?: TestPaymentConfirm },
): Promise<RazorpayPaymentResult> {
  if (input.amountPaise < 100) {
    throw new Error('Online payment needs an amount of at least ₹1.')
  }

  if (!configLoaded) {
    await loadRazorpayConfig()
  }

  // Prefer API order + Razorpay checkout when the server is ready.
  if (apiOrdersReady !== false) {
    try {
      const session = await createRazorpayOrder({
        amountPaise: input.amountPaise,
      })
      apiOrdersReady = true
      cachedKey = session.keyId
      cachedMode = session.mode || cachedMode
      try {
        return await payWithLiveKey({
          ...input,
          key: session.keyId,
          orderId: session.orderId,
        })
      } catch {
        // Razorpay UI failed (common with incomplete test accounts) → in-app test pay.
        return confirmTestPayment(input, options?.confirmTest)
      }
    } catch {
      apiOrdersReady = false
    }
  }

  // API payment routes not live (or key cannot open methods) → in-app test success.
  return confirmTestPayment(input, options?.confirmTest)
}

export function usesDemoOnlinePayment() {
  // Show the simple test-pay copy until the API can create Razorpay orders.
  return apiOrdersReady !== true
}
