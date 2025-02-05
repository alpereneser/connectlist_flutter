<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-[51px]">
      <h1 class="text-2xl font-bold text-gray-900">Welcome to Connectlist</h1>
      <p class="text-gray-600">You are logged in!</p>
    </main>
    <Footer />
  </div>
</template>

<script setup lang="ts">
import Header from '../components/Header.vue'
import Footer from '../components/Footer.vue'
</script>