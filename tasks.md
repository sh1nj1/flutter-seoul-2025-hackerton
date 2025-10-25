# Hackathon Task Plan

## 1. Setup & Dependencies
- Install required Flutter packages (`google_generative_ai`, optional `flutter_colorpicker`, `path_provider`) and configure API key storage (dotenv or secrets file ignored by VCS).
- Wire environment loading inside `main.dart` so the Gemini key is available before API calls.

## 2. Canvas Interface
- Build single-screen `Scaffold` with custom drawing canvas: use `GestureDetector` + `CustomPainter` to capture and render strokes.
- Structure drawing state (strokes, active color, brush size) with a lightweight `ChangeNotifier` or plain `StatefulWidget` variables for speed.
- Implement "새로 만들기" to reset canvas state and clear any generated icon preview.

## 3. Color Selection & Tools
- Add color picker dialog (predefined palette or `flutter_colorpicker`) that updates the active brush color.
- Provide "지우기" to clear current strokes; optionally support undo if time allows.
- Keep UI responsive on mobile and desktop targets (flexible button row with icons + labels).

## 4. Icon Generation Workflow
- On "아이콘 만들기", open dialog with prefilled prompt template tied to current concept and allow edits.
- Capture canvas as PNG bytes via `ui.Image`/`PictureRecorder`, encode base64, and bundle with prompt for Gemini request.
- Show loading overlay while awaiting API; handle errors with retry messaging.

## 5. Result Handling
- Render generated icon preview in a modal or bottom sheet with "다운로드" (save to device using `path_provider` + platform channels if needed) and "다시 생성" (issue repeat call with same prompt).
- Store the latest prompt and result state to enable quick regenerations without reentering text.

## 6. Polish & Deliverables
- Localize visible strings for Korean/English if time permits; otherwise keep consistent Korean labels.
- Document usage instructions and API key setup in README for teammates; skip automated tests for hackathon speed but perform manual smoke checks on primary devices.
