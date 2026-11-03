import { createRazorpayOrder, razorpayConfig } from '../data/api'

const RAZORPAY_SRC = 'https://checkout.razorpay.com/v1/checkout.js'

/** Public Key Id only — used if the API has not been redeployed with payment routes yet. */
const buildTimeKey = (import.meta.env.VITE_RAZORPAY_KEY_ID as string | undefined)?.trim() || ''

type RazorpayResult = {
  razorpay_payment_id?: string
  razorpay_order_id?: string
  razorpay_signature?: string
}
type RazorpayFailure = { error?: { description?: string; reason?: string; code?: string } }

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

let cachedKey = ''
let cachedMode = ''
let configLoaded = false

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
  return `pay_demo_${Date.now().toString(36)}`
}

function formatRupees(paise: number) {
  const value = Math.round(paise / 100)
  return `₹${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(value)}`
}

function isMissingMethods(message: string) {
  return /no appropriate payment method/i.test(message)
}

function isCancelled(message: string) {
  return /payment was cancelled/i.test(message)
}

/** Confirmed test payment when Razorpay checkout cannot show methods. */
async function payWithDemo(input: {
  amountPaise: number
  description: string
  reason?: string
}): Promise<RazorpayPaymentResult> {
  const hint = input.reason
    ? `${input.reason}\n\n`
    : ''
  const ok = window.confirm(
    `${hint}Razorpay test payment\n\n${input.description}\nAmount: ${formatRupees(input.amountPaise)}\n\nNo money is charged. Continue to place the order?`,
  )
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
    let sawFailure = ''
    const openedAt = Date.now()

    const finish = (error: Error) => {
      if (settled) return
      settled = true
      reject(error)
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
          // Razorpay often closes the "No appropriate payment method" dialog via dismiss only.
          if (sawFailure) {
            finish(new Error(sawFailure))
            return
          }
          if (Date.now() - openedAt < 3000) {
            finish(new Error('No appropriate payment method found.'))
            return
          }
          finish(new Error('Payment was cancelled.'))
        },
      },
    })
    checkout.on('payment.failed', (payload) => {
      sawFailure =
        payload.error?.description || payload.error?.reason || 'Payment failed.'
      // Keep the modal able to dismiss; ondismiss will reject with sawFailure.
    })
    checkout.open()
  })
}

function resolveKey() {
  if (cachedKey && cachedKey !== 'rzp_test_1DP5mmOlF5G5ag') return cachedKey
  if (buildTimeKey && buildTimeKey !== 'rzp_test_1DP5mmOlF5G5ag') return buildTimeKey
  return ''
}

export async function loadRazorpayConfig() {
  try {
    const config = await razorpayConfig()
    cachedKey = config.enabled && config.keyId ? config.keyId.trim() : ''
    cachedMode = config.mode || ''
  } catch {
    cachedKey = ''
    cachedMode = ''
  }
  configLoaded = true
  const keyId = resolveKey()
  return { keyId, mode: cachedMode, enabled: Boolean(keyId) }
}

async function completeWithFallback(
  input: { amountPaise: number; description: string },
  error: unknown,
): Promise<RazorpayPaymentResult> {
  const message = error instanceof Error ? error.message : ''
  if (isMissingMethods(message) || (resolveKey().startsWith('rzp_test_') && isCancelled(message))) {
    return payWithDemo({
      ...input,
      reason: isMissingMethods(message)
        ? 'Razorpay could not list payment methods for this test key.'
        : undefined,
    })
  }
  throw error instanceof Error ? error : new Error('Payment failed.')
}

export async function payWithRazorpay(input: {
  amountPaise: number
  phone: string
  email: string
  description: string
}): Promise<RazorpayPaymentResult> {
  if (input.amountPaise < 100) {
    throw new Error('Online payment needs an amount of at least ₹1.')
  }

  if (!configLoaded) {
    await loadRazorpayConfig()
  }

  try {
    const session = await createRazorpayOrder({
      amountPaise: input.amountPaise,
    })
    cachedKey = session.keyId
    cachedMode = session.mode || cachedMode
    try {
      return await payWithLiveKey({
        ...input,
        key: session.keyId,
        orderId: session.orderId,
      })
    } catch (error) {
      return completeWithFallback(input, error)
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : ''
    if (isMissingMethods(message) || isCancelled(message)) {
      return completeWithFallback(input, error)
    }

    const key = resolveKey()
    if (key) {
      try {
        return await payWithLiveKey({ ...input, key })
      } catch (liveError) {
        return completeWithFallback(input, liveError)
      }
    }

    if (/not configured|not reachable|404|could not complete/i.test(message)) {
      return payWithDemo(input)
    }
    throw error
  }
}

export function usesDemoOnlinePayment() {
  return !resolveKey()
}
