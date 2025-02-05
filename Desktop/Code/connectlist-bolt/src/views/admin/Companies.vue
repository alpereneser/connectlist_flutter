<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { PhBuildings, PhPlus, PhPencil, PhTrash } from '@phosphor-icons/vue'
import type { Database } from '../../lib/supabase-types'

type Company = Database['public']['Tables']['companies']['Insert']

const companies = ref<Database['public']['Tables']['companies']['Row'][]>([])
const isLoading = ref(true)
const error = ref('')
const isModalOpen = ref(false)
const newCompany = ref<Company>({
  name: '',
  description: '',
  founding_date: null,
  website: '',
  headquarters_address: '',
  logo_url: '',
  company_type: [],
  status: 'draft'
})

const resetForm = () => {
  newCompany.value = {
    name: '',
    description: '',
    founding_date: null,
    website: '',
    headquarters_address: '',
    logo_url: '',
    company_type: [],
    status: 'draft'
  }
}

const handleSubmit = async () => {
  try {
    const { error: insertError } = await supabase
      .from('companies')
      .insert(newCompany.value)

    if (insertError) throw insertError

    isModalOpen.value = false
    resetForm()
    loadCompanies()
  } catch (err: any) {
    error.value = err.message
  }
}

const loadCompanies = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('companies')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    companies.value = data || []
  } catch (err: any) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  loadCompanies()
})
</script>

<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <PhBuildings :size="28" weight="bold" />
          Companies
        </h1>
        <button 
          @click="isModalOpen = true"
          class="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90"
        >
          <PhPlus :size="20" weight="bold" />
          Add Company
        </button>
      </div>
      <p class="text-gray-600 mt-1">Manage companies and organizations</p>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mb-6 p-4 bg-red-50 text-red-600 rounded-lg">
      {{ error }}
    </div>

    <!-- Companies Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Type
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-if="isLoading">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                Loading companies...
              </td>
            </tr>
            <tr v-else-if="companies.length === 0">
              <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                No companies found
              </td>
            </tr>
            <tr v-for="company in companies" :key="company.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <img 
                    v-if="company.logo_url"
                    :src="company.logo_url"
                    :alt="company.name"
                    class="w-10 h-10 rounded object-contain"
                  />
                  <div v-else class="w-10 h-10 bg-gray-200 rounded flex items-center justify-center">
                    <PhBuildings :size="20" class="text-gray-500" weight="bold" />
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ company.name }}
                    </div>
                    <div class="text-sm text-gray-500">
                      {{ company.founding_date ? new Date(company.founding_date).getFullYear() : 'N/A' }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ company.company_type?.join(', ') || 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': company.status === 'published',
                    'bg-yellow-100 text-yellow-800': company.status === 'draft',
                    'bg-gray-100 text-gray-800': company.status === 'archived'
                  }">
                  {{ company.status }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button 
                    class="p-1 text-gray-400 hover:text-primary rounded-full hover:bg-gray-100"
                    title="Edit company"
                  >
                    <PhPencil :size="20" weight="bold" />
                  </button>
                  <button 
                    class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100"
                    title="Delete company"
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

    <!-- Add Company Modal -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">Add New Company</h2>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Name *</label>
            <input
              v-model="newCompany.name"
              type="text"
              required
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
            <textarea
              v-model="newCompany.description"
              rows="4"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            ></textarea>
          </div>

          <!-- Founding Date -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Founding Date</label>
            <input
              v-model="newCompany.founding_date"
              type="date"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Website -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Website</label>
            <input
              v-model="newCompany.website"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Headquarters Address -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Headquarters Address</label>
            <input
              v-model="newCompany.headquarters_address"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Logo URL -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Logo URL</label>
            <input
              v-model="newCompany.logo_url"
              type="url"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
          </div>

          <!-- Company Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Company Type</label>
            <input
              v-model="newCompany.company_type"
              type="text"
              placeholder="Enter types separated by commas"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
              @input="e => newCompany.company_type = (e.target as HTMLInputElement).value.split(',').map(t => t.trim())"
            >
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="newCompany.status"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary"
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <!-- Form Actions -->
          <div class="flex justify-end gap-4 pt-4 border-t border-gray-200">
            <button
              type="button"
              @click="isModalOpen = false"
              class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-4 py-2 text-white bg-primary rounded-lg hover:bg-primary/90"
            >
              Add Company
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>