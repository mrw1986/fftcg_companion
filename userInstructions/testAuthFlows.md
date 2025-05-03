# Authentication Flow Testing Instructions

## Test Cases

### 1. Email Update Flow

#### A. Basic Email Update (Single Auth Method)

1. Create a new account with email/password
2. Go to Account Settings
3. Click "Change" next to the email
4. Enter a new email address
5. Verify the UI shows:
   - Original email in main section
   - Pending email with "Unverified" chip
   - Correct message about being logged out after verification
6. Open verification email and click the link
7. Verify:
   - Success dialog appears
   - App UI updates immediately (pending email disappears)
   - You are logged out (email/password only)
8. Log in with new email

#### B. Email Update with Google Auth

1. Create/use an account with both Google and email/password
2. Go to Account Settings
3. Click "Change" next to the email
4. Enter a new email address
5. Verify the UI shows:
   - Original email in main section
   - Pending email with "Unverified" chip
   - Message indicates you'll stay logged in (due to Google auth)
6. Open verification email and click the link
7. Verify:
   - Success dialog appears
   - App UI updates immediately (pending email disappears)
   - You remain logged in
   - Email is updated in UI

#### C. Edge Cases

1. **Multiple Updates:**
   - Start an email update
   - Before verifying, initiate another email update
   - Verify the first email update is cancelled
   - Complete the second email update
   - Verify UI updates correctly

2. **Background/Foreground:**
   - Start an email update
   - Background the app
   - Verify the email via link
   - Return to app
   - Verify UI updates correctly

3. **Cancel Update:**
   - Start an email update
   - Close the app without verifying
   - Reopen the app
   - Verify pending email state is preserved
   - Cancel the update
   - Verify UI clears pending state

### 2. Provider Linking

#### A. Link Email/Password to Google

1. Create account with email/password only
2. Go to Account Settings
3. Click "Link with Google"
4. Complete Google sign-in
5. Verify:
   - Both providers appear immediately
   - "Change Password" option appears
   - No unwanted redirects occur

#### B. Link Google to Email/Password

1. Create account with Google only
2. Go to Account Settings
3. Click "Link Email/Password"
4. Enter email/password
5. Verify:
   - Both providers appear immediately
   - "Change Password" option appears
   - No unwanted redirects occur

### 3. Provider Unlinking

#### A. Unlink Email/Password

1. Have account with both providers
2. Go to Account Settings
3. Click unlink icon next to Email/Password
4. Verify:
   - Provider disappears immediately
   - "Change Password" option disappears
   - No unwanted redirects occur

#### B. Unlink Google

1. Have account with both providers
2. Go to Account Settings
3. Click unlink icon next to Google
4. Verify:
   - Provider disappears immediately
   - No unwanted redirects occur

### 4. Account Deletion

#### A. Delete with Email/Password

1. Create account with email/password
2. Go to Account Settings
3. Click "Delete Account"
4. Confirm deletion
5. Enter credentials if prompted
6. Verify:
   - Success message appears
   - Redirected to auth page
   - Cannot log in with deleted account

#### B. Delete with Google

1. Create account with Google
2. Go to Account Settings
3. Click "Delete Account"
4. Confirm deletion
5. Complete Google re-auth if prompted
6. Verify:
   - Success message appears
   - Redirected to auth page
   - Cannot log in with deleted account

### 5. Password Management

#### A. Change Password

1. Have account with email/password
2. Go to Account Settings
3. Click "Change Password"
4. Complete re-authentication if prompted
5. Enter new password
6. Verify:
   - Success message appears
   - Can log in with new password
   - Cannot log in with old password

#### B. Reset Password

1. Go to login page
2. Click "Forgot Password"
3. Enter email
4. Open reset email
5. Click reset link
6. Enter new password
7. Verify:
   - Success message appears
   - Can log in with new password
   - Cannot log in with old password

### 6. Email Verification

#### A. New Account

1. Create account with email/password
2. Verify:
   - Verification banner appears
   - "Unverified" chip shows
3. Click verification link in email
4. Verify:
   - Banner disappears immediately
   - Chip disappears immediately
   - No page reload needed

#### B. After Linking Email

1. Have Google-only account
2. Link email/password
3. Verify:
   - Verification banner appears
   - "Unverified" chip shows
4. Click verification link in email
5. Verify:
   - Banner disappears immediately
   - Chip disappears immediately
   - No page reload needed

## Common Issues to Watch For

1. **UI Updates:**
   - All changes should reflect immediately without manual refresh
   - No flickering or temporary incorrect states
   - Proper loading indicators during operations

2. **Navigation:**
   - No unexpected redirects
   - Proper handling of back navigation
   - Correct destination after operations

3. **Error Handling:**
   - Clear error messages
   - Proper recovery from failed operations
   - No stuck loading states

4. **State Management:**
   - Correct provider states after operations
   - No orphaned states after sign-out
   - Proper cleanup after account deletion

## Reporting Issues

When reporting issues, please include:

1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. Screenshots if relevant
5. Error messages from logs
6. Device/OS information
