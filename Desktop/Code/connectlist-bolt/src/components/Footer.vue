<script setup lang="ts">
import { ref } from 'vue'

const currentLanguage = ref('English')
const languages = ['English', 'Türkçe']
const isLanguageDropdownOpen = ref(false)

const changeLanguage = (lang: string) => {
  currentLanguage.value = lang
  isLanguageDropdownOpen.value = false
}
</script>

<template>
  <footer class="bg-white border-t border-gray-200 fixed bottom-0 left-0 right-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-[35px]">
        <!-- Copyright -->
        <div class="text-xs text-gray-500">
          © 2025 Connectlist
        </div>

        <!-- Language Selector -->
        <div class="relative">
          <button 
            @click="isLanguageDropdownOpen = !isLanguageDropdownOpen"
            class="text-xs text-gray-500 hover:text-gray-700 flex items-center"
          >
            {{ currentLanguage }}
          </button>
          
          <!-- Language Dropdown -->
          <div 
            v-if="isLanguageDropdownOpen"
            class="absolute bottom-full right-0 mb-2 bg-white rounded-lg shadow-lg py-1 border border-gray-200"
          >
            <button
              v-for="lang in languages"
              :key="lang"
              @click="changeLanguage(lang)"
              class="block w-full px-4 py-2 text-xs text-left text-gray-700 hover:bg-gray-100"
              :class="{ 'text-primary': currentLanguage === lang }"
            >
              {{ lang }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </footer>
</template>