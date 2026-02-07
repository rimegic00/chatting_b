// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Mobile Performance Test Suite
 * Measures Core Web Vitals and performance metrics on mobile devices
 */

test.describe('Mobile Performance Analysis', () => {

    test.beforeEach(async ({ page }) => {
        // Enable performance metrics collection
        await page.coverage.startJSCoverage();
        await page.coverage.startCSSCoverage();
    });

    test.afterEach(async ({ page }) => {
        // Collect coverage data
        const [jsCoverage, cssCoverage] = await Promise.all([
            page.coverage.stopJSCoverage(),
            page.coverage.stopCSSCoverage(),
        ]);

        // Calculate unused bytes
        const jsUnused = jsCoverage.reduce((acc, entry) => {
            const totalBytes = entry.text.length;
            const usedBytes = entry.ranges.reduce((sum, range) => sum + (range.end - range.start), 0);
            return acc + (totalBytes - usedBytes);
        }, 0);

        console.log(`Unused JavaScript: ${(jsUnused / 1024).toFixed(2)} KB`);
    });

    test('Homepage - Initial Load Performance', async ({ page }) => {
        // Start performance measurement
        const startTime = Date.now();

        // Navigate to homepage
        const response = await page.goto('/', {
            waitUntil: 'networkidle',
            timeout: 30000
        });

        const loadTime = Date.now() - startTime;
        console.log(`Page Load Time: ${loadTime}ms`);

        // Check response status
        expect(response?.status()).toBe(200);

        // Measure Core Web Vitals
        const metrics = await page.evaluate(() => {
            return new Promise((resolve) => {
                // Wait for page to be fully loaded
                if (document.readyState === 'complete') {
                    collectMetrics();
                } else {
                    window.addEventListener('load', collectMetrics);
                }

                function collectMetrics() {
                    const perfData = performance.getEntriesByType('navigation')[0];
                    const paintMetrics = performance.getEntriesByType('paint');

                    const fcp = paintMetrics.find(m => m.name === 'first-contentful-paint')?.startTime || 0;
                    const lcp = paintMetrics.find(m => m.name === 'largest-contentful-paint')?.startTime || 0;

                    resolve({
                        // Navigation timing
                        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
                        domInteractive: perfData.domInteractive - perfData.fetchStart,
                        loadComplete: perfData.loadEventEnd - perfData.fetchStart,

                        // Resource timing
                        dnsLookup: perfData.domainLookupEnd - perfData.domainLookupStart,
                        tcpConnection: perfData.connectEnd - perfData.connectStart,
                        serverResponse: perfData.responseEnd - perfData.requestStart,

                        // Paint metrics
                        firstContentfulPaint: fcp,
                        largestContentfulPaint: lcp,

                        // Transfer sizes
                        transferSize: perfData.transferSize,
                        encodedBodySize: perfData.encodedBodySize,
                        decodedBodySize: perfData.decodedBodySize,
                    });
                }
            });
        });

        console.log('Performance Metrics:', JSON.stringify(metrics, null, 2));

        // Assert performance budgets
        expect(metrics.loadComplete).toBeLessThan(5000); // 5s max
        expect(metrics.firstContentfulPaint).toBeLessThan(2500); // 2.5s FCP target

        // Take screenshot
        await page.screenshot({
            path: `test-results/homepage-loaded-${Date.now()}.png`,
            fullPage: true
        });
    });

    test('Posts Index - Scrolling Performance', async ({ page }) => {
        await page.goto('/posts', { waitUntil: 'networkidle' });

        // Measure scroll performance
        const scrollMetrics = await page.evaluate(() => {
            return new Promise((resolve) => {
                let frameCount = 0;
                let totalTime = 0;
                const frameTimes = [];
                let lastTimestamp = performance.now();

                function measureFrame(timestamp) {
                    const delta = timestamp - lastTimestamp;
                    frameTimes.push(delta);
                    totalTime += delta;
                    frameCount++;
                    lastTimestamp = timestamp;

                    if (frameCount < 60) { // Measure 60 frames
                        requestAnimationFrame(measureFrame);
                    } else {
                        const avgFrameTime = totalTime / frameCount;
                        const fps = 1000 / avgFrameTime;
                        const jankFrames = frameTimes.filter(t => t > 16.67).length; // Frames slower than 60fps

                        resolve({
                            averageFrameTime: avgFrameTime,
                            fps: fps,
                            jankFrames: jankFrames,
                            jankPercentage: (jankFrames / frameCount) * 100
                        });
                    }
                }

                // Start scrolling
                window.scrollTo({ top: 500, behavior: 'smooth' });
                requestAnimationFrame(measureFrame);
            });
        });

        console.log('Scroll Performance:', JSON.stringify(scrollMetrics, null, 2));

        // Assert smooth scrolling (target: < 20% jank)
        expect(scrollMetrics.jankPercentage).toBeLessThan(20);
        expect(scrollMetrics.fps).toBeGreaterThan(50); // Close to 60fps
    });

    test('Tab Switching - Interaction Performance', async ({ page }) => {
        await page.goto('/posts', { waitUntil: 'networkidle' });

        // Measure tab click responsiveness
        const tabClickTimes = [];

        const tabs = [
            { selector: 'a.tab-link:has-text("🔥시장")', name: 'Market' },
            { selector: 'a.tab-link:has-text("💬커뮤")', name: 'Community' },
            { selector: 'a.tab-link:has-text("🟢LIVE")', name: 'Live' },
            { selector: 'a.tab-link:has-text("전체")', name: 'All' },
        ];

        for (const tab of tabs) {
            const startTime = Date.now();
            await page.click(tab.selector);
            await page.waitForLoadState('networkidle');
            const clickTime = Date.now() - startTime;

            tabClickTimes.push({ tab: tab.name, time: clickTime });
            console.log(`${tab.name} tab click: ${clickTime}ms`);

            // Wait a bit between clicks
            await page.waitForTimeout(500);
        }

        // Assert tab switching is fast (< 1s)
        const avgTabTime = tabClickTimes.reduce((sum, t) => sum + t.time, 0) / tabClickTimes.length;
        console.log(`Average tab switch time: ${avgTabTime}ms`);
        expect(avgTabTime).toBeLessThan(1000);
    });

    test('Network Waterfall Analysis', async ({ page }) => {
        // Collect all network requests
        const requests = [];

        page.on('request', request => {
            requests.push({
                url: request.url(),
                method: request.method(),
                resourceType: request.resourceType(),
                timestamp: Date.now()
            });
        });

        const responses = [];
        page.on('response', response => {
            responses.push({
                url: response.url(),
                status: response.status(),
                size: response.headers()['content-length'] || 0,
                timing: response.timing(),
                timestamp: Date.now()
            });
        });

        await page.goto('/posts', { waitUntil: 'networkidle' });

        console.log(`Total Requests: ${requests.length}`);
        console.log(`Total Responses: ${responses.length}`);

        // Analyze resource types
        const resourceTypes = requests.reduce((acc, req) => {
            acc[req.resourceType] = (acc[req.resourceType] || 0) + 1;
            return acc;
        }, {});

        console.log('Resource Types:', resourceTypes);

        // Find slow requests (> 500ms)
        const slowResponses = responses.filter(r => {
            const timing = r.timing;
            if (!timing) return false;
            const totalTime = timing.responseEnd - timing.requestStart;
            return totalTime > 500;
        });

        if (slowResponses.length > 0) {
            console.log('Slow Requests (>500ms):', slowResponses.map(r => ({
                url: r.url,
                status: r.status
            })));
        }

        // Assert reasonable number of requests
        expect(requests.length).toBeLessThan(50); // Avoid too many requests
    });

    test('JavaScript Execution Time', async ({ page }) => {
        await page.goto('/posts');

        // Measure JavaScript execution time
        const jsExecutionTime = await page.evaluate(() => {
            const perfEntries = performance.getEntriesByType('measure');
            const scriptEntries = performance.getEntriesByType('resource')
                .filter(entry => entry.initiatorType === 'script');

            const totalScriptDuration = scriptEntries.reduce((sum, entry) => {
                return sum + entry.duration;
            }, 0);

            return {
                scriptCount: scriptEntries.length,
                totalDuration: totalScriptDuration,
                scripts: scriptEntries.map(s => ({
                    name: s.name.split('/').pop(),
                    duration: s.duration,
                    size: s.transferSize
                }))
            };
        });

        console.log('JavaScript Execution:', JSON.stringify(jsExecutionTime, null, 2));

        // Assert reasonable JS execution time
        expect(jsExecutionTime.totalDuration).toBeLessThan(1000); // < 1s total
    });

    test('Layout Stability (CLS)', async ({ page }) => {
        await page.goto('/posts');

        // Measure Cumulative Layout Shift
        const cls = await page.evaluate(() => {
            return new Promise((resolve) => {
                let clsScore = 0;

                const observer = new PerformanceObserver((list) => {
                    for (const entry of list.getEntries()) {
                        if (entry.entryType === 'layout-shift' && !entry.hadRecentInput) {
                            clsScore += entry.value;
                        }
                    }
                });

                observer.observe({ type: 'layout-shift', buffered: true });

                // Wait 3 seconds to collect layout shifts
                setTimeout(() => {
                    observer.disconnect();
                    resolve(clsScore);
                }, 3000);
            });
        });

        console.log(`Cumulative Layout Shift: ${cls}`);

        // Assert good CLS (< 0.1 is good, < 0.25 is acceptable)
        expect(cls).toBeLessThan(0.25);
    });
});

