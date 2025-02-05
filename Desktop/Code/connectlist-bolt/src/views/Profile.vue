<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '../lib/supabase'
import Header from '../components/Header.vue'
import { useRoute, useRouter } from 'vue-router' 
import { PhPencil, PhUserPlus, PhUserMinus, PhEnvelope, PhCheck, PhX, PhCamera } from '@phosphor-icons/vue'
import type { Database } from '../lib/supabase-types'

const route = useRoute()
const router = useRouter()
const profile = ref<Database['public']['Tables']['profiles']['Row'] | null>(null)
const isUploadingAvatar = ref(false)
const editedProfile = ref<{
  full_name: string
  username: string
  bio: string | null
  website: string | null
  location: string | null
}>({
  full_name: '',
  username: '',
  bio: null,
  website: null,
  location: null
})
const isEditing = ref(false)
const currentUser = ref<string | null>(null)
const isFollowing = ref(false)
const followerCount = ref(0)
const followingCount = ref(0)
const isLoading = ref(false)
const error = ref('')
const success = ref('')

const isOwnProfile = computed(() => currentUser.value === profile.value?.id)

const startEditing = () => {
  if (profile.value) {
    editedProfile.value = {
      full_name: profile.value.full_name || '',
      username: profile.value.username,
      bio: profile.value.bio,
      website: profile.value.website,
      location: profile.value.location
    }
    isEditing.value = true
  }
}

const cancelEditing = () => {
  isEditing.value = false
  error.value = ''
  success.value = ''
}

const uploadAvatar = async (event: Event) => {
  const fileInput = event.target as HTMLInputElement
  if (!fileInput.files || fileInput.files.length === 0) return
  
  const file = fileInput.files[0]
  const fileExt = file.name.split('.').pop()
  const fileName = `${Math.random()}.${fileExt}`
  const filePath = `${fileName}`

  isUploadingAvatar.value = true
  error.value = ''

  try {
    // Upload image to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(filePath, file)

    if (uploadError) throw uploadError

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('avatars')
      .getPublicUrl(filePath)

    // Delete old avatar if exists
    if (profile.value?.avatar_url) {
      const oldFilePath = profile.value.avatar_url.split('/').pop()
      if (oldFilePath) {
        await supabase.storage
          .from('avatars')
          .remove([oldFilePath])
      }
    }

    // Update profile with new avatar URL
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        avatar_url: publicUrl,
        updated_at: new Date().toISOString()
      })
      .eq('id', profile.value?.id)

    if (updateError) throw updateError

    success.value = 'Profile photo updated successfully'
    await loadProfile() // Reload profile data
  } catch (err: any) {
    error.value = err.message
  } finally {
    isUploadingAvatar.value = false
  }
}

const saveProfile = async () => {
  if (!profile.value) return
  
  isLoading.value = true
  error.value = ''
  success.value = ''

  try {
    // Check if username is taken (if changed)
    if (editedProfile.value.username !== profile.value.username) {
      const { data: existingUser } = await supabase
        .from('profiles')
        .select('id')
        .eq('username', editedProfile.value.username)
        .maybeSingle()

      if (existingUser) {
        throw new Error('Username is already taken')
      }
    }

    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        username: editedProfile.value.username,
        full_name: editedProfile.value.full_name,
        bio: editedProfile.value.bio,
        website: editedProfile.value.website,
        location: editedProfile.value.location,
        updated_at: new Date().toISOString()
      })
      .eq('id', profile.value.id)

    if (updateError) throw updateError

    success.value = 'Profile updated successfully'
    await loadProfile() // Reload profile data
    isEditing.value = false
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

