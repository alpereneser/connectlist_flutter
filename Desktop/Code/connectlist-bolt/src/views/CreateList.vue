<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />

    <main class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <!-- Breadcrumbs -->
      <nav class="mb-8">
        <ol class="flex items-center space-x-2 text-sm text-gray-500">
          <li>
            <router-link to="/select-category" class="hover:text-gray-700">Categories</router-link>
          </li>
          <li>
            <i class="fas fa-chevron-right text-xs"></i>
          </li>
          <li class="font-medium text-gray-900 capitalize">{{ category }}</li>
        </ol>
      </nav>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Left Column - List Creation Form -->
        <div class="bg-white p-6 rounded-lg shadow-sm">
          <h2 class="text-2xl font-bold mb-6">Create New List</h2>
          
          <!-- List Title -->
          <div class="mb-6">
            <label for="title" class="block text-sm font-medium text-gray-700 mb-1">List Title</label>
            <input 
              type="text" 
              id="title" 
              v-model="listTitle"
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
              placeholder="Enter list title"
            >
          </div>

          <!-- List Description -->
          <div class="mb-6">
            <label for="description" class="block text-sm font-medium text-gray-700 mb-1">List Description</label>
            <textarea 
              id="description" 
              v-model="listDescription"
              rows="3"
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
              placeholder="Enter list description"
            ></textarea>
          </div>

          <!-- Search Input -->
          <div class="mb-6">
            <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search {{ category }}</label>
            <div class="relative">
              <input 
                type="text" 
                id="search" 
                v-model="searchQuery"
                @input="handleSearch"
                class="w-full px-4 py-2 pl-10 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                :placeholder="'Search ' + category"
              >
              <i class="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"></i>
            </div>
          </div>

          <!-- Search Results -->
          <div v-if="searchResults.length > 0" class="mb-6">
            <h3 class="text-sm font-medium text-gray-700 mb-2">Search Results</h3>
            <div class="space-y-2 max-h-60 overflow-y-auto">
              <div 
                v-for="item in searchResults" 
                :key="item.id"
                class="flex items-center p-2 border border-gray-200 rounded-md hover:bg-gray-50 cursor-pointer"
                @click="toggleItem(item)"
              >
                <input 
                  type="checkbox"
                  :checked="isItemSelected(item)"
                  @click.stop
                  @change="toggleItem(item)"
                  class="h-4 w-4 text-primary border-gray-300 rounded"
                >
                <img 
                  :src="getItemImage(item)"
                  :alt="getItemTitle(item)"
                  class="w-10 h-10 object-cover rounded ml-2"
                >
                <div class="ml-3">
                  <p class="text-sm font-medium text-gray-900">{{ getItemTitle(item) }}</p>
                  <p class="text-xs text-gray-500">{{ getItemSubtitle(item) }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Create Button -->
          <button 
            @click="createList"
            :disabled="!canCreateList"
            class="w-full bg-primary text-white py-2 px-4 rounded-md hover:bg-primary-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Create List
          </button>
        </div>

        <!-- Right Column - List Preview -->
        <div class="bg-white p-6 rounded-lg shadow-sm">
          <h2 class="text-2xl font-bold mb-6">List Preview</h2>
          
          <!-- List Info Preview -->
          <div class="mb-6 border-b border-gray-200 pb-6">
            <h3 class="text-xl font-semibold text-gray-900">
              {{ listTitle || 'Untitled List' }}
            </h3>
            <p class="mt-2 text-gray-600">
              {{ listDescription || 'No description provided' }}
            </p>
            <div class="mt-2 flex items-center text-sm text-gray-500">
              <i class="fas fa-layer-group mr-1"></i>
              <span class="capitalize">{{ category }}</span>
              <span class="mx-2">•</span>
              <span>{{ selectedItems.length }} items</span>
            </div>
          </div>

          <!-- Selected Items -->
          <div v-if="selectedItems.length > 0" class="space-y-4">
            <div 
              v-for="item in selectedItems" 
              :key="item.id"
              class="flex items-center p-3 border border-gray-200 rounded-lg"
            >
              <img 
                :src="getItemImage(item)"
                :alt="getItemTitle(item)"
                class="w-16 h-16 object-cover rounded"
              >
              <div class="ml-4">
                <h3 class="font-medium text-gray-900">{{ getItemTitle(item) }}</h3>
                <p class="text-sm text-gray-500">{{ getItemSubtitle(item) }}</p>
              </div>
              <button 
                @click="removeItem(item)"
                class="ml-auto text-gray-400 hover:text-red-500"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>

          <div 
            v-else 
            class="flex flex-col items-center justify-center h-64 text-gray-400"
          >
            <i class="fas fa-list text-4xl mb-2"></i>
            <p>No items selected</p>
          </div>
        </div>
      </div>
    </main>

    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { contentService } from '../services/content'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'

const route = useRoute()
const router = useRouter()
const category = computed(() => route.params.category as string)

// Form state
const listTitle = ref('')
const listDescription = ref('')
const searchQuery = ref('')
const searchResults = ref<any[]>([])
const selectedItems = ref<any[]>([])

// Debounce search
let searchTimeout: NodeJS.Timeout | null = null
const handleSearch = () => {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(async () => {
    if (searchQuery.value.length < 2) {
      searchResults.value = []
      return
    }
    try {
      const results = await contentService.search(searchQuery.value, category.value)
      searchResults.value = results?.results || []
    } catch (error) {
      console.error('Search error:', error)
      searchResults.value = []
    }
  }, 300)
}

// Helper functions for different content types
const getItemImage = (item: any) => {
  switch (category.value) {
    case 'movies':
      return item.poster_path ? `https://image.tmdb.org/t/p/w92${item.poster_path}` : '/placeholder-poster.jpg'
    case 'series':
      return item.poster_path ? `https://image.tmdb.org/t/p/w92${item.poster_path}` : '/placeholder-poster.jpg'
    case 'books':
      return item.volumeInfo?.imageLinks?.thumbnail || '/placeholder-book.jpg'
    case 'people':
      return item.profile_path ? `https://image.tmdb.org/t/p/w92${item.profile_path}` : '/placeholder-profile.jpg'
    case 'videos':
      return item.thumbnail || '/placeholder-video.jpg'
    default:
      return '/placeholder.jpg'
  }
}

const getItemTitle = (item: any) => {
  switch (category.value) {
    case 'movies':
      return item.title
    case 'series':
      return item.name
    case 'books':
      return item.volumeInfo?.title
    case 'people':
      return item.name
    case 'videos':
      return item.title
    default:
      return 'Unknown'
  }
}

const getItemSubtitle = (item: any) => {
  switch (category.value) {
    case 'movies':
      return item.release_date ? new Date(item.release_date).getFullYear() : 'Unknown year'
    case 'series':
      return item.first_air_date ? new Date(item.first_air_date).getFullYear() : 'Unknown year'
    case 'books':
      return item.volumeInfo?.authors?.join(', ') || 'Unknown author'
    case 'people':
      return item.known_for_department || 'Actor'
    case 'videos':
      return item.channel || ''
    default:
      return ''
  }
}

const removeItem = (item: any) => {
  selectedItems.value = selectedItems.value.filter(i => i.id !== item.id)
}

const isItemSelected = (item: any) => {
  return selectedItems.value.some(i => i.id === item.id)
}

const toggleItem = (item: any) => {
  if (isItemSelected(item)) {
    removeItem(item)
  } else {
    selectedItems.value.push(item)
  }
}

const canCreateList = computed(() => {
  return listTitle.value.trim() !== '' && selectedItems.value.length > 0
})

const createList = async () => {
  if (!canCreateList.value) return
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('User not authenticated')

    const listData = {
      title: listTitle.value,
      description: listDescription.value,
      category: category.value,
      items: selectedItems.value,
      created_at: new Date().toISOString(),
      user_id: user.id,
      comments_count: 0,
      likes_count: 0,
      saves_count: 0
    }
    
    // Save list to database
    const { data, error } = await supabase
      .from('lists')
      .insert([listData])
      .select()
      .single()

    if (error) throw error

    // Navigate to list details page
    router.push(`/lists/${data.id}`)
  } catch (error) {
    console.error('Error creating list:', error)
    // TODO: Show error notification to user
  }
}
</script>
