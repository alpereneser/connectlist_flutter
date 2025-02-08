<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { contentService } from '../services/content'
import { useRouter } from 'vue-router'
import { 
  PhBell, 
  PhEnvelope, 
  PhUser, 
  PhCaretDown, 
  PhGear, 
  PhSignOut, 
  PhMagnifyingGlass, 
  PhList, 
  PhX, 
  PhUsers, 
  PhCheck, 
  PhTrash, 
  PhSpinner, 
  PhChatCircleDots,
  PhFilmSlate,
  PhTelevision,
  PhBook,
  PhGameController
} from '@phosphor-icons/vue'
import type { Database } from '../lib/supabase-types'
import { useLocalStorage } from '@vueuse/core'

const router = useRouter()

// UI State
const isSearchVisible = ref(false)
const isMobileMenuOpen = ref(false)
const isDropdownOpen = ref(false)
const isNotificationsOpen = ref(false)

// User State
const userProfile = ref<any>(null)
const userFullName = ref<string | null>(null)

// Notifications State
const notifications = ref<any[]>([])
const unreadNotificationsCount = ref(0)

// Search state
const searchQuery = ref('')
const isSearching = ref(false)
const activeTab = ref('users')
const searchResults = ref({
  users: [],
  movies: [],
  series: [],
  books: [],
  games: [],
  people: []
})
const showSearchResults = ref(false)
const searchDebounceTimeout = ref<number | null>(null)
const loadingStates = ref({
  users: false,
  movies: false,
  series: false,
  books: false,
  games: false,
  people: false
})

// Messages state
const unreadCount = ref(0)
let messagesSubscription: any
let notificationsSubscription: any

// Load notifications
const loadNotifications = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('notifications')
      .select(`
        *,
        sender:profiles!notifications_from_user_id_fkey (
          id,
          username,
          name,
          avatar_url
        )
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(20)

    if (error) throw error
    notifications.value = data || []
    unreadNotificationsCount.value = data?.filter(n => !n.read).length || 0
  } catch (err) {
    console.error('Error loading notifications:', err)
    notifications.value = []
    unreadNotificationsCount.value = 0
  }
}

// Search functions
const searchUsers = async (query: string) => {
  if (!query) {
    searchResults.value.users = []
    return
  }

  try {
    const { data: users, error } = await supabase
      .from('profiles')
      .select('id, username, name, avatar_url')
      .or(`username.ilike.%${query}%,name.ilike.%${query}%`)
      .limit(5)

    if (error) throw error

    searchResults.value.users = users || []
  } catch (error) {
    console.error('Error searching users:', error)
    searchResults.value.users = []
  }
}

const performSearch = async () => {
  const query = searchQuery.value?.trim()
  if (!query) {
    searchResults.value = {
      users: [],
      movies: [],
      series: [],
      books: [],
      games: [],
      people: []
    }
    showSearchResults.value = false
    return
  }

  // Reset all results and set loading states
  Object.keys(loadingStates.value).forEach(key => {
    loadingStates.value[key] = true
  })
  
  showSearchResults.value = true

  try {
    // Search all content types in parallel
    const [
      usersResult,
      moviesResult,
      seriesResult,
      booksResult,
      gamesResult,
      peopleResult
    ] = await Promise.all([
      // Search users
      searchUsers(query),
      // Search other content types
      contentService.search(query, 'movies'),
      contentService.search(query, 'series'),
      contentService.search(query, 'books'),
      contentService.search(query, 'games'),
      contentService.search(query, 'people')
    ])

    // Update search results
    searchResults.value = {
      users: searchResults.value.users,
      movies: moviesResult?.results || [],
      series: seriesResult?.results || [],
      books: booksResult?.results || [],
      games: gamesResult?.results || [],
      people: peopleResult?.results || []
    }
  } catch (err) {
    console.error('Error performing search:', err)
  } finally {
    // Reset loading states
    Object.keys(loadingStates.value).forEach(key => {
      loadingStates.value[key] = false
    })
  }
}

// Watch search query changes
watch(searchQuery, (newQuery) => {
  if (searchDebounceTimeout.value) {
    clearTimeout(searchDebounceTimeout.value)
  }

  if (!newQuery?.trim()) {
    searchResults.value = {
      users: [],
      movies: [],
      series: [],
      books: [],
      games: [],
      people: []
    }
    showSearchResults.value = false
    return
  }

  showSearchResults.value = true
  searchDebounceTimeout.value = setTimeout(() => {
    performSearch()
  }, 300)
})

const handleSearch = () => {
  if (searchDebounceTimeout.value) {
    clearTimeout(searchDebounceTimeout.value)
  }
  searchDebounceTimeout.value = setTimeout(performSearch, 300)
}

const getResultCount = computed(() => {
  return {
    users: searchResults.value.users.length,
    movies: searchResults.value.movies.length,
    series: searchResults.value.series.length,
    books: searchResults.value.books.length,
    games: searchResults.value.games.length,
    people: searchResults.value.people.length
  }
})

const getTotalResults = computed(() => {
  return Object.values(getResultCount.value).reduce((a, b) => a + b, 0)
})

// Navigation functions
const navigateToProfile = (username: string) => {
  router.push(`/@${username}`)
  searchQuery.value = ''
  showSearchResults.value = false
  isSearchVisible.value = false
}

const navigateToMessages = () => {
  router.push('/messages')
}

// Handle clicks outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.profile-dropdown') && !target.closest('.notifications-dropdown')) {
    isDropdownOpen.value = false
    isNotificationsOpen.value = false
  }
}

const handleSearchClickOutside = (event: MouseEvent) => {
  const searchContainer = document.querySelector('.search-container')
  if (searchContainer && !searchContainer.contains(event.target as Node) && !searchQuery.value?.trim()) {
    showSearchResults.value = false
  }
}

// Auth functions
async function handleLogout() {
  try {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    router.push('/login')
  } catch (err) {
    console.error('Error logging out:', err)
  }
}

// Lifecycle hooks
onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser()
  
  if (user) {
    userFullName.value = user.user_metadata.full_name

    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profile) {
      userProfile.value = profile
    }

    // Load initial data
    await Promise.all([
      loadNotifications(),
      loadUnreadCount()
    ])

    // Set up subscriptions
    notificationsSubscription = supabase
      .channel('notifications')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${user.id}`
        },
        () => {
          loadNotifications()
        }
      )
      .subscribe()

    messagesSubscription = supabase
      .channel('messages')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'messages',
          filter: `recipient_id=eq.${user.id}`
        },
        () => {
          loadUnreadCount()
        }
      )
      .subscribe()
  }

  // Add event listeners
  document.addEventListener('click', handleClickOutside)
  document.addEventListener('click', handleSearchClickOutside)
})

