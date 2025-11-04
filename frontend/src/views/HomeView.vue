<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Print Header (only visible when printing) -->
    <div class="print-header">
      <h1 class="text-2xl font-bold">Measurement Data Report</h1>
      <p class="text-sm">Generated: {{ new Date().toLocaleString() }}</p>
    </div>

    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Measurement Data Viewer</h1>
      <p class="text-gray-600">Browse and visualize measurement data from all series</p>
    </div>

    <div v-if="initialLoading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Loading data...</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Print Button -->
      <div class="flex justify-end print:hidden">
        <button
          @click="handlePrint"
          class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-md text-sm font-medium transition flex items-center space-x-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
          </svg>
          <span>Print Report</span>
        </button>
      </div>

      <!-- Series Filter -->
      <SeriesFilter />

      <!-- Chart -->
      <div class="measurement-chart">
        <MeasurementChart />
      </div>

      <!-- Table -->
      <div class="measurement-table">
        <MeasurementTable />
      </div>

      <!-- Print Footer -->
      <div class="print-footer">
        <p>ZAI Measurement Data Collection System</p>
        <p>Page printed on {{ new Date().toLocaleDateString() }}</p>
      </div>
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

function handlePrint() {
  window.print()
}

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
