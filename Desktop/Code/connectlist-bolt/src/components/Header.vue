<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { supabase } from '../lib/supabase'
import { PhBell, PhEnvelope, PhUser, PhCaretDown, PhGear, PhSignOut, PhMagnifyingGlass, PhList, PhX, PhUsers, PhCheck, PhTrash, PhSpinner, PhChatCircleDots } from '@phosphor-icons/vue'
import type { Database } from '../lib/supabase-types'
import { useRouter } from 'vue-router'
import { useLocalStorage } from '@vueuse/core'

// Search state
const searchQuery = ref('')
const isSearching = ref(false)
const searchResults = ref<Database['public']['Tables']['profiles']['Row'][]>([])
const showSearchResults = ref(false)
const searchDebounceTimeout = ref<number | null>(null)
const searchCache = useLocalStorage<Record<string, { data: any[], timestamp: number }>>('search_cache', {})
const CACHE_DURATION = 5 * 60 * 1000 // 5 minutes

// Search functions
const performSearch = async () => {
  const query = searchQuery.value?.trim()
  if (!query) {
    searchResults.value = []
    showSearchResults.value = false
    return
  }

  isSearching.value = true
  try {
    console.log('Searching for:', query)
    
    // First, let's check what profiles exist
    const { data: allProfiles, error: profileError } = await supabase
      .from('profiles')
      .select('*')
    console.log('All profiles:', allProfiles)
    console.log('Profile error:', profileError)

    // Now do the search with textSearch
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .or(`username.ilike.%${query}%,full_name.ilike.%${query}%`)
      .limit(5)

    console.log('Search results:', data)
    console.log('Search error:', error)
    
    if (error) {
      console.error('Search error:', error)
      throw error
    }

    searchResults.value = data || []
    showSearchResults.value = true
  } catch (err) {
    console.error('Search error:', err)
    searchResults.value = []
  } finally {
    isSearching.value = false
  }
}

// Clear old cache entries
const cleanupCache = () => {
  const now = Date.now()
  const newCache: Record<string, { data: any[], timestamp: number }> = {}
  
  Object.entries(searchCache.value).forEach(([key, value]) => {
    if (now - value.timestamp < CACHE_DURATION) {
      newCache[key] = value
    }
  })
  
  searchCache.value = newCache
}

interface HighlightedText {
  before: string
  highlight: string
  after: string
}

const getHighlightedText = (text: string, query: string): HighlightedText => {
  if (!query) {
    return {
      before: text,
      highlight: '',
      after: ''
    }
  }

  const normalizedText = text.toLowerCase()
  const normalizedQuery = query.toLowerCase()
  const index = normalizedText.indexOf(normalizedQuery)
  
  if (index === -1) {
    return {
      before: text,
      highlight: '',
      after: ''
    }
  }
  
  return {
    before: text.slice(0, index),
    highlight: text.slice(index, index + query.length),
    after: text.slice(index + query.length)
  }
}

const handleSearch = () => {
  // Clear previous timeout
  if (searchDebounceTimeout.value) {
    clearTimeout(searchDebounceTimeout.value)
  }

  const query = searchQuery.value?.trim()
  showSearchResults.value = Boolean(query)

  // Set new timeout
  searchDebounceTimeout.value = setTimeout(() => {
    performSearch()
  }, 300) as unknown as number
}

const navigateToProfile = (username: string) => {
  router.push(`/@${username.toLowerCase()}`)
  searchQuery.value = ''
  showSearchResults.value = false
  isSearchVisible.value = false // Close mobile search bar
}

// Close search results when clicking outside
const handleSearchClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.search-container') && !target.closest('.search-input')) {
    showSearchResults.value = false
  }
}

const userProfile = ref<Database['public']['Tables']['profiles']['Row'] | null>(null)
const userFullName = ref<string | null>(null)
const isDropdownOpen = ref(false)
const isMobileMenuOpen = ref(false)
const isSearchVisible = ref(false)
const isNotificationsOpen = ref(false)
const router = useRouter()

