<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <SubHeader />

    <main class="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-12">
        <h1 class="text-3xl font-bold text-gray-900">Select category for your list</h1>
        <p class="mt-4 text-gray-600">
          You can create a list with a URL or search for a list based on the category you choose.
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-3xl mx-auto">
        <!-- Movies -->
        <button 
          @click="router.push('/create-list/movies')"
          class="p-8 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 flex flex-col items-center space-y-4"
        >
          <div class="w-16 h-16 flex items-center justify-center bg-blue-50 rounded-full">
            <PhFilmStrip :size="32" weight="fill" class="text-blue-600" />
          </div>
          <span class="text-lg font-medium text-gray-900">Movies</span>
        </button>

        <!-- Series -->
        <button 
          @click="router.push('/create-list/series')"
          class="p-8 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 flex flex-col items-center space-y-4"
        >
          <div class="w-16 h-16 flex items-center justify-center bg-purple-50 rounded-full">
            <PhTelevisionSimple :size="32" weight="fill" class="text-purple-600" />
          </div>
          <span class="text-lg font-medium text-gray-900">Series</span>
        </button>

        <!-- Books -->
        <button 
          @click="router.push('/create-list/books')"
          class="p-8 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 flex flex-col items-center space-y-4"
        >
          <div class="w-16 h-16 flex items-center justify-center bg-green-50 rounded-full">
            <PhBookOpen :size="32" weight="fill" class="text-green-600" />
          </div>
          <span class="text-lg font-medium text-gray-900">Books</span>
        </button>

        <!-- People -->
        <button 
          @click="router.push('/create-list/people')"
          class="p-8 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 flex flex-col items-center space-y-4"
        >
          <div class="w-16 h-16 flex items-center justify-center bg-yellow-50 rounded-full">
            <PhUsersThree :size="32" weight="fill" class="text-yellow-600" />
          </div>
          <span class="text-lg font-medium text-gray-900">People</span>
        </button>

        <!-- Videos -->
        <button 
          @click="router.push('/create-list/videos')"
          class="p-8 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 flex flex-col items-center space-y-4"
        >
          <div class="w-16 h-16 flex items-center justify-center bg-red-50 rounded-full">
            <PhPlayCircle :size="32" weight="fill" class="text-red-600" />
          </div>
          <span class="text-lg font-medium text-gray-900">Videos</span>
        </button>
      </div>
    </main>

    <Footer />
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'
import { 
  PhFilmStrip, 
  PhTelevisionSimple, 
  PhBookOpen, 
  PhUsersThree, 
  PhPlayCircle 
} from '@phosphor-icons/vue'

const router = useRouter()
</script>
