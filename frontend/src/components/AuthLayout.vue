<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
      <div class="text-center mb-6">
        <h1 class="text-3xl font-bold text-gray-800 mb-2">📏 measures</h1>
        <p class="text-gray-600">{{ subtitle }}</p>
      </div>

      <slot></slot>
    </div>
  </div>
</template>

<script setup>
defineProps({
  subtitle: {
    type: String,
    default: 'Data Collection System',
  },
})
</script>
