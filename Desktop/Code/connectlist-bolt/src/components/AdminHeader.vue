<script setup lang="ts">
import { useRouter } from 'vue-router'
import { PhHouse } from '@phosphor-icons/vue'

const router = useRouter()

const goToHome = () => {
  router.push('/')
}
</script>

<template>
  <header class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Logo and Title -->
        <div class="flex items-center gap-3">
          <img 
            src="../assets/connectlist-beta-logo.png" 
            alt="Connectlist Beta" 
            class="h-5"
          />
          <div class="h-6 w-px bg-gray-200"></div>
          <span class="text-gray-600 font-medium">Management</span>
        </div>

        <!-- Return to Home -->
        <button 
          @click="goToHome"
          class="flex items-center gap-2 text-gray-600 hover:text-primary px-4 py-2 rounded-lg hover:bg-gray-50"
        >
          <PhHouse :size="20" weight="bold" />
          <span class="font-medium">Return to Connectlist</span>
        </button>
      </div>
    </div>
  </header>
</template>