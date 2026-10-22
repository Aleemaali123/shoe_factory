import { createContext, useContext, useState, type ReactNode } from 'react'

const SESSION_KEY = 'sf-admin-session'
const PROFILE_KEY = 'sf-admin-profile'

export type AdminProfile = {
  name: string
  email: string
  phone: string
}

export const DEFAULT_ADMIN: AdminProfile = {
  name: 'Factory Admin',
  email: 'admin@shoefactory.shop',
  phone: '9876501234',
}

type OtpChallenge = { phone: string; code: string; expiresAt: number }

let challenge: OtpChallenge | null = null

export type OtpRequest = { ok: boolean; code?: string; error?: string }

type Auth = {
  name: string | null
  email: string | null
  phone: string | null
  profile: AdminProfile
  requestOtp: (phone: string) => OtpRequest
  verifyOtp: (phone: string, code: string) => string | null
  updateProfile: (next: AdminProfile) => string | null
  signOut: () => void
}

const AuthContext = createContext<Auth | null>(null)

function digits(value: string) {
  return value.replace(/\D/g, '')
}

function loadProfile(): AdminProfile {
  try {
    const raw = localStorage.getItem(PROFILE_KEY)
    if (!raw) return DEFAULT_ADMIN
    const parsed = JSON.parse(raw) as Partial<AdminProfile>
    const phone = digits(parsed.phone ?? '')
    return {
      name: parsed.name?.trim() || DEFAULT_ADMIN.name,
      email: parsed.email?.trim() || DEFAULT_ADMIN.email,
      phone: /^[6-9]\d{9}$/.test(phone) ? phone : DEFAULT_ADMIN.phone,
    }
  } catch {
    return DEFAULT_ADMIN
  }
}

function readSession() {
  return sessionStorage.getItem(SESSION_KEY) === '1'
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<AdminProfile>(loadProfile)
  const [signedIn, setSignedIn] = useState(readSession)

  const auth: Auth = {
    name: signedIn ? profile.name : null,
    email: signedIn ? profile.email : null,
    phone: signedIn ? profile.phone : null,
    profile,
    requestOtp: (raw) => {
      const mobile = digits(raw)
      if (!/^[6-9]\d{9}$/.test(mobile)) {
        return { ok: false, error: 'Enter a 10-digit mobile number.' }
      }
      if (mobile !== profile.phone) {
        return { ok: false, error: 'That mobile number is not on the admin desk.' }
      }
      const code = String(Math.floor(100000 + Math.random() * 900000))
      challenge = { phone: mobile, code, expiresAt: Date.now() + 5 * 60 * 1000 }
      return { ok: true, code }
    },
    verifyOtp: (raw, code) => {
      const mobile = digits(raw)
      if (!challenge || challenge.phone !== mobile) return 'Request a code for this mobile number first.'
      if (Date.now() > challenge.expiresAt) return 'That code has expired. Request a new one.'
      if (challenge.code !== digits(code)) return 'That code does not match.'
      challenge = null
      sessionStorage.setItem(SESSION_KEY, '1')
      setSignedIn(true)
      return null
    },
    updateProfile: (next) => {
      const name = next.name.trim()
      const email = next.email.trim()
      const phone = digits(next.phone)
      if (name.length < 2) return 'Enter your name.'
      if (!email.includes('@') || !email.includes('.')) return 'Enter a valid email.'
      if (!/^[6-9]\d{9}$/.test(phone)) return 'Enter a 10-digit mobile number.'
      const saved = { name, email, phone }
      localStorage.setItem(PROFILE_KEY, JSON.stringify(saved))
      setProfile(saved)
      return null
    },
    signOut: () => {
      sessionStorage.removeItem(SESSION_KEY)
      setSignedIn(false)
    },
  }

  return <AuthContext.Provider value={auth}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const auth = useContext(AuthContext)
  if (!auth) throw new Error('useAuth must be used inside AuthProvider')
  return auth
}
