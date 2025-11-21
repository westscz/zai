<template>
  <nav class="bg-white shadow-md print:hidden">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <div class="flex items-center">
          <router-link to="/" class="text-xl font-bold text-indigo-600">
            📏 measures
          </router-link>

          <div class="ml-10 flex space-x-4">
            <router-link
              to="/"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Home
            </router-link>

            <router-link
              v-if="authStore.isAuthenticated"
              to="/dashboard"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Admin Dashboard
            </router-link>
          </div>
        </div>

        <div class="flex items-center space-x-4">
          <template v-if="authStore.isAuthenticated">
            <span class="text-sm text-gray-700">
              {{ authStore.user?.username }}
              <span v-if="authStore.isAdmin" class="text-xs bg-indigo-100 text-indigo-800 px-2 py-1 rounded ml-1">
                Admin
              </span>
            </span>

            <router-link
              to="/profile"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Profile
            </router-link>

            <button
              @click="handleLogout"
              class="bg-gray-200 hover:bg-gray-300 text-gray-800 px-4 py-2 rounded-md text-sm font-medium transition"
            >
              Logout
            </button>
          </template>

          <template v-else>
            <router-link
              to="/login"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Login
            </router-link>

            <router-link
              to="/register"
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition"
            >
              Register
            </router-link>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

function handleLogout() {
  authStore.logout()
  router.push('/')
}
</script>
