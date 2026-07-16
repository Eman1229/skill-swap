# Implementation Plan - Fix Build Errors and Identify Screens

This plan outlines the steps to resolve the build errors shown in the provided screenshot and identifies the screens responsible for the learning and teaching detail UI.

## User Review Required

> [!NOTE]
> The primary build errors were caused by missing dependencies (`intl_phone_field`). Running `flutter pub get` has already resolved the "Target of URI doesn't exist" and "method isn't defined" errors in `sign up.dart`. The remaining changes are for code cleanup (unused imports/variables) as shown in the screenshot.

## Proposed Changes

### Build Fixes & Cleanup

#### [Home Screen1.dart](file:///D:/skill-swap/lib/screens/Home%20Screens/Home%20Screen1.dart)
- Remove unused imports:
    - `package:skill_swap/models/swap_listing.dart`
    - `package:skill_swap/utils/user_display_name.dart`

#### [swapping Available.dart](file:///D:/skill-swap/lib/screens/Home%20Screens/swapping%20Available.dart)
- Remove unreferenced declarations:
    - `_buildEmptyHomeState`
    - `_LiveBadge`

#### [assignments_screen.dart](file:///D:/skill-swap/lib/screens/Swap/assignments_screen.dart)
- Remove unused import:
    - `dart:typed_data`

#### [create_assignment_screen.dart](file:///D:/skill-swap/lib/screens/Swap/create_assignment_screen.dart)
- Remove unused import:
    - `package:skill_swap/Ui_helper/translation_helper.dart`
- Remove unused local variable:
    - `uid` in `_createAssignment` method.

#### [edit_session_screen.dart](file:///D:/skill-swap/lib/screens/Swap/edit_session_screen.dart)
- Remove unused import:
    - `package:skill_swap/utils/user_display_name.dart`

---

### Screen Identification

Based on the project structure and navigation logic:

- **Learning Detail UI**: [skill_detail_screen.dart](file:///D:/skill-swap/lib/screens/Swap/skill_detail_screen.dart) (when navigated from `MyLearningScreen`).
- **Teaching Detail UI**: [skill_detail_screen.dart](file:///D:/skill-swap/lib/screens/Swap/skill_detail_screen.dart) (when navigated from `MyTeachingScreen`).
- **Learning List UI**: [my_learning_screen.dart](file:///D:/skill-swap/lib/screens/Swap/my_learning_screen.dart).
- **Teaching List UI**: [my_teaching_screen.dart](file:///D:/skill-swap/lib/screens/Swap/my_teaching_screen.dart).

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure all warnings and errors are resolved.

### Manual Verification
- Verify that `sign up.dart` no longer has errors related to `intl_phone_field`.
