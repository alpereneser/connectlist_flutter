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
      <h1 class="text-3xl md:text-4xl font-bold mb-4">Check Your Email</h1>
      <p class="text-gray-600 mb-8">
        We've sent you a verification email. Please check your inbox and click the verification link to complete your registration.
      </p>
      
      <button @click="openEmailApp" class="w-full bg-primary text-white py-3 px-6 rounded-lg font-medium hover:bg-primary/90 transition-colors mb-4">
        Open Email App
      </button>
      
      <div class="text-center">
        <p class="text-gray-600 mb-4">
          After verifying your email, you can proceed to login.
        </p>
        <router-link to="/login" class="text-primary hover:text-primary/80 font-medium">
          Go to Login Page
        </router-link>
      </div>
    </div>
    
    <div class="hidden md:flex flex-1 bg-cover bg-center items-center justify-center p-8 text-white text-center"
         style="background-image: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.5)), url('https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&q=80')">
      <h2 class="text-3xl md:text-4xl font-semibold drop-shadow-lg">
        Check Your Email!<br>Complete Verification<br>Start Your Journey
      </h2>
    </div>
  </div>
</template>

<script setup lang="ts">
const openEmailApp = () => {
  // List of common email clients
  const mailToUrl = 'mailto:'
  
  // Try to open the default email client
  window.location.href = mailToUrl
  
  // Fallback for mobile devices
  if (/iPhone|iPad|iPod|Android/i.test(navigator.userAgent)) {
    window.open(mailToUrl)
  }
}
</script>