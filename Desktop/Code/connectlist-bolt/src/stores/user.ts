import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'

export interface User {
  id: string
  email?: string
  username?: string
  name?: string
  avatar_url?: string
}

export const useUserStore = defineStore('user', () => {
  const user = ref<User | null>(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!user.value)

  const setUser = (newUser: User | null) => {
    user.value = newUser
  }

  const loadUser = async () => {
    try {
      loading.value = true
      const { data: { user: authUser } } = await supabase.auth.getUser()
      
      if (authUser) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', authUser.id)
          .single()

        setUser(profile)
      } else {
        setUser(null)
      }
    } catch (error) {
      console.error('Error loading user:', error)
      setUser(null)
    } finally {
      loading.value = false
    }
  }

  // Initialize auth state listener
  supabase.auth.onAuthStateChange(async (event, session) => {
    if (event === 'SIGNED_IN' && session?.user) {
      await loadUser()
    } else if (event === 'SIGNED_OUT') {
      setUser(null)
    }
  })

  return {
    user,
    loading,
    isAuthenticated,
    setUser,
    loadUser
  }
})
