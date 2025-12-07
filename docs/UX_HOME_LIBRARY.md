# UX Specification: Home & Library Module

## A) Home Page (Dashboard & Smart Feed)

### 1. Feed Layout
- **Header**: Top app bar with logo and profile/settings access.
- **Carousel**: "Case of the Week", "Announcements".
- **Feed**: Vertical scroll of `CaseCard` items.

### 2. Case Cards
- **Visual**: Clean, medical aesthetic, card-based.
- **Content**:
    - Title, Specialty, Difficulty (Badge).
    - Teaser text (max 2 lines).
- **Actions (Pre-Video)**:
    - 📄 **Preparation Materials**: Opens bottom sheet with PDF lists.
    - 📌 **Add to Calendar**: Adds reminder for Q&A (Mock integration).
    - **Open Case**: Navigates to details.
- **User Actions**:
    - ❤️ Favorite (Icon toggle)
    - 🕒 Watch Later (Icon toggle)

### 3. Top Carousel
- Configurable via `banners` collection in Firestore.
- Displays images with optional overlays.

## B) Library & Search Module

### 1. Library Screen
- **Categories**: Tabs or Horizontal Scroll Chips for Specialties (Endo, Pedo, Surgery, etc.).
- **List**: Grid or List view of cases matching category.

### 2. Implementation Details
- **Filtering**: Dropdown or Modal for Difficulty (Easy, Medium, Hard).
- **Search**: Free text search bar at top.

### 3. User Lists
- **Watch Later**: Accessible from Profile or Library tab.
- **Favorites**: Accessible from Profile or Library tab.
- **Functionality**: Real-time sync with user's subcollections.

## C) Data Logic
- **Watch Later**: stored in `users/{uid}/watchLater/{caseId}`.
- **Favorites**: stored in `users/{uid}/favorites/{caseId}`.
