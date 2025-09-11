// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo_app/models/user.dart' as UserModel; // Korrekter Import deines Models

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserModel.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Hole Benutzerdaten aus Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserModel.User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      print('Fehler beim Login: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserModel.User?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? firebaseUser = result.user;
      
      // Create user document in Firestore
      if (firebaseUser != null) {
        UserModel.User user = UserModel.User(
          uid: firebaseUser.uid,
          email: email,
          username: username,
        );
        
        await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
        return user;
      }
      
      return null;
    } catch (e) {
      print('Fehler bei der Registrierung: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user with extended data
  Future<UserModel.User?> getCurrentUserData() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return UserModel.User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    return null;
  }
}