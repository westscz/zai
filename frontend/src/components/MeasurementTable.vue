<template>
  <div class="bg-white rounded-lg shadow overflow-hidden">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h2 class="text-xl font-semibold text-gray-900">Measurements</h2>
        <span class="text-sm text-gray-600">
          {{ filteredMeasurements.length }} records
        </span>
      </div>
    </div>

    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Timestamp
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Series
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Value
            </th>
            <th v-if="isAdmin" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="loading">
            <td colspan="4" class="px-6 py-4 text-center text-gray-500">
              Loading...
            </td>
          </tr>
          <tr v-else-if="filteredMeasurements.length === 0">
            <td colspan="4" class="px-6 py-4 text-center text-gray-500">
              No measurements found
            </td>
          </tr>
          <tr
            v-else
            v-for="measurement in paginatedMeasurements"
            :key="measurement.id"
            class="hover:bg-gray-50 cursor-pointer"
            :class="{ 'bg-indigo-50': dataStore.selectedMeasurementId === measurement.id }"
            @click="selectMeasurement(measurement)"
          >
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
              {{ formatTimestamp(measurement.timestamp) }}
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                :style="{ backgroundColor: getSeriesColor(measurement.series_id) + '20', color: getSeriesColor(measurement.series_id) }"
              >
                {{ getSeriesName(measurement.series_id) }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
              {{ measurement.value.toFixed(2) }} {{ getSeriesUnit(measurement.series_id) }}
            </td>
            <td v-if="isAdmin" class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button
                @click.stop="editMeasurement(measurement)"
                class="text-indigo-600 hover:text-indigo-900 mr-4"
              >
                Edit
              </button>
              <button
                @click.stop="deleteMeasurement(measurement)"
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="bg-gray-50 px-6 py-3 border-t border-gray-200">
      <div class="flex items-center justify-between">
        <div class="text-sm text-gray-700">
          Showing {{ (currentPage - 1) * pageSize + 1 }} to {{ Math.min(currentPage * pageSize, filteredMeasurements.length) }} of {{ filteredMeasurements.length }} results
        </div>
        <div class="flex space-x-2">
          <button
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="px-3 py-1 rounded bg-white border border-gray-300 text-gray-700 text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
          >
            Previous
          </button>
          <button
            v-for="page in visiblePages"
            :key="page"
            @click="currentPage = page"
            :class="[
              'px-3 py-1 rounded text-sm',
              page === currentPage
                ? 'bg-indigo-600 text-white'
                : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
            ]"
          >
            {{ page }}
          </button>
          <button
            @click="currentPage++"
            :disabled="currentPage === totalPages"
            class="px-3 py-1 rounded bg-white border border-gray-300 text-gray-700 text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDataStore } from '../stores/data'
import { useAuthStore } from '../stores/auth'
import { format } from 'date-fns'

const dataStore = useDataStore()
const authStore = useAuthStore()

const loading = computed(() => dataStore.loading)
const isAdmin = computed(() => authStore.isAdmin)

const currentPage = ref(1)
const pageSize = ref(50)
const showAddModal = ref(false)

const filteredMeasurements = computed(() => {
  let measurements = dataStore.measurements.filter(m =>
    dataStore.selectedSeriesIds.includes(m.series_id)
  )


  if (dataStore.chartSelectionRange) {
    const start = new Date(dataStore.chartSelectionRange.start).getTime()
    const end = new Date(dataStore.chartSelectionRange.end).getTime()
    measurements = measurements.filter(m => {
      const timestamp = new Date(m.timestamp).getTime()
      return timestamp >= start && timestamp <= end
    })
  }

  return measurements
})

const totalPages = computed(() => Math.ceil(filteredMeasurements.value.length / pageSize.value))

const paginatedMeasurements = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredMeasurements.value.slice(start, end)
})

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, currentPage.value - 2)
  const end = Math.min(totalPages.value, currentPage.value + 2)

  for (let i = start; i <= end; i++) {
    pages.push(i)
  }

  return pages
})

function formatTimestamp(timestamp) {
  return format(new Date(timestamp), 'yyyy-MM-dd HH:mm:ss')
}

function getSeriesName(seriesId) {
  const series = dataStore.series.find(s => s.id === seriesId)
  return series?.name || 'Unknown'
}

function getSeriesColor(seriesId) {
  const series = dataStore.series.find(s => s.id === seriesId)
  return series?.color || '#3B82F6'
}

function getSeriesUnit(seriesId) {
  const series = dataStore.series.find(s => s.id === seriesId)
  return series?.unit || ''
}

function selectMeasurement(measurement) {
  dataStore.setSelectedMeasurement(measurement.id)
}

async function editMeasurement(measurement) {

  console.log('Edit measurement:', measurement)
}

async function deleteMeasurement(measurement) {
  if (!confirm(`Are you sure you want to delete this measurement?`)) {
    return
  }

  try {
    await dataStore.deleteMeasurement(measurement.id)
    alert('Measurement deleted successfully')
  } catch (error) {
    alert('Failed to delete measurement: ' + (error.response?.data?.detail || error.message))
  }
}
</script>