const loadProfile = async () => {
  error.value = ''
  isLoading.value = true
  const username = (route.params.username as string)?.toLowerCase()?.trim()?.replace('@', '')

  if (!username?.trim()) {
    error.value = 'Username is required'
    isLoading.value = false
    return
  }

  try {
    // Get user and profile data in parallel
    const [{ data: { user } }, { data: profileData, error: profileError }] = await Promise.all([
      supabase.auth.getUser(),
      supabase
        .from('profiles')
        .select('*')
        .eq('username', username)
        .maybeSingle()
    ])

    if (profileError) throw profileError
    
    if (!profileData) {
      error.value = 'Profile not found'
      isLoading.value = false
      return
    }
    
    currentUser.value = user?.id || null
    profile.value = profileData

    // Get follower and following counts in parallel
    const [followerData, followingData, followsData] = await Promise.all([
      // Get follower count
      supabase.rpc('get_follower_count', { 
        profile_id: profileData.id 
      }),
      
      // Get following count
      supabase.rpc('get_following_count', { 
        profile_id: profileData.id 
      }),
      
      // Check if current user follows this profile
      currentUser.value ? supabase.rpc(
        'check_if_follows',
        { 
          follower: currentUser.value, 
          following: profileData.id 
        }
      ) : Promise.resolve({ data: false })
    ])

    followerCount.value = followerData.data || 0
    followingCount.value = followingData.data || 0
    isFollowing.value = followsData.data || false
  } catch (err: any) {
    console.error('Error loading profile:', err)
    error.value = err.message || 'Error loading profile'
  } finally {
    isLoading.value = false
  }
}

