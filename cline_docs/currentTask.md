# Current Task

## Current Objective 46: Fix Riverpod Error After Google Linking & Subsequent Analyzer Issues

### Context

1. **Original Issue:** After successfully linking a Google account, a Riverpod error occurred: `Providers are not allowed to modify other providers during their initialization`. This happened because `authStateProvider` tried to modify `emailVerificationDetectedProvider` during its build phase.
2. **Initial Fix Attempt:** Introduced `authStateListenerProvider` to handle the side effect, but this created a dependency cycle.
3. **Subsequent Analyzer Errors:** Fixing the cycle revealed other analyzer errors related to null safety and type inference in `auto_auth_provider.dart`, `email_verification_checker.dart`, and a lint warning in `account_settings_page.dart`.

### Fix Applied (Objective 46)

1. **Riverpod Cycle Fix:**
    * Removed the incorrect `authStateListenerProvider`.
    * Integrated the logic for resetting `emailVerificationDetectedProvider` into the `ref.listen` callback within `firestoreUserSyncProvider`. This provider already listens to the source `firebaseUserProvider` and can safely perform the side effect after the state change.
2. **Analyzer Error Fixes:**
    * Added null-aware checks (`?.`) and default values (`?? false`) in `auto_auth_provider.dart`'s listener.
    * Added explicit type annotations (`AuthState? previous, AuthState next`) and null checks in `email_verification_checker.dart`'s listener.
    * Added an additional `if (mounted)` check immediately before `context.go()` in `_handleSuccessfulDeletion` within `account_settings_page.dart` to resolve the `use_build_context_synchronously` lint warning.

### Next Steps

1. **Test Google Linking:** Verify that linking a Google account no longer causes the Riverpod error.
2. **Test Email Verification Flow:** Ensure the `emailVerificationDetectedProvider` is correctly reset by the updated logic in `firestoreUserSyncProvider` when the user becomes verified or signs out.
3. **Test Account Deletion Flow:** Re-test account deletion (Objective 45) to ensure the `BuildContext` fix didn't introduce regressions.
4. **Test "Unverified" Chip Logic (Objective 44):** Test if the chip updates consistently with the banner after email verification.
5. Update `codebaseSummary.md` to reflect this objective's completion.
6. Proceed with testing other pending tasks (e.g., anonymous linking from Objective 27).

## Previous Objectives (Completed - Pending Testing)

### Objective 45: Refine Account Deletion Flow & Add Confirmation

* **Context:** Account deletion flow simplified, confirmation added, "Account Limits" dialog issue fixed. `use_build_context_synchronously` lint appeared.
* **Fix Applied:** Simplified `AuthService.deleteUser`, updated re-auth logic, added `_handleSuccessfulDeletion` helper with `skipAccountLimitsDialog: true` and Snackbar workaround. **Added extra `if (mounted)` check before navigation in helper (Obj 46).**
* **Status:** Fixes applied. **Testing required.**

### Objective 44: Fix "Unverified" Chip Logic

* **Context:** "Unverified" chip in `AccountSettingsPage` didn't update immediately after email verification.
* **Fix Applied:** Aligned chip logic with banner logic using `authState.status == AuthStatus.emailNotVerified && !verificationDetected`.
* **Status:** Fix applied. **Testing required.**

### Objective 42: Fix Email Verification UI Update Delay

* **Context:** Verification banner in `AccountSettingsPage` didn't update immediately.
* **Fix Applied (Attempt 2):** Implemented hybrid approach using immediate Firestore update and `emailVerificationDetectedProvider`.
* **Status:** Fix applied. **Testing required.** (Chip logic addressed in Obj 44)

## Previous Objectives (Completed)

1. **Diagnose Google Linking Error and Consolidate User Creation Logic (Objective 41)**
    * **Context:** Google linking failed (`credential-already-in-use`), duplicated Firestore update logic identified.
    * **Changes:** Centralized most Firestore updates via `firestoreUserSyncProvider`. Reverted immediate update for `linkEmailAndPasswordToAnonymous`. Added router `redirect` and `errorBuilder`. Standardized `context.pop()`.
    * **Result:** Google linking error resolved. Navigation after linking/registration fixed. Router best practices improved. Revealed email verification UI delay (Obj 42). **Riverpod error during linking fixed in Obj 46.**

2. **Prevent Anonymous Dialog After Password Reset (Objective 40)**
    * **Status:** Completed.

3. **Fix Email Verification Status Update (Objective 39)**
    * **Status:** Implemented (UI timing addressed in Obj 42/44, state reset logic refined in Obj 46).

4. **Authentication Flow and Firestore Data Issues (Objective 38)**
    * **Status:** Superseded by Objective 41.

5. **Fix Registration Routing Error (Objective 36)**
    * **Status:** Completed.

6. **Update Registration Confirmation Text & Verify Navigation (Objective 35)**
    * **Status:** Completed.

7. **Correct Account Deletion Order (Objective 34)**
    * **Status:** Superseded by Objective 45.

8. **Ensure Firestore User Document is Fully Populated During Authentication (Objective 33)**
    * **Status:** Completed. Testing recommended.

9. **Fixed Google Authentication Display Name Issue (Objective 30)**
    * **Status:** Completed.

10. **Firestore Permission Issues During Data Migration (Objective 27 - Fix Applied)**
    * **Status:** Completed. Testing still recommended.

11. **Fixed Email Update Flow and UI Updates (Objective 26)**
    * **Status:** Completed.

12. **Authentication System Rebuild**
    * **Status:** Completed.

## Pending Tasks from Previous Objectives

1. **Test Firestore Permission Fix (Critical - Objective 27):**
    * [ ] **Test anonymous user linking to Google account (Primary test).**
    * [ ] Verify user document creation for new anonymous users.
    * [ ] Test standard operations for both user types.
    * [ ] Check Firestore logs for permission errors.

2. **Continue Authentication System Testing:**
    * [ ] Verify all edge cases are handled.
    * [ ] Ensure proper state transitions.

3. **Expand Data Migration (If Permission Fix Successful):**
    * [ ] Implement deck data migration.
    * [ ] Add user settings migration.
    * [ ] Include user preferences migration.
