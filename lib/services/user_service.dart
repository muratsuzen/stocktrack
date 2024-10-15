import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');

  /// Kullanıcı kaydı
  Future<void> registerUser(String email, String password) async {
    try {
      // Kullanıcıyı kaydet
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini kaydet
      final userId = userCredential.user!.uid; // Kullanıcı kimliği

      await _databaseRef.child(userId).set({
        'email': email,
        'subscriptionType': 'basic', // Varsayılan abonelik tipi
        'portfolios': {}, // Başlangıçta boş portföy
      });

      print("Kullanıcı başarıyla kaydedildi: $userId");
    } on FirebaseAuthException catch (e) {
      print("Hata: ${e.message}");
    }
  }

  /// Kullanıcı girişi
  Future<void> loginUser(String email, String password) async {
    try {
      // Kullanıcıyı giriş yap
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı kimliğini al
      final userId = userCredential.user!.uid; // Kullanıcı kimliği

      // Kullanıcı bilgilerini al
      final userSnapshot = await _databaseRef.child(userId).get();

      if (userSnapshot.exists) {
        print("Kullanıcı bilgileri: ${userSnapshot.value}");
      } else {
        print("Kullanıcı bulunamadı.");
      }
    } on FirebaseAuthException catch (e) {
      print("Hata: ${e.message}");
    }
  }

  /// Abonelik tipini güncelle
  Future<void> updateSubscriptionType(String userId, String newSubscriptionType) async {
    await _databaseRef.child(userId).update({
      'subscriptionType': newSubscriptionType,
    });

    print("Abonelik tipi güncellendi: $newSubscriptionType");
  }

}
