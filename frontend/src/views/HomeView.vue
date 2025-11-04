<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Measurement Data Viewer</h1>
      <p class="text-gray-600">Browse and visualize measurement data from all series</p>
    </div>

    <div v-if="initialLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Loading data...</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Series Filter -->
      <SeriesFilter />

      <!-- Chart -->
      <MeasurementChart />

      <!-- Table -->
      <MeasurementTable />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useDataStore } from '../stores/data'
import MeasurementChart from '../components/MeasurementChart.vue'
import MeasurementTable from '../components/MeasurementTable.vue'
import SeriesFilter from '../components/SeriesFilter.vue'

const dataStore = useDataStore()
const initialLoading = ref(true)

onMounted(async () => {
  try {
    await dataStore.fetchSeries()
    await dataStore.fetchMeasurements()
  } catch (error) {
    console.error('Failed to load initial data:', error)
  } finally {
    initialLoading.value = false
  }
})
</script>
