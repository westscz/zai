<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Measurement Data Viewer</h1>
      <p class="text-gray-600">Browse and visualize measurement data from all series</p>
    </div>

    <div v-if="dataStore.loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Loading data...</p>
    </div>

    <div v-else>
      <!-- Placeholder for chart and table components (to be created in next tasks) -->
      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Chart will be here</h2>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Table will be here</h2>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useDataStore } from '../stores/data'

const dataStore = useDataStore()

onMounted(async () => {
  await dataStore.fetchSeries()
  await dataStore.fetchMeasurements()
})
</script>
