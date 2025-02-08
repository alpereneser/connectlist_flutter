<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Person details content -->
      <div v-if="person" class="bg-white shadow rounded-lg overflow-hidden">
        <!-- Person Header -->
        <div class="md:flex">
          <!-- Profile Image -->
          <div class="md:w-1/3 p-6">
            <img 
              :src="person.profile_path ? `https://image.tmdb.org/t/p/w500${person.profile_path}` : '/placeholder-profile.jpg'" 
              class="w-64 h-64 rounded-lg shadow-lg mx-auto object-cover" 
              :alt="person.name"
            >
            <!-- Actions -->
            <div class="mt-6 space-y-4">
              <button class="w-full px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark">
                Add to List
              </button>
              <button class="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200">
                Who Added List
              </button>
            </div>
          </div>

          <!-- Person Info -->
          <div class="md:w-2/3 p-6">
            <h1 class="text-3xl font-bold text-gray-900">{{ person.name }}</h1>
            
            <!-- Personal Info -->
            <div class="mt-4 grid grid-cols-2 gap-4">
              <div>
                <p class="text-gray-500">Born</p>
                <p class="font-medium">{{ person.birthday }}</p>
              </div>
              <div v-if="person.deathday">
                <p class="text-gray-500">Died</p>
                <p class="font-medium">{{ person.deathday }}</p>
              </div>
              <div>
                <p class="text-gray-500">Place of Birth</p>
                <p class="font-medium">{{ person.place_of_birth }}</p>
              </div>
              <div>
                <p class="text-gray-500">Gender</p>
                <p class="font-medium">{{ formatGender(person.gender) }}</p>
              </div>
            </div>

            <!-- Biography -->
            <div class="mt-6">
              <h2 class="text-2xl font-bold mb-4">Biography</h2>
              <p class="text-gray-600 whitespace-pre-line">{{ person.biography }}</p>
            </div>
          </div>
        </div>

        <!-- Filmography -->
        <div class="p-6 border-t border-gray-200">
          <h2 class="text-2xl font-bold mb-6">Filmography</h2>
          
          <!-- Movies -->
          <div class="mb-8">
            <h3 class="text-xl font-semibold mb-4">Movies</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              <div 
                v-for="movie in sortedMovies" 
                :key="movie.id"
                class="group cursor-pointer"
                @click="router.push(`/movies/${movie.id}`)"
              >
                <div class="relative aspect-[2/3] mb-2">
                  <img 
                    :src="movie.poster_path ? `https://image.tmdb.org/t/p/w342${movie.poster_path}` : '/placeholder-poster.jpg'" 
                    class="w-full h-full object-cover rounded-lg" 
                    :alt="movie.title"
                  >
                  <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-opacity rounded-lg flex items-center justify-center">
                    <span class="text-white opacity-0 group-hover:opacity-100 transition-opacity">View Details</span>
                  </div>
                </div>
                <p class="font-medium text-sm">{{ movie.title }}</p>
                <p class="text-sm text-gray-500">{{ movie.character }}</p>
                <p class="text-xs text-gray-400">{{ formatYear(movie.release_date) }}</p>
              </div>
            </div>
          </div>

          <!-- TV Shows -->
          <div>
            <h3 class="text-xl font-semibold mb-4">TV Shows</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              <div 
                v-for="show in sortedTVShows" 
                :key="show.id"
                class="group cursor-pointer"
                @click="router.push(`/series/${show.id}`)"
              >
                <div class="relative aspect-[2/3] mb-2">
                  <img 
                    :src="show.poster_path ? `https://image.tmdb.org/t/p/w342${show.poster_path}` : '/placeholder-poster.jpg'" 
                    class="w-full h-full object-cover rounded-lg" 
                    :alt="show.name"
                  >
                  <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-opacity rounded-lg flex items-center justify-center">
                    <span class="text-white opacity-0 group-hover:opacity-100 transition-opacity">View Details</span>
                  </div>
                </div>
                <p class="font-medium text-sm">{{ show.name }}</p>
                <p class="text-sm text-gray-500">{{ show.character }}</p>
                <p class="text-xs text-gray-400">
                  {{ formatYear(show.first_air_date) }}
                  {{ show.episode_count ? `• ${show.episode_count} episodes` : '' }}
                </p>
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
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { contentService } from '../services/content'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'

const route = useRoute()
const router = useRouter()
const person = ref<any>(null)

// Sort movies by release date (newest first)
const sortedMovies = computed(() => {
  return [...(person.value?.movie_credits?.cast || [])]
    .sort((a, b) => {
      if (!a.release_date) return 1
      if (!b.release_date) return -1
      return new Date(b.release_date).getTime() - new Date(a.release_date).getTime()
    })
})

// Sort TV shows by first air date (newest first)
const sortedTVShows = computed(() => {
  return [...(person.value?.tv_credits?.cast || [])]
    .sort((a, b) => {
      if (!a.first_air_date) return 1
      if (!b.first_air_date) return -1
      return new Date(b.first_air_date).getTime() - new Date(a.first_air_date).getTime()
    })
})

const formatYear = (date: string) => {
  if (!date) return 'TBA'
  return new Date(date).getFullYear()
}

const loadPersonDetails = async () => {
  try {
    const personId = route.params.id
    const response = await contentService.getPersonDetails(personId)
    person.value = response
  } catch (error) {
    console.error('Error fetching person details:', error)
  }
}

onMounted(() => {
  loadPersonDetails()
})

const formatGender = (gender: number) => {
  switch (gender) {
    case 1: return 'Female'
    case 2: return 'Male'
    default: return 'Not specified'
  }
}
</script>
