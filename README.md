# WildSense — Premium V-Modal Environmental Intelligence MVP

Search wildlife footage by meaning. Find the moments that matter.

WildSense is a premium proof-of-concept demonstrating how environmental researchers can use the **V-Modal Flutter SDK** to upload wildlife footage, index it, and perform semantic searches to find specific moments using natural language.

## Features

- **Wildlife Library**: View and manage field research footage.
- **Smart Upload**: Select and upload videos directly to V-Modal.
- **AI Indexing**: Automatic semantic indexing of video content.
- **Semantic Search**: Search for moments like "elephants near water" without tags or keywords.
- **Global Archive Search**: Search across your entire research library in one query.
- **Research Semantic Chips**: One-tap filters for predation, drinking, human intrusion, and more.
- **Sightings Discover Feed**: A live aggregate feed of detected moments from all footage.
- **Observation Bookmarks**: Save and organize important field moments into reports with local persistence.
- **Visual Reference Search**: Use an image (e.g., a photo of a specific leopard) to find all matching appearances across your footage.
- **Real-Time AI Thumbnails**: Dynamic resolution of video frame previews for all search and discovery results.
- **Moment Navigation**: Jump directly to the relevant timestamp in search results.

## Architecture

WildSense follows a feature-first architecture using **GetX**:

- **app/**: Routes, Themes, and Global Bindings.
- **core/**: Constants, Utilities, and Extensions.
- **services/**: Isolated V-Modal SDK integration (`VModalService`).
- **features/**: Functional modules (Home, Upload, Search, Video).
- **shared/**: Reusable widgets and models.

## Tech Stack

- **Flutter**: UI Framework.
- **GetX**: State management, routing, and dependency injection.
- **V-Modal SDK**: Semantic video search and indexing.
- **Video Player**: Native video playback.

## Visual Reference Search (Image-to-Video)

WildSense now supports searching by visual similarity. This is useful for finding specific individuals or environmental patterns that are hard to describe in words.

1. Navigate to the **Search** screen.
2. Tap the **Camera/Photo icon** in the search bar.
3. Select an image from your gallery.
4. The search engine will now use the visual features of that image to query your video index.
5. Results will show every timestamp where a similar subject appears.

## Global Archive & Semantic Filters

WildSense allows researchers to discover patterns across many videos at once.

1.  **Global Archive Toggle**: In the **Search** screen, flip the "Global Archive" switch to query your entire indexed library instead of just the currently selected video.
2.  **Semantic Chips**: Use the quick-tap filters like `🐾 Predation` or `💧 Drinking` to instantly trigger AI searches for common wildlife behaviors.
3.  **Discovery Feed**: Check the **Home** screen for a live "Discovery Feed" of recently indexed wildlife activity from all your footage.
4.  **Bookmarks**: Tap the bookmark icon on any search result to save it to your **Saved Observations**. These are persisted locally and will be available even after restarting the app.

## Data Persistence & Visual Previews

WildSense is designed for long-term field research with robust data handling:

- **Local Persistence**: Uses `localstore` to save your "Saved Observations" JSON database directly on your device. Your research work is never lost when the app closes.
- **Dynamic AI Thumbnails**: Every search result and discovery moment automatically fetches its corresponding video frame from V-Modal. This provides immediate visual context before you even press play.
- **Interactive Feed**: The Discovery Feed on the Home screen is fully interactive. Tap any moment to play it instantly or receive guidance on which archived video contains that sighting.

## Setup

1. **V-Modal API Key**:
   Obtain an API key from V-Modal and configure it via dart-define:
   ```bash
   flutter run --dart-define=VMODAL_API_KEY=your_api_key --dart-define=VMODAL_PROJECT_ID=your_project_id
   ```

2. **Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Android Platform**:
   Ensure your `minSdkVersion` is 21 or higher.

## Demo Flow

1. **Home**: View the wildlife intelligence dashboard.
2. **Add**: Upload a new piece of field footage.
3. **Index**: Wait for V-Modal to complete semantic analysis.
4. **Search**: Enter a natural language query or tap the **Visual Reference** icon to search using an image.
5. **Discover**: Tap a result to jump directly to that moment in the video.

---

Built with WildSense & V-Modal.
