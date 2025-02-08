<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Movie details content -->
      <div v-if="loading" class="text-center py-8">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        <p class="mt-2 text-sm text-gray-500">Loading movie details...</p>
      </div>
      <div v-else-if="error" class="text-center py-8">
        <p class="text-red-500">{{ error }}</p>
      </div>
      <div v-else class="bg-white shadow rounded-lg overflow-hidden">
        <!-- Movie content here -->
        <div class="relative h-96">
          <img 
            :src="movie.backdrop_path ? `https://image.tmdb.org/t/p/original${movie.backdrop_path}` : '/placeholder-backdrop.jpg'" 
            class="w-full h-full object-cover" 
            :alt="movie.title"
          >
          <div class="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black to-transparent">
            <h1 class="text-4xl font-bold text-white">{{ movie.title }}</h1>
            <p class="text-gray-300 mt-2">{{ movie.release_date }} • {{ movie.runtime }} min</p>
          </div>
        </div>

        <!-- Movie Content -->
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
            <h2 class="text-2xl font-bold mb-4">Overview</h2>
            <p class="text-gray-600">{{ movie.overview }}</p>
          </div>

          <!-- Cast -->
          <div class="mb-8">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-2xl font-bold">Cast</h2>
              <button 
                v-if="movie.credits?.cast?.length > initialCastCount"
                @click="showAllCast = !showAllCast"
                class="text-primary hover:text-primary-dark text-sm font-medium transition-colors"
              >
                {{ showAllCast ? 'Show Less' : 'Show More' }}
              </button>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              <div 
                v-for="actor in displayedCast" 
                :key="actor.id" 
                class="text-center cursor-pointer hover:opacity-90 transition-opacity"
                @click="router.push(`/people/${actor.id}`)"
              >
                <div class="relative">
                  <img 
                    :src="actor.profile_path ? `https://image.tmdb.org/t/p/w185${actor.profile_path}` : '/placeholder-profile.jpg'" 
                    class="w-32 h-32 rounded-full mx-auto object-cover" 
                    :alt="actor.name"
                  >
                  <div class="absolute inset-0 bg-black opacity-0 hover:opacity-20 rounded-full transition-opacity"></div>
                </div>
                <p class="mt-2 font-medium text-gray-900">{{ actor.name }}</p>
                <p class="text-sm text-gray-500">{{ actor.character }}</p>
              </div>
            </div>
          </div>

          <!-- Details -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 class="text-lg font-semibold mb-2">Details</h3>
              <dl class="space-y-2">
                <div class="flex">
                  <dt class="w-32 text-gray-500">Status</dt>
                  <dd>{{ movie.status }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Original Language</dt>
                  <dd>{{ movie.original_language }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Budget</dt>
                  <dd>${{ formatNumber(movie.budget) }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Revenue</dt>
                  <dd>${{ formatNumber(movie.revenue) }}</dd>
                </div>
              </dl>
            </div>
            <div>
              <h3 class="text-lg font-semibold mb-2">Production</h3>
              <div class="space-y-4">
                <div v-for="company in movie.production_companies" :key="company.id" class="flex items-center">
                  <img v-if="company.logo_path" :src="company.logo_path" class="h-8 mr-2" :alt="company.name">
                  <span>{{ company.name }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { contentService } from '../services/content'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'

const route = useRoute()
const router = useRouter()
const movie = ref<any>(null)
const loading = ref(true)
const error = ref<string | null>(null)

// Cast display state
const initialCastCount = 6
const showAllCast = ref(false)

// Computed property for displayed cast members
const displayedCast = computed(() => {
  if (!movie.value?.credits?.cast) return []
  return showAllCast.value 
    ? movie.value.credits.cast 
    : movie.value.credits.cast.slice(0, initialCastCount)
})

const loadMovieDetails = async () => {
  loading.value = true
  error.value = null
  try {
    const movieId = route.params.id as string
    const data = await contentService.getMovieDetails(movieId)
    movie.value = data
  } catch (err: any) {
    console.error('Error fetching movie details:', err)
    error.value = err.message || 'Failed to load movie details'
  } finally {
    loading.value = false
  }
}

const formatNumber = (num: number) => {
  return new Intl.NumberFormat('en-US').format(num)
}

onMounted(() => {
  loadMovieDetails()
})
</script>
