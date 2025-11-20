import { test, expect } from '@playwright/test'

test.describe('Visual Regression Tests - Public Data View', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to View Data page (public access)
    await page.goto('/')

    // Click "View Data" to see the dashboard
    await page.click('text=View Data')

    // Wait for data to load
    await page.waitForLoadState('networkidle')

    // Wait for initial data to render
    await page.waitForTimeout(2000)
  })

  test('Dashboard - full page screenshot', async ({ page }) => {
    // Wait for chart and table to be fully rendered
    await page.waitForSelector('.measurement-chart', { timeout: 10000 })
    await page.waitForSelector('table')

    // Wait a bit for chart animation to complete
    await page.waitForTimeout(1000)

    // Take full page screenshot
    await expect(page).toHaveScreenshot('dashboard-full.png', {
      fullPage: true,
      animations: 'disabled',
    })
  })

  test('MeasurementTable - component screenshot', async ({ page }) => {
    // Wait for table to be rendered
    await page.waitForSelector('table')

    // Take screenshot of the table container
    const tableContainer = page.locator('.bg-white.rounded-lg.shadow').last()
    await expect(tableContainer).toHaveScreenshot('measurement-table.png')
  })

  test('MeasurementChart - component screenshot', async ({ page }) => {
    // Wait for chart to be rendered
    await page.waitForSelector('canvas')
    await page.waitForTimeout(1000) // Wait for chart animation

    // Take screenshot of the chart container
    const chartContainer = page.locator('.measurement-chart').first()
    await expect(chartContainer).toHaveScreenshot('measurement-chart.png', {
      animations: 'disabled',
    })
  })

  test('Series filters - UI state', async ({ page }) => {
    // Wait for series checkboxes
    await page.waitForSelector('input[type="checkbox"]')

    // Take screenshot with all series selected
    const filtersSection = page.locator('.bg-white.rounded-lg.shadow').first()
    await expect(filtersSection).toHaveScreenshot('series-filters-all-selected.png')
  })

  test('MeasurementTable - with data visible', async ({ page }) => {
    // Wait for table rows to be visible
    await page.waitForSelector('tbody tr')

    // Ensure we have data rows (not just loading/empty state)
    const rowCount = await page.locator('tbody tr').count()
    expect(rowCount).toBeGreaterThan(0)

    // Take screenshot of table with data
    const tableContainer = page.locator('.bg-white.rounded-lg.shadow').last()
    await expect(tableContainer).toHaveScreenshot('measurement-table-with-data.png')
  })

  test('Dashboard - viewport 1920x1080', async ({ page }) => {
    // Set larger viewport
    await page.setViewportSize({ width: 1920, height: 1080 })

    await page.waitForSelector('.measurement-chart')
    await page.waitForTimeout(1000)

    await expect(page).toHaveScreenshot('dashboard-1920x1080.png', {
      fullPage: true,
      animations: 'disabled',
    })
  })
})
