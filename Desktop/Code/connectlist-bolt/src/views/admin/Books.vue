<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhBook, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Book = Database['public']['Tables']['books']['Insert']

const books = ref<Database['public']['Tables']['books']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newBook = ref<Book>({
  title: '',
  original_title: '',
  description: '',
  isbn: '',
  publication_date: null,
  publisher: '',
  genres: [],
  language: '',
  page_count: null,
  cover_image_url: '',
  status: 'draft'
})

const resetForm = () => {
  newBook.value = {
    title: '',
    original_title: '',
    description: '',
    isbn: '',
    publication_date: null,
    publisher: '',
    genres: [],
    language: '',
    page_count: null,
    cover_image_url: '',
    status: 'draft'
  }
}

const handleSubmit = async () => {
  try {
    const { error: insertError } = await supabase
      .from('books')
      .insert(newBook.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadBooks()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadBooks = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('books')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    books.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadBooks()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhBook :size="28" weight="bold" />
          Books
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Book
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage books and publications</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Books Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Publisher
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
                Loading books...
              </td>
            </tr>
            <tr v-else-if="books.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No books found
              </td>
            </tr>
            <tr v-for="book in books" :key="book.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="book.cover_image_url"
                    :src="book.cover_image_url"
                    :alt="book.title"
                    class="w-10 h-14 rounded object-cover"
                  />
                  <div v-else class="w-10 h-14 bg-gray-200 rounded flex items-center justify-center">
                    <PhBook :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ book.title }}
                    </div>
                    <div v-if="book.original_title && book.original_title !== book.title" class="text-sm text-gray-500">
                      {{ book.original_title }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ book.publisher || 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': book.status === 'published',
                    'bg-yellow-100 text-yellow-800': book.status === 'draft',
                    'bg-gray-100 text-gray-800': book.status === 'archived'
                  }">
                  {{ book.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit book"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete book"
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

    <!-- Add Book Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New Book</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Title *</label>
            <input
              v-model="newBook.title"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Original Title -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Original Title</label>
            <input
              v-model="newBook.original_title"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
            <textarea
              v-model="newBook.description"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- ISBN -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">ISBN</label>
            <input
              v-model="newBook.isbn"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Publication Date -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Publication Date</label>
            <input
              v-model="newBook.publication_date"
              type="date"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Publisher -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Publisher</label>
            <input
              v-model="newBook.publisher"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Language -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Language</label>
            <input
              v-model="newBook.language"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Page Count -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Page Count</label>
            <input
              v-model="newBook.page_count"
              type="number"
              min="1"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Cover Image URL -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Cover Image URL</label>
            <input
              v-model="newBook.cover_image_url"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newBook.status"
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
              Add Book
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>