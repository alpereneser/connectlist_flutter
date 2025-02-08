<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Game details content -->
      <div v-if="game" class="bg-white shadow rounded-lg overflow-hidden">
        <!-- Game Header -->
        <div class="relative h-96">
          <img :src="game.background_image" class="w-full h-full object-cover" :alt="game.name">
          <div class="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black to-transparent">
            <h1 class="text-4xl font-bold text-white">{{ game.name }}</h1>
            <p class="text-gray-300 mt-2">{{ game.released }} • {{ game.developers?.map(d => d.name).join(', ') }}</p>
          </div>
        </div>

        <!-- Game Content -->
        <div class="p-6">
          <!-- Actions -->
          <div class="flex space-x-4 mb-6">
            <button class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark">
              Add to List
            </button>
            <button class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200">
              Who Added List
            </button>
          </div>

          <!-- Overview -->
          <div class="mb-8">
            <h2 class="text-2xl font-bold mb-4">About</h2>
            <p class="text-gray-600 whitespace-pre-line">{{ game.description_raw }}</p>
          </div>

          <!-- Screenshots -->
          <div class="mb-8">
            <h2 class="text-2xl font-bold mb-4">Screenshots</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <img v-for="(screenshot, index) in game.screenshots" 
                   :key="index"
                   :src="screenshot.image"
                   class="w-full h-48 object-cover rounded-lg"
                   :alt="'Screenshot ' + (index + 1)">
            </div>
          </div>

          <!-- Details -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 class="text-lg font-semibold mb-2">Game Details</h3>
              <dl class="space-y-2">
                <div class="flex">
                  <dt class="w-32 text-gray-500">Platforms</dt>
                  <dd>{{ game.platforms?.map(p => p.platform.name).join(', ') }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Release Date</dt>
                  <dd>{{ game.released }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Publisher</dt>
                  <dd>{{ game.publishers?.map(p => p.name).join(', ') }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Age Rating</dt>
                  <dd>{{ game.esrb_rating?.name || 'Not rated' }}</dd>
                </div>
              </dl>
            </div>
            <div>
              <h3 class="text-lg font-semibold mb-2">Features</h3>
              <div class="flex flex-wrap gap-2">
                <span v-for="tag in game.tags" 
                      :key="tag.id"
                      class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm">
                  {{ tag.name }}
                </span>
              </div>
            </div>
          </div>

          <!-- System Requirements -->
          <div class="mt-8" v-if="game.pc_requirements">
            <h2 class="text-2xl font-bold mb-4">System Requirements</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 class="text-lg font-semibold mb-2">Minimum</h3>
                <div class="prose prose-sm text-gray-600" v-html="game.pc_requirements.minimum"></div>
              </div>
              <div v-if="game.pc_requirements.recommended">
                <h3 class="text-lg font-semibold mb-2">Recommended</h3>
                <div class="prose prose-sm text-gray-600" v-html="game.pc_requirements.recommended"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-else class="flex justify-center items-center h-96">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    </main>
    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { contentService } from '../services/content'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'

const route = useRoute()
const game = ref(null)

onMounted(async () => {
  try {
    const gameId = route.params.id
    const response = await contentService.getGameDetails(gameId)
    game.value = response
  } catch (error) {
    console.error('Error fetching game details:', error)
  }
})
</script>
