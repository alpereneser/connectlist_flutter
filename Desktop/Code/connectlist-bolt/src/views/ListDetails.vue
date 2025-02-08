<template>
  <div class="min-h-screen bg-white">
    <Header />
    <SubHeader />

    <main class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <div v-if="loading" class="flex justify-center items-center h-64">
        <div class="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>

      <template v-else-if="list">
        <!-- User Info and List Header -->
        <div class="mb-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <img 
                :src="list.profiles?.avatar_url || '/default-avatar.png'" 
                :alt="list.profiles?.name"
                class="w-10 h-10 rounded-full object-cover"
              >
              <div class="flex items-center gap-2 text-sm text-gray-600">
                <span class="font-medium text-gray-900">{{ list.profiles?.name }}</span>
                <span>added it to</span>
                <span class="font-medium text-gray-900">{{ list.title }}</span>
                <span>list</span>
              </div>
            </div>

            <!-- Action Buttons -->
            <div v-if="isOwner" class="flex items-center space-x-2">
              <router-link
                to="/search"
                class="inline-flex items-center px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors"
              >
                <PhPlus class="w-5 h-5 mr-1" />
                Add Items
              </router-link>
              
              <button
                @click="openEditModal"
                class="p-2 text-gray-500 hover:text-blue-500 hover:bg-blue-50 rounded-full transition-colors"
                title="Edit List"
              >
                <PhPencil class="w-5 h-5" />
              </button>
              
              <button
                @click="showDeleteModal = true"
                class="p-2 text-gray-500 hover:text-red-500 hover:bg-red-50 rounded-full transition-colors"
                title="Delete List"
              >
                <PhTrash class="w-5 h-5" />
              </button>
            </div>
          </div>
          <div class="flex items-center gap-2 text-sm text-gray-500 mt-1 ml-[52px]">
            <span>@{{ list.profiles?.username }}</span>
            <span>·</span>
            <span class="inline-flex items-center">
              <PhBook class="w-4 h-4 mr-1" />
              {{ list.category }}
            </span>
            <span>·</span>
            <span>{{ formatTimeAgo(list.created_at) }}</span>
          </div>
        </div>

        <!-- List Description -->
        <div class="mb-8 ml-[52px]">
          <p class="text-gray-700 whitespace-pre-line">{{ list.description }}</p>
        </div>

        <!-- List Items Grid -->
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
          <div 
            v-for="item in list.items" 
            :key="item.id"
            class="flex flex-col"
          >
            <div class="relative aspect-[2/3] mb-2">
              <img 
                :src="`https://image.tmdb.org/t/p/w500${item.poster_path}`"
                :alt="item.name"
                class="w-full h-full object-cover rounded-lg shadow hover:shadow-lg transition-shadow"
                @error="$event.target.src = '/placeholder-cover.jpg'"
              >
              <div class="absolute bottom-2 right-2 bg-black/75 text-white text-xs px-2 py-1 rounded-full">
                ★ {{ item.vote_average?.toFixed(1) }}
              </div>
            </div>
            <h3 class="font-medium text-gray-900 text-sm line-clamp-2">{{ item.name }}</h3>
            <p class="text-sm text-gray-500">{{ item.first_air_date ? new Date(item.first_air_date).getFullYear() : '' }}</p>
          </div>
        </div>

        <!-- Engagement Stats -->
        <div class="flex items-center gap-6 text-sm text-gray-600 ml-[52px]">
          <button class="flex items-center gap-2 hover:text-gray-900">
            <PhChat class="w-5 h-5" />
            <span>43</span>
          </button>
          <button class="flex items-center gap-2 hover:text-gray-900">
            <PhHeart class="w-5 h-5" />
            <span>1.2K</span>
          </button>
          <button class="flex items-center gap-2 hover:text-gray-900">
            <PhBookmark class="w-5 h-5" />
            <span>451</span>
          </button>
          <button class="flex items-center gap-2 hover:text-gray-900">
            <PhShareNetwork class="w-5 h-5" />
          </button>
        </div>
      </template>

      <div v-else class="text-center py-12">
        <p class="text-gray-500">List not found</p>
      </div>
    </main>

    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { useUserStore } from '../stores/user'
import Header from '../components/Header.vue'
import SubHeader from '../components/SubHeader.vue'
import Footer from '../components/Footer.vue'
import { 
  PhBook,
  PhChat,
  PhHeart,
  PhBookmark,
  PhShareNetwork,
  PhPlus,
  PhPencil,
  PhTrash
} from '@phosphor-icons/vue'

const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/w500'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const list = ref<any>(null)
const loading = ref(true)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editedList = ref({
  title: '',
  description: '',
  category: ''
})

// Liste sahibi kontrolü
const isOwner = computed(() => {
  return userStore.user && list.value && userStore.user.id === list.value.user_id
})

const formatTimeAgo = (date: string) => {
  const now = new Date()
  const past = new Date(date)
  const diffInMinutes = Math.floor((now.getTime() - past.getTime()) / (1000 * 60))

  if (diffInMinutes < 1) return 'just now'
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`
  
  const diffInHours = Math.floor(diffInMinutes / 60)
  if (diffInHours < 24) return `${diffInHours}h ago`
  
  const diffInDays = Math.floor(diffInHours / 24)
  if (diffInDays < 7) return `${diffInDays}d ago`
  
  return past.toLocaleDateString()
}

const loadList = async () => {
  try {
    loading.value = true
    
    // Get list with profile
    const { data, error } = await supabase
      .from('lists')
      .select(`
        id,
        user_id,
        description,
        created_at,
        title,
        category,
        items,
        profiles!lists_user_id_fkey (
          name,
          username,
          avatar_url
        )
      `)
      .eq('id', route.params.id)
      .single()

    if (error) throw error

    if (data) {
      list.value = {
        ...data,
        items: Array.isArray(data.items) ? data.items : []
      }
    }
  } catch (error) {
    console.error('Error loading list:', error)
  } finally {
    loading.value = false
  }
}

const openEditModal = () => {
  editedList.value = {
    title: list.value.title,
    description: list.value.description,
    category: list.value.category
  }
  showEditModal.value = true
}

const updateList = async () => {
  try {
    loading.value = true
    const { error } = await supabase
      .from('lists')
      .update({
        title: editedList.value.title,
        description: editedList.value.description,
        category: editedList.value.category,
        updated_at: new Date().toISOString()
      })
      .eq('id', list.value.id)

    if (error) throw error

    // Update local data
    list.value = {
      ...list.value,
      ...editedList.value
    }

    showEditModal.value = false
  } catch (error: any) {
    console.error('Error updating list:', error.message)
  } finally {
    loading.value = false
  }
}

const deleteList = async () => {
  try {
    loading.value = true
    const { error } = await supabase
      .from('lists')
      .delete()
      .eq('id', list.value.id)

    if (error) throw error

    // Redirect to profile page
    router.push(`/profile/${list.value.user_id}`)
  } catch (error: any) {
    console.error('Error deleting list:', error.message)
  } finally {
    loading.value = false
    showDeleteModal.value = false
  }
}

onMounted(() => {
  loadList()
})
</script>
