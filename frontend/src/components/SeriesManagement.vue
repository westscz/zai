<template>
  <div class="bg-white rounded-lg shadow">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h2 class="text-xl font-semibold text-gray-900">Series Management</h2>
        <button
          @click="showCreateModal = true"
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition"
        >
          + Create Series
        </button>
      </div>
    </div>

    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Name
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Range
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Color
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Description
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="dataStore.series.length === 0">
            <td colspan="5" class="px-6 py-4 text-center text-gray-500">
              No series found. Create your first series to get started.
            </td>
          </tr>
          <tr v-else v-for="series in dataStore.series" :key="series.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="flex items-center space-x-2">
                <div
                  class="w-3 h-3 rounded-full"
                  :style="{ backgroundColor: series.color }"
                ></div>
                <span class="text-sm font-medium text-gray-900">{{ series.name }}</span>
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
              {{ series.min_value }} - {{ series.max_value }} {{ series.unit }}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
              {{ series.color }}
            </td>
            <td class="px-6 py-4 text-sm text-gray-500">
              <span class="line-clamp-2">{{ series.description || 'N/A' }}</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button
                @click="editSeries(series)"
                class="text-indigo-600 hover:text-indigo-900 mr-4"
              >
                Edit
              </button>
              <button
                @click="deleteSeries(series)"
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create/Edit Modal -->
    <div
      v-if="showCreateModal || showEditModal"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
      @click.self="closeModal"
    >
      <div class="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900">
            {{ showEditModal ? 'Edit Series' : 'Create New Series' }}
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
            <label class="block text-sm font-medium text-gray-700 mb-1">Name *</label>
            <input
              v-model="formData.name"
              type="text"
              required
              maxlength="100"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g., Temperature Sensor 1"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              v-model="formData.description"
              maxlength="500"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Describe this series..."
            ></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Min Value *</label>
              <input
                v-model.number="formData.min_value"
                type="number"
                step="any"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Max Value *</label>
              <input
                v-model.number="formData.max_value"
                type="number"
                step="any"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Color *</label>
              <div class="flex items-center space-x-2">
                <input
                  v-model="formData.color"
                  type="color"
                  class="h-10 w-20 border border-gray-300 rounded cursor-pointer"
                />
                <input
                  v-model="formData.color"
                  type="text"
                  pattern="^#[0-9A-Fa-f]{6}$"
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  placeholder="#3B82F6"
                />
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Unit</label>
              <input
                v-model="formData.unit"
                type="text"
                maxlength="20"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                placeholder="e.g., °C, %, hPa"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Icon</label>
            <input
              v-model="formData.icon"
              type="text"
              maxlength="50"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g., chart-line, temperature-high"
            />
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
              {{ submitting ? 'Saving...' : (showEditModal ? 'Update' : 'Create') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useDataStore } from '../stores/data'

const dataStore = useDataStore()

const showCreateModal = ref(false)
const showEditModal = ref(false)
const editingSeriesId = ref(null)
const submitting = ref(false)
const formError = ref('')

const formData = reactive({
  name: '',
  description: '',
  min_value: 0,
  max_value: 100,
  color: '#3B82F6',
  icon: 'chart-line',
  unit: ''
})

function resetForm() {
  formData.name = ''
  formData.description = ''
  formData.min_value = 0
  formData.max_value = 100
  formData.color = '#3B82F6'
  formData.icon = 'chart-line'
  formData.unit = ''
  formError.value = ''
}

function closeModal() {
  showCreateModal.value = false
  showEditModal.value = false
  editingSeriesId.value = null
  resetForm()
}

function editSeries(series) {
  editingSeriesId.value = series.id
  formData.name = series.name
  formData.description = series.description || ''
  formData.min_value = series.min_value
  formData.max_value = series.max_value
  formData.color = series.color
  formData.icon = series.icon
  formData.unit = series.unit || ''
  showEditModal.value = true
}

async function submitForm() {
  formError.value = ''

  // Validation
  if (formData.max_value <= formData.min_value) {
    formError.value = 'Max value must be greater than min value'
    return
  }

  submitting.value = true

  try {
    if (showEditModal.value) {
      await dataStore.updateSeries(editingSeriesId.value, formData)
      alert('Series updated successfully')
    } else {
      await dataStore.createSeries(formData)
      alert('Series created successfully')
    }
    closeModal()
  } catch (error) {
    formError.value = error.response?.data?.detail || 'Operation failed. Please try again.'
  } finally {
    submitting.value = false
  }
}

async function deleteSeries(series) {
  if (!confirm(`Are you sure you want to delete "${series.name}"? This will also delete all associated measurements.`)) {
    return
  }

  try {
    await dataStore.deleteSeries(series.id)
    alert('Series deleted successfully')
  } catch (error) {
    alert('Failed to delete series: ' + (error.response?.data?.detail || error.message))
  }
}
</script>
