/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string
  /** Public Razorpay Key Id fallback when the API payment routes are unavailable. */
  readonly VITE_RAZORPAY_KEY_ID?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