const toggleFollow = async () => {
  if (!currentUser.value || !profile.value) return
  
  isLoading.value = true
  error.value = ''

  try {
    if (isFollowing.value) {
      // Unfollow
      const { error: unfollowError } = await supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUser.value)
        .eq('following_id', profile.value.id)

      if (unfollowError) throw unfollowError
    } else {
      // Follow
      const { error: followError } = await supabase
        .from('follows')
        .insert({
          follower_id: currentUser.value,
          following_id: profile.value.id
        })

      if (followError) throw followError
    }

    isFollowing.value = !isFollowing.value
    followerCount.value += isFollowing.value ? 1 : -1
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

const navigateToMessages = () => {
  router.push('/messages')
}

onMounted(async () => {
  await loadProfile()
})

// Watch for route changes to reload profile
watch(() => route.params.username, async () => {
  await loadProfile()
})
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-[51px]">
      <!-- Error Message -->
      <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
        {{ error }}
      </div>

      <div class="bg-white shadow rounded-lg">
        <!-- Profile Info -->
        <div class="p-8">
          <!-- Avatar and Actions -->
          <div class="flex items-start gap-8 mb-8">
            <!-- Avatar -->
            <div class="flex-shrink-0">
              <div class="relative group">
                <div class="w-32 h-32 rounded-full border-4 border-white overflow-hidden">
                  <img
                    v-if="profile?.avatar_url"
                    :src="profile.avatar_url"
                    :alt="profile?.full_name || ''"
                    class="w-full h-full object-cover"
                  />
                  <div v-else class="w-full h-full bg-gray-200 flex items-center justify-center">
                    <span class="text-4xl text-gray-500 font-semibold">
                      {{ profile?.full_name?.[0]?.toUpperCase() }}
                    </span>
                  </div>
                </div>
                
                <!-- Edit Avatar Button -->
                <template v-if="isOwnProfile && isEditing">
                  <input
                    type="file"
                    id="avatar-upload"
                    accept="image/*"
                    class="hidden"
                    @change="uploadAvatar"
                  />
                  <label
                    for="avatar-upload"
                    class="absolute inset-0 bg-black bg-opacity-40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center cursor-pointer"
                  >
                    <div class="flex flex-col items-center text-white">
                      <PhCamera :size="24" weight="bold" />
                      <span class="text-xs mt-1">
                        {{ isUploadingAvatar ? 'Uploading...' : 'Change Photo' }}
                      </span>
                    </div>
                  </label>
                </template>
              </div>
            </div>

            <!-- User Info and Stats -->
            <div class="flex-1">
              <div class="flex justify-between items-start mb-4">
                <!-- Name and Username -->
                <div>
                  <h1 class="text-2xl font-bold text-gray-900 mb-1">
                    <template v-if="isEditing">
                      <input
                        v-model="editedProfile.full_name"
                        type="text"
                        class="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                        placeholder="Your full name"
                      >
                    </template>
                    <template v-else>
                      {{ profile?.full_name }}
                    </template>
                  </h1>
                  <p class="text-gray-500">
                    <template v-if="isEditing">
                      <div class="flex items-center">
                        <span class="text-gray-400">@</span>
                        <input
                          v-model="editedProfile.username"
                          type="text"
                          class="px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                          placeholder="username"
                        >
                      </div>
                    </template>
                    <template v-else>
                      @{{ profile?.username }}
                    </template>
                  </p>
                </div>

                <!-- Action Buttons -->
                <div class="flex gap-2">
                  <!-- Edit Profile Button (Only shown on own profile) -->
                  <template v-if="isOwnProfile">
                    <button
                      v-show="!isEditing"
                      @click="startEditing"
                      class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                      title="Edit Profile"
                    >
                      <PhPencil :size="20" weight="bold" />
                    </button>
                  </template>

                  <template v-if="isEditing">
                    <button
                      @click="saveProfile"
                      :disabled="isLoading"
                      class="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50"
                    >
                      <PhCheck :size="20" weight="bold" />
                      <span class="font-medium">{{ isLoading ? 'Saving...' : 'Save' }}</span>
                    </button>
                    
                    <button
                      @click="cancelEditing"
                      class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                      <PhX :size="20" weight="bold" />
                      <span class="font-medium">Cancel</span>
                    </button>
                  </template>

                  <!-- Follow and Message Buttons (Only shown on other profiles) -->
                  <template v-if="!isOwnProfile">
                    <button
                      @click="toggleFollow"
                      :disabled="isLoading"
                      class="flex items-center gap-2 px-4 py-2 rounded-lg transition-colors"
                      :class="isFollowing ? 
                        'bg-gray-100 text-gray-700 hover:bg-gray-200' : 
                        'bg-primary text-white hover:bg-primary/90'"
                      :title="isFollowing ? 'Unfollow' : 'Follow'"
                    >
                      <component 
                        :is="isFollowing ? PhUserMinus : PhUserPlus"
                        :size="20" 
                        weight="bold" 
                      />
                    </button>

                    <router-link
                      :to="`/messages?user_id=${profile?.id}`"
                      class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg font-medium hover:bg-gray-200"
                    >
                      Message
                    </router-link>
                  </template>
                </div>
              </div>

              <!-- User Stats -->
              <div class="flex gap-6 mb-4">
                <div class="text-center">
                  <div class="text-lg font-bold text-gray-900">0</div>
                  <div class="text-sm text-gray-600">Lists</div>
                </div>
                <div class="text-center">
                  <div class="text-lg font-bold text-gray-900">0</div>
                  <div class="text-sm text-gray-600">Liked Lists</div>
                </div>
                <div class="text-center">
                  <div class="text-lg font-bold text-gray-900">{{ followerCount }}</div>
                  <div class="text-sm text-gray-600">Followers</div>
                </div>
                <div class="text-center">
                  <div class="text-lg font-bold text-gray-900">{{ followingCount }}</div>
                  <div class="text-sm text-gray-600">Following</div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Bio & Details -->
          <div class="space-y-4">
            <div>
              <template v-if="isEditing">
                <textarea
                  v-model="editedProfile.bio"
                  rows="3"
                  class="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                  placeholder="Write a bio..."
                ></textarea>
              </template>
              <template v-else>
                <p v-if="profile?.bio" class="text-gray-700">
                  {{ profile.bio }}
                </p>
              </template>
            </div>
            
            <div class="flex flex-wrap gap-4 text-sm text-gray-500">
              <div class="flex items-center">
                <span class="mr-2">📍</span>
                <template v-if="isEditing">
                  <input
                    v-model="editedProfile.location"
                    type="text"
                    class="px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Add location"
                  >
                </template>
                <template v-else>
                  <span v-if="profile?.location">
                    {{ profile.location }}
                  </span>
                </template>
              </div>
              
              <div class="flex items-center">
                <span class="mr-2">🔗</span>
                <template v-if="isEditing">
                  <input
                    v-model="editedProfile.website"
                    type="url"
                    class="px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Add website"
                  >
                </template>
                <a v-else-if="profile?.website" 
                  :href="profile.website"
                target="_blank"
                rel="noopener noreferrer"
                class="flex items-center text-primary hover:text-primary/80"
              >
                🔗 {{ profile.website }}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>