<template>
  <div class="bg-white rounded-lg shadow">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-xl font-semibold text-gray-900">Sensors Management</h2>
          <p class="text-sm text-gray-500 mt-1">Register sensors to submit measurement data via API</p>
        </div>
        <button
          @click="showCreateModal = true"
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition"
        >
          + Register Sensor
        </button>
      </div>
    </div>

    <div v-if="loading" class="px-6 py-12 text-center">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      <p class="mt-2 text-gray-600">Loading sensors...</p>
    </div>

    <div v-else class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Sensor Name
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Series
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              API Key
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Created
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-if="dataStore.sensors.length === 0">
            <td colspan="6" class="px-6 py-8 text-center text-gray-500">
              <div class="flex flex-col items-center">
                <svg class="w-12 h-12 text-gray-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
                </svg>
                <p class="font-medium">No sensors registered</p>
                <p class="text-sm">Register a sensor to start submitting measurements via API</p>
              </div>
            </td>
          </tr>
          <tr v-else v-for="sensor in dataStore.sensors" :key="sensor.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ sensor.name }}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                :style="{ backgroundColor: getSeriesColor(sensor.series_id) + '20', color: getSeriesColor(sensor.series_id) }"
              >
                {{ getSeriesName(sensor.series_id) }}
              </span>
            </td>
            <td class="px-6 py-4">
              <div class="flex items-center space-x-2">
                <code class="text-xs bg-gray-100 px-2 py-1 rounded font-mono">
                  {{ showApiKey[sensor.id] ? sensor.api_key : '••••••••••••••••' }}
                </code>
                <button
                  @click="toggleApiKey(sensor.id)"
                  class="text-gray-400 hover:text-gray-600"
                  :title="showApiKey[sensor.id] ? 'Hide' : 'Show'"
                >
                  <svg v-if="!showApiKey[sensor.id]" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
                <button
                  @click="copyApiKey(sensor.api_key)"
                  class="text-gray-400 hover:text-gray-600"
                  title="Copy to clipboard"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </button>
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                :class="[
                  'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                  sensor.is_active
                    ? 'bg-green-100 text-green-800'
                    : 'bg-red-100 text-red-800'
                ]"
              >
                {{ sensor.is_active ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              {{ formatDate(sensor.created_at) }}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button
                @click="viewApiDoc(sensor)"
                class="text-indigo-600 hover:text-indigo-900 mr-4"
              >
                API Doc
              </button>
              <button
                @click="deleteSensor(sensor)"
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create Modal -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
      @click.self="closeModal"
    >
      <div class="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900">Register New Sensor</h3>
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

          <div v-if="createdSensor" class="bg-green-50 border-l-4 border-green-500 p-4 rounded">
            <p class="text-green-800 text-sm font-semibold mb-2">Sensor registered successfully!</p>
            <p class="text-green-700 text-xs mb-2">Save this API key - it won't be shown again:</p>
            <div class="flex items-center space-x-2 bg-white p-2 rounded">
              <code class="text-xs font-mono flex-1 break-all">{{ createdSensor.api_key }}</code>
              <button
                type="button"
                @click="copyApiKey(createdSensor.api_key)"
                class="text-green-600 hover:text-green-800 flex-shrink-0"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Sensor Name *</label>
            <input
              v-model="formData.name"
              type="text"
              required
              maxlength="100"
              :disabled="!!createdSensor"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100"
              placeholder="e.g., Temperature Sensor ESP32-01"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Series *</label>
            <select
              v-model="formData.series_id"
              required
              :disabled="!!createdSensor"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100"
            >
              <option value="">Select a series</option>
              <option v-for="series in dataStore.series" :key="series.id" :value="series.id">
                {{ series.name }}
              </option>
            </select>
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              @click="closeModal"
              class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition"
            >
              {{ createdSensor ? 'Close' : 'Cancel' }}
            </button>
            <button
              v-if="!createdSensor"
              type="submit"
              :disabled="submitting"
              class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white rounded-md transition"
            >
              {{ submitting ? 'Registering...' : 'Register' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- API Documentation Modal -->
    <div
      v-if="showApiDocModal && selectedSensor"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
      @click.self="showApiDocModal = false"
    >
      <div class="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900">API Documentation - {{ selectedSensor.name }}</h3>
          <button @click="showApiDocModal = false" class="text-gray-400 hover:text-gray-600">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="space-y-4">
          <div>
            <h4 class="font-semibold text-gray-900 mb-2">Endpoint</h4>
            <code class="block bg-gray-100 p-3 rounded text-sm">POST /api/sensors/data</code>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-2">Headers</h4>
            <pre class="bg-gray-100 p-3 rounded text-sm overflow-x-auto"><code>X-API-Key: {{ selectedSensor.api_key }}
Content-Type: application/json</code></pre>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-2">Request Body</h4>
            <pre class="bg-gray-100 p-3 rounded text-sm overflow-x-auto"><code>{
  "value": 23.5,
  "timestamp": "2025-01-04T12:00:00Z"  // Optional
}</code></pre>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-2">Example with cURL</h4>
            <pre class="bg-gray-100 p-3 rounded text-xs overflow-x-auto"><code>curl -X POST http://localhost:8000/api/sensors/data \
  -H "X-API-Key: {{ selectedSensor.api_key }}" \
  -H "Content-Type: application/json" \
  -d '{"value": 23.5}'</code></pre>
          </div>

          <div>
            <h4 class="font-semibold text-gray-900 mb-2">Example with Python</h4>
            <pre class="bg-gray-100 p-3 rounded text-xs overflow-x-auto"><code>import requests

response = requests.post(
    'http://localhost:8000/api/sensors/data',
    headers={'X-API-Key': '{{ selectedSensor.api_key }}'},
    json={'value': 23.5}
)
print(response.json())</code></pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useDataStore } from '../stores/data'
import { format } from 'date-fns'

const dataStore = useDataStore()

const loading = ref(false)
const showCreateModal = ref(false)
const showApiDocModal = ref(false)
const selectedSensor = ref(null)
const submitting = ref(false)
const formError = ref('')
const createdSensor = ref(null)
const showApiKey = reactive({})

const formData = reactive({
  name: '',
  series_id: ''
})

function formatDate(dateString) {
  return format(new Date(dateString), 'yyyy-MM-dd HH:mm')
}

function getSeriesName(seriesId) {
  const series = dataStore.series.find(s => s.id === seriesId)
  return series?.name || 'Unknown'
}

function getSeriesColor(seriesId) {
  const series = dataStore.series.find(s => s.id === seriesId)
  return series?.color || '#3B82F6'
}

function toggleApiKey(sensorId) {
  showApiKey[sensorId] = !showApiKey[sensorId]
}

async function copyApiKey(apiKey) {
  try {
    await navigator.clipboard.writeText(apiKey)
    alert('API key copied to clipboard!')
  } catch (error) {
    console.error('Failed to copy:', error)
    alert('Failed to copy API key')
  }
}

function resetForm() {
  formData.name = ''
  formData.series_id = ''
  formError.value = ''
  createdSensor.value = null
}

function closeModal() {
  showCreateModal.value = false
  resetForm()
}

async function submitForm() {
  formError.value = ''
  submitting.value = true

  try {
    const sensor = await dataStore.createSensor(formData)
    createdSensor.value = sensor
  } catch (error) {
    formError.value = error.response?.data?.detail || 'Failed to register sensor. Please try again.'
  } finally {
    submitting.value = false
  }
}

function viewApiDoc(sensor) {
  selectedSensor.value = sensor
  showApiDocModal.value = true
}

async function deleteSensor(sensor) {
  if (!confirm(`Are you sure you want to delete sensor "${sensor.name}"?`)) {
    return
  }

  try {
    await dataStore.deleteSensor(sensor.id)
    alert('Sensor deleted successfully')
  } catch (error) {
    alert('Failed to delete sensor: ' + (error.response?.data?.detail || error.message))
  }
}

onMounted(async () => {
  loading.value = true
  try {
    await dataStore.fetchSensors()
  } catch (error) {
    console.error('Failed to load sensors:', error)
  } finally {
    loading.value = false
  }
})
</script>
