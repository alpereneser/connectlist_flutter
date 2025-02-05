<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhMonitorPlay, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Series = Database['public']['Tables']['series']['Insert']

const series = ref<Database['public']['Tables']['series']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newSeries = ref<Series>({
  title: '',
  original_title: '',
  tagline: '',
  overview: '',
  first_air_date: null,
  last_air_date: null,
  number_of_seasons: null,
  number_of_episodes: null,
  episode_runtime: [],
  genres: [],
  poster_path: '',
  backdrop_path: '',
  tmdb_id: null,
  imdb_id: '',
  status: 'draft'
})

const resetForm = () => {
  newSeries.value = {
    title: '',
    original_title: '',
    tagline: '',
    overview: '',
    first_air_date: null,
    last_air_date: null,
    number_of_seasons: null,
    number_of_episodes: null,
    episode_runtime: [],
    genres: [],
    poster_path: '',
    backdrop_path: '',
    tmdb_id: null,
    imdb_id: '',
    status: 'draft'
  }
}

const handleSubmit = async () => {
  try {
    const { error: insertError } = await supabase
      .from('series')
      .insert(newSeries.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadSeries()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadSeries = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('series')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    series.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadSeries()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhMonitorPlay :size="28" weight="bold" />
          TV Series
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Series
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage TV series and their details</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Series Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                First Air Date
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-if="isLoading">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                Loading series...
              </td>
            </tr>
            <tr v-else-if="series.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No series found
              </td>
            </tr>
            <tr v-for="show in series" :key="show.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="show.poster_path"
                    :src="show.poster_path"
                    :alt="show.title"
                    class="w-10 h-10 rounded object-cover"
                  />
                  <div v-else class="w-10 h-10 bg-gray-200 rounded flex items-center justify-center">
                    <PhMonitorPlay :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ show.title }}
                    </div>
                    <div v-if="show.original_title && show.original_title !== show.title" class="text-sm text-gray-500">
                      {{ show.original_title }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ show.first_air_date ? new Date(show.first_air_date).toLocaleDateString() : 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': show.status === 'published',
                    'bg-yellow-100 text-yellow-800': show.status === 'draft',
                    'bg-gray-100 text-gray-800': show.status === 'archived'
                  }">
                  {{ show.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit series"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete series"
                  >
                    <PhTrash :size="20" weight="bold" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add Series Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New TV Series</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Title *</label>
            <input
              v-model="newSeries.title"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Original Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Original Title</label>
            <input
              v-model="newSeries.original_title"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Tagline -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Tagline</label>
            <input
              v-model="newSeries.tagline"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Overview -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Overview</label>
            <textarea
              v-model="newSeries.overview"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- First Air Date -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">First Air Date</label>
            <input
              v-model="newSeries.first_air_date"
              type="date"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Number of Seasons -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Number of Seasons</label>
            <input
              v-model="newSeries.number_of_seasons"
              type="number"
              min="1"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Number of Episodes -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Number of Episodes</label>
            <input
              v-model="newSeries.number_of_episodes"
              type="number"
              min="1"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Poster Path -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Poster URL</label>
            <input
              v-model="newSeries.poster_path"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newSeries.status"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <!-- Form Actions -->
          <div class="flex justify-end gap-4 pt-4 border-t border-gray-200">
            <button
              type="button"
              @click="isModalOpen = false"
              class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-4 py-2 text-white bg-primary rounded-lg hover:bg-primary/90"
            >
              Add Series
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>