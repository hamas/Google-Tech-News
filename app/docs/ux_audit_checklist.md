# UX Audit Checklist

## 1. Legibility & Typography
- [ ] **Dynamic Type**: Check text scales correctly with System Font Size (Small -> Huge).
- [ ] **Contrast**: Ensure text colors meet WCAG AA (4.5:1) against background.
    -   Verify "OnSurface" vs "Surface" colors.
    -   Verify "Primary" vs "OnPrimary" colors.
- [ ] **Line Length**: Ensure lines ~60 characters on Tablet/Desktop for readability.

## 2. Latency & Performance
- [ ] **Cold Start**: App interactive within 2 seconds.
- [ ] **Feed Load**: Cached content visible immediately (<100ms).
- [ ] **Image Loading**: No layout shifts (placeholders used).
- [ ] **Scroll Jank**: Maintain 60fps during rapid scroll.

## 3. Accessibility (A11y)
- [ ] **TalkBack / VoiceOver**:
    -   [ ] Verify all interactive elements have semantic labels.
    -   [ ] Verify "News Card" reads Title + Source + Time concisely.
- [ ] **Touch Targets**: Minimum 48x48dp for all buttons.
- [ ] **Navigation**: Focus order logic for keyboard/switch access.

## 4. Visual Polish (Material 3)
- [ ] **Elevation**: Correct use of tonal elevation vs shadows.
- [ ] **Motion**: Transitions (Hero) follow standard duration/curve.
- [ ] **Responsive**: Layout adapts to Fold state (Postures).
