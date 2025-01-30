# ErrorHandling

## Common Error Types

### Network Errors
1. Connection Issues
   ```dart
   try {
     await repository.fetchData();
   } on SocketException catch (e) {
     // Handle no internet connection
     logger.e('Network error: ${e.message}');
     return Left(NetworkError(e.message));
   }
   ```

2. Timeout Handling
   ```dart
   try {
     await repository.fetchData().timeout(
       Duration(seconds: 30),
       onTimeout: () => throw TimeoutException('Request timed out'),
     );
   } on TimeoutException catch (e) {
     // Handle timeout
     return Left(TimeoutError());
   }
   ```

### Firebase Errors
1. Authentication
   ```dart
   try {
     await auth.signIn();
   } on FirebaseAuthException catch (e) {
     switch (e.code) {
       case 'user-not-found':
         return Left(AuthError.userNotFound);
       case 'wrong-password':
         return Left(AuthError.wrongPassword);
       default:
         return Left(AuthError.unknown);
     }
   }
   ```

2. Firestore
   ```dart
   try {
     await firestore.collection('cards').add(data);
   } on FirebaseException catch (e) {
     if (e.code == 'permission-denied') {
       return Left(DatabaseError.permissionDenied);
     }
     return Left(DatabaseError.unknown);
   }
   ```

### Local Storage Errors
1. Hive Operations
   ```dart
   try {
     await Hive.openBox('cards');
   } catch (e) {
     logger.e('Failed to open Hive box: $e');
     return Left(StorageError.boxOpenFailed);
   }
   ```

2. Cache Management
   ```dart
   try {
     await cacheManager.saveCard(card);
   } on HiveError catch (e) {
     return Left(CacheError.saveFailed);
   }
   ```

## Error Handling Strategies

### Repository Layer
```dart
class CardRepository {
  Future<Either<Failure, List<Card>>> getCards() async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkError.noConnection);
      }
      
      final result = await remoteDataSource.getCards();
      await localDataSource.cacheCards(result);
      return Right(result);
    } catch (e) {
      return Left(handleError(e));
    }
  }
}
```

### Presentation Layer
```dart
class CardsProvider extends StateNotifier<CardsState> {
  Future<void> loadCards() async {
    state = CardsState.loading();
    
    final result = await repository.getCards();
    state = result.fold(
      (failure) => CardsState.error(failure.message),
      (cards) => CardsState.loaded(cards)
    );
  }
}
```

## Error Recovery

### Retry Mechanisms
```dart
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempts = 0;
  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts == maxAttempts) rethrow;
      await Future.delayed(delay * attempts);
    }
  }
  throw Exception('Max retry attempts reached');
}
```

### Offline Support
```dart
Future<Either<Failure, List<Card>>> getCards() async {
  try {
    if (await networkInfo.isConnected) {
      return await remoteDataSource.getCards();
    } else {
      return await localDataSource.getCards();
    }
  } catch (e) {
    return Left(handleError(e));
  }
}
```

## Error Reporting

### Logging
```dart
class Logger {
  void error(String message, [Error? error, StackTrace? stackTrace]) {
    // Log to analytics service
    // Print to console in debug mode
    // Store locally for crash reporting
  }
}
```

### User Feedback
```dart
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

## Best Practices

### Error Prevention
- Validate input data
- Check network connectivity before requests
- Implement proper state management
- Use type-safe APIs

### Error Recovery
- Implement retry mechanisms
- Provide offline functionality
- Cache critical data
- Handle edge cases

### Error Reporting
- Log errors appropriately
- Include context in error messages
- Track error metrics
- Monitor crash reports

## Actionable Advice
- Always handle errors at appropriate layers
- Provide meaningful error messages to users
- Implement proper logging and monitoring
- Test error scenarios thoroughly
- Keep error handling consistent across the app
- Document error types and handling strategies
