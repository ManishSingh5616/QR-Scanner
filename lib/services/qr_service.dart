import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/history_model.dart';

class QRService {
  static final QRService instance = QRService._internal();
  QRService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    if (_uid == null) return null;
    return _firestore.collection('users').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>>? get _historyCol {
    if (_uid == null) return null;
    return _firestore.collection('users').doc(_uid).collection('history');
  }

  // Record a generated QR code
  Future<String?> recordGenerated({
    required String qrType,
    required String title,
    required String data,
  }) async {
    if (_historyCol == null || _userDoc == null) return null;

    final docRef = _historyCol!.doc();
    final historyItem = HistoryModel(
      id: docRef.id,
      type: 'generated',
      qrType: qrType,
      title: title,
      data: data,
      createdAt: DateTime.now(),
    );

    await docRef.set(historyItem.toJson());

    // Atomically increment stats
    await _userDoc!.update({
      'totalGenerated': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Record a scanned QR code
  Future<String?> recordScanned({
    required String qrType,
    required String title,
    required String data,
  }) async {
    if (_historyCol == null || _userDoc == null) return null;

    final docRef = _historyCol!.doc();
    final historyItem = HistoryModel(
      id: docRef.id,
      type: 'scanned',
      qrType: qrType,
      title: title,
      data: data,
      createdAt: DateTime.now(),
    );

    await docRef.set(historyItem.toJson());

    await _userDoc!.update({
      'totalScanned': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Mark History item as saved
  Future<void> markSaved(String historyId) async {
    if (_historyCol == null || _userDoc == null) return;

    await _historyCol!.doc(historyId).update({'saved': true});
    await _userDoc!.update({'totalSaved': FieldValue.increment(1)});
  }

  // Mark History item as shared
  Future<void> markShared(String historyId) async {
    if (_historyCol == null || _userDoc == null) return;

    await _historyCol!.doc(historyId).update({'shared': true});
    await _userDoc!.update({'totalShared': FieldValue.increment(1)});
  }

  // Delete a specific history document
  Future<void> deleteHistory(String historyId) async {
    if (_historyCol == null) return;
    await _historyCol!.doc(historyId).delete();
  }

  // Clear all history documents without changing statistics
  Future<void> clearAllHistory() async {
    if (_historyCol == null) return;
    final snapshot = await _historyCol!.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Stream history list for real-time UI updates
  Stream<List<HistoryModel>> streamHistory() {
    if (_historyCol == null) return Stream.value([]);
    return _historyCol!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HistoryModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}