# Daily Challenges Experience Analysis & Roadmap

## Current State Analysis
The current implementation of Daily Challenges in `PlannerScreen` provides the core CRUD functionality:
- **Creation**: Users can create Reps, Time, and Fluid based challenges.
- **Tracking**: Manual entry + Quick Add buttons for easy logging.
- **Timer**: Functional timer for time-based tasks.
- **Stats Integration**: Completion maps to specific attributes (STR, AGI, INT, DIS).

## Functionality Gaps & Opportunities

### 1. "Priority Target" Integration
**Issue**: The Home Screen currently shows a hardcoded "Priority Target".
**Solution**: 
- Logic: Automatically designate the first active challenge or the one with the highest target as the "Priority Target".
- UI: Display this specific challenge prominently on the Home Screen with a real-time progress bar.

### 2. High-Fidelity Feedback (Gamification)
**Issue**: Completing a task currently shows a standard SnackBar.
**Solution**:
- **Visuals**: Implement a particle/confetti explosion overlay when a task reaches 100%.
- **Haptics**: Add haptic feedback (vibration) on quick-add taps and completion.
- **Micro-animations**: Animate the progress bar fill and text numbers counting up.

### 3. Gesture-Based Interaction
**Issue**: Deleting requires a distinct icon tap; no way to mark complete quickly.
**Solution**:
- **Swipe Actions**: Implement `Dismissible` widgets allowing:
  - Swipe Right: Quick Add default amount.
  - Swipe Left: Delete or Archive.
- **Drag & Drop**: Allow reordering of tasks to let users define their own priority order.

### 4. Smart Suggestions & Presets
**Issue**: Users have to manually type "Pushups" every time.
**Solution**:
- **Preset Library**: A carousel of common challenges (e.g., "Morning Jog", "Hydration", "Meditation") that users can add with one tap.
- **Contextual Suggestions**: "Your Agility is low (Lvl 5). Recommended: 15 min Stretch."

### 5. Detailed Task History
**Issue**: Progress tracks "Today" only.
**Solution**:
- Click to expand a card to view a mini-heatmap of that specific habit over the last 7 days.

## Proposed Implementation Plan

### Phase 1: Visual Polish & Feedback (Immediate)
1.  **Confetti Overlay**: Create a `ConfettiOverlay` widget that triggers on state changes `isCompleted: true`.
2.  **Home Screen Sync**: Refactor `HomeScreen` to consume the `Planner` state (Provider or Singleton) to show the real Priority Target.
3. Please add also a section, which highlights what the individual activities were done - so which is showing the daily progress of each challenge. please visualize the progress for each activity of the challenge as arcarde-bar with the color of the activity and the amount of reps/time/fluid done. Keep the daily tracker progress section intuitive, user-friendly and easy to navigate.

### Phase 2: Presets & Templates
1.  **Preset Widget**: Add a horizontal scroll list at the top of Planner with "Quick Start" pills.
2.  **Smart Defaults**: Pre-fill specific attributes based on the task name (e.g., "Run" -> Agility).

### Phase 3: Persistence
1.  Integrate `shared_preferences` or `hive` to save state across app restarts, ensuring the "Daily" logic resets progress at midnight while keeping the Task definitions.