onUnmounted(() => {
  // Remove event listeners
  document.removeEventListener('click', handleClickOutside)
  document.removeEventListener('click', handleSearchClickOutside)

  // Clear timeouts
  if (searchDebounceTimeout.value) {
    clearTimeout(searchDebounceTimeout.value)
  }

  // Clean up subscriptions
  if (notificationsSubscription) {
    supabase.removeChannel(notificationsSubscription)
  }
  if (messagesSubscription) {
    supabase.removeChannel(messagesSubscription)
  }
})

// Load unread messages count
const loadUnreadCount = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { count, error } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .eq('receiver_id', user.id)
      .eq('read', false)

    if (error) throw error
    unreadCount.value = count || 0
  } catch (error) {
    console.error('Error loading unread count:', error)
  }
}
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
            
            <!-- Search Results Dropdown -->
            <div 
              v-if="showSearchResults && searchQuery" 
              class="absolute top-full left-0 right-0 mt-1 bg-white rounded-lg shadow-lg border border-gray-200 z-50"
            >
              <!-- Tabs -->
              <div class="flex border-b border-gray-200">
                <button
                  v-for="(count, tab) in getResultCount"
                  :key="tab"
                  @click="activeTab = tab"
                  class="flex-1 px-4 py-2 text-sm font-medium"
                  :class="{
                    'text-primary border-b-2 border-primary': activeTab === tab,
                    'text-gray-500 hover:text-gray-700': activeTab !== tab
                  }"
                >
                  {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
                  <span class="ml-1 text-gray-400">({{ count }})</span>
                </button>
              </div>

              <!-- Results -->
              <div class="max-h-96 overflow-y-auto">
                <!-- Loading State -->
                <div v-if="Object.values(loadingStates).some(state => state)" class="p-4 text-center">
                  <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                  <p class="mt-2 text-sm text-gray-500">Searching...</p>
                </div>

                <!-- Content -->
                <div v-else>
                  <!-- Users Tab -->
                  <div v-if="activeTab === 'users'" class="p-2">
                    <div v-if="searchResults.users.length === 0" class="p-4 text-center text-gray-500">
                      No users found
                    </div>
                    <div
                      v-else
                      v-for="user in searchResults.users"
                      :key="user.id"
                      @click="navigateToProfile(user.username)"
                      class="flex items-center p-2 hover:bg-gray-50 cursor-pointer rounded-lg"
                    >
                      <!-- User result content -->
                      <img 
                        v-if="user.avatar_url"
                        :src="user.avatar_url"
                        :alt="user.full_name || user.username"
                        class="w-10 h-10 rounded-full"
                      />
                      <div v-else class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                        <PhUser :size="20" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="text-sm font-medium text-gray-900">{{ user.full_name }}</p>
                        <p class="text-sm text-gray-500">@{{ user.username }}</p>
                      </div>
                    </div>
                  </div>

                  <!-- Movies Tab -->
                  <div v-if="activeTab === 'movies'" class="p-2">
                    <div
                      v-for="movie in searchResults.movies"
                      :key="movie.id"
                      @click="router.push(`/movies/${movie.id}`)"
                      class="flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer"
                    >
                      <img 
                        v-if="movie.poster_path"
                        :src="`https://image.tmdb.org/t/p/w92${movie.poster_path}`"
                        :alt="movie.title"
                        class="w-12 h-16 object-cover rounded"
                      />
                      <div v-else class="w-12 h-16 bg-gray-200 rounded flex items-center justify-center">
                        <PhFilmSlate :size="24" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="font-medium">{{ movie.title }}</p>
                        <p class="text-sm text-gray-500">{{ movie.release_date }}</p>
                      </div>
                    </div>
                  </div>

                  <!-- Series Tab -->
                  <div v-if="activeTab === 'series'" class="p-2">
                    <div
                      v-for="series in searchResults.series"
                      :key="series.id"
                      @click="router.push(`/series/${series.id}`)"
                      class="flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer"
                    >
                      <img 
                        v-if="series.poster_path"
                        :src="`https://image.tmdb.org/t/p/w92${series.poster_path}`"
                        :alt="series.name"
                        class="w-12 h-16 object-cover rounded"
                      />
                      <div v-else class="w-12 h-16 bg-gray-200 rounded flex items-center justify-center">
                        <PhTelevision :size="24" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="font-medium">{{ series.name }}</p>
                        <p class="text-sm text-gray-500">{{ series.first_air_date }}</p>
                      </div>
                    </div>
                  </div>

                  <!-- Books Tab -->
                  <div v-if="activeTab === 'books'" class="p-2">
                    <div
                      v-for="book in searchResults.books"
                      :key="book.id"
                      @click="router.push(`/books/${book.id}`)"
                      class="flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer"
                    >
                      <img 
                        v-if="book.volumeInfo.imageLinks?.thumbnail"
                        :src="book.volumeInfo.imageLinks.thumbnail"
                        :alt="book.volumeInfo.title"
                        class="w-12 h-16 object-cover rounded"
                      />
                      <div v-else class="w-12 h-16 bg-gray-200 rounded flex items-center justify-center">
                        <PhBook :size="24" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="font-medium">{{ book.volumeInfo.title }}</p>
                        <p class="text-sm text-gray-500">{{ book.volumeInfo.authors?.join(', ') }}</p>
                      </div>
                    </div>
                  </div>

                  <!-- Games Tab -->
                  <div v-if="activeTab === 'games'" class="p-2">
                    <div
                      v-for="game in searchResults.games"
                      :key="game.id"
                      @click="router.push(`/games/${game.id}`)"
                      class="flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer"
                    >
                      <img 
                        v-if="game.background_image"
                        :src="game.background_image"
                        :alt="game.name"
                        class="w-12 h-16 object-cover rounded"
                      />
                      <div v-else class="w-12 h-16 bg-gray-200 rounded flex items-center justify-center">
                        <PhGameController :size="24" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="font-medium">{{ game.name }}</p>
                        <p class="text-sm text-gray-500">{{ new Date(game.released).getFullYear() }}</p>
                      </div>
                    </div>
                  </div>

                  <!-- People Tab -->
                  <div v-if="activeTab === 'people'" class="p-2">
                    <div
                      v-for="person in searchResults.people"
                      :key="person.id"
                      @click="router.push(`/people/${person.id}`)"
                      class="flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer"
                    >
                      <img 
                        v-if="person.profile_path"
                        :src="`https://image.tmdb.org/t/p/w92${person.profile_path}`"
                        :alt="person.name"
                        class="w-10 h-10 rounded-full"
                      />
                      <div v-else class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                        <PhUser :size="20" weight="bold" class="text-gray-500" />
                      </div>
                      <div class="ml-3">
                        <p class="font-medium">{{ person.name }}</p>
                        <p class="text-sm text-gray-500">{{ person.known_for_department }}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
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
            class="relative p-2 text-gray-500 hover:text-primary rounded-full hover:bg-gray-100"
            title="Messages"
          >
            <PhChatCircleDots :size="24" weight="bold" />
            <span v-if="unreadCount > 0" 
              class="absolute -top-1 -right-1 flex items-center justify-center w-5 h-5 text-xs text-white bg-red-500 rounded-full">
              {{ unreadCount }}
            </span>
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
              class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50"
            >
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
                class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
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
              <div v-if="searchResults.users.length === 0" class="p-4 text-center text-gray-500">
                <p class="text-sm">No users found</p>
              </div>

              <!-- User Results -->
              <div v-else class="max-h-[300px] overflow-y-auto">
                <button
                  v-for="user in searchResults.users"
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