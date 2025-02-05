<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhMusicNote, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Music = Database['public']['Tables']['musics']['Insert']

const musics = ref<Database['public']['Tables']['musics']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newMusic = ref<Music>({
  title: '',
  album: '',
  release_date: null,
  duration: null,
  genres: [],
  lyrics: '',
  cover_art_url: '',
  spotify_id: '',
  apple_music_id: '',
  status: 'draft'
})

const resetForm = () => {
  newMusic.value = {
    title: '',
    album: '',
    release_date: null,
    duration: null,
    genres: [],
    lyrics: '',
    cover_art_url: '',
    spotify_id: '',
    apple_music_id: '',
    status: 'draft'
  }
}

const handleSubmit = async () => {
  try {
    const { error: insertError } = await supabase
      .from('musics')
      .insert(newMusic.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadMusics()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadMusics = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('musics')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    musics.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadMusics()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhMusicNote :size="28" weight="bold" />
          Music
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Music
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage music tracks and albums</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Music Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Album
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
                Loading music...
              </td>
            </tr>
            <tr v-else-if="musics.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No music found
              </td>
            </tr>
            <tr v-for="music in musics" :key="music.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="music.cover_art_url"
                    :src="music.cover_art_url"
                    :alt="music.title"
                    class="w-10 h-10 rounded object-cover"
                  />
                  <div v-else class="w-10 h-10 bg-gray-200 rounded flex items-center justify-center">
                    <PhMusicNote :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ music.title }}
                    </div>
                    <div class="text-sm text-gray-500">
                      {{ music.duration ? `${Math.floor(music.duration.minutes)}:${String(music.duration.seconds).padStart(2, '0')}` : 'N/A' }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ music.album || 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': music.status === 'published',
                    'bg-yellow-100 text-yellow-800': music.status === 'draft',
                    'bg-gray-100 text-gray-800': music.status === 'archived'
                  }">
                  {{ music.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit music"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete music"
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

    <!-- Add Music Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New Music</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Title *</label>
            <input
              v-model="newMusic.title"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Album -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Album</label>
            <input
              v-model="newMusic.album"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Release Date -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Release Date</label>
            <input
              v-model="newMusic.release_date"
              type="date"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Lyrics -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Lyrics</label>
            <textarea
              v-model="newMusic.lyrics"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- Cover Art URL -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Cover Art URL</label>
            <input
              v-model="newMusic.cover_art_url"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Spotify ID -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Spotify ID</label>
            <input
              v-model="newMusic.spotify_id"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Apple Music ID -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Apple Music ID</label>
            <input
              v-model="newMusic.apple_music_id"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newMusic.status"
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
              Add Music
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>