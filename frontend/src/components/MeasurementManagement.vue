<template>
  <div class="bg-white rounded-lg shadow">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h2 class="text-xl font-semibold text-gray-900">Measurement Management</h2>
        <button
          @click="showCreateModal = true"
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition"
        >
          + Add Measurement
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Filter by Series</label>
          <select
            v-model="filterSeriesId"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option :value="null">All Series</option>
            <option v-for="series in dataStore.series" :key="series.id" :value="series.id">
              {{ series.name }}
            </option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
          <input
            v-model="filterStartDate"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
          <input
            v-model="filterEndDate"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>
    </div>

    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              ID
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Timestamp
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Series
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Value
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="filteredMeasurements.length === 0">
            <td colspan="5" class="px-6 py-4 text-center text-gray-500">
              No measurements found
            </td>
          </tr>
          <tr v-else v-for="measurement in paginatedMeasurements" :key="measurement.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              #{{ measurement.id }}
            </td>
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
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button
                @click="editMeasurement(measurement)"
                class="text-indigo-600 hover:text-indigo-900 mr-4"
              >
                Edit
              </button>
              <button
                @click="deleteMeasurement(measurement)"
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

    <!-- Create/Edit Modal -->
    <div
      v-if="showCreateModal || showEditModal"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
      @click.self="closeModal"
      @keydown.esc="closeModal"
    >
      <div
        ref="modalRef"
        class="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white"
        @keydown.tab="trapFocus"
      >
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900">
            {{ showEditModal ? 'Edit Measurement' : 'Add New Measurement' }}
          </h3>
          <button @click="closeModal" class="text-gray-400 hover:text-gray-600">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form @submit.prevent="submitForm" class="space-y-4">
          <div v-if="formError" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
            <p class="text-red-800 text-sm">{{ formError }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Series *</label>
            <select
              v-model="formData.series_id"
              required
              :disabled="showEditModal"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100"
            >
              <option value="">Select a series</option>
              <option v-for="series in dataStore.series" :key="series.id" :value="series.id">
                {{ series.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Value *</label>
            <div class="relative">
              <input
                v-model.number="formData.value"
                type="number"
                step="any"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <span v-if="selectedSeries" class="absolute right-3 top-2 text-sm text-gray-500">
                {{ selectedSeries.unit }}
              </span>
            </div>
            <p v-if="selectedSeries" class="mt-1 text-xs text-gray-500">
              Range: {{ selectedSeries.min_value }} - {{ selectedSeries.max_value }}
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Timestamp</label>
            <input
              v-model="formData.timestamp"
              type="datetime-local"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <p class="mt-1 text-xs text-gray-500">Leave empty to use current time</p>
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              @click="closeModal"
              class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submitting"
              class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white rounded-md transition"
            >
              {{ submitting ? 'Saving...' : (showEditModal ? 'Update' : 'Add') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, nextTick } from 'vue'
import { useDataStore } from '../stores/data'
import { format } from 'date-fns'

const dataStore = useDataStore()

const modalRef = ref(null)
const showCreateModal = ref(false)
const showEditModal = ref(false)
const editingMeasurementId = ref(null)
const submitting = ref(false)
const formError = ref('')

const filterSeriesId = ref(null)
const filterStartDate = ref('')
const filterEndDate = ref('')

const currentPage = ref(1)
const pageSize = ref(20)

const formData = reactive({
  series_id: '',
  value: 0,
  timestamp: ''
})

const selectedSeries = computed(() => {
  if (!formData.series_id) return null
  return dataStore.series.find(s => s.id === formData.series_id)
})

const filteredMeasurements = computed(() => {
  let measurements = dataStore.measurements

  if (filterSeriesId.value !== null) {
    measurements = measurements.filter(m => m.series_id === filterSeriesId.value)
  }

  if (filterStartDate.value) {
    const startDate = new Date(filterStartDate.value)
    measurements = measurements.filter(m => new Date(m.timestamp) >= startDate)
  }

  if (filterEndDate.value) {
    const endDate = new Date(filterEndDate.value)
    measurements = measurements.filter(m => new Date(m.timestamp) <= endDate)
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

function resetForm() {
  formData.series_id = ''
  formData.value = 0
  formData.timestamp = ''
  formError.value = ''
}

function closeModal() {
  showCreateModal.value = false
  showEditModal.value = false
  editingMeasurementId.value = null
  resetForm()
}

function editMeasurement(measurement) {
  editingMeasurementId.value = measurement.id
  formData.series_id = measurement.series_id
  formData.value = measurement.value
  formData.timestamp = format(new Date(measurement.timestamp), "yyyy-MM-dd'T'HH:mm")
  showEditModal.value = true
}

async function submitForm() {
  formError.value = ''

  // Validation
  if (selectedSeries.value) {
    if (formData.value < selectedSeries.value.min_value || formData.value > selectedSeries.value.max_value) {
      formError.value = `Value must be between ${selectedSeries.value.min_value} and ${selectedSeries.value.max_value}`
      return
    }
  }

  submitting.value = true

  try {
    const payload = {
      series_id: formData.series_id,
      value: formData.value,
      timestamp: formData.timestamp ? new Date(formData.timestamp).toISOString() : null
    }

    if (showEditModal.value) {
      await dataStore.updateMeasurement(editingMeasurementId.value, payload)
      alert('Measurement updated successfully')
    } else {
      await dataStore.createMeasurement(payload)
      alert('Measurement added successfully')
    }
    closeModal()
  } catch (error) {
    formError.value = error.response?.data?.detail || 'Operation failed. Please try again.'
  } finally {
    submitting.value = false
  }
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

// Focus trap for modal accessibility
function trapFocus(event) {
  if (!modalRef.value) return

  const focusableElements = modalRef.value.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const firstElement = focusableElements[0]
  const lastElement = focusableElements[focusableElements.length - 1]

  if (event.shiftKey && document.activeElement === firstElement) {
    event.preventDefault()
    lastElement.focus()
  } else if (!event.shiftKey && document.activeElement === lastElement) {
    event.preventDefault()
    firstElement.focus()
  }
}

// Auto-focus first input when modal opens
watch([showCreateModal, showEditModal], async ([create, edit]) => {
  if (create || edit) {
    await nextTick()
    if (modalRef.value) {
      const firstInput = modalRef.value.querySelector('select, input')
      if (firstInput) {
        firstInput.focus()
      }
    }
  }
})
</script>
