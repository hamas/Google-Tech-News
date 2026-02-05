# Performance Verification Checklist

## 1. Frame Analysis (DevTools)
**Target**: < 16ms per frame (60fps) or < 12ms (90Hz+).

- [ ] **Run in Profile Mode**: `flutter run --profile`.
- [ ] **Open DevTools**: Click the "Open DevTools" link in console.
- [ ] **Navigate to Performance Tab**.
- [ ] **Action**: Scroll the News Feed rapidly.
    -   [ ] Verify "Raster" thread bars are green (below target line).
    -   [ ] Verify "UI" thread bars are green.
    -   [ ] Check for "Jank" frames (red bars).
-   **Action**: Open/Close Articles (Hero Transition).
    -   [ ] Verify transition smoothness.

## 2. Memory Leaks
**Target**: Stable memory usage over time.

- [ ] **Navigate to Memory Tab**.
- [ ] **Action**: Open 10 articles and go back.
    -   [ ] Click "GC" (Garbage Collect).
    -   [ ] Verify "Dart Heap" returns to baseline (~approx).
    -   [ ] Check `InAppWebView` instances are disposed (if visible in snapshots).

## 3. App Size (R8 Check)
- [ ] **Build Release**: `flutter build apk --release`.
- [ ] **Analyze APK**: Drag into Android Studio "APK Analyzer".
    -   [ ] Verify `classes.dex` size is reasonable.
    -   [ ] Verify Unused Resources are removed.
