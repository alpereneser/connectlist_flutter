<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhUsers, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Profile = Database['public']['Tables']['profiles']['Row']

const users = ref<Profile[]>([])
const isLoading = ref(true)
const error = ref('')

const loadUsers = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .not('role', 'is', null)
    
    if (fetchError) throw fetchError
    
    users.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhUsers :size="28" weight="bold" />
          Users
        </h1>
        <button class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90">
          <PhPlus :size="20" weight="bold" />
          Add User
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage users and their roles</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Users Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Joined
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-if="isLoading">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                Loading users...
              </td>
            </tr>
            <tr v-else-if="users.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No users found
              </td>
            </tr>
            <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                    <span class="text-sm font-medium text-gray-500">
                      {{ user.full_name?.[0]?.toUpperCase() }}
                    </span>
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ user.full_name }}
                    </div>
                    <div class="text-sm text-gray-500">
                      @{{ user.username }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-red-100 text-red-800': user.role === 'admin',
                    'bg-blue-100 text-blue-800': user.role === 'editor',
                    'bg-green-100 text-green-800': user.role === 'writer',
                    'bg-gray-100 text-gray-800': user.role === 'user'
                  }">
                  {{ user.role }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ new Date(user.created_at).toLocaleDateString() }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit user"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete user"
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
  </div>
</template>