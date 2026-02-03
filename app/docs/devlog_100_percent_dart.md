# DevLog: Building a 100% Dart Ecosystem

## Intro
"Why I ditched the backend and went Full Dart."
A deep dive into building **Google Tech News** with a specific constraint: No external servers (except the RSS feeds themselves).

## The Stack
*   **RSS Parsing**: `xml` package (Robust against random Google Blog formats).
*   **Database**: `isar` (Super fast, offline-first).
*   **State**: `riverpod` (AsyncValue is a cheat code for UI states).
*   **UI**: Material 3 Expressive (Animations, Dynamic Color).

## Challenges
*   **Parsing feeds**: Atom vs RSS 2.0 inconsistencies.
*   **Image Caching**: Handling high-res blog headers.
*   **Search**: Implementing fuzzy search purely on-device.

## Conclusion
Dart on the client is powerful enough to handle complex aggregation logic without a middleman.
