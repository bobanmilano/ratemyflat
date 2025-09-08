import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addApartment(Map<String, dynamic> apartmentData) async {
    await _db.collection('apartments').add(apartmentData);
  }

}