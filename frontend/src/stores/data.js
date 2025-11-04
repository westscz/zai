import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../utils/api'

export const useDataStore = defineStore('data', () => {
  const series = ref([])
  const measurements = ref([])
  const sensors = ref([])
  const selectedSeriesIds = ref([])
  const dateRange = ref({
    start: null,
    end: null,
  })
  const loading = ref(false)

  async function fetchSeries() {
    try {
      loading.value = true
      const response = await api.get('/api/series/')
      series.value = response.data
      // Select all series by default
      if (selectedSeriesIds.value.length === 0) {
        selectedSeriesIds.value = series.value.map((s) => s.id)
      }
    } catch (error) {
      console.error('Failed to fetch series:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  async function createSeries(seriesData) {
    try {
      const response = await api.post('/api/series/', seriesData)
      series.value.push(response.data)
      return response.data
    } catch (error) {
      console.error('Failed to create series:', error)
      throw error
    }
  }

  async function updateSeries(seriesId, updates) {
    try {
      const response = await api.put(`/api/series/${seriesId}`, updates)
      const index = series.value.findIndex((s) => s.id === seriesId)
      if (index !== -1) {
        series.value[index] = response.data
      }
      return response.data
    } catch (error) {
      console.error('Failed to update series:', error)
      throw error
    }
  }

  async function deleteSeries(seriesId) {
    try {
      await api.delete(`/api/series/${seriesId}`)
      series.value = series.value.filter((s) => s.id !== seriesId)
      selectedSeriesIds.value = selectedSeriesIds.value.filter((id) => id !== seriesId)
    } catch (error) {
      console.error('Failed to delete series:', error)
      throw error
    }
  }

  async function fetchMeasurements() {
    try {
      loading.value = true
      const params = {}

      if (selectedSeriesIds.value.length > 0) {
        params.series_ids = selectedSeriesIds.value.join(',')
      }

      if (dateRange.value.start) {
        params.start_date = dateRange.value.start
      }

      if (dateRange.value.end) {
        params.end_date = dateRange.value.end
      }

      const response = await api.get('/api/measurements/', { params })
      measurements.value = response.data
    } catch (error) {
      console.error('Failed to fetch measurements:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  async function createMeasurement(measurementData) {
    try {
      const response = await api.post('/api/measurements/', measurementData)
      measurements.value.unshift(response.data)
      return response.data
    } catch (error) {
      console.error('Failed to create measurement:', error)
      throw error
    }
  }

  async function updateMeasurement(measurementId, updates) {
    try {
      const response = await api.put(`/api/measurements/${measurementId}`, updates)
      const index = measurements.value.findIndex((m) => m.id === measurementId)
      if (index !== -1) {
        measurements.value[index] = response.data
      }
      return response.data
    } catch (error) {
      console.error('Failed to update measurement:', error)
      throw error
    }
  }

  async function deleteMeasurement(measurementId) {
    try {
      await api.delete(`/api/measurements/${measurementId}`)
      measurements.value = measurements.value.filter((m) => m.id !== measurementId)
    } catch (error) {
      console.error('Failed to delete measurement:', error)
      throw error
    }
  }

  function toggleSeriesSelection(seriesId) {
    const index = selectedSeriesIds.value.indexOf(seriesId)
    if (index === -1) {
      selectedSeriesIds.value.push(seriesId)
    } else {
      selectedSeriesIds.value.splice(index, 1)
    }
  }

  function setDateRange(start, end) {
    dateRange.value = { start, end }
  }

  // Sensor functions
  async function fetchSensors() {
    try {
      loading.value = true
      const response = await api.get('/api/sensors/')
      sensors.value = response.data
    } catch (error) {
      console.error('Failed to fetch sensors:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  async function createSensor(sensorData) {
    try {
      const response = await api.post('/api/sensors/', sensorData)
      sensors.value.push(response.data)
      return response.data
    } catch (error) {
      console.error('Failed to create sensor:', error)
      throw error
    }
  }

  async function deleteSensor(sensorId) {
    try {
      await api.delete(`/api/sensors/${sensorId}`)
      sensors.value = sensors.value.filter((s) => s.id !== sensorId)
    } catch (error) {
      console.error('Failed to delete sensor:', error)
      throw error
    }
  }

  return {
    series,
    measurements,
    sensors,
    selectedSeriesIds,
    dateRange,
    loading,
    fetchSeries,
    createSeries,
    updateSeries,
    deleteSeries,
    fetchMeasurements,
    createMeasurement,
    updateMeasurement,
    deleteMeasurement,
    toggleSeriesSelection,
    setDateRange,
    fetchSensors,
    createSensor,
    deleteSensor,
  }
})
