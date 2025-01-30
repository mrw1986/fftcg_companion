import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_service.dart';

part 'firestore_provider.g.dart';

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
FirestoreService firestoreService(ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreService(firestore);
}
