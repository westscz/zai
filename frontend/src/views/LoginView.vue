<template>
  <AuthLayout subtitle="Sign in to your account">
    <form @submit.prevent="handleLogin" class="space-y-4">
      <div v-if="error" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
        <p class="text-red-800 text-sm">{{ error }}</p>
      </div>

      <div>
        <label for="username" class="block text-sm font-medium text-gray-700 mb-1">
          Username
        </label>
        <input
          id="username"
          v-model="username"
          type="text"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Enter your username"
        />
      </div>

      <div>
        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
          Password
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Enter your password"
        />
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-md transition duration-200"
      >
        {{ loading ? 'Signing in...' : 'Sign In' }}
      </button>

      <div class="text-center text-sm text-gray-600">
        Don't have an account?
        <router-link to="/register" class="text-indigo-600 hover:text-indigo-700 font-medium">
          Register
        </router-link>
      </div>

      <div class="text-center text-sm text-gray-600">
        <router-link to="/" class="text-indigo-600 hover:text-indigo-700 font-medium">
          Continue as guest
        </router-link>
      </div>
    </form>
  </AuthLayout>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AuthLayout from '../components/AuthLayout.vue'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  loading.value = true
  error.value = ''

  try {
    await authStore.login(username.value, password.value)
    router.push('/dashboard')
  } catch (err) {
    error.value = err.response?.data?.detail || 'Login failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
