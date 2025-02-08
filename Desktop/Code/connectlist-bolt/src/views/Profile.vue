<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import Header from '../components/Header.vue'
import Footer from '../components/Footer.vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { PhCamera, PhMapPin, PhX } from '@phosphor-icons/vue'

interface Profile {
  id: string
  username: string
  name: string
  avatar_url?: string
  about?: string
  website?: string
  location?: string
  followers_count: number
  following_count: number
}

interface FollowData {
  follower_id: string
  following_id: string
  follower: {
    id: string
    username: string
    name: string
    avatar_url?: string
  }
  following: {
    id: string
    username: string
    name: string
    avatar_url?: string
  }
}

interface Follow {
  follower_id: string
  following_id: string
  follower: Profile
  following: Profile
}

interface List {
  id: string
  title: string
  description: string
  category: string
  items: any[]
  created_at: string
  user_id: string
}

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const profile = ref<Profile | null>(null)
const lists = ref<List[]>([])
const loading = ref(true)
const isLoading = ref(false)
const error = ref('')
const success = ref('')
const showFollowersModal = ref(false)
const showFollowingModal = ref(false)
const showEditModal = ref(false)
const followers = ref<Follow[]>([])
const following = ref<Follow[]>([])
const editedProfileData = ref({
  name: '',
  username: '',
  about: '',
  website: '',
  location: ''
})

// Computed properties
const followerCount = computed(() => profile.value?.followers_count ?? 0)
const followingCount = computed(() => profile.value?.following_count ?? 0)
const isOwnProfile = computed(() => userStore.user?.id === profile.value?.id)

const isFollowing = computed(() => {
  if (!profile.value || !userStore.user) return false
  return following.value.some(f => f.following.id === profile.value.id)
})

// Load profile data
const loadProfile = async () => {
  const username = route.params.username?.toString().replace('@', '')
  if (!username) {
    error.value = 'Invalid username'
    return
  }

  try {
    loading.value = true
    
    // First get the user ID from username
    const { data: userData, error: userError } = await supabase
      .from('profiles')
      .select('*')
      .eq('username', username)
      .single()

    if (userError) throw userError
    if (!userData) throw new Error('User not found')

    // Get follower count
    const { data: followers, error: followersError } = await supabase
      .from('follows')
      .select('follower_id')
      .eq('following_id', userData.id)

    if (followersError) throw followersError

    // Get following count
    const { data: following, error: followingError } = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', userData.id)

    if (followingError) throw followingError

    // Create profile object with all required fields
    profile.value = {
      id: userData.id,
      username: userData.username,
      name: userData.name,
      avatar_url: userData.avatar_url,
      about: userData.about,
      website: userData.website,
      location: userData.location,
      followers_count: followers?.length || 0,
      following_count: following?.length || 0
    }

    // Initialize edit form data
    editedProfileData.value = {
      name: profile.value.name,
      username: profile.value.username,
      about: profile.value.about || '',
      website: profile.value.website || '',
      location: profile.value.location || ''
    }

    // Load related data after profile is set
    if (profile.value) {
      await Promise.all([
        loadFollowers(),
        loadFollowing(),
        loadLists()
      ])
    }
  } catch (err: any) {
    console.error('Error loading profile:', err.message)
    error.value = err.message || 'Failed to load profile'
  } finally {
    loading.value = false
  }
}

// Load lists
const loadLists = async () => {
  const currentProfile = profile.value
  if (!currentProfile) return

  try {
    const { data, error } = await supabase
      .from('lists')
      .select(`
        id,
        title,
        description,
        category,
        items,
        created_at,
        user_id
      `)
      .eq('user_id', currentProfile.id)
      .order('created_at', { ascending: false })

    if (error) throw error
    lists.value = data || []
  } catch (err) {
    console.error('Error loading lists:', err)
  }
}