test.describe('Mobile-Specific Issues', () => {

    test('Touch Target Sizes', async ({ page }) => {
        await page.goto('/posts');

        // Check if interactive elements are large enough for touch
        const touchTargets = await page.evaluate(() => {
            const interactiveElements = document.querySelectorAll('a, button, input, [onclick]');
            const smallTargets = [];

            interactiveElements.forEach(el => {
                const rect = el.getBoundingClientRect();
                const area = rect.width * rect.height;

                // Minimum touch target: 44x44px (Apple HIG) or 48x48px (Material Design)
                if (rect.width < 44 || rect.height < 44) {
                    smallTargets.push({
                        tag: el.tagName,
                        class: el.className,
                        width: rect.width,
                        height: rect.height,
                        text: el.textContent?.substring(0, 30)
                    });
                }
            });

            return {
                total: interactiveElements.length,
                smallTargets: smallTargets.length,
                examples: smallTargets.slice(0, 5)
            };
        });

        console.log('Touch Target Analysis:', JSON.stringify(touchTargets, null, 2));

        // Warn if many targets are too small
        if (touchTargets.smallTargets > 0) {
            console.warn(`Found ${touchTargets.smallTargets} touch targets smaller than 44x44px`);
        }
    });

    test('Font Sizes on Mobile', async ({ page }) => {
        await page.goto('/posts');

        // Check for text that's too small on mobile
        const fontSizes = await page.evaluate(() => {
            const textElements = document.querySelectorAll('p, span, a, div, h1, h2, h3, h4, h5, h6');
            const smallText = [];

            textElements.forEach(el => {
                const fontSize = parseFloat(window.getComputedStyle(el).fontSize);

                // Minimum readable font size on mobile: 12px
                if (fontSize < 12 && el.textContent?.trim()) {
                    smallText.push({
                        tag: el.tagName,
                        fontSize: fontSize,
                        text: el.textContent?.substring(0, 30)
                    });
                }
            });

            return {
                total: textElements.length,
                smallText: smallText.length,
                examples: smallText.slice(0, 5)
            };
        });

        console.log('Font Size Analysis:', JSON.stringify(fontSizes, null, 2));

        if (fontSizes.smallText > 0) {
            console.warn(`Found ${fontSizes.smallText} text elements smaller than 12px`);
        }
    });
});
