# Mobile Performance Testing Guide

## Quick Start

### 1. Prerequisites
- Rails server must be running: `bin/dev` or `rails s`
- Playwright browsers installed: `npx playwright install`

### 2. Run Performance Tests

```bash
# Run all mobile performance tests
npm run test:perf

# Run on specific mobile devices
npm run test:mobile

# View HTML report with metrics
npm run test:report
```

## Test Coverage

### Performance Metrics Measured
- **Page Load Time**: Total time to fully load the page
- **First Contentful Paint (FCP)**: When first content appears (target: < 2.5s)
- **Largest Contentful Paint (LCP)**: When main content is visible (target: < 2.5s)
- **Cumulative Layout Shift (CLS)**: Visual stability (target: < 0.1)
- **Time to Interactive (TTI)**: When page becomes interactive (target: < 3s)
- **JavaScript Execution Time**: Total JS processing time
- **Scroll Performance**: Frame rate during scrolling (target: 60fps)

### Test Scenarios
1. **Homepage Initial Load** - Measures cold start performance
2. **Posts Index Scrolling** - Tests scroll smoothness and jank
3. **Tab Switching** - Measures interaction responsiveness
4. **Network Waterfall** - Analyzes resource loading patterns
5. **JavaScript Execution** - Identifies heavy scripts
6. **Layout Stability** - Detects unexpected layout shifts
7. **Touch Target Sizes** - Validates mobile-friendly tap targets
8. **Font Sizes** - Checks readability on mobile

## Interpreting Results

### Good Performance Targets
- ✅ Page Load: < 2 seconds on 3G
- ✅ FCP: < 1.8 seconds
- ✅ LCP: < 2.5 seconds
- ✅ CLS: < 0.1
- ✅ Scroll FPS: > 55fps
- ✅ Tab Switch: < 500ms

### Common Issues to Look For
- 🔴 **High Page Load Time** → Too many resources, large bundle sizes
- 🔴 **Poor Scroll Performance** → Heavy DOM, complex CSS, layout thrashing
- 🔴 **High CLS** → Images without dimensions, dynamic content injection
- 🔴 **Slow Tab Switching** → Inefficient filtering, re-rendering entire lists

## Next Steps After Testing

1. **Review the HTML report**: `npm run test:report`
2. **Identify bottlenecks** from console logs and metrics
3. **Implement optimizations** based on findings
4. **Re-run tests** to measure improvements
5. **Compare before/after** metrics

## Troubleshooting

### Server Not Running
If tests fail with connection errors:
```bash
# Start Rails server in another terminal
bin/dev
# or
rails s
```

### Playwright Not Installed
```bash
npx playwright install
```

### Network Issues
Set custom base URL:
```bash
BASE_URL=http://localhost:3000 npm run test:perf
```
