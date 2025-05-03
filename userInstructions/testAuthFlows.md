# Authentication Flow Testing Plan (v4)

This plan outlines the steps to test the authentication flows, focusing on the recent fixes for email updates, linking/unlinking providers, and ensuring the "Change Password" option appears correctly.

**Important:** Perform these tests on a device or emulator with a working internet connection and access to the email account used for testing.

## Setup

1. Ensure the app is running with the latest code changes.
2. Open the app on a test device or emulator.
3. If already signed in, sign out.

## Test Cases

### 1. Anonymous Sign-in & Account Creation

1. Start the app. You should be signed in anonymously.
2. Navigate to the Profile tab.
3. Tap "Sign In or Register".
4. Tap "Create Account".
5. Enter a **new** email address and password.
6. Tap "Create Account".
    - **Expected:** Account created successfully. You should be navigated to the Account Settings page. A verification email should be sent to the provided email address. The "Email/Password" authentication method should be listed. **The "Change Password" option should be visible immediately.**
7. Check the email inbox for the verification email and click the link.
8. Return to the app.
    - **Expected:** The "Email Not Verified" banner and chip should disappear. The "Change Password" option should remain visible.

### 2. Google Sign-in & Account Creation

1. Start the app. You should be signed in anonymously.
2. Navigate to the Profile tab.
3. Tap "Sign In or Register".
4. Tap "Sign in with Google".
5. Select a Google account (or add a new one).
    - **Expected:** You should be signed in with your Google account and navigated to the Account Settings page. The "Google" authentication method should be listed. **The "Change Password" option should NOT be visible.**

### 3. Linking Email/Password to an Existing Google Account

1. Sign in with a Google account (if not already).
2. Navigate to the Account Settings page.
3. Under "Authentication Methods", tap the "Link" icon next to "Email/Password".
4. Enter a **new** email address and password in the dialog.
5. Tap "Link Account".
    - **Expected:** The dialog should close. A success message should appear. The "Email/Password" authentication method should now be listed alongside Google. A verification email should be sent to the newly linked email address. **The "Change Password" option should be visible immediately.**
6. Check the email inbox for the verification email and click the link.
7. Return to the app.
    - **Expected:** The "Email Not Verified" banner and chip (if they appeared briefly) should disappear. The "Change Password" option should remain visible.

### 4. Linking Google to an Existing Email/Password Account

1. Sign in with an Email/Password account (if not already).
2. Navigate to the Account Settings page.
3. Under "Authentication Methods", tap the "Link" icon next to "Google".
4. Tap "Sign in with Google" in the dialog.
5. Select a Google account (or add a new one).
    - **Expected:** The dialog should close. A success message should appear. The "Google" authentication method should now be listed alongside Email/Password. The "Change Password" option should remain visible.

### 5. Unlinking Authentication Methods

1. Sign in with an account that has **multiple** authentication methods linked (e.g., Email/Password and Google).
2. Navigate to the Account Settings page.
3. Under "Authentication Methods", tap the "Unlink" icon next to one of the providers (e.g., Google).
    - **Expected:** A confirmation dialog should appear.
4. Tap "Unlink".
    - **Expected:** The provider should be unlinked. The corresponding authentication method should disappear from the list. The "Change Password" option should remain visible if Email/Password is still linked, or disappear if Email/Password was unlinked.
5. Repeat for the other linked provider.
    - **Expected:** You should be left with only one authentication method (if you started with two). If you unlink the last method, you should be signed out and returned to the Auth page.

### 6. Email Update Flow (Stay Logged In)

1. Sign in with an account that has **multiple** authentication methods (e.g., Email/Password and Google).
2. Navigate to the Account Settings page.
3. Tap "Change" next to the Email/Password method.
4. Enter a **new, unverified** email address.
5. Tap "Update Email".
    - **Expected:** A confirmation dialog appears stating you will remain logged in.
6. Tap "Send Verification Email".
    - **Expected:** A dialog appears confirming the verification email has been sent. The pending email should be displayed in the Account Information section. You should remain logged in.
7. Check the email inbox for the verification email and click the link.
8. Return to the app.
    - **Expected:** The pending email display should disappear. The email address listed under Email/Password should update to the new verified email. The "Change Password" option should remain visible.

### 7. Email Update Flow (Logged Out)

1. Sign in with an account that has **only** Email/Password authentication.
2. Navigate to the Account Settings page.
3. Tap "Change" next to the Email/Password method.
4. Enter a **new, unverified** email address.
5. Tap "Update Email".
    - **Expected:** A confirmation dialog appears stating you will be logged out.
6. Tap "Send Verification Email".
    - **Expected:** A dialog appears confirming the verification email has been sent. The pending email should be displayed. You should be logged out and returned to the Auth page.
7. Check the email inbox for the verification email and click the link.
8. Return to the app.
    - **Expected:** You should be able to sign in with the **new** email address and the **old** password. The Account Settings page should show the new email as verified, and the "Change Password" option should be visible.

### 8. Account Deletion

1. Sign in with any account.
2. Navigate to the Account Settings page.
3. Under "Account Actions", tap "Delete Account".
    - **Expected:** A confirmation dialog should appear.
4. Tap "Delete Account".
    - **Expected:** If re-authentication is required, a re-authentication dialog should appear.
5. Complete the re-authentication (if prompted).
    - **Expected:** The account should be deleted. A success snackbar should appear. You should be signed out and returned to the Auth page.

### 9. Re-authentication

1. Sign in with any account.
2. Navigate to the Account Settings page.
3. Attempt an action that requires re-authentication (e.g., deleting the account, changing email if prompted).
    - **Expected:** A re-authentication dialog should appear.
4. Choose to re-authenticate with either Email/Password or Google (if available).
    - **Expected:** Upon successful re-authentication, the dialog should close, and the original action should proceed.

## Reporting

- For each test case, note whether the expected behavior occurred.
- If unexpected behavior or errors occur, record:
  - The test case number and step.
  - A description of what happened.
  - Any error messages or relevant logs from the console.
  - A screenshot if it's a UI issue.

This comprehensive plan should help verify the fixes and ensure the authentication flows are working as expected, including the correct display of the "Change Password" option.
