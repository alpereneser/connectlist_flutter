import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import ForgotPassword from '../views/ForgotPassword.vue'
import EmailVerification from '../views/EmailVerification.vue'
import Profile from '../views/Profile.vue'
import Index from '../views/Index.vue'
import Messages from '../views/Messages.vue'
import Settings from '../views/Settings.vue'
import AdminLayout from '../views/admin/Layout.vue'
import AdminDashboard from '../views/admin/Dashboard.vue'
import AdminUsers from '../views/admin/Users.vue'
import AdminMovies from '../views/admin/Movies.vue'
import AdminSeries from '../views/admin/Series.vue'
import AdminPeople from '../views/admin/People.vue'
import AdminGames from '../views/admin/Games.vue'
import AdminSoftwares from '../views/admin/Softwares.vue'
import AdminMusics from '../views/admin/Musics.vue'
import AdminPlaces from '../views/admin/Places.vue'
import AdminBooks from '../views/admin/Books.vue'
import AdminCompanies from '../views/admin/Companies.vue'
import { supabase } from '../lib/supabase'
import type { NavigationGuardNext, RouteLocationNormalized } from 'vue-router'

// Navigation guard to check auth status
const requireAuth = async (
  _to: RouteLocationNormalized,
  _from: RouteLocationNormalized,
  next: NavigationGuardNext
) => {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) {
    next('/login')
  } else {
    next()
  }
}

const requireGuest = async (
  _to: RouteLocationNormalized,
  _from: RouteLocationNormalized,
  next: NavigationGuardNext
) => {
  const { data: { session } } = await supabase.auth.getSession()
  if (session) {
    next('/')
  } else {
    next()
  }
}

// Navigation guard for admin routes
const requireAdmin = async (
  _to: RouteLocationNormalized,
  _from: RouteLocationNormalized,
  next: NavigationGuardNext
) => {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) {
    next('/login')
    return
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', session.user.id)
    .single()

  if (profile?.role !== 'admin') {
    next('/')
  } else {
    next()
  }
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: Index,
      beforeEnter: requireAuth
    },
    {
      path: '/login',
      component: Login,
      beforeEnter: requireGuest
    },
    {
      path: '/register',
      component: Register,
      beforeEnter: requireGuest
    },
    {
      path: '/forgot-password',
      component: ForgotPassword,
      beforeEnter: requireGuest
    },
    {
      path: '/verify-email',
      component: EmailVerification
    },
    {
      path: '/@:username',
      component: Profile,
      beforeEnter: requireAuth
    },
    {
      path: '/admin',
      component: AdminLayout,
      beforeEnter: requireAdmin,
      children: [
        {
          path: '',
          component: AdminDashboard
        },
        {
          path: 'users',
          component: AdminUsers
        },
        {
          path: 'movies',
          component: AdminMovies
        },
        {
          path: 'series',
          component: AdminSeries
        },
        {
          path: 'people',
          component: AdminPeople
        },
        {
          path: 'games',
          component: AdminGames
        },
        {
          path: 'softwares',
          component: AdminSoftwares
        },
        {
          path: 'musics',
          component: AdminMusics
        },
        {
          path: 'places',
          component: AdminPlaces
        },
        {
          path: 'books',
          component: AdminBooks
        },
        {
          path: 'companies',
          component: AdminCompanies
        }
      ]
    },
    {
      path: '/messages',
      name: 'Messages',
      component: () => import('../views/Messages.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      component: Settings,
      beforeEnter: requireAuth
    }
  ]
})

// Update page titles
router.beforeEach((to, _from, next) => {
  // Default title suffix
  const suffix = 'Connectlist'
  
  // Set title based on route
  switch (to.path) {
    case '/':
      document.title = `Home - ${suffix}`
      break
    case '/login':
      document.title = `Login - ${suffix}`
      break
    case '/register':
      document.title = `Create Account - ${suffix}`
      break
    case '/forgot-password':
      document.title = `Reset Password - ${suffix}`
      break
    case '/verify-email':
      document.title = `Verify Email - ${suffix}`
      break
    case '/profile':
      document.title = `Profile - ${suffix}`
      break
    case '/settings':
      document.title = `Settings - ${suffix}`
      break
    case '/admin':
      document.title = `Admin Dashboard - ${suffix}`
      break
    default:
      document.title = suffix
  }
  
  next()
})

export default router