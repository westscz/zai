<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Admin Dashboard</h1>
      <p class="text-gray-600">Manage series and measurements</p>
    </div>

    <div v-if="!authStore.isAdmin" class="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded">
      <p class="text-yellow-800">You need admin privileges to access this page.</p>
    </div>

    <div v-else>
      <!-- Dashboard content will be added in next tasks -->
      <p class="text-gray-600">Dashboard components coming soon...</p>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
</script>