// Mock notifications data - Replace with real data from Supabase
const notifications = ref([
  {
    id: 1,
    title: 'New follower',
    message: 'John Doe started following you',
    time: '5m ago',
    read: false
  },
  {
    id: 2,
    title: 'List shared',
    message: 'Jane Smith shared a list with you',
    time: '1h ago',
    read: false
  },
  {
    id: 3,
    title: 'List update',
    message: 'Your list "Favorite Books" was updated',
    time: '2h ago',
    read: true
  }
])

const unreadNotificationsCount = computed(() => {
  return notifications.value.filter(n => !n.read).length
})

const unreadCount = ref(0)

// Load unread messages count
const loadUnreadCount = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return

  const { data, error } = await supabase
    .rpc('get_unread_messages_count', {
      user_id: user.id
    })

  if (error) {
    console.error('Error loading unread count:', error)
    return
  }

  unreadCount.value = data || 0
}

// Set up realtime subscription for messages
let messagesSubscription

onMounted(async () => {
  await loadUnreadCount()

  messagesSubscription = supabase
    .channel('messages')
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'messages'
    }, () => {
      loadUnreadCount()
    })
    .subscribe()
})

onUnmounted(() => {
  if (messagesSubscription) {
    supabase.removeChannel(messagesSubscription)
  }
})

// Close dropdowns when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.profile-dropdown') && !target.closest('.notifications-dropdown')) {
    isDropdownOpen.value = false
    isNotificationsOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  document.addEventListener('click', handleSearchClickOutside)
  cleanupCache() // Clean old cache entries on mount
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  document.removeEventListener('click', handleSearchClickOutside)
  if (searchDebounceTimeout.value) {
    clearTimeout(searchDebounceTimeout.value)
  }
})

const markNotificationAsRead = (notificationId: number) => {
  const notification = notifications.value.find(n => n.id === notificationId)
  if (notification) {
    notification.read = true
  }
}

const deleteNotification = (notificationId: number) => {
  notifications.value = notifications.value.filter(n => n.id !== notificationId)
}

const markAllNotificationsAsRead = () => {
  notifications.value.forEach(n => n.read = true)
}

const navigateToMessages = () => {
  router.push('/messages')
}

const handleLogout = async () => {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    router.push('/login')
  }
}

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser()
  
  if (user) {
    // Get user metadata for full name
    userFullName.value = user.user_metadata.full_name

    // Get profile data
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, username, full_name, role')
      .eq('id', user.id)
      .single()

    if (profile) {
      userProfile.value = {
        id: profile.id,
        username: profile.username,
        full_name: profile.full_name,
        role: profile.role,
        avatar_url: null,
        website: null,
        location: null,
        bio: null,
        referral_code: '',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    }
  }
})
</script>

