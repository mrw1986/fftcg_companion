import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_repository.dart';
import 'package:fftcg_companion/features/collection/domain/models/collection_item.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Migrates all collection items from [fromUserId] to [toUserId].
Future<void> migrateCollectionData({
  required CollectionRepository collectionRepository,
  required String fromUserId,
  required String toUserId,
}) async {
  try {
    talker.debug('Starting collection data migration');
    talker.debug('From user: $fromUserId');
    talker.debug('To user: $toUserId');

    final fromItems = await collectionRepository.getUserCollection(fromUserId);
    final toItems = await collectionRepository.getUserCollection(toUserId);

    if (fromItems.isEmpty) {
      talker.debug('No items found for source user, skipping migration');
      return;
    }

    final toItemMap = {for (var item in toItems) item.cardId: item};
    final List<CollectionItem> mergedItems = [];

    for (final item in fromItems) {
      final existing = toItemMap[item.cardId];
      if (existing != null) {
        // Merge quantities and metadata
        final merged = existing.copyWith(
          regularQty: existing.regularQty + item.regularQty,
          foilQty: existing.foilQty + item.foilQty,
          condition: {...existing.condition, ...item.condition},
          purchaseInfo: {...existing.purchaseInfo, ...item.purchaseInfo},
          gradingInfo: {...existing.gradingInfo, ...item.gradingInfo},
          lastModified: Timestamp.now(), // Update modification time
        );
        mergedItems.add(merged);
        talker.debug('Merged item: ${item.cardId}');
      } else {
        // Reassign userId and add as new
        mergedItems.add(item.copyWith(
          userId: toUserId,
          lastModified: Timestamp.now(), // Update modification time
        ));
        talker.debug('Added new item: ${item.cardId}');
      }
    }

    if (mergedItems.isNotEmpty) {
      await collectionRepository.batchUpdateCards(mergedItems);
      talker.debug('Successfully updated ${mergedItems.length} items');
    }
  } catch (e, stack) {
    talker.error('Error during collection data migration', e, stack);
    // Don't rethrow - we want to continue with the account linking process
    // even if collection migration fails
  }
}
