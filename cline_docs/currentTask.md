# Current Task

## Current Objective 49: Revert Firestore Rules for Collection Path

### Context

- **Initial Error:** Users encountered `[cloud_firestore/permission-denied]` errors when adding/updating cards.
- **Incorrect Fix (Objective 48):** Based on an assumption about best practices, `firestore.rules` was modified to expect collection data in a `/users/{userId}/collection/` subcollection, and the rules for the top-level `/collections/` path were removed.
- **New Logs Analysis:** Subsequent logs clearly showed the application code (`CollectionRepository`) is actually reading from and writing to the top-level `/collections/{collectionId}` path, causing new read/write permission errors because the rules no longer matched the code's behavior.

### Fix Applied (Objective 49)

- Reverted `firestore.rules` to the state *before* Objective 48.
  - Restored the `match /collections/{collectionId}` block with its associated read/write/create/update/delete rules.
  - Removed the incorrect nested `match /users/{userId}/collection/{collectionItemId}` block that was added in Objective 48.
- This aligns the Firestore rules with the data path currently used by the application code.

### Next Steps

1. **Test Collection Add/Update/View (Critical):** Verify that adding, updating, and viewing cards in the user collection now works without permission errors, using the reverted rules for the `/collections/` path.
2. **If Errors Persist:** If permission errors still occur on the `/collections/` path after this reversion, investigate potential issues with data validation (`isValidCollectionItem`) or the data being sent by `CollectionRepository`.
3. **Test App Initialization (Objective 47):** Verify that the app starts without the `NoSuchMethodError` during set count preloading.
4. **Test Google Linking (Objective 46):** Verify that linking a Google account no longer causes the Riverpod error.
5. **Test Email Verification Flow (Objective 46):** Ensure the `emailVerificationDetectedProvider` is correctly reset by the updated logic in `firestoreUserSyncProvider`.
6. **Test Account Deletion Flow (Objective 45):** Re-test account deletion to ensure the `BuildContext` fix didn't introduce regressions.
7. **Test "Unverified" Chip Logic (Objective 44):** Test if the chip updates consistently with the banner after email verification.
8. Update `codebaseSummary.md` to reflect the completion of Objectives 47 and 49 (and the reversion of 48).
9. Proceed with testing other pending tasks (e.g., anonymous linking from Objective 27).

## Previous Objectives (Completed - Pending Testing / Reverted)

### Objective 48: Fix Firestore Permission Denied Error for Collection - **REVERTED**

- **Context:** Initial permission denied error.
- **Attempted Fix (Incorrect):** Modified rules to use `/users/{userId}/collection/` path based on assumption. Removed rules for `/collections/`.
- **Outcome:** Caused new read/write errors as rules no longer matched the code's actual path (`/collections/`). **Reverted by Objective 49.**

### Objective 47: Fix Initialization Error During Set Count Preload

- **Context:** App initialization failed with `NoSuchMethodError: Class 'Future<int>' has no instance method 'ignore'.` when preloading set card counts in `initializationProvider`.
- **Fix Applied:** Modified `lib/features/cards/presentation/providers/initialization_provider.dart`. Replaced `.ignore()` with `await` on the `filteredSetCardCountCacheProvider(setId).future` call within the loop.
- **Status:** Fix applied. **Testing required.**

### Objective 46: Fix Riverpod Error After Google Linking & Subsequent Analyzer Issues

- **Context:** Google linking caused Riverpod error, fixing revealed cycle and analyzer errors.
- **Fix Applied:** Removed listener provider, integrated reset logic into `firestoreUserSyncProvider`, fixed analyzer errors (null safety, types, mounted checks).
- **Status:** Fixes applied. **Testing required.**

### Objective 45: Refine Account Deletion Flow & Add Confirmation

- **Context:** Account deletion flow simplified, confirmation added, "Account Limits" dialog issue fixed. `use_build_context_synchronously` lint appeared.
- **Fix Applied:** Simplified `AuthService.deleteUser`, updated re-auth logic, added `_handleSuccessfulDeletion` helper with `skipAccountLimitsDialog: true` and Snackbar workaround. Added extra `if (mounted)` check before navigation in helper (Obj 46).
- **Status:** Fixes applied. **Testing required.**

### Objective 44: Fix "Unverified" Chip Logic

- **Context:** "Unverified" chip in `AccountSettingsPage` didn't update immediately after email verification.
- **Fix Applied:** Aligned chip logic with banner logic using `authState.status == AuthStatus.emailNotVerified && !verificationDetected`.
- **Status:** Fix applied. **Testing required.**

### Objective 42: Fix Email Verification UI Update Delay

- **Context:** Verification banner in `AccountSettingsPage` didn't update immediately.
- **Fix Applied (Attempt 2):** Implemented hybrid approach using immediate Firestore update and `emailVerificationDetectedProvider`.
- **Status:** Fix applied. **Testing required.** (Chip logic addressed in Obj 44)

## Previous Objectives (Completed)

1. **Diagnose Google Linking Error and Consolidate User Creation Logic (Objective 41)**
    - **Context:** Google linking failed (`credential-already-in-use`), duplicated Firestore update logic identified.
    - **Changes:** Centralized most Firestore updates via `firestoreUserSyncProvider`. Reverted immediate update for `linkEmailAndPasswordToAnonymous`. Added router `redirect` and `errorBuilder`. Standardized `context.pop()`.
    - **Result:** Google linking error resolved. Navigation after linking/registration fixed. Router best practices improved. Revealed email verification UI delay (Obj 42). Riverpod error during linking fixed in Obj 46.

2. **Prevent Anonymous Dialog After Password Reset (Objective 40)**
    - **Status:** Completed.

3. **Fix Email Verification Status Update (Objective 39)**
    - **Status:** Implemented (UI timing addressed in Obj 42/44, state reset logic refined in Obj 46).

4. **Authentication Flow and Firestore Data Issues (Objective 38)**
    - **Status:** Superseded by Objective 41.

5. **Fix Registration Routing Error (Objective 36)**
    - **Status:** Completed.

6. **Update Registration Confirmation Text & Verify Navigation (Objective 35)**
    - **Status:** Completed.

7. **Correct Account Deletion Order (Objective 34)**
    - **Status:** Superseded by Objective 45.

8. **Ensure Firestore User Document is Fully Populated During Authentication (Objective 33)**
    - **Status:** Completed. Testing recommended.

9. **Fixed Google Authentication Display Name Issue (Objective 30)**
    - **Status:** Completed.

10. **Firestore Permission Issues During Data Migration (Objective 27 - Fix Applied)**
    - **Status:** Completed. Testing still recommended.

11. **Fixed Email Update Flow and UI Updates (Objective 26)**
    - **Status:** Completed.

12. **Authentication System Rebuild**
    - **Status:** Completed.

## Pending Tasks from Previous Objectives

1. **Test Firestore Permission Fix (Critical - Objective 27):**
    - [ ] **Test anonymous user linking to Google account (Primary test).**
    - [ ] Verify user document creation for new anonymous users.
    - [ ] Test standard operations for both user types.
    - [ ] Check Firestore logs for permission errors.

2. **Continue Authentication System Testing:**
    - [ ] Verify all edge cases are handled.
    - [ ] Ensure proper state transitions.

3. **Expand Data Migration (If Permission Fix Successful):**
    - [ ] Implement deck data migration.
    - [ ] Add user settings migration.
    - [ ] Include user preferences migration.
