import 'package:fftcg_companion/features/collection/data/repositories/collection_repository.dart';
import 'package:fftcg_companion/features/collection/domain/models/collection_item.dart';

/// Migrates all collection items from [fromUserId] to [toUserId].
Future<void> migrateCollectionData({
  required CollectionRepository collectionRepository,
  required String fromUserId,
  required String toUserId,
}) async {
  final fromItems = await collectionRepository.getUserCollection(fromUserId);
  final toItems = await collectionRepository.getUserCollection(toUserId);
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
      );
      mergedItems.add(merged);
    } else {
      // Reassign userId and add as new
      mergedItems.add(item.copyWith(userId: toUserId));
    }
  }

  await collectionRepository.batchUpdateCards(mergedItems);
}
