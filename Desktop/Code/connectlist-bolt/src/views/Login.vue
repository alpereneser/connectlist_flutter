<template>
  <div class="flex flex-col md:flex-row min-h-screen w-full">
    <div class="flex-1 p-4 md:p-8 flex flex-col justify-center md:max-w-lg mx-auto w-full">
      <div class="mb-8">
        <img 
          src="../assets/connectlist-beta-logo.png" 
          alt="Connectlist Beta" 
          class="h-8"
        />
      </div>
      <h1 class="text-3xl md:text-4xl font-bold mb-4">Welcome</h1>
      <p class="text-gray-600 mb-8">After a few steps, you're ready to list.<br>Enter your information and join us.</p>
      
      <form @submit.prevent="handleLogin">
        <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
          {{ error }}
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Email</label>
          <input type="email" v-model="email" placeholder="Enter your email" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Password</label>
          <input type="password" v-model="password" placeholder="Enter your password" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6 flex items-center justify-between">
          <label class="flex items-center">
            <input type="checkbox" v-model="rememberMe" class="mr-2">
            Remember me 30 days
          </label>
          <router-link to="/forgot-password" class="text-primary hover:text-primary/80">
            Forgot your password?
          </router-link>
        </div>
        
        <button type="submit" class="w-full bg-primary text-white py-3 px-6 rounded-lg font-medium hover:bg-primary/90 transition-colors">
          Login
        </button>
      </form>
      
      <div class="mt-6 text-center">
        Don't have an account already? 
        <router-link to="/register" class="text-primary hover:text-primary/80 ml-1">
          Sign up
        </router-link>
      </div>
    </div>
    
    <div class="hidden md:flex flex-1 bg-cover bg-center items-center justify-center p-8 text-white text-center"
         style="background-image: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.5)), url('https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80')">
      <h2 class="text-3xl md:text-4xl font-semibold drop-shadow-lg">
        Socialize With Lists,<br>Get Information,<br>Socializing.
      </h2>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const error = ref('')
const router = useRouter()

const handleLogin = async () => {
  error.value = ''

  try {
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (signInError) throw signInError

    router.push('/')
  } catch (err: any) {
    console.error('Error:', err?.message || 'An error occurred')
    error.value = err?.message || 'An error occurred during login'
  }
}
</script>