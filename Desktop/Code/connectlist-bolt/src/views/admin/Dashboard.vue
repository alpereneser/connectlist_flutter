<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { 
  PhUsers, PhFilmSlate, PhMonitorPlay, PhPerson, PhGameController, 
  PhBrowser, PhMusicNote, PhMapPin, PhBook, PhBuildings,
  PhChartBar, PhArrowRight
} from '@phosphor-icons/vue'

const categories = [
  {
    name: 'Users',
    path: '/admin/users',
    icon: PhUsers,
    color: 'bg-blue-500',
    description: 'Manage user accounts and permissions'
  },
  {
    name: 'Movies',
    path: '/admin/movies',
    icon: PhFilmSlate,
    color: 'bg-red-500',
    description: 'Manage movies and film content'
  },
  {
    name: 'TV Series',
    path: '/admin/series',
    icon: PhMonitorPlay,
    color: 'bg-purple-500',
    description: 'Manage TV series and shows'
  },
  {
    name: 'People',
    path: '/admin/people',
    icon: PhPerson,
    color: 'bg-green-500',
    description: 'Manage people and their roles'
  },
  {
    name: 'Games',
    path: '/admin/games',
    icon: PhGameController,
    color: 'bg-indigo-500',
    description: 'Manage games and gaming content'
  },
  {
    name: 'Software',
    path: '/admin/softwares',
    icon: PhBrowser,
    color: 'bg-cyan-500',
    description: 'Manage software applications'
  },
  {
    name: 'Music',
    path: '/admin/musics',
    icon: PhMusicNote,
    color: 'bg-pink-500',
    description: 'Manage music tracks and albums'
  },
  {
    name: 'Places',
    path: '/admin/places',
    icon: PhMapPin,
    color: 'bg-amber-500',
    description: 'Manage locations and venues'
  },
  {
    name: 'Books',
    path: '/admin/books',
    icon: PhBook,
    color: 'bg-teal-500',
    description: 'Manage books and publications'
  },
  {
    name: 'Companies',
    path: '/admin/companies',
    icon: PhBuildings,
    color: 'bg-orange-500',
    description: 'Manage companies and organizations'
  }
]

const stats = ref({
  users: 0,
  movies: 0,
  series: 0,
  people: 0,
  games: 0,
  softwares: 0,
  musics: 0,
  places: 0,
  books: 0,
  companies: 0
})

const isLoading = ref(true)
const error = ref('')

const loadStats = async () => {
  try {
    // Load counts for each category
    const promises = [
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('movies').select('id', { count: 'exact', head: true }),
      supabase.from('series').select('id', { count: 'exact', head: true }),
      supabase.from('people').select('id', { count: 'exact', head: true }),
      supabase.from('games').select('id', { count: 'exact', head: true }),
      supabase.from('softwares').select('id', { count: 'exact', head: true }),
      supabase.from('musics').select('id', { count: 'exact', head: true }),
      supabase.from('places').select('id', { count: 'exact', head: true }),
      supabase.from('books').select('id', { count: 'exact', head: true }),
      supabase.from('companies').select('id', { count: 'exact', head: true })
    ]

    const results = await Promise.all(promises)

    stats.value = {
      users: results[0].count || 0,
      movies: results[1].count || 0,
      series: results[2].count || 0,
      people: results[3].count || 0,
      games: results[4].count || 0,
      softwares: results[5].count || 0,
      musics: results[6].count || 0,
      places: results[7].count || 0,
      books: results[8].count || 0,
      companies: results[9].count || 0
    }
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadStats()
})
</script>

<template>
  <div>
    <!-- Dashboard Header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
        <PhChartBar :size="28" weight="bold" />
        Dashboard
      </h1>
      <p class="text-gray-600 mt-1">Overview of all content categories</p>
    </div>
    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="text-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
      <p class="mt-4 text-gray-600">Loading statistics...</p>
    </div>

    <!-- Category Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <router-link
        v-for="category in categories"
        :key="category.name"
        :to="category.path"
        class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden group"
      >
        <div class="p-6">
          <!-- Icon and Count -->
          <div class="flex items-start justify-between mb-4">
            <div 
              class="p-3 rounded-lg"
              :class="category.color"
            >
              <component 
                :is="category.icon" 
                :size="24" 
                weight="bold"
                class="text-white"
              />
            </div>
            <span class="text-2xl font-bold text-gray-900">
              {{ stats[category.name.toLowerCase() as keyof typeof stats]?.toLocaleString() ?? '0' }}
            </span>
          </div>

          <!-- Category Info -->
          <h3 class="text-lg font-semibold text-gray-900 mb-2 flex items-center gap-2">
            {{ category.name }}
            <PhArrowRight 
              :size="20" 
              class="text-gray-400 transition-transform duration-200 group-hover:translate-x-1" 
            />
          </h3>
          <p class="text-gray-600 text-sm">
            {{ category.description }}
          </p>
        </div>
      </router-link>
    </div>
  </div>
</template>