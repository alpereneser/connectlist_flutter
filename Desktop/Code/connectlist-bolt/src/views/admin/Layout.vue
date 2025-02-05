<script setup lang="ts">
import { ref } from 'vue'
import AdminHeader from '../../components/AdminHeader.vue'
import Footer from '../../components/Footer.vue'
import { 
  PhUsers, PhFilmSlate, PhMonitorPlay, PhPerson, PhGameController, 
  PhBrowser, PhMusicNote, PhMapPin, PhBook, PhBuildings,
  PhChartBar
} from '@phosphor-icons/vue'
const menuItems = [
  { 
    name: 'Dashboard', 
    path: '/admin',
    icon: PhChartBar 
  },
  { 
    name: 'Users', 
    path: '/admin/users',
    icon: PhUsers 
  },
  { 
    name: 'Movies', 
    path: '/admin/movies',
    icon: PhFilmSlate
  },
  { 
    name: 'TV Series', 
    path: '/admin/series',
    icon: PhMonitorPlay
  },
  { 
    name: 'People', 
    path: '/admin/people',
    icon: PhPerson 
  },
  { 
    name: 'Games', 
    path: '/admin/games',
    icon: PhGameController 
  },
  { 
    name: 'Software', 
    path: '/admin/softwares',
    icon: PhBrowser 
  },
  { 
    name: 'Music', 
    path: '/admin/musics',
    icon: PhMusicNote 
  },
  { 
    name: 'Places', 
    path: '/admin/places',
    icon: PhMapPin 
  },
  { 
    name: 'Books', 
    path: '/admin/books',
    icon: PhBook 
  },
  { 
    name: 'Companies', 
    path: '/admin/companies',
    icon: PhBuildings 
  }
]

const isSidebarOpen = ref(true)
const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <AdminHeader />
    <div class="flex">
      <!-- Sidebar with adjusted height for footer -->
      <aside 
        class="fixed left-0 top-16 h-[calc(100vh-115px)] bg-white border-r border-gray-200 transition-all duration-300"
        :class="isSidebarOpen ? 'w-64' : 'w-16'"
      >
        <div class="h-full flex flex-col">
          <!-- Toggle Button -->
          <button 
            @click="toggleSidebar"
            class="p-4 text-gray-500 hover:text-gray-700 border-b border-gray-200"
          >
            <div class="flex items-center">
              <PhChartBar :size="24" weight="bold" />
              <span 
                v-if="isSidebarOpen"
                class="ml-3 font-medium"
              >
                Admin Panel
              </span>
            </div>
          </button>

          <!-- Navigation -->
          <nav class="flex-1 overflow-y-auto py-4">
            <router-link
              v-for="item in menuItems"
              :key="item.path"
              :to="item.path"
              class="flex items-center px-4 py-2 text-gray-700 hover:bg-gray-100"
              :class="{ 
                'bg-gray-100': $route.path === item.path,
                'justify-center': !isSidebarOpen
              }"
            >
              <component :is="item.icon" :size="24" weight="bold" />
              <span 
                v-if="isSidebarOpen"
                class="ml-3"
              >
                {{ item.name }}
              </span>
            </router-link>
          </nav>
        </div>
      </aside>

      <!-- Main Content -->
      <main 
        class="flex-1 transition-all duration-300 pb-[51px]"
        :class="isSidebarOpen ? 'ml-64' : 'ml-16'"
      >
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <router-view></router-view>
        </div>
      </main>
    </div>
    <Footer />
  </div>
</template>