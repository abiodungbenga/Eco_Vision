# WildSense — Premium V-Modal Environmental Intelligence MVP

Search wildlife footage by meaning. Find the moments that matter.

WildSense is a premium proof-of-concept demonstrating how environmental researchers can use the **V-Modal Flutter SDK** to upload wildlife footage, index it, and perform semantic searches to find specific moments using natural language.

## Features

- **Wildlife Library**: View and manage field research footage.
- **Smart Upload**: Select and upload videos directly to V-Modal.
- **AI Indexing**: Automatic semantic indexing of video content.
- **Semantic Search**: Search for moments like "elephants near water" without tags or keywords.
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
4. **Search**: Enter a query like "animals grazing".
5. **Discover**: Tap a result to jump directly to that moment in the video.

---

Built with WildSense & V-Modal.
