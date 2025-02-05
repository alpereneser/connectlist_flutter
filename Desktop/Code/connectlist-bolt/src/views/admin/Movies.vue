<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhFilmSlate, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Movie = Database['public']['Tables']['movies']['Insert']

const movies = ref<Database['public']['Tables']['movies']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newMovie = ref<Movie>({
  title: '',
  original_title: '',
  tagline: '',
  overview: '',
  release_date: null,
  runtime: null,
  budget: null,
  revenue: null,
  genres: [],
  poster_path: '',
  backdrop_path: '',
  tmdb_id: null,
  imdb_id: '',
  status: 'draft'
})

const resetForm = () => {
  newMovie.value = {
    title: '',
    original_title: '',
    tagline: '',
    overview: '',
    release_date: null,
    runtime: null,
    budget: null,
    revenue: null,
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
      .from('movies')
      .insert(newMovie.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadMovies()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadMovies = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('movies')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    movies.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadMovies()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhFilmSlate :size="28" weight="bold" />
          Movies
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Movie
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage movies and their details</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Movies Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Release Date
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
                Loading movies...
              </td>
            </tr>
            <tr v-else-if="movies.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No movies found
              </td>
            </tr>
            <tr v-for="movie in movies" :key="movie.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="movie.poster_path"
                    :src="movie.poster_path"
                    :alt="movie.title"
                    class="w-10 h-10 rounded object-cover"
                  />
                  <div v-else class="w-10 h-10 bg-gray-200 rounded flex items-center justify-center">
                    <PhFilmSlate :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ movie.title }}
                    </div>
                    <div v-if="movie.original_title && movie.original_title !== movie.title" class="text-sm text-gray-500">
                      {{ movie.original_title }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ movie.release_date ? new Date(movie.release_date).toLocaleDateString() : 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': movie.status === 'published',
                    'bg-yellow-100 text-yellow-800': movie.status === 'draft',
                    'bg-gray-100 text-gray-800': movie.status === 'archived'
                  }">
                  {{ movie.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit movie"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete movie"
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

    <!-- Add Movie Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New Movie</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Title *</label>
            <input
              v-model="newMovie.title"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Original Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Original Title</label>
            <input
              v-model="newMovie.original_title"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Tagline -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Tagline</label>
            <input
              v-model="newMovie.tagline"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Overview -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Overview</label>
            <textarea
              v-model="newMovie.overview"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- Release Date -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Release Date</label>
            <input
              v-model="newMovie.release_date"
              type="date"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Runtime -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Runtime (minutes)</label>
            <input
              v-model="newMovie.runtime"
              type="number"
              min="0"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Poster Path -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Poster URL</label>
            <input
              v-model="newMovie.poster_path"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newMovie.status"
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
              Add Movie
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>