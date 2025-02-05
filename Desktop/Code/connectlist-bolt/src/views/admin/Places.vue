<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhMapPin, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Place = Database['public']['Tables']['places']['Insert']

const places = ref<Database['public']['Tables']['places']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newPlace = ref<Place>({
  name: '',
  description: '',
  address: '',
  city: '',
  country: '',
  latitude: null,
  longitude: null,
  categories: [],
  website: '',
  phone: '',
  photos: [],
  google_place_id: '',
  status: 'draft'
})

const resetForm = () => {
  newPlace.value = {
    name: '',
    description: '',
    address: '',
    city: '',
    country: '',
    latitude: null,
    longitude: null,
    categories: [],
    website: '',
    phone: '',
    photos: [],
    google_place_id: '',
    status: 'draft'
  }
}

const handleSubmit = async () => {
  try {
    const { error: insertError } = await supabase
      .from('places')
      .insert(newPlace.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadPlaces()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadPlaces = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('places')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    places.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadPlaces()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhMapPin :size="28" weight="bold" />
          Places
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Place
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage locations and venues</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Places Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Location
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
                Loading places...
              </td>
            </tr>
            <tr v-else-if="places.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No places found
              </td>
            </tr>
            <tr v-for="place in places" :key="place.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="place.photos?.[0]"
                    :src="place.photos[0]"
                    :alt="place.name"
                    class="w-10 h-10 rounded object-cover"
                  />
                  <div v-else class="w-10 h-10 bg-gray-200 rounded flex items-center justify-center">
                    <PhMapPin :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ place.name }}
                    </div>
                    <div class="text-sm text-gray-500">
                      {{ place.categories?.join(', ') }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ [place.city, place.country].filter(Boolean).join(', ') || 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': place.status === 'published',
                    'bg-yellow-100 text-yellow-800': place.status === 'draft',
                    'bg-gray-100 text-gray-800': place.status === 'archived'
                  }">
                  {{ place.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit place"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete place"
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

    <!-- Add Place Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New Place</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Name *</label>
            <input
              v-model="newPlace.name"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
            <textarea
              v-model="newPlace.description"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- Address -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Address</label>
            <input
              v-model="newPlace.address"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- City -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">City</label>
            <input
              v-model="newPlace.city"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Country -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Country</label>
            <input
              v-model="newPlace.country"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Coordinates -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Latitude</label>
              <input
                v-model="newPlace.latitude"
                type="number"
                step="any"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Longitude</label>
              <input
                v-model="newPlace.longitude"
                type="number"
                step="any"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
              >
            </div>
          </div>

          <!-- Website -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Website</label>
            <input
              v-model="newPlace.website"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Phone -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Phone</label>
            <input
              v-model="newPlace.phone"
              type="tel"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Google Place ID -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Google Place ID</label>
            <input
              v-model="newPlace.google_place_id"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newPlace.status"
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
              Add Place
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>