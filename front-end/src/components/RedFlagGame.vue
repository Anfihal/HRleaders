<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'

interface Obstacle { x: number; passed: boolean }

const canvas = ref<HTMLCanvasElement | null>(null)
const score = ref(0)
const lost = ref(false)
const running = ref(true)
let frame = 0
let lastTime = 0
let spawnTime = 0
let width = 560
let height = 150
let playerY = 0
let velocity = 0
let obstacles: Obstacle[] = []
let resizeObserver: ResizeObserver | undefined
const ground = () => height - 28
const playerX = 54

function draw() {
  const element = canvas.value
  const context = element?.getContext('2d')
  if (!element || !context) return
  const ratio = window.devicePixelRatio || 1
  element.width = Math.round(width * ratio)
  element.height = Math.round(height * ratio)
  context.setTransform(ratio, 0, 0, ratio, 0, 0)
  context.clearRect(0, 0, width, height)
  context.fillStyle = '#f8f7ff'
  context.fillRect(0, 0, width, height)
  context.strokeStyle = '#dedbea'
  context.setLineDash([4, 6])
  context.beginPath()
  context.moveTo(0, ground() + 1)
  context.lineTo(width, ground() + 1)
  context.stroke()
  context.setLineDash([])

  for (const obstacle of obstacles) {
    context.strokeStyle = '#b5b1c4'
    context.lineWidth = 3
    context.beginPath()
    context.moveTo(obstacle.x, ground() - 2)
    context.lineTo(obstacle.x, ground() - 34)
    context.stroke()
    context.fillStyle = '#e57382'
    context.beginPath()
    context.moveTo(obstacle.x + 2, ground() - 34)
    context.lineTo(obstacle.x + 23, ground() - 29)
    context.lineTo(obstacle.x + 3, ground() - 20)
    context.closePath()
    context.fill()
  }

  const foot = ground() - playerY
  context.strokeStyle = '#5445cb'
  context.lineWidth = 4
  context.lineCap = 'round'
  context.beginPath()
  context.arc(playerX + 10, foot - 29, 7, 0, Math.PI * 2)
  context.fillStyle = '#ffd9bf'
  context.fill()
  context.strokeStyle = '#6b5bd8'
  context.beginPath()
  context.moveTo(playerX + 10, foot - 21)
  context.lineTo(playerX + 10, foot - 7)
  context.moveTo(playerX + 10, foot - 17)
  context.lineTo(playerX + 2, foot - 10)
  context.moveTo(playerX + 10, foot - 17)
  context.lineTo(playerX + 19, foot - 12)
  context.moveTo(playerX + 10, foot - 7)
  context.lineTo(playerX + 3, foot)
  context.moveTo(playerX + 10, foot - 7)
  context.lineTo(playerX + 18, foot)
  context.stroke()
}

function tick(time: number) {
  if (!running.value || lost.value || document.hidden) return
  const delta = Math.min(34, time - (lastTime || time)) / 1000
  lastTime = time
  const speed = Math.min(220, 155 + score.value * 4)
  velocity -= 750 * delta
  playerY = Math.max(0, playerY + velocity * delta)
  if (playerY === 0) velocity = 0
  spawnTime += delta
  if (spawnTime > 1.45) {
    obstacles.push({ x: width + 12, passed: false })
    spawnTime = 0
  }
  obstacles = obstacles.filter((item) => item.x > -35)
  for (const obstacle of obstacles) {
    obstacle.x -= speed * delta
    if (!obstacle.passed && obstacle.x + 23 < playerX) {
      obstacle.passed = true
      score.value += 1
    }
    const overlaps = obstacle.x < playerX + 20 && obstacle.x + 19 > playerX + 2
    if (overlaps && playerY < 27) {
      lost.value = true
      running.value = false
    }
  }
  draw()
  if (!lost.value) frame = requestAnimationFrame(tick)
}

function start() {
  cancelAnimationFrame(frame)
  score.value = 0
  lost.value = false
  running.value = true
  lastTime = 0
  spawnTime = 0
  playerY = 0
  velocity = 0
  obstacles = []
  draw()
  frame = requestAnimationFrame(tick)
}

function jump() {
  if (lost.value) return
  if (!running.value) start()
  if (playerY === 0) velocity = 360
}

function onKey(event: KeyboardEvent) {
  if (event.code === 'Space' || event.code === 'ArrowUp') {
    if (event.target instanceof HTMLElement && event.target.closest('input, textarea, button, select, [contenteditable="true"]')) return
    event.preventDefault()
    jump()
  }
}

function onVisibility() {
  if (document.hidden) {
    cancelAnimationFrame(frame)
  } else if (running.value && !lost.value) {
    lastTime = 0
    frame = requestAnimationFrame(tick)
  }
}

onMounted(() => {
  const element = canvas.value
  if (!element) return
  resizeObserver = new ResizeObserver(([entry]) => {
    width = entry.contentRect.width
    draw()
  })
  resizeObserver.observe(element)
  window.addEventListener('keydown', onKey)
  document.addEventListener('visibilitychange', onVisibility)
  draw()
  frame = requestAnimationFrame(tick)
})

onBeforeUnmount(() => {
  cancelAnimationFrame(frame)
  resizeObserver?.disconnect()
  window.removeEventListener('keydown', onKey)
  document.removeEventListener('visibilitychange', onVisibility)
})
</script>

<template>
  <div class="red-flag-game">
    <canvas ref="canvas" class="game-canvas" aria-label="Кандидат прыгает через красные флаги. Нажмите на игру или пробел, чтобы прыгнуть." @pointerdown="jump" />
    <div class="game-controls">
      <span><strong>{{ score }}</strong> флагов пройдено</span>
      <span v-if="lost" class="game-over"><UIcon name="i-lucide-heart-crack" /> Столкновение — попробуйте ещё раз</span>
      <span v-else class="game-hint"><UIcon name="i-lucide-arrow-up" /> Нажмите на дорожку или пробел, чтобы прыгнуть</span>
      <UButton v-if="lost" size="xs" color="neutral" variant="outline" icon="i-lucide-rotate-ccw" @click="start">Сначала</UButton>
    </div>
  </div>
</template>