<template>
  <header class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="relative flex justify-between items-center h-16">
        <!-- Logo -->
        <div class="flex-shrink-0">
          <router-link to="/" class="text-primary text-2xl font-bold">
            <img 
              src="../assets/connectlist-beta-logo.png" 
              alt="Connectlist Beta" 
              class="h-5"
            />
          </router-link>
        </div>

        <!-- Search -->
        <div class="hidden md:block flex-1 max-w-2xl mx-8 search-container">
          <div class="relative">
            <PhMagnifyingGlass 
              :size="20" 
              weight="bold" 
              class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
            />
            <div v-if="isSearching && searchQuery" class="absolute right-3 top-1/2 transform -translate-y-1/2">
              <PhSpinner 
                :size="16" 
                weight="bold"
                class="text-gray-400 animate-spin" 
              />
            </div>
            <input
              v-model="searchQuery"
              @input="handleSearch"
              @focus="() => { if (searchQuery?.trim()) showSearchResults = true }"
              class="search-input w-full h-8 bg-gray-50 border border-gray-300 rounded-lg pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
              placeholder="Search anything"
            >
            
            <!-- Search Results Popup -->
            <div 
              v-if="showSearchResults && searchQuery?.trim()" 
              class="absolute top-full left-0 right-0 mt-2 bg-white rounded-lg shadow-lg border border-gray-200 overflow-hidden z-50"
            >
              <!-- Loading State -->
              <div v-if="isSearching" class="p-4 text-center text-gray-500">
                <PhSpinner :size="24" weight="bold" class="animate-spin mx-auto mb-2" />
                <p class="text-sm">Searching...</p>
              </div>

              <!-- Results -->
              <template v-else>
                <div class="p-2 border-b border-gray-200">
                  <h3 class="text-xs font-medium text-gray-500 uppercase">Users</h3>
                </div>
                
                <!-- No Results Message -->
                <div v-if="searchResults.length === 0" class="p-4 text-center text-gray-500">
                  <p class="text-sm">No users found</p>
                </div>

                <!-- User Results -->
                <div v-else class="max-h-[300px] overflow-y-auto">
                  <button
                    v-for="user in searchResults"
                    :key="user.id"
                    @click.prevent="navigateToProfile(user.username)"
                    class="w-full p-3 flex items-center gap-3 hover:bg-gray-50 transition-colors"
                  >
                    <!-- User Avatar -->
                    <div v-if="user.avatar_url" class="w-10 h-10 rounded-full">
                      <img
                        v-if="user.avatar_url"
                        :src="user.avatar_url"
                        :alt="user.full_name || user.username"
                        class="w-full h-full object-cover rounded-full"
                      />
                    </div>
                    <div v-else class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                      <PhUser :size="20" weight="bold" class="text-gray-500" />
                    </div>
                    
                    <!-- User Info -->
                    <div class="text-left">
                      <div class="font-medium text-gray-900">
                        {{ user.full_name || user.username }}
                      </div>
                      <div v-if="user.full_name" class="text-sm text-gray-500">
                        @{{ user.username }}
                      </div>
                    </div>
                  </button>
                </div>
              </template>
            </div>
          </div>
        </div>

        <!-- Mobile Search Button -->
        <button 
          @click="isSearchVisible = !isSearchVisible"
          class="md:hidden p-2 text-gray-500 hover:text-primary rounded-full hover:bg-gray-100"
        >
          <PhMagnifyingGlass :size="24" weight="bold" />
        </button>

        <!-- Right section -->
        <div class="hidden md:flex items-center space-x-4">
          <!-- Notifications -->
          <div class="relative notifications-dropdown">
            <button 
              @click="isNotificationsOpen = !isNotificationsOpen"
              class="p-2 text-gray-500 hover:text-primary rounded-full hover:bg-gray-100 relative"
            >
              <PhBell :size="24" weight="bold" />
              <span 
                v-if="unreadNotificationsCount > 0"
                class="absolute top-0 right-0 transform translate-x-1/2 -translate-y-1/2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center"
              >
                {{ unreadNotificationsCount }}
              </span>
            </button>

            <!-- Notifications Dropdown -->
            <div 
              v-if="isNotificationsOpen"
              class="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg py-1 z-50 border border-gray-200"
            >
              <div class="px-4 py-2 border-b border-gray-200 flex justify-between items-center">
                <h3 class="font-semibold text-gray-900">Notifications</h3>
                <button 
                  v-if="unreadNotificationsCount > 0"
                  @click="markAllNotificationsAsRead"
                  class="text-xs text-primary hover:text-primary/80"
                >
                  Mark all as read
                </button>
              </div>
              
              <div class="max-h-96 overflow-y-auto">
                <div 
                  v-for="notification in notifications" 
                  :key="notification.id"
                  class="px-4 py-3 hover:bg-gray-50 flex items-start justify-between gap-2"
                  :class="{ 'bg-orange-50/50': !notification.read }"
                >
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900">
                      {{ notification.title }}
                    </p>
                    <p class="text-sm text-gray-600 truncate">
                      {{ notification.message }}
                    </p>
                    <p class="text-xs text-gray-500 mt-1">
                      {{ notification.time }}
                    </p>
                  </div>
                  <div class="flex items-center gap-1">
                    <button 
                      v-if="!notification.read"
                      @click="markNotificationAsRead(notification.id)"
                      class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                      title="Mark as read"
                    >
                      <PhCheck :size="16" weight="bold" />
                    </button>
                    <button 
                      @click="deleteNotification(notification.id)"
                      class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                      title="Delete"
                    >
                      <PhTrash :size="16" weight="bold" />
                    </button>
                  </div>
                </div>
                
                <div v-if="notifications.length === 0" class="px-4 py-3 text-sm text-gray-500 text-center">
                  No notifications
                </div>
              </div>
            </div>
          </div>

          <!-- Messages -->
          <router-link 
            to="/messages" 
            class="relative flex items-center px-3 py-2 text-gray-700 rounded-lg hover:bg-gray-100"
          >
            <PhChatCircleDots :size="20" weight="bold" class="mr-3" />
            <span v-if="unreadCount > 0" 
              class="absolute -top-1 -right-1 flex items-center justify-center w-5 h-5 text-xs text-white bg-red-500 rounded-full">
              {{ unreadCount }}
            </span>
            Messages
          </router-link>

          <!-- Profile dropdown -->
          <div class="relative profile-dropdown">
            <button 
              @click="isDropdownOpen = !isDropdownOpen"
              class="flex items-center space-x-3 p-2 rounded-full hover:bg-gray-100"
            >
              <div v-if="userProfile?.avatar_url" class="w-8 h-8 rounded-full">
                <img
                  :src="userProfile.avatar_url"
                  :alt="userFullName || ''"
                  class="w-full h-full object-cover rounded-full"
                />
              </div>
              <div v-else class="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                <PhUser :size="20" weight="bold" class="text-gray-500" />
              </div>
              <div class="hidden md:block text-left">
                <div class="text-sm font-semibold text-gray-700">
                  {{ userFullName }}
                </div>
                <div class="text-xs text-gray-500">
                  @{{ userProfile?.username }}
                </div>
              </div>
              <PhCaretDown 
                :size="16" 
                class="text-gray-400 ml-1 transition-transform duration-200" 
                :class="{ 'rotate-180': isDropdownOpen }" 
              />
            </button>
            
            <!-- Dropdown Menu -->
            <div v-if="isDropdownOpen" 
              class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-1 z-50 border border-gray-200">
              <router-link 
                v-if="userProfile?.role === 'admin'"
                to="/admin" 
                class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
              >
                <PhUsers :size="16" weight="bold" class="mr-2" />
                Admin Dashboard
              </router-link>
              
              <router-link 
                :to="'/@' + userProfile?.username" 
                class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                <PhUser :size="16" weight="bold" class="mr-2" />
                Profile
              </router-link>
              <router-link to="/settings" 
                class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                <PhGear :size="16" weight="bold" class="mr-2" />
                Settings
              </router-link>
              <button @click="handleLogout"
                class="flex items-center w-full px-4 py-2 text-red-600 hover:bg-gray-100">
                <PhSignOut :size="16" weight="bold" class="mr-2" />
                Log out
              </button>
            </div>
          </div>
        </div>

        <!-- Mobile Menu Button -->
        <button 
          @click="isMobileMenuOpen = !isMobileMenuOpen"
          class="md:hidden p-2 text-gray-500 hover:text-primary rounded-full hover:bg-gray-100"
        >
          <PhList v-if="!isMobileMenuOpen" :size="24" weight="bold" />
          <PhX v-else :size="24" weight="bold" />
        </button>
      </div>

      <!-- Mobile Search Bar -->
      <div 
        v-if="isSearchVisible" 
        class="md:hidden py-3 -mx-4 px-4 border-t border-gray-200">
        <div class="relative search-container">
          <PhMagnifyingGlass 
            :size="20" 
            weight="bold" 
            class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
          />
          <div v-if="isSearching && searchQuery" class="absolute right-3 top-1/2 transform -translate-y-1/2">
            <PhSpinner 
              :size="16" 
              weight="bold"
              class="text-gray-400 animate-spin" 
            />
          </div>
          <input
            v-model="searchQuery"
            @input="handleSearch"
            @focus="() => { if (searchQuery?.trim()) showSearchResults = true }"
            class="search-input w-full h-8 bg-gray-50 border border-gray-300 rounded-lg pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            placeholder="Search anything"
          >
          
          <!-- Mobile Search Results -->
          <div 
            v-if="showSearchResults && searchQuery?.trim()" 
            class="absolute top-full left-0 right-0 mt-2 bg-white rounded-lg shadow-lg border border-gray-200 overflow-hidden z-50"
          >
            <!-- Loading State -->
            <div v-if="isSearching" class="p-4 text-center text-gray-500">
              <PhSpinner :size="24" weight="bold" class="animate-spin mx-auto mb-2" />
              <p class="text-sm">Searching...</p>
            </div>

            <!-- Results -->
            <template v-else>
              <div class="p-2 border-b border-gray-200">
                <h3 class="text-xs font-medium text-gray-500 uppercase">Users</h3>
              </div>
              
              <!-- No Results Message -->
              <div v-if="searchResults.length === 0" class="p-4 text-center text-gray-500">
                <p class="text-sm">No users found</p>
              </div>

              <!-- User Results -->
              <div v-else class="max-h-[300px] overflow-y-auto">
                <button
                  v-for="user in searchResults"
                  :key="user.id"
                  @click.prevent="navigateToProfile(user.username)"
                  class="w-full p-3 flex items-center gap-3 hover:bg-gray-50 transition-colors"
                >
                  <!-- User Avatar -->
                  <div v-if="user.avatar_url" class="w-10 h-10 rounded-full">
                    <img
                      v-if="user.avatar_url"
                      :src="user.avatar_url"
                      :alt="user.full_name || user.username"
                      class="w-full h-full object-cover rounded-full"
                    />
                  </div>
                  <div v-else class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                    <PhUser :size="20" weight="bold" class="text-gray-500" />
                  </div>
                  
                  <!-- User Info -->
                  <div class="text-left">
                    <div class="font-medium text-gray-900">
                      {{ user.full_name || user.username }}
                    </div>
                    <div v-if="user.full_name" class="text-sm text-gray-500">
                      @{{ user.username }}
                    </div>
                  </div>
                </button>
              </div>
            </template>
          </div>
        </div>
      </div>

      <!-- Mobile Menu -->
      <div 
        v-if="isMobileMenuOpen" 
        class="md:hidden py-4 -mx-4 px-4 border-t border-gray-200 bg-white"
      >
        <div class="flex items-center space-x-3 mb-4">
          <div v-if="userProfile?.avatar_url" class="w-10 h-10 rounded-full">
            <img
              :src="userProfile.avatar_url"
              :alt="userFullName || ''"
              class="w-full h-full object-cover rounded-full"
            />
          </div>
          <div v-else class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
            <PhUser :size="24" weight="bold" class="text-gray-500" />
          </div>
          <div>
            <div class="font-semibold text-gray-900">{{ userFullName }}</div>
            <div class="text-sm text-gray-500">@{{ userProfile?.username }}</div>
          </div>
        </div>

        <nav class="space-y-1">
          <router-link 
            v-if="userProfile?.role === 'admin'"
            to="/admin" 
            class="flex items-center px-3 py-2 text-gray-700 rounded-lg hover:bg-gray-100"
          >
            <PhUsers :size="20" weight="bold" class="mr-3" />
            Admin Dashboard
          </router-link>
          
          <router-link 
            :to="'/@' + userProfile?.username" 
            class="flex items-center px-3 py-2 text-gray-700 rounded-lg hover:bg-gray-100">
            <PhUser :size="20" weight="bold" class="mr-3" />
            Profile
          </router-link>
          
          <router-link 
            to="/settings" 
            class="flex items-center px-3 py-2 text-gray-700 rounded-lg hover:bg-gray-100">
            <PhGear :size="20" weight="bold" class="mr-3" />
            Settings
          </router-link>
          
          <button 
            @click="handleLogout"
            class="flex items-center w-full px-3 py-2 text-red-600 rounded-lg hover:bg-gray-100"
          >
            <PhSignOut :size="20" weight="bold" class="mr-3" />
            Log out
          </button>
        </nav>
      </div>
    </div>
  </header>
</template>