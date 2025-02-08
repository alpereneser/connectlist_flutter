<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="bg-white rounded-lg shadow-lg overflow-hidden">
        <!-- Book Header -->
        <div class="p-6 md:p-8 flex flex-col md:flex-row gap-8">
          <div class="w-full md:w-1/3 lg:w-1/4">
            <img :src="book.cover_path" class="w-full rounded-lg shadow-lg" :alt="book.title">
          </div>
          <div class="flex-1">
            <h1 class="text-4xl font-bold text-gray-900">{{ book.title }}</h1>
            <p class="text-xl text-gray-600 mt-2">by {{ book.author }}</p>
            
            <!-- Actions -->
            <div class="flex space-x-4 mt-6">
              <button class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark">
                Add to List
              </button>
              <button class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200">
                Who Added List
              </button>
            </div>

            <!-- Quick Details -->
            <div class="mt-6 grid grid-cols-2 gap-4">
              <div>
                <p class="text-gray-500">Published</p>
                <p class="font-medium">{{ book.publication_date }}</p>
              </div>
              <div>
                <p class="text-gray-500">Publisher</p>
                <p class="font-medium">{{ book.publisher }}</p>
              </div>
              <div>
                <p class="text-gray-500">Pages</p>
                <p class="font-medium">{{ book.pages }}</p>
              </div>
              <div>
                <p class="text-gray-500">Language</p>
                <p class="font-medium">{{ book.language }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Book Content -->
        <div class="p-6 md:p-8 border-t border-gray-200">
          <!-- Synopsis -->
          <div class="mb-8">
            <h2 class="text-2xl font-bold mb-4">Synopsis</h2>
            <p class="text-gray-600 whitespace-pre-line">{{ book.synopsis }}</p>
          </div>

          <!-- Details -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 class="text-lg font-semibold mb-2">Book Details</h3>
              <dl class="space-y-2">
                <div class="flex">
                  <dt class="w-32 text-gray-500">ISBN-13</dt>
                  <dd>{{ book.isbn_13 }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">ISBN-10</dt>
                  <dd>{{ book.isbn_10 }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Format</dt>
                  <dd>{{ book.format }}</dd>
                </div>
                <div class="flex">
                  <dt class="w-32 text-gray-500">Edition</dt>
                  <dd>{{ book.edition }}</dd>
                </div>
              </dl>
            </div>
            <div>
              <h3 class="text-lg font-semibold mb-2">Categories</h3>
              <div class="flex flex-wrap gap-2">
                <span v-for="category in book.categories" 
                      :key="category"
                      class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm">
                  {{ category }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-8">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        <p class="mt-2 text-sm text-gray-500">Loading book details...</p>
      </div>
      <div v-else-if="error" class="text-center py-8">
        <p class="text-red-500">{{ error }}</p>
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
const book = ref(null)
const loading = ref(true)
const error = ref<string | null>(null)

const loadBookDetails = async () => {
  loading.value = true
  error.value = null
  try {
    const bookId = route.params.id
    const response = await contentService.getBookDetails(bookId)
    book.value = response
  } catch (err: any) {
    console.error('Error fetching book details:', err)
    error.value = err.message || 'Failed to load book details'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadBookDetails()
})
</script>
