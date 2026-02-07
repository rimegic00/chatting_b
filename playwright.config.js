// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Mobile Performance Testing Configuration
 * Tests the chatting_b Rails app on various mobile devices
 */
module.exports = defineConfig({
    testDir: './tests',

    // Maximum time one test can run
    timeout: 60 * 1000,

    // Run tests in parallel
    fullyParallel: true,

    // Fail the build on CI if you accidentally left test.only
    forbidOnly: !!process.env.CI,

    // Retry on CI only
    retries: process.env.CI ? 2 : 0,

    // Reporter to use
    reporter: [
        ['html', { outputFolder: 'playwright-report' }],
        ['json', { outputFile: 'test-results/results.json' }],
        ['list']
    ],

    use: {
        // Base URL for tests
        baseURL: process.env.BASE_URL || 'http://localhost:3000',

        // Collect trace on failure
        trace: 'on-first-retry',

        // Screenshot on failure
        screenshot: 'only-on-failure',

        // Video on failure
        video: 'retain-on-failure',
    },

    // Configure projects for major mobile browsers
    projects: [
        {
            name: 'mobile-chrome',
            use: {
                ...devices['Pixel 5'],
                // Simulate 3G network for realistic testing
                launchOptions: {
                    slowMo: 0,
                }
            },
        },
        {
            name: 'mobile-safari',
            use: {
                ...devices['iPhone 12'],
            },
        },
        {
            name: 'mobile-samsung',
            use: {
                ...devices['Galaxy S9+'],
            },
        },
        {
            name: 'mobile-small',
            use: {
                // Test on smaller screens (360px width)
                viewport: { width: 360, height: 740 },
                userAgent: 'Mozilla/5.0 (Linux; Android 11; SM-A505F) AppleWebKit/537.36',
                deviceScaleFactor: 2,
                isMobile: true,
                hasTouch: true,
            },
        },
    ],

    // Run local dev server before starting tests (optional)
    // Uncomment if you want Playwright to start the server automatically
    // webServer: {
    //   command: 'bin/dev',
    //   url: 'http://localhost:3000',
    //   reuseExistingServer: !process.env.CI,
    //   timeout: 120 * 1000,
    // },
});
