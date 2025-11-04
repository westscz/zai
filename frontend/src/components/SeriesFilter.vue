<template>
  <div class="bg-white rounded-lg shadow p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Filter by Series</h3>

    <div v-if="dataStore.series.length === 0" class="text-gray-500 text-sm">
      No series available
    </div>

    <div v-else class="space-y-3">
      <div class="flex items-center justify-between mb-4">
        <button
          @click="selectAll"
          class="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
        >
          Select All
        </button>
        <button
          @click="deselectAll"
          class="text-sm text-gray-600 hover:text-gray-800 font-medium"
        >
          Deselect All
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
        <label
          v-for="series in dataStore.series"
          :key="series.id"
          class="flex items-center space-x-3 p-3 rounded-lg border-2 cursor-pointer transition"
          :class="isSelected(series.id) ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300'"
        >
          <input
            type="checkbox"
            :checked="isSelected(series.id)"
            @change="toggleSeries(series.id)"
            class="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center space-x-2">
              <div
                class="w-3 h-3 rounded-full flex-shrink-0"
                :style="{ backgroundColor: series.color }"
              ></div>
              <span class="text-sm font-medium text-gray-900 truncate">
                {{ series.name }}
              </span>
            </div>
            <p v-if="series.description" class="text-xs text-gray-500 mt-1 truncate">
              {{ series.description }}
            </p>
            <div class="flex items-center space-x-2 mt-1">
              <span class="text-xs text-gray-400">
                {{ series.min_value }} - {{ series.max_value }} {{ series.unit }}
              </span>
            </div>
          </div>
        </label>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useDataStore } from '../stores/data'

const dataStore = useDataStore()

function isSelected(seriesId) {
  return dataStore.selectedSeriesIds.includes(seriesId)
}

function toggleSeries(seriesId) {
  dataStore.toggleSeriesSelection(seriesId)
}

function selectAll() {
  dataStore.selectedSeriesIds = dataStore.series.map(s => s.id)
}

function deselectAll() {
  dataStore.selectedSeriesIds = []
}
</script>
