import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import {
  getAdminProfile,
  loginAdmin,
  updateAdminCredentials,
  updateAdminProfile,
  type AdminProfile,
} from './api'

const SESSION_KEY = 'sf-admin-session'

export type { AdminProfile }

export const DEFAULT_ADMIN: AdminProfile = {
  name: 'Factory Admin',
  email: 'admin@shoefactory.shop',
  phone: '8075090160',
  username: 'Malik@shoefactory',
}

type Credentials = {
  currentPassword: string
  username: string
  password?: string
}

type Auth = {
  name: string | null
  email: string | null
  phone: string | null
  username: string | null
  profile: AdminProfile
  signIn: (username: string, password: string) => Promise<string | null>
  updateProfile: (next: AdminProfile) => Promise<string | null>
  updateCredentials: (next: Credentials) => Promise<string | null>
  signOut: () => void
}

const AuthContext = createContext<Auth | null>(null)

function readSession() {
  return sessionStorage.getItem(SESSION_KEY) === '1'
}

function withUsername(profile: Partial<AdminProfile>): AdminProfile {
  return {
    ...DEFAULT_ADMIN,
    ...profile,
    username: profile.username?.trim() || DEFAULT_ADMIN.username,
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<AdminProfile>(DEFAULT_ADMIN)
  const [signedIn, setSignedIn] = useState(readSession)

  useEffect(() => {
    void getAdminProfile()
      .then((next) => setProfile(withUsername(next)))
      .catch(() => setProfile(DEFAULT_ADMIN))
  }, [])

  const auth: Auth = {
    name: signedIn ? profile.name : null,
    email: signedIn ? profile.email : null,
    phone: signedIn ? profile.phone : null,
    username: signedIn ? profile.username : null,
    profile,
    signIn: async (username, password) => {
      try {
        const result = await loginAdmin(username, password)
        setProfile(withUsername(result.profile))
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
        setProfile(withUsername(saved))
        return null
      } catch (err) {
        return err instanceof Error ? err.message : 'Could not save your profile.'
      }
    },
    updateCredentials: async (next) => {
      try {
        const saved = await updateAdminCredentials(next)
        setProfile(withUsername(saved))
        return null
      } catch (err) {
        return err instanceof Error ? err.message : 'Could not change the sign-in details.'
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