// Load followers
const loadFollowers = async () => {
  if (!profile.value) return

  try {
    const { data, error } = await supabase
      .from('follows')
      .select(`
        follower_id,
        following_id,
        follower:profiles!follows_follower_id_fkey (
          id,
          username,
          name,
          avatar_url
        )
      `)
      .eq('following_id', profile.value.id)

    if (error) throw error
    
    // Map the data to include profile information
    followers.value = (data || []).map((item: FollowData) => ({
      follower_id: item.follower_id,
      following_id: item.following_id,
      follower: {
        ...item.follower,
        followers_count: 0,
        following_count: 0
      },
      following: profile.value
    }))
  } catch (err) {
    console.error('Error loading followers:', err)
  }
}

// Load following
const loadFollowing = async () => {
  if (!profile.value) return

  try {
    const { data, error } = await supabase
      .from('follows')
      .select(`
        follower_id,
        following_id,
        following:profiles!follows_following_id_fkey (
          id,
          username,
          name,
          avatar_url
        )
      `)
      .eq('follower_id', profile.value.id)

    if (error) throw error

    // Map the data to include profile information
    following.value = (data || []).map((item: FollowData) => ({
      follower_id: item.follower_id,
      following_id: item.following_id,
      follower: profile.value,
      following: {
        ...item.following,
        followers_count: 0,
        following_count: 0
      }
    }))
  } catch (err) {
    console.error('Error loading following:', err)
  }
}

// Update profile
const updateProfile = async (e: Event) => {
  e.preventDefault()
  const currentProfile = profile.value
  if (!currentProfile) return
  
  try {
    isLoading.value = true
    error.value = ''
    success.value = ''

    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        name: editedProfileData.value.name,
        username: editedProfileData.value.username,
        about: editedProfileData.value.about,
        website: editedProfileData.value.website,
        location: editedProfileData.value.location,
        updated_at: new Date().toISOString()
      })
      .eq('id', currentProfile.id)

    if (updateError) throw updateError

    // Update local profile data
    profile.value = {
      ...currentProfile,
      ...editedProfileData.value
    }

    success.value = 'Profile updated successfully!'
    showEditModal.value = false
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

// Toggle follow status
const toggleFollow = async () => {
  if (!userStore.user || !profile.value) return
  
  try {
    isLoading.value = true
    
    if (isFollowing.value) {
      const { error } = await supabase
        .from('follows')
        .delete()
        .eq('follower_id', userStore.user.id)
        .eq('following_id', profile.value.id)

      if (error) throw error
    } else {
      const { error } = await supabase
        .from('follows')
        .insert({
          follower_id: userStore.user.id,
          following_id: profile.value.id
        })

      if (error) throw error
    }

    // Reload followers and following lists
    await Promise.all([
      loadFollowers(),
      loadFollowing()
    ])
  } catch (err) {
    console.error('Error toggling follow:', err)
  } finally {
    isLoading.value = false
  }
}

// Navigation
const navigateToProfile = (username: string) => {
  router.push(`/@${username}`)
}

// Handle image error
const handleImageError = (event: Event) => {
  const target = event.target as HTMLImageElement
  if (target) {
    target.src = '/placeholder-cover.jpg'
  }
}

// Watch for route changes
watch(() => route.params.username, async (newUsername) => {
  if (newUsername) {
    await loadProfile()
  }
})

onMounted(() => {
  loadProfile()
})
</script>

