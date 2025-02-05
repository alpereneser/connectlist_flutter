<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import Header from '../components/Header.vue'
import Footer from '../components/Footer.vue'
import { PhUser, PhEnvelope, PhGlobe, PhMapPin, PhTextT, PhLock, PhBell, PhEye, PhUserCircle, PhShieldCheck, PhBrowsers, PhCamera } from '@phosphor-icons/vue'
import type { Database } from '../lib/supabase-types'

const userProfile = ref<Database['public']['Tables']['profiles']['Row'] | null>(null)
const isLoading = ref(false)
const isUploadingAvatar = ref(false)
const error = ref('')
const success = ref('')

// Form fields
const fullName = ref('')
const username = ref('')
const email = ref('')
const website = ref('')
const location = ref('')
const bio = ref('')
const isPrivateProfile = ref(false)
const emailNotifications = ref({
  newFollower: true,
  listShared: true,
  listUpdates: true,
  mentions: true
})
const privacySettings = ref({
  showLocation: true,
  showEmail: false,
  allowTagging: true,
  showActivity: true
})
const activeTab = ref('edit')

const loadProfile = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  
  if (user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()
    
    if (profile) {
      userProfile.value = profile
      fullName.value = profile.full_name || ''
      username.value = profile.username
      website.value = profile.website || ''
      location.value = profile.location || ''
      bio.value = profile.bio || ''
      email.value = user.email || ''
    }
  }
}

const updateProfile = async () => {
  isLoading.value = true
  error.value = ''
  success.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('No user found')

    // Check if username is taken (if changed)
    if (username.value !== userProfile.value?.username) {
      const { data: existingUser } = await supabase
        .from('profiles')
        .select('id')
        .eq('username', username.value)
        .maybeSingle()

      if (existingUser) {
        throw new Error('Username is already taken')
      }
    }

    // Update profile
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        username: username.value,
        full_name: fullName.value,
        website: website.value || null,
        location: location.value || null,
        bio: bio.value || null,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id)

    if (updateError) throw updateError

    success.value = 'Profile updated successfully'
    await loadProfile()
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
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
    if (userProfile.value?.avatar_url) {
      const oldFilePath = userProfile.value.avatar_url.split('/').pop()
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
      .eq('id', userProfile.value?.id)

    if (updateError) throw updateError

    success.value = 'Profile photo updated successfully'
    await loadProfile()
  } catch (err: any) {
    error.value = err.message
  } finally {
    isUploadingAvatar.value = false
  }
}

