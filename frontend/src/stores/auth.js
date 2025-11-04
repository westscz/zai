import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../utils/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('access_token'))

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.is_admin || false)

  async function login(username, password) {
    try {
      const response = await api.post('/api/auth/login', { username, password })
      token.value = response.data.access_token
      localStorage.setItem('access_token', token.value)
      await fetchCurrentUser()
      return true
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  async function register(username, email, password) {
    try {
      await api.post('/api/auth/register', { username, email, password })
      return true
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    }
  }

  async function fetchCurrentUser() {
    try {
      const response = await api.get('/api/auth/me')
      user.value = response.data
      localStorage.setItem('user', JSON.stringify(user.value))
    } catch (error) {
      console.error('Failed to fetch user:', error)
      logout()
    }
  }

  async function updateProfile(updates) {
    try {
      const response = await api.put('/api/auth/me', updates)
      user.value = response.data
      localStorage.setItem('user', JSON.stringify(user.value))
      return true
    } catch (error) {
      console.error('Profile update failed:', error)
      throw error
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('user')
  }

  // Initialize from localStorage
  const savedUser = localStorage.getItem('user')
  if (savedUser && token.value) {
    try {
      user.value = JSON.parse(savedUser)
      // Verify token is still valid
      fetchCurrentUser().catch(() => logout())
    } catch (e) {
      logout()
    }
  }

  return {
    user,
    token,
    isAuthenticated,
    isAdmin,
    login,
    register,
    logout,
    fetchCurrentUser,
    updateProfile,
  }
})
