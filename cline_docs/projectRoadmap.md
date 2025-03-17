# Project Roadmap

## High-Level Goals

1. Create a comprehensive card collection management system
2. Provide robust user authentication and account management
3. Implement deck building and analysis tools
4. Add card scanning capabilities
5. Implement price tracking and market analysis
6. Enable collection sharing and social features

## Key Features

### Completed Features ✓

1. Theme Customization
   - [x] Light/dark mode support
   - [x] Custom color selection
   - [x] Theme persistence
   - [x] Contrast guarantees

2. Collection Management
   - [x] Card tracking (regular/foil)
   - [x] Condition tracking
   - [x] Purchase information
   - [x] Professional grading
   - [x] Collection statistics
   - [x] Grid/list views
   - [x] Filtering and sorting
   - [x] Search functionality

3. Authentication
   - [x] Email/password authentication
   - [x] Google Sign-In
   - [x] Email verification
   - [x] Account deletion
   - [x] Re-authentication flow
   - [x] Provider management
   - [x] Anonymous accounts
   - [x] Email update with proper logout flow

### In Progress Features

1. Card Database
   - [x] Card browsing
   - [x] Search functionality
   - [x] Filtering options
   - [ ] Advanced search features
   - [ ] Card relationships

### Planned Features

1. Deck Builder
   - [ ] Deck creation and editing
   - [ ] Deck analysis
   - [ ] Deck sharing
   - [ ] Deck statistics

2. Card Scanner
   - [ ] Image recognition
   - [ ] Bulk scanning
   - [ ] Collection import

3. Price Tracking
   - [ ] Market price tracking
   - [ ] Price history
   - [ ] Price alerts
   - [ ] Collection value analysis

4. Social Features
   - [ ] Collection sharing
   - [ ] Deck sharing
   - [ ] User profiles
   - [ ] Community features

## Completion Criteria

### Authentication System ✓

- [x] Implement secure user authentication
- [x] Support multiple auth providers
- [x] Handle email verification
- [x] Manage user accounts
- [x] Provide secure account deletion
- [x] Implement re-authentication
- [x] Support anonymous accounts
- [x] Implement proper email update flow with logout

### Collection Management ✓

- [x] Track card quantities
- [x] Track card conditions
- [x] Support professional grading
- [x] Provide collection statistics
- [x] Enable filtering and sorting
- [x] Implement search functionality
- [x] Support offline access

### Theme System ✓

- [x] Support light/dark modes
- [x] Allow custom colors
- [x] Ensure text contrast
- [x] Persist settings
- [x] Support system theme

## Progress Tracking

### Recently Completed

1. Simplified theme system by removing ContrastExtension dependency
2. Fixed Profile screen redundancies and improved UI layout
3. Enhanced theme settings page with interactive color selection
4. Improved theme consistency across the application
5. Updated all UI components to use standard Material ColorScheme

6. Enhanced email verification with proper UI updates
7. Improved account deletion flow with confirmation dialogs
8. Added better re-authentication handling
9. Fixed token refresh issues in auth service
10. Improved error messages and user feedback
11. Refactored profile page into smaller components for better maintainability
12. Improved "Change Email" flow with proper logout and user messaging

### Next Steps

1. Implement deck builder feature
2. Add card scanner functionality
3. Develop price tracking system
4. Add collection import/export
5. Implement collection sharing
6. Add favorites and wishlist
7. Enhance filtering options
8. Add batch operations

## Future Considerations

1. Performance Optimization
   - [ ] Implement lazy loading
   - [ ] Add caching mechanisms
   - [ ] Optimize image loading
   - [ ] Reduce network requests

2. Offline Support
   - [ ] Enhance offline capabilities
   - [ ] Implement sync queue
   - [ ] Add conflict resolution
   - [ ] Support offline edits

3. Analytics and Monitoring
   - [ ] Add usage analytics
   - [ ] Implement error tracking
   - [ ] Monitor performance
   - [ ] Track user engagement