<template>
  <div>
    <Header />
    <div v-if="profile">
      <!-- Profile Card -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="bg-white">
          <div class="flex flex-col md:flex-row items-start gap-8 p-6">
            <!-- Avatar Section -->
            <div class="flex-shrink-0 mx-auto md:mx-0 mb-6 md:mb-0">
              <div class="relative group">
                <img
                  :src="profile.avatar_url || '/placeholder-avatar.jpg'"
                  alt="Profile"
                  class="w-32 h-32 md:w-40 md:h-40 rounded-full object-cover border-2 border-gray-200"
                />
                <button
                  v-if="isOwnProfile"
                  @click="showEditModal = true"
                  class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 rounded-full opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                >
                  <PhCamera class="w-8 h-8 text-white" />
                </button>
              </div>
            </div>

            <!-- Profile Info Section -->
            <div class="flex-grow space-y-6">
              <!-- Username and Edit Button Row -->
              <div class="flex flex-col md:flex-row md:items-center gap-4">
                <h1 class="text-2xl font-light">{{ profile.username }}</h1>
                <div class="flex gap-2">
                  <template v-if="isOwnProfile">
                    <button
                      @click="showEditModal = true"
                      class="px-4 py-1.5 border border-gray-300 rounded-md text-sm font-medium hover:bg-gray-50 w-full md:w-auto"
                    >
                      Edit Profile
                    </button>
                  </template>
                  <template v-else>
                    <button
                      v-if="!isFollowing"
                      @click="toggleFollow"
                      class="px-4 py-1.5 bg-blue-500 text-white rounded-md text-sm font-medium hover:bg-blue-600 w-full md:w-auto"
                      :disabled="isLoading"
                    >
                      Follow
                    </button>
                    <button
                      v-else
                      @click="toggleFollow"
                      class="px-4 py-1.5 border border-gray-300 rounded-md text-sm font-medium hover:bg-gray-50 w-full md:w-auto"
                      :disabled="isLoading"
                    >
                      Following
                    </button>
                  </template>
                </div>
              </div>

              <!-- Stats Row -->
              <div class="flex gap-8 text-sm">
                <div class="text-center md:text-left">
                  <span class="font-semibold">{{ lists.length }}</span>
                  <span class="text-gray-900 ml-1">lists</span>
                </div>
                <button @click="showFollowersModal = true" class="text-center md:text-left">
                  <span class="font-semibold">{{ followerCount }}</span>
                  <span class="text-gray-900 ml-1">followers</span>
                </button>
                <button @click="showFollowingModal = true" class="text-center md:text-left">
                  <span class="font-semibold">{{ followingCount }}</span>
                  <span class="text-gray-900 ml-1">following</span>
                </button>
              </div>

              <!-- Name and Bio -->
              <div class="space-y-2">
                <div class="font-semibold text-gray-900">{{ profile.name }}</div>
                <div class="text-gray-900 whitespace-pre-wrap text-sm">{{ profile.about || 'No bio yet.' }}</div>
                <a
                  v-if="profile.website"
                  :href="profile.website"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-blue-900 hover:underline text-sm block"
                >
                  {{ profile.website }}
                </a>
                <div v-if="profile.location" class="flex items-center text-gray-500 text-sm">
                  <PhMapPin class="w-4 h-4 mr-1" />
                  {{ profile.location }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Divider -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="border-t border-gray-200"></div>
      </div>

      <!-- Lists Section -->
      <section class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold text-gray-900">Lists</h2>
        </div>
        
        <div class="grid grid-cols-1 gap-6">
          <div v-for="list in lists" :key="list.id" class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
            <div class="p-6">
              <!-- User Info -->
              <div class="flex items-center mb-4">
                <img :src="profile.avatar_url || '/placeholder-avatar.jpg'" alt="User Avatar" class="w-10 h-10 rounded-full">
                <div class="ml-3">
                  <p class="font-medium text-gray-900">{{ profile.name }}</p>
                  <p class="text-sm text-gray-600">@{{ profile.username }}</p>
                </div>
              </div>

              <!-- List Info -->
              <h2 class="text-xl font-bold text-gray-900 mb-2">{{ list.title }}</h2>
              <p class="text-gray-600 mb-4 line-clamp-2">{{ list.description }}</p>

              <!-- List Item Covers -->
              <div class="flex space-x-2 mb-4 overflow-x-auto pb-2">
                <div v-for="(item, index) in (list.items || []).slice(0, 4)" :key="index" class="flex-shrink-0">
                  <img 
                    :src="`https://image.tmdb.org/t/p/w200${item.poster_path}`"
                    :alt="item.name"
                    class="w-20 h-28 object-cover rounded-md"
                    @error="handleImageError"
                  >
                </div>
                <div v-if="list.items?.length > 4" class="flex-shrink-0 w-20 h-28 bg-gray-200 rounded-md flex items-center justify-center">
                  <span class="text-gray-600 font-medium">+{{ list.items.length - 4 }}</span>
                </div>
              </div>

              <!-- Category and Date -->
              <div class="flex items-center justify-between text-sm text-gray-500">
                <span class="inline-flex items-center px-2.5 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-xs font-medium">
                  {{ list.category }}
                </span>
                <span>{{ new Date(list.created_at).toLocaleDateString() }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="!lists.length" class="text-center py-12">
          <p class="text-gray-500">No lists created yet.</p>
        </div>
      </section>
    </div>

    <!-- Followers Modal -->
    <TransitionRoot appear :show="showFollowersModal" as="template">
      <Dialog as="div" @close="showFollowersModal = false" class="relative z-10">
        <TransitionChild
          as="template"
          enter="duration-300 ease-out"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100"
          leave-to="opacity-0"
        >
          <div class="fixed inset-0 bg-black bg-opacity-25" />
        </TransitionChild>

        <div class="fixed inset-0 overflow-y-auto">
          <div class="flex min-h-full items-center justify-center p-4 text-center">
            <TransitionChild
              as="template"
              enter="duration-300 ease-out"
              enter-from="opacity-0 scale-95"
              enter-to="opacity-100 scale-100"
              leave="duration-200 ease-in"
              leave-from="opacity-100 scale-100"
              leave-to="opacity-0 scale-95"
            >
              <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900 mb-4">
                  Followers
                </DialogTitle>
                <div class="max-h-96 overflow-y-auto">
                  <div v-if="followers.length === 0" class="text-center text-gray-500 py-4">
                    No followers yet
                  </div>
                  <div v-else v-for="user in followers" :key="user.follower_id" 
                    class="flex items-center justify-between py-3 hover:bg-gray-50 px-2 rounded-lg cursor-pointer"
                    @click="navigateToProfile(user.follower.username)"
                  >
                    <div class="flex items-center gap-3">
                      <img :src="user.follower.avatar_url || '/placeholder-avatar.jpg'" class="w-10 h-10 rounded-full" />
                      <div>
                        <div class="font-medium text-gray-900">{{ user.follower.name }}</div>
                        <div class="text-sm text-gray-500">@{{ user.follower.username }}</div>
                      </div>
                    </div>
                    <button 
                      v-if="userStore.user?.id !== user.follower.id"
                      @click.stop="toggleFollow"
                      class="px-4 py-2 rounded-lg text-sm font-medium"
                      :class="isFollowing ? 'bg-gray-100 text-gray-700' : 'bg-blue-500 text-white'"
                    >
                      {{ isFollowing ? 'Following' : 'Follow' }}
                    </button>
                  </div>
                </div>
              </DialogPanel>
            </TransitionChild>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>

    <!-- Following Modal -->
    <TransitionRoot appear :show="showFollowingModal" as="template">
      <Dialog as="div" @close="showFollowingModal = false" class="relative z-10">
        <TransitionChild
          as="template"
          enter="duration-300 ease-out"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100"
          leave-to="opacity-0"
        >
          <div class="fixed inset-0 bg-black bg-opacity-25" />
        </TransitionChild>

        <div class="fixed inset-0 overflow-y-auto">
          <div class="flex min-h-full items-center justify-center p-4 text-center">
            <TransitionChild
              as="template"
              enter="duration-300 ease-out"
              enter-from="opacity-0 scale-95"
              enter-to="opacity-100 scale-100"
              leave="duration-200 ease-in"
              leave-from="opacity-100 scale-100"
              leave-to="opacity-0 scale-95"
            >
              <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900 mb-4">
                  Following
                </DialogTitle>
                <div class="max-h-96 overflow-y-auto">
                  <div v-if="following.length === 0" class="text-center text-gray-500 py-4">
                    Not following anyone yet
                  </div>
                  <div v-else v-for="user in following" :key="user.following_id" 
                    class="flex items-center justify-between py-3 hover:bg-gray-50 px-2 rounded-lg cursor-pointer"
                    @click="navigateToProfile(user.following.username)"
                  >
                    <div class="flex items-center gap-3">
                      <img :src="user.following.avatar_url || '/placeholder-avatar.jpg'" class="w-10 h-10 rounded-full" />
                      <div>
                        <div class="font-medium text-gray-900">{{ user.following.name }}</div>
                        <div class="text-sm text-gray-500">@{{ user.following.username }}</div>
                      </div>
                    </div>
                    <button 
                      v-if="userStore.user?.id !== user.following.id"
                      @click.stop="toggleFollow"
                      class="px-4 py-2 rounded-lg text-sm font-medium"
                      :class="isFollowing ? 'bg-gray-100 text-gray-700' : 'bg-blue-500 text-white'"
                    >
                      {{ isFollowing ? 'Following' : 'Follow' }}
                    </button>
                  </div>
                </div>
              </DialogPanel>
            </TransitionChild>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>

    <!-- Edit Profile Modal -->
    <TransitionRoot appear :show="showEditModal" as="template">
      <Dialog as="div" @close="showEditModal = false" class="relative z-50">
        <TransitionChild
          as="template"
          enter="duration-300 ease-out"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100"
          leave-to="opacity-0"
        >
          <div class="fixed inset-0 bg-black/25" />
        </TransitionChild>

        <div class="fixed inset-0 overflow-y-auto">
          <div class="flex min-h-full items-center justify-center p-4 text-center">
            <TransitionChild
              as="template"
              enter="duration-300 ease-out"
              enter-from="opacity-0 scale-95"
              enter-to="opacity-100 scale-100"
              leave="duration-200 ease-in"
              leave-from="opacity-100 scale-100"
              leave-to="opacity-0 scale-95"
            >
              <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <DialogTitle as="div" class="flex items-center justify-between border-b border-gray-200 pb-4 mb-6">
                  <h3 class="text-lg font-medium leading-6 text-gray-900">
                    Edit Profile
                  </h3>
                  <button
                    @click="showEditModal = false"
                    class="text-gray-400 hover:text-gray-500"
                  >
                    <PhX class="w-5 h-5" />
                  </button>
                </DialogTitle>

                <!-- Avatar Preview -->
                <div class="flex justify-center mb-6">
                  <div class="relative">
                    <img
                      :src="profile.avatar_url || '/placeholder-avatar.jpg'"
                      alt="Profile"
                      class="w-20 h-20 rounded-full object-cover border-2 border-gray-200"
                    />
                    <button
                      @click="showEditModal = true"
                      class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 rounded-full opacity-0 hover:opacity-100 transition-opacity"
                    >
                      <PhCamera class="w-6 h-6 text-white" />
                    </button>
                  </div>
                </div>

                <!-- Form -->
                <form @submit.prevent="updateProfile" class="space-y-4">
                  <!-- Success Message -->
                  <div
                    v-if="success"
                    class="bg-green-50 text-green-600 px-4 py-2 rounded-md text-sm mb-4"
                  >
                    {{ success }}
                  </div>

                  <!-- Error Message -->
                  <div
                    v-if="error"
                    class="bg-red-50 text-red-600 px-4 py-2 rounded-md text-sm mb-4"
                  >
                    {{ error }}
                  </div>

                  <!-- Name -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Name
                    </label>
                    <input
                      v-model="editedProfileData.name"
                      type="text"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      :disabled="isLoading"
                    />
                  </div>

                  <!-- Username -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Username
                    </label>
                    <div class="flex">
                      <span class="inline-flex items-center px-2.5 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
                        @
                      </span>
                      <input
                        v-model="editedProfileData.username"
                        type="text"
                        class="flex-1 px-3 py-2 border border-gray-300 rounded-r-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                        :disabled="isLoading"
                      />
                    </div>
                  </div>

                  <!-- Bio -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Bio
                    </label>
                    <textarea
                      v-model="editedProfileData.about"
                      rows="3"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      :disabled="isLoading"
                    ></textarea>
                  </div>

                  <!-- Website -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Website
                    </label>
                    <input
                      v-model="editedProfileData.website"
                      type="url"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      :disabled="isLoading"
                    />
                  </div>

                  <!-- Location -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Location
                    </label>
                    <input
                      v-model="editedProfileData.location"
                      type="text"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      :disabled="isLoading"
                    />
                  </div>

                  <!-- Submit Button -->
                  <div class="mt-6">
                    <button
                      type="submit"
                      class="w-full px-4 py-2 bg-blue-500 text-white rounded-md font-medium hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                      :disabled="isLoading"
                    >
                      {{ isLoading ? 'Saving...' : 'Submit' }}
                    </button>
                  </div>
                </form>
              </DialogPanel>
            </TransitionChild>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>
    <Footer />
  </div>
</template>