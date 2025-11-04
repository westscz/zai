<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">User Profile</h1>
      <p class="text-gray-600">Manage your account settings</p>
    </div>

    <div class="bg-white rounded-lg shadow p-6 max-w-2xl">
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-semibold mb-4">Account Information</h2>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
              <p class="text-gray-900">{{ authStore.user?.username }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <p class="text-gray-900">{{ authStore.user?.email }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Role</label>
              <p class="text-gray-900">
                <span v-if="authStore.isAdmin" class="text-indigo-600 font-medium">Administrator</span>
                <span v-else class="text-gray-600">Reader</span>
              </p>
            </div>
          </div>
        </div>

        <div class="border-t pt-6">
          <h2 class="text-xl font-semibold mb-4">Change Password</h2>
          <form @submit.prevent="handlePasswordChange" class="space-y-4">
            <div v-if="error" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
              <p class="text-red-800 text-sm">{{ error }}</p>
            </div>

            <div v-if="success" class="bg-green-50 border-l-4 border-green-500 p-4 rounded">
              <p class="text-green-800 text-sm">{{ success }}</p>
            </div>

            <div>
              <label for="newPassword" class="block text-sm font-medium text-gray-700 mb-1">
                New Password
              </label>
              <input
                id="newPassword"
                v-model="newPassword"
                type="password"
                required
                minlength="8"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                placeholder="At least 8 characters"
              />
            </div>

            <div>
              <label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-1">
                Confirm New Password
              </label>
              <input
                id="confirmPassword"
                v-model="confirmPassword"
                type="password"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                placeholder="Repeat your password"
              />
            </div>

            <button
              type="submit"
              :disabled="loading"
              class="bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white font-semibold py-2 px-6 rounded-md transition duration-200"
            >
              {{ loading ? 'Updating...' : 'Update Password' }}
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()

const newPassword = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')

async function handlePasswordChange() {
  loading.value = true
  error.value = ''
  success.value = ''

  if (newPassword.value !== confirmPassword.value) {
    error.value = 'Passwords do not match'
    loading.value = false
    return
  }

  try {
    await authStore.updateProfile({ password: newPassword.value })
    success.value = 'Password updated successfully!'
    newPassword.value = ''
    confirmPassword.value = ''
  } catch (err) {
    error.value = err.response?.data?.detail || 'Failed to update password. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
