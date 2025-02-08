<script setup lang="ts">
import { ref, markRaw } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { 
  PhListBullets, 
  PhTelevision,
  PhFilmSlate,
  PhBook,
  PhVideo,
  PhUsers,
  PhMagnifyingGlass,
  PhPlus
} from '@phosphor-icons/vue'

const route = useRoute()
const router = useRouter()

interface Category {
  id: string
  name: string
  slug: string
  icon: any
}

const categories = ref<Category[]>([
  { id: 'timeline', name: 'Timeline', slug: 'timeline', icon: markRaw(PhListBullets) },
  { id: 'movies', name: 'Movies', slug: 'movies', icon: markRaw(PhFilmSlate) },
  { id: 'series', name: 'Series', slug: 'series', icon: markRaw(PhTelevision) },
  { id: 'books', name: 'Books', slug: 'books', icon: markRaw(PhBook) },
  { id: 'videos', name: 'Videos', slug: 'videos', icon: markRaw(PhVideo) },
  { id: 'people', name: 'People', slug: 'people', icon: markRaw(PhUsers) }
])

const selectCategory = (category: string) => {
  router.push(`/${category}`)
}

const navigateToDiscover = () => {
  router.push('/discover')
}

const navigateToAddList = () => {
  router.push('/lists/new')
}
</script>

<template>
  <nav class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <div class="flex">
          <div class="flex-shrink-0 flex items-center">
            <!-- Logo -->
          </div>
          <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
            <a
              v-for="category in categories"
              :key="category.id"
              :href="`/${category.slug}`"
              :class="[
                route.path.startsWith(`/${category.slug}`)
                  ? 'border-indigo-500 text-gray-900'
                  : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                'inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium'
              ]"
              @click.prevent="selectCategory(category.slug)"
            >
              <component :is="category.icon" :size="20" class="mr-1" />
              {{ category.name }}
            </a>
          </div>
        </div>
        <div class="hidden sm:ml-6 sm:flex sm:items-center">
          <div class="flex items-center space-x-4">
            <button 
              class="flex items-center px-4 py-2 border-2 border-orange-500 rounded-lg text-orange-500 hover:bg-orange-500 hover:text-white transition-colors"
              @click="router.push('/discover')"
            >
              <i class="fas fa-compass mr-2"></i>
              <span>Discover</span>
            </button>
            <button 
              class="flex items-center px-4 py-2 border-2 border-orange-500 rounded-lg text-orange-500 hover:bg-orange-500 hover:text-white transition-colors"
              @click="router.push('/select-category')"
            >
              <i class="fas fa-plus mr-2"></i>
              <span>Add List</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>