onMounted(() => {
  loadProfile()
})
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-[51px]">
      <div class="max-w-2xl mx-auto">
        <div class="bg-white shadow rounded-lg">
          <!-- Settings Navigation -->
          <div class="border-b border-gray-200">
            <nav class="flex">
              <button
                @click="activeTab = 'edit'"
                class="px-6 py-4 text-sm font-medium border-b-2 -mb-px"
                :class="activeTab === 'edit' ? 'text-primary border-primary' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'"
              >
                <span class="flex items-center gap-2">
                  <PhUserCircle :size="20" weight="bold" />
                  Edit Profile
                </span>
              </button>
              <button
                @click="activeTab = 'privacy'"
                class="px-6 py-4 text-sm font-medium border-b-2 -mb-px"
                :class="activeTab === 'privacy' ? 'text-primary border-primary' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'"
              >
                <span class="flex items-center gap-2">
                  <PhLock :size="20" weight="bold" />
                  Privacy
                </span>
              </button>
              <button
                @click="activeTab = 'notifications'"
                class="px-6 py-4 text-sm font-medium border-b-2 -mb-px"
                :class="activeTab === 'notifications' ? 'text-primary border-primary' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'"
              >
                <span class="flex items-center gap-2">
                  <PhBell :size="20" weight="bold" />
                  Notifications
                </span>
              </button>
            </nav>
          </div>

          <!-- Success and Error Messages -->
          <div class="p-6">
            <!-- Success Message -->
            <div v-if="success" class="p-4 bg-green-50 text-green-600 rounded-lg">
              {{ success }}
            </div>
            
            <!-- Error Message -->
            <div v-if="error" class="p-4 bg-red-50 text-red-600 rounded-lg">
              {{ error }}
            </div>
          </div>

          <!-- Edit Profile Tab -->
          <form v-if="activeTab === 'edit'" @submit.prevent="updateProfile" class="p-6 space-y-6">
            <!-- Profile Picture -->
            <div class="flex items-center space-x-6 relative">
              <div class="w-20 h-20 rounded-full relative group">
                <img
                  v-if="userProfile?.avatar_url"
                  :src="userProfile.avatar_url"
                  :alt="fullName"
                  class="w-full h-full object-cover rounded-full"
                />
                <div v-else class="w-full h-full bg-gray-200 rounded-full flex items-center justify-center">
                  <span class="text-2xl font-semibold text-gray-500">
                  {{ fullName[0]?.toUpperCase() }}
                  </span>
                </div>
                <div class="absolute inset-0 bg-black bg-opacity-40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  <PhCamera :size="24" class="text-white" weight="bold" />
                </div>
              </div>
              <div>
                <input
                  type="file"
                  id="avatar-upload"
                  accept="image/*"
                  class="hidden"
                  @change="uploadAvatar"
                />
                <label
                  for="avatar-upload"
                  class="text-primary hover:text-primary/80 font-medium cursor-pointer"
                >
                  {{ isUploadingAvatar ? 'Uploading...' : 'Change Profile Photo' }}
                </label>
              </div>
            </div>

            <!-- Full Name -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Full Name</label>
              <div class="col-span-2">
                <div class="relative">
                  <PhUser 
                    :size="20" 
                    weight="bold" 
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
                  />
                  <input
                    v-model="fullName"
                    type="text"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Your full name"
                  >
                </div>
              </div>
            </div>

            <!-- Username -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Username</label>
              <div class="col-span-2">
                <div class="relative">
                  <span 
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                  >@</span>
                  <input
                    v-model="username"
                    type="text"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Your username"
                  >
                </div>
              </div>
            </div>

            <!-- Email -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Email</label>
              <div class="col-span-2">
                <div class="relative">
                  <PhEnvelope 
                    :size="20" 
                    weight="bold" 
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
                  />
                  <input
                    v-model="email"
                    type="email"
                    disabled
                    class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-300 rounded-lg text-gray-500 cursor-not-allowed"
                  >
                </div>
              </div>
            </div>

            <!-- Website -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Website</label>
              <div class="col-span-2">
                <div class="relative">
                  <PhGlobe 
                    :size="20" 
                    weight="bold" 
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
                  />
                  <input
                    v-model="website"
                    type="url"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Your website"
                  >
                </div>
              </div>
            </div>

            <!-- Location -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Location</label>
              <div class="col-span-2">
                <div class="relative">
                  <PhMapPin 
                    :size="20" 
                    weight="bold" 
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" 
                  />
                  <input
                    v-model="location"
                    type="text"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Your location"
                  >
                </div>
              </div>
            </div>

            <!-- Bio -->
            <div class="grid grid-cols-3 gap-4 items-start">
              <label class="text-sm font-medium text-gray-700 pt-2">Bio</label>
              <div class="col-span-2">
                <div class="relative">
                  <PhTextT 
                    :size="20" 
                    weight="bold" 
                    class="absolute left-3 top-3 text-gray-400" 
                  />
                  <textarea
                    v-model="bio"
                    rows="4"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
                    placeholder="Write a short bio..."
                  ></textarea>
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <div class="grid grid-cols-3 gap-4">
              <div></div>
              <div class="col-span-2">
                <button
                  type="submit"
                  class="w-full bg-primary text-white py-2 px-4 rounded-lg font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  :disabled="isLoading"
                >
                  {{ isLoading ? 'Saving...' : 'Save Changes' }}
                </button>
              </div>
            </div>
          </form>

          <!-- Privacy Tab -->
          <div v-else-if="activeTab === 'privacy'" class="p-6 space-y-6">
            <div class="space-y-6">
              <!-- Account Privacy -->
              <div class="flex items-center justify-between">
                <div class="flex items-start gap-3">
                  <div class="p-2 bg-primary/10 rounded-lg">
                    <PhEye :size="24" class="text-primary" weight="bold" />
                  </div>
                  <div>
                    <h3 class="text-sm font-medium text-gray-900">Private Account</h3>
                    <p class="text-sm text-gray-500">When your account is private, only people you approve can see your lists.</p>
                  </div>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" v-model="isPrivateProfile" class="sr-only peer">
                  <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                </label>
              </div>

              <!-- Privacy Settings -->
              <div class="space-y-4">
                <h3 class="text-sm font-medium text-gray-900 flex items-center gap-2">
                  <PhShieldCheck :size="20" weight="bold" class="text-primary" />
                  Privacy Settings
                </h3>
                
                <div class="space-y-3">
                  <div class="flex items-center justify-between">
                    <label class="text-sm text-gray-700">Show location on profile</label>
                    <label class="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="privacySettings.showLocation" class="sr-only peer">
                      <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div class="flex items-center justify-between">
                    <label class="text-sm text-gray-700">Show email on profile</label>
                    <label class="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="privacySettings.showEmail" class="sr-only peer">
                      <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div class="flex items-center justify-between">
                    <label class="text-sm text-gray-700">Allow others to tag you</label>
                    <label class="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="privacySettings.allowTagging" class="sr-only peer">
                      <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div class="flex items-center justify-between">
                    <label class="text-sm text-gray-700">Show activity status</label>
                    <label class="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="privacySettings.showActivity" class="sr-only peer">
                      <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                </div>
              </div>

              <!-- Login Activity -->
              <div class="pt-4">
                <h3 class="text-sm font-medium text-gray-900 flex items-center gap-2 mb-3">
                  <PhBrowsers :size="20" weight="bold" class="text-primary" />
                  Login Activity
                </h3>
                <button class="text-sm text-primary hover:text-primary/80">
                  View login activity
                </button>
              </div>
            </div>
          </div>

          <!-- Notifications Tab -->
          <div v-else-if="activeTab === 'notifications'" class="p-6 space-y-6">
            <div class="space-y-4">
              <h3 class="text-sm font-medium text-gray-900 flex items-center gap-2">
                <PhBell :size="20" weight="bold" class="text-primary" />
                Email Notifications
              </h3>
              
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <label class="text-sm text-gray-700">New follower notifications</label>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" v-model="emailNotifications.newFollower" class="sr-only peer">
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                  </label>
                </div>
                
                <div class="flex items-center justify-between">
                  <label class="text-sm text-gray-700">List shared with you</label>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" v-model="emailNotifications.listShared" class="sr-only peer">
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                  </label>
                </div>
                
                <div class="flex items-center justify-between">
                  <label class="text-sm text-gray-700">List updates</label>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" v-model="emailNotifications.listUpdates" class="sr-only peer">
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                  </label>
                </div>
                
                <div class="flex items-center justify-between">
                  <label class="text-sm text-gray-700">Mentions and tags</label>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" v-model="emailNotifications.mentions" class="sr-only peer">
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    <Footer />
  </div>
</template>