// ============================================================
// Charts Modülü — TR90 Sprint Kanban
// Chart.js ESM wrapper fonksiyonları
// ============================================================
import Chart from 'https://cdn.jsdelivr.net/npm/chart.js/+esm'

/**
 * Mevcut chart'ı temizler
 * @param {string} canvasId
 */
function destroyIfExists(canvasId) {
  Chart.getChart(canvasId)?.destroy()
}

/**
 * GKİ Trendi çizgi grafiği
 * @param {string} canvasId
 * @param {string[]} labels
 * @param {number[]} gkiData
 */
export function renderGkiTrend(canvasId, labels, gkiData) {
  destroyIfExists(canvasId)
  const ctx = document.getElementById(canvasId)
  if (!ctx) return
  new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'GKİ (%)',
        data: gkiData,
        borderColor: '#1a2744',
        backgroundColor: 'rgba(26,39,68,0.1)',
        borderWidth: 2.5,
        pointBackgroundColor: '#1a2744',
        pointRadius: 4,
        tension: 0.3,
        fill: true
      }]
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: 'GKİ Trendi (%)',
          color: '#1a2744',
          font: { size: 13, weight: '700' }
        },
        legend: { display: false }
      },
      scales: {
        y: {
          min: 0,
          max: 120,
          ticks: { font: { size: 11 } },
          grid: { color: 'rgba(0,0,0,0.06)' }
        },
        x: {
          ticks: { font: { size: 11 } },
          grid: { display: false }
        }
      }
    }
  })
}

/**
 * Hepiniss (G.ort) Trendi çizgi grafiği
 * @param {string} canvasId
 * @param {string[]} labels
 * @param {number[]} hepinissData
 */
export function renderHepinissTrend(canvasId, labels, hepinissData) {
  destroyIfExists(canvasId)
  const ctx = document.getElementById(canvasId)
  if (!ctx) return
  new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Hepiniss (G.ort)',
        data: hepinissData,
        borderColor: '#c9a227',
        backgroundColor: 'rgba(201,162,39,0.1)',
        borderWidth: 2.5,
        pointBackgroundColor: '#c9a227',
        pointRadius: 4,
        tension: 0.3,
        fill: true
      }]
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: 'Hepiniss (G.ort) Trendi',
          color: '#1a2744',
          font: { size: 13, weight: '700' }
        },
        legend: { display: false }
      },
      scales: {
        y: {
          min: 0,
          max: 10,
          ticks: { font: { size: 11 } },
          grid: { color: 'rgba(0,0,0,0.06)' }
        },
        x: {
          ticks: { font: { size: 11 } },
          grid: { display: false }
        }
      }
    }
  })
}

/**
 * Plan vs Gerçekleşme grouped bar grafiği
 * @param {string} canvasId
 * @param {string[]} labels
 * @param {number[]} planData
 * @param {number[]} gercekData
 */
export function renderPlanGerceklesme(canvasId, labels, planData, gercekData) {
  destroyIfExists(canvasId)
  const ctx = document.getElementById(canvasId)
  if (!ctx) return
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: 'Plan (gün)',
          data: planData,
          backgroundColor: '#1a2744',
          borderRadius: 4
        },
        {
          label: 'Gerçekleşme (gün)',
          data: gercekData,
          backgroundColor: '#c9a227',
          borderRadius: 4
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: 'Plan vs Gerçekleşme (gün)',
          color: '#1a2744',
          font: { size: 13, weight: '700' }
        },
        legend: {
          display: true,
          position: 'bottom',
          labels: { font: { size: 11 }, padding: 12 }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: { font: { size: 11 } },
          grid: { color: 'rgba(0,0,0,0.06)' }
        },
        x: {
          ticks: { font: { size: 11 } },
          grid: { display: false }
        }
      }
    }
  })
}

/**
 * Organizasyon Puanı Trendi çizgi grafiği
 * @param {string} canvasId
 * @param {string[]} labels
 * @param {number[]} orgData
 */
export function renderOrgPuan(canvasId, labels, orgData) {
  destroyIfExists(canvasId)
  const ctx = document.getElementById(canvasId)
  if (!ctx) return
  new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Org. Puanı',
        data: orgData,
        borderColor: '#22c55e',
        backgroundColor: 'rgba(34,197,94,0.1)',
        borderWidth: 2.5,
        pointBackgroundColor: '#22c55e',
        pointRadius: 4,
        tension: 0.3,
        fill: true
      }]
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: 'Organizasyon Puanı Trendi',
          color: '#1a2744',
          font: { size: 13, weight: '700' }
        },
        legend: { display: false }
      },
      scales: {
        y: {
          min: 0,
          max: 10,
          ticks: { font: { size: 11 } },
          grid: { color: 'rgba(0,0,0,0.06)' }
        },
        x: {
          ticks: { font: { size: 11 } },
          grid: { display: false }
        }
      }
    }
  })
}
