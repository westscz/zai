<template>
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex justify-between items-center mb-4">
      <div>
        <h2 class="text-xl font-semibold text-gray-900">Measurement Data</h2>
        <p v-if="dataStore.chartSelectionRange" class="text-sm text-indigo-600 mt-1">
          Selection: {{ formatDate(dataStore.chartSelectionRange.start) }} - {{ formatDate(dataStore.chartSelectionRange.end) }}
          <button @click="clearSelection" class="ml-2 text-gray-500 hover:text-gray-700 underline">Clear</button>
        </p>
      </div>
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
      <Line
        ref="chartRef"
        :data="chartData"
        :options="chartOptions"
        @mousedown="onMouseDown"
        @mousemove="onMouseMove"
        @mouseup="onMouseUp"
        @mouseleave="onMouseLeave"
      />
      <!-- Selection overlay -->
      <div
        v-if="isSelecting && selectionStart !== null && selectionEnd !== null"
        class="absolute top-0 bg-indigo-200 bg-opacity-30 pointer-events-none"
        :style="{
          left: Math.min(selectionStart, selectionEnd) + 'px',
          width: Math.abs(selectionEnd - selectionStart) + 'px',
          height: '100%'
        }"
      ></div>
    </div>

    <p class="text-xs text-gray-500 mt-2 print:hidden">
      Tip: Click and drag on the chart to select a time range and filter the table below.
    </p>
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
import { format } from 'date-fns'


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

const chartRef = ref(null)
const loading = ref(false)
const selectedTimeRange = ref('24h')


const isSelecting = ref(false)
const selectionStart = ref(null)
const selectionEnd = ref(null)

const timeRanges = [
  { label: '24h', value: '24h' },
  { label: '7d', value: '7d' },
  { label: '30d', value: '30d' },
  { label: 'All', value: 'all' }
]

function formatDate(date) {
  return format(new Date(date), 'MMM d, HH:mm')
}

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    mode: 'index',
    intersect: false,
  },
  onClick: (event, elements) => {
    if (elements.length > 0) {
      const element = elements[0]
      const datasetIndex = element.datasetIndex
      const index = element.index
      const dataset = chartData.value.datasets[datasetIndex]


      const seriesId = dataset.seriesId
      const timestamp = dataset.data[index].x
      const measurement = dataStore.measurements.find(
        m => m.series_id === seriesId && new Date(m.timestamp).getTime() === timestamp.getTime()
      )

      if (measurement) {
        dataStore.setSelectedMeasurement(measurement.id)
      }
    }
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
      },

      min: dataStore.chartSelectionRange ? dataStore.chartSelectionRange.start : undefined,
      max: dataStore.chartSelectionRange ? dataStore.chartSelectionRange.end : undefined
    },
    y: {
      beginAtZero: false,
      grid: {
        color: 'rgba(0, 0, 0, 0.05)'
      }
    }
  }
}))

const chartData = computed(() => {
  const datasets = []


  const measurementsBySeries = {}

  dataStore.measurements.forEach(measurement => {
    if (!measurementsBySeries[measurement.series_id]) {
      measurementsBySeries[measurement.series_id] = []
    }
    measurementsBySeries[measurement.series_id].push(measurement)
  })


  Object.keys(measurementsBySeries).forEach(seriesId => {
    const series = dataStore.series.find(s => s.id === parseInt(seriesId))
    if (!series) return


    if (!dataStore.selectedSeriesIds.includes(series.id)) return

    const measurements = measurementsBySeries[seriesId]
      .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))


    const pointBackgroundColor = measurements.map(m =>
      m.id === dataStore.selectedMeasurementId ? '#FBBF24' : series.color + '80'
    )
    const pointRadius = measurements.map(m =>
      m.id === dataStore.selectedMeasurementId ? 8 : 2
    )
    const pointBorderWidth = measurements.map(m =>
      m.id === dataStore.selectedMeasurementId ? 3 : 0
    )

    datasets.push({
      label: series.name,
      data: measurements.map(m => ({
        x: new Date(m.timestamp),
        y: m.value,
        measurementId: m.id
      })),
      borderColor: series.color,
      backgroundColor: series.color + '20',
      tension: 0.4,
      pointRadius,
      pointHoverRadius: 6,
      pointBackgroundColor,
      pointBorderColor: '#FBBF24',
      pointBorderWidth,
      seriesId: series.id
    })
  })

  return {
    datasets
  }
})


function onMouseDown(event) {
  if (!chartRef.value?.chart) return

  const chart = chartRef.value.chart
  const rect = chart.canvas.getBoundingClientRect()
  const x = event.clientX - rect.left


  if (x >= chart.chartArea.left && x <= chart.chartArea.right) {
    isSelecting.value = true
    selectionStart.value = x
    selectionEnd.value = x
  }
}

function onMouseMove(event) {
  if (!isSelecting.value || !chartRef.value?.chart) return

  const chart = chartRef.value.chart
  const rect = chart.canvas.getBoundingClientRect()
  const x = event.clientX - rect.left


  selectionEnd.value = Math.max(chart.chartArea.left, Math.min(chart.chartArea.right, x))
}

function onMouseUp() {
  if (!isSelecting.value || !chartRef.value?.chart) return

  const chart = chartRef.value.chart


  const xScale = chart.scales.x
  const startX = Math.min(selectionStart.value, selectionEnd.value)
  const endX = Math.max(selectionStart.value, selectionEnd.value)


  if (Math.abs(endX - startX) > 10) {
    const startDate = xScale.getValueForPixel(startX)
    const endDate = xScale.getValueForPixel(endX)

    dataStore.setChartSelectionRange({
      start: new Date(startDate),
      end: new Date(endDate)
    })
  }

  isSelecting.value = false
  selectionStart.value = null
  selectionEnd.value = null
}

function onMouseLeave() {
  if (isSelecting.value) {
    isSelecting.value = false
    selectionStart.value = null
    selectionEnd.value = null
  }
}

function clearSelection() {
  dataStore.clearChartSelection()
}

function setTimeRange(range) {
  selectedTimeRange.value = range
  dataStore.clearChartSelection()
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


watch(() => dataStore.selectedSeriesIds, () => {
  refreshData()
}, { deep: true })

onMounted(() => {
  applyTimeRange()
})
</script>
