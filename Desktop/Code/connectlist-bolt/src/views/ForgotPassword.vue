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
      <h1 class="text-3xl md:text-4xl font-bold mb-4">Reset Password</h1>
      <p class="text-gray-600 mb-8">Enter your email address and we'll send you instructions to reset your password.</p>
      
      <form @submit.prevent="handleForgotPassword">
        <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
          {{ error }}
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Email</label>
          <input type="email" v-model="email" placeholder="Enter your email" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <button type="submit" class="w-full bg-primary text-white py-3 px-6 rounded-lg font-medium hover:bg-primary/90 transition-colors">
          Send Reset Instructions
        </button>
      </form>
      
      <div class="mt-6 text-center">
        Remember your password? 
        <router-link to="/login" class="text-primary hover:text-primary/80 ml-1">
          Login
        </router-link>
      </div>
    </div>
    
    <div class="hidden md:flex flex-1 bg-cover bg-center items-center justify-center p-8 text-white text-center"
         style="background-image: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.5)), url('https://images.unsplash.com/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&q=80')">
      <h2 class="text-3xl md:text-4xl font-semibold drop-shadow-lg">
        Recover Your Account<br>Get Back to Listing<br>Stay Connected
      </h2>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const email = ref('')
const error = ref('')
const router = useRouter()

const handleForgotPassword = async () => {
  error.value = ''

  try {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      email.value,
      {
        redirectTo: `${window.location.origin}/reset-password`
      }
    )

    if (resetError) throw resetError

    alert('Password reset instructions have been sent to your email')
    router.push('/login')
  } catch (err: any) {
    console.error('Error:', err?.message || 'An error occurred')
    error.value = err?.message || 'An error occurred during password reset'
  }
}
</script>