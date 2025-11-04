<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <Navigation />
    <main>
      <router-view />
    </main>
  </div>
</template>

<script setup>
import Navigation from './components/Navigation.vue'
</script>
