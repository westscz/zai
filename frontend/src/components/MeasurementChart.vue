<template>
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex justify-between items-center mb-4">
      <h2 class="text-xl font-semibold text-gray-900">Measurement Data</h2>
      <div class="flex space-x-2">
        <button
          v-for="range in timeRanges"
          :key="range.value"
          @click="setTimeRange(range.value)"
          :class="[
            'px-3 py-1 rounded text-sm font-medium transition',
            selectedTimeRange === range.value
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          ]"
        >
          {{ range.label }}
        </button>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <div v-else-if="chartData.datasets.length === 0" class="flex justify-center items-center h-64">
      <p class="text-gray-500">No data available</p>
    </div>

    <div v-else class="relative h-96">
      <Line :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale
} from 'chart.js'
import 'chartjs-adapter-date-fns'
import { useDataStore } from '../stores/data'

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale
)

const dataStore = useDataStore()

const loading = ref(false)
const selectedTimeRange = ref('24h')

const timeRanges = [
  { label: '24h', value: '24h' },
  { label: '7d', value: '7d' },
  { label: '30d', value: '30d' },
  { label: 'All', value: 'all' }
]

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    mode: 'index',
    intersect: false,
  },
  plugins: {
    legend: {
      position: 'top',
      labels: {
        usePointStyle: true,
        padding: 15
      }
    },
    tooltip: {
      callbacks: {
        label: function(context) {
          const series = dataStore.series.find(s => s.id === context.dataset.seriesId)
          const unit = series?.unit || ''
          return `${context.dataset.label}: ${context.parsed.y.toFixed(2)} ${unit}`
        }
      }
    }
  },
  scales: {
    x: {
      type: 'time',
      time: {
        displayFormats: {
          hour: 'MMM d, HH:mm',
          day: 'MMM d',
          week: 'MMM d',
          month: 'MMM yyyy'
        }
      },
      grid: {
        display: false
      }
    },
    y: {
      beginAtZero: false,
      grid: {
        color: 'rgba(0, 0, 0, 0.05)'
      }
    }
  }
}

const chartData = computed(() => {
  const datasets = []

  // Group measurements by series
  const measurementsBySeries = {}

  dataStore.measurements.forEach(measurement => {
    if (!measurementsBySeries[measurement.series_id]) {
      measurementsBySeries[measurement.series_id] = []
    }
    measurementsBySeries[measurement.series_id].push(measurement)
  })

  // Create dataset for each series
  Object.keys(measurementsBySeries).forEach(seriesId => {
    const series = dataStore.series.find(s => s.id === parseInt(seriesId))
    if (!series) return

    // Only include selected series
    if (!dataStore.selectedSeriesIds.includes(series.id)) return

    const measurements = measurementsBySeries[seriesId]
      .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))

    datasets.push({
      label: series.name,
      data: measurements.map(m => ({
        x: new Date(m.timestamp),
        y: m.value
      })),
      borderColor: series.color,
      backgroundColor: series.color + '20',
      tension: 0.4,
      pointRadius: 2,
      pointHoverRadius: 5,
      seriesId: series.id
    })
  })

  return {
    datasets
  }
})

function setTimeRange(range) {
  selectedTimeRange.value = range
  applyTimeRange()
}

function applyTimeRange() {
  const now = new Date()
  let startDate = null

  switch (selectedTimeRange.value) {
    case '24h':
      startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000)
      break
    case '7d':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      break
    case '30d':
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      break
    case 'all':
      startDate = null
      break
  }

  dataStore.setDateRange(
    startDate ? startDate.toISOString() : null,
    now.toISOString()
  )

  refreshData()
}

async function refreshData() {
  loading.value = true
  try {
    await dataStore.fetchMeasurements()
  } catch (error) {
    console.error('Failed to fetch measurements:', error)
  } finally {
    loading.value = false
  }
}

// Watch for changes in selected series
watch(() => dataStore.selectedSeriesIds, () => {
  refreshData()
}, { deep: true })

onMounted(() => {
  applyTimeRange()
})
</script>
