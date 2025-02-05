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
      <h1 class="text-3xl md:text-4xl font-bold mb-4">Create Account</h1>
      <p class="text-gray-600 mb-8">Join our community and start creating your lists.</p>
      
      <form @submit.prevent="handleRegister" class="space-y-6">
        <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
          {{ error }}
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Full Name</label>
          <input type="text" v-model="fullName" placeholder="Enter your full name" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Username</label>
          <input type="text" v-model="username" placeholder="Choose a username" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Email</label>
          <input type="email" v-model="email" placeholder="Enter your email" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Password</label>
          <input type="password" v-model="password" placeholder="Create a password" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Confirm Password</label>
          <input type="password" v-model="passwordConfirm" placeholder="Confirm your password" required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
          <p v-if="passwordMismatch" class="mt-2 text-red-500 text-sm">
            Passwords do not match
          </p>
        </div>
        
        <div class="mb-6">
          <label class="block mb-2 text-gray-700">Referral Code</label>
          <input type="text" v-model="referralCode" placeholder="Enter referral code if you have one"
            required
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            :class="{'border-red-500': referralCodeError}">
          <p v-if="referralCodeError" class="mt-2 text-red-500 text-sm">
            {{ referralCodeError }}
          </p>
        </div>
        
        <button type="submit" class="w-full bg-primary text-white py-3 px-6 rounded-lg font-medium hover:bg-primary/90 transition-colors">
          Create Account
        </button>
      </form>
      
      <div class="mt-6 text-center">
        Already have an account? 
        <router-link to="/login" class="text-primary hover:text-primary/80 ml-1">
          Login
        </router-link>
      </div>
    </div>
    
    <div class="hidden md:flex flex-1 bg-cover bg-center items-center justify-center p-8 text-white text-center"
         style="background-image: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.5)), url('https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?auto=format&fit=crop&q=80')">
      <h2 class="text-3xl md:text-4xl font-semibold drop-shadow-lg">
        Join Our Community<br>Share Your Lists<br>Connect with Others
      </h2>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router' 

const username = ref('')
const fullName = ref('')
const email = ref('')
const password = ref('')
const passwordConfirm = ref('')
const referralCode = ref('')
const error = ref('')
const referralCodeError = ref('')
const router = useRouter()

const passwordMismatch = computed(() => {
  return password.value && passwordConfirm.value && password.value !== passwordConfirm.value
})

const validateReferralCode = async () => {
  const { data, error: refError } = await supabase
    .from('referral_codes')
    .select('*')
    .eq('code', referralCode.value)
    .maybeSingle()

  if (refError || !data) {
    referralCodeError.value = 'Invalid referral code'
    return false
  }

  if (data.used_by) {
    referralCodeError.value = 'This referral code has already been used'
    return false
  }

  return true
}

const checkUsername = async () => {
  const { data, error: userError } = await supabase
    .from('profiles')
    .select('id')
    .eq('username', username.value)
    .maybeSingle()

  if (data) {
    error.value = 'Username is already taken'
    return false
  }

  if (userError) {
    console.error('Error checking username:', userError)
    error.value = 'Error checking username availability'
    return false
  }

  return true
}

const handleRegister = async () => {
  error.value = ''
  referralCodeError.value = ''

  if (passwordMismatch.value) {
    return
  }

  try {
    // Validate username and referral code
    const [isUsernameAvailable, isReferralCodeValid] = await Promise.all([
      checkUsername(),
      validateReferralCode()
    ])

    if (!isUsernameAvailable || !isReferralCodeValid) {
      return
    }

    const { error: signUpError } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
      options: {
        emailRedirectTo: `${window.location.origin}/verify-email`,
        data: {
          full_name: fullName.value,
          username: username.value,
          referral_code: referralCode.value
        }
      }
    })

    if (signUpError) throw signUpError

    // Redirect to email verification page after successful registration
    router.push('/verify-email')
  } catch (err: any) {
    console.error('Error:', err?.message || 'An error occurred')
    error.value = err?.message || 'An error occurred during registration'
  }
}
</script>