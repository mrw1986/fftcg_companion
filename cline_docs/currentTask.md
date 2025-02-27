# Current Task

## Objective

Implement proper metadata system for efficient card syncing

## Context

The app's incremental sync functionality was not working properly because:

1. The sync service wasn't adding the `dataVersion` field to card documents
2. The app was trying to query cards with a `dataVersion` field greater than the locally stored version
3. This mismatch caused the app to always perform full syncs, resulting in excessive Firestore reads

## Implementation Plan

### 1. Add dataVersion Field to Card Documents

Location: ../fftcg-sync-service/functions/src/services/cardSync.ts

Current Issue:

- The `dataVersion` field was defined in the CardDocument interface but not being set when creating card documents
- This caused the app's incremental sync functionality to fail

Solution:

- Add the `dataVersion` field to the card document in the `processCards` method:

  ```typescript
  const cardDoc: CardDocument = {
    // existing fields...
    dataVersion: currentVersion, // Add the current version to enable incremental sync
  };
  ```

Impact:

- New and updated cards will have the proper version information
- Enables the app to query only for cards updated since last sync
- Reduces Firestore reads during updates

### 2. Ensure Existing Cards Get Updated

Location: ../fftcg-sync-service/functions/src/services/cardSync.ts

Current Issue:

- Existing cards without the `dataVersion` field wouldn't be updated unless their content changed
- The sync service was skipping updates for cards with matching hashes

Solution:

- Modify the skip condition to check for the `dataVersion` field:

  ```typescript
  // Check if the card document has the dataVersion field
  const cardData = cardSnapshot.data();
  const hasDataVersion = cardSnapshot.exists && cardData && 'dataVersion' in cardData;

  // Skip only if document exists, hash matches, has dataVersion, and not forcing update
  if (cardSnapshot.exists && currentHash === storedHash && hasDataVersion && !options.forceUpdate) {
    logger.info(`Skipping card ${card.productId} - no changes detected`);
    return;
  }
  ```

Impact:

- Existing cards will be updated with the `dataVersion` field on the next sync
- No force flag required - the regular sync process will handle it
- Smooth transition to the new versioning system

## Testing Strategy

1. Sync Process Testing
   - Run a normal sync without the force flag
   - Verify cards are updated with the `dataVersion` field
   - Check that subsequent syncs skip cards with matching hashes and existing `dataVersion` field

2. Incremental Sync Testing
   - Update a few cards in the sync service
   - Verify only those cards are fetched by the app during sync
   - Confirm the app's local version is updated correctly

3. Offline Functionality
   - Test sync with no internet connection
   - Verify graceful fallback to cached data
   - Check error handling for permission issues

## Success Criteria

- All card documents have the `dataVersion` field after a sync
- The app only fetches cards updated since the last sync
- Firestore reads are significantly reduced during sync operations
- Sync works properly even with intermittent connectivity
- Version tracking is consistent between app and backend

## Next Steps

1. Monitor sync performance and Firestore usage
2. Consider implementing batch processing for large sync operations
3. Add analytics to track sync efficiency
4. Explore further optimizations for the sync process
