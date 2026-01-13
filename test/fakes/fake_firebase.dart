import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight stub for Firestore used only inside unit tests and fakes.
class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
