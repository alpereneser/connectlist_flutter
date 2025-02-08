<template>
  <div class="min-h-screen bg-gray-100">
    <Header />
    <SubHeader />

    <main class="container mx-auto px-4 py-8">
      <div v-if="loading" class="flex justify-center items-center h-64">
        <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>

      <div v-else class="grid grid-cols-1 gap-6">
        <router-link v-for="list in lists" :key="list.id" :to="'/lists/' + list.id" class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
          <div class="p-6">
            <!-- User Info -->
            <div class="flex items-center mb-4">
              <img :src="list.profiles?.avatar_url || '/placeholder-avatar.jpg'" alt="User Avatar" class="w-10 h-10 rounded-full">
              <div class="ml-3">
                <p class="font-medium text-gray-900">{{ list.profiles?.name || '' }}</p>
                <p class="text-sm text-gray-600">@{{ list.profiles?.username || '' }}</p>
              </div>
            </div>

            <!-- List Info -->
            <h2 class="text-xl font-bold text-gray-900 mb-2">{{ list.title }}</h2>
            <p class="text-gray-600 mb-4 line-clamp-2">{{ list.description }}</p>

            <!-- List Item Covers -->
            <div class="flex space-x-2 mb-4 overflow-x-auto pb-2">
              <div v-for="(item, index) in list.items.slice(0, 4)" :key="index" class="flex-shrink-0">
                <img 
                  :src="item.contentcoverimage ? 'https://image.tmdb.org/t/p/w200' + item.contentcoverimage : '/placeholder-cover.jpg'" 
                  :alt="item.contenttitle"
                  class="w-20 h-28 object-cover rounded-md"
                >
              </div>
              <div v-if="list.items.length > 4" class="flex-shrink-0 w-20 h-28 bg-gray-200 rounded-md flex items-center justify-center">
                <span class="text-gray-600 font-medium">+{{ list.items.length - 4 }}</span>
              </div>
            </div>

            <!-- Engagement Stats -->
            <div class="flex items-center text-gray-500 space-x-4">
              <div class="flex items-center">
                <PhChatCircleDots class="w-5 h-5 mr-1" />
                <span>{{ list.comments_count }}</span>
              </div>
              <div class="flex items-center" :class="{ 'text-red-500': list.is_liked }">
                <PhHeart class="w-5 h-5 mr-1" :weight="list.is_liked ? 'fill' : 'regular'" />
                <span>{{ list.likes_count }}</span>
              </div>
            </div>
          </div>
        </router-link>
      </div>
    </main>

    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import Header from '../components/Header.vue'
import Footer from '../components/Footer.vue'
import SubHeader from '../components/SubHeader.vue'
import { PhChatCircleDots, PhHeart } from '@phosphor-icons/vue'

interface Profile {
  id: string
  username: string
  name: string
  avatar_url: string | null
}

interface ListItem {
  poster_path?: string
  background_path?: string
  name: string
  first_air_date?: string
  original_name?: string
  adult?: boolean
}

interface List {
  id: string
  title: string
  description: string
  user_id: string
  items: ListItem[]
  profiles?: Profile
  comments_count: number
  likes_count: number
  is_liked: boolean
  created_at: string
}

const router = useRouter()
const loading = ref(true)
const lists = ref<List[]>([])

// Transform the items JSONB array into the format we need
const transformListData = (list: any): List => {
  return {
    ...list,
    items: (list.items || []).map((item: any) => ({
      contentcoverimage: item.poster_path || item.background_path,
      contenttitle: item.name,
      contentreleaseyear: item.first_air_date?.split('-')[0] || '',
      contenttype: item.original_name,
      contentdescription: item.adult ? 'Adult' : 'All Ages'
    }))
  }
}

const loadLists = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('lists')
      .select(`
        *,
        profiles!lists_user_id_fkey (
          id,
          username,
          name,
          avatar_url
        )
      `)
      .order('created_at', { ascending: false })

    if (error) throw error
    
    lists.value = (data || []).map(list => transformListData(list))
  } catch (error) {
    console.error('Error loading lists:', error)
  } finally {
    loading.value = false
  }
}

// Initial load
onMounted(() => {
  loadLists()
})
</script>

<style>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>