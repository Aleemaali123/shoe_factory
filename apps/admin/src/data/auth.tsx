import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { getAdminProfile, requestAdminOtp, updateAdminProfile, verifyAdminOtp, type AdminProfile } from './api'

const SESSION_KEY = 'sf-admin-session'

export type { AdminProfile }

export const DEFAULT_ADMIN: AdminProfile = {
  name: 'Factory Admin',
  email: 'admin@shoefactory.shop',
  phone: '9876501234',
}

export type OtpRequest = { ok: boolean; code?: string; error?: string }

type Auth = {
  name: string | null
  email: string | null
  phone: string | null
  profile: AdminProfile
  requestOtp: (phone: string) => Promise<OtpRequest>
  verifyOtp: (phone: string, code: string) => Promise<string | null>
  updateProfile: (next: AdminProfile) => Promise<string | null>
  signOut: () => void
}

const AuthContext = createContext<Auth | null>(null)

function readSession() {
  return sessionStorage.getItem(SESSION_KEY) === '1'
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<AdminProfile>(DEFAULT_ADMIN)
  const [signedIn, setSignedIn] = useState(readSession)

  useEffect(() => {
    void getAdminProfile()
      .then(setProfile)
      .catch(() => setProfile(DEFAULT_ADMIN))
  }, [])

  const auth: Auth = {
    name: signedIn ? profile.name : null,
    email: signedIn ? profile.email : null,
    phone: signedIn ? profile.phone : null,
    profile,
    requestOtp: async (raw) => {
      try {
        const result = await requestAdminOtp(raw)
        return { ok: true, code: result.code }
      } catch (err) {
        return { ok: false, error: err instanceof Error ? err.message : 'Could not send a code.' }
      }
    },
    verifyOtp: async (raw, code) => {
      try {
        const result = await verifyAdminOtp(raw, code)
        setProfile(result.profile)
        sessionStorage.setItem(SESSION_KEY, '1')
        setSignedIn(true)
        return null
      } catch (err) {
        return err instanceof Error ? err.message : 'Could not sign in.'
      }
    },
    updateProfile: async (next) => {
      try {
        const saved = await updateAdminProfile(next)
        setProfile(saved)
        return null
      } catch (err) {
        return err instanceof Error ? err.message : 'Could not save your profile.'
      }
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
