import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import ui from '@nuxt/ui/vue-plugin'
import App from './App.vue'
import { guard, routes } from './router'
import './app.css'

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 })
})
router.beforeEach(guard)

createApp(App).use(router).use(ui).mount('#app')
