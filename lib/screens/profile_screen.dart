import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _userId;
  String _subscriptionType = 'Free'; // Varsayılan abonelik türü

  // Abonelik türleri
  final List<String> _subscriptionTypes = ['Free', 'Premium'];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Kullanıcı ID'sini SharedPreferences'dan yükleme
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
    // Kullanıcı bilgilerini Firebase'den yükle
    _loadSubscriptionType();
  }

// Kullanıcının abonelik türünü Firebase'den yükleme
Future<void> _loadSubscriptionType() async {
  if (_userId != null) {
    final snapshot = await _database.child('users/$_userId/subscriptionType').once();
    if (snapshot.snapshot.exists) {
      String fetchedType = snapshot.snapshot.value as String;
      print("Fetched subscription type from Firebase: $fetchedType"); // Debug print
      if (_subscriptionTypes.contains(fetchedType)) {
        setState(() {
          _subscriptionType = fetchedType;
        });
      } else {
        // Handle unexpected value
        print("Unexpected subscription type fetched: $fetchedType");
        setState(() {
          _subscriptionType = _subscriptionTypes.first; // Set to default or first available
        });
      }
    }
  }
}


  // Abonelik türünü Firebase'de güncelleme
  Future<void> _updateSubscriptionType() async {
    if (_userId != null) {
      await _database.child('users/$_userId').update({
        'subscriptionType': _subscriptionType,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Abonelik türü güncellendi: $_subscriptionType'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Ayarları'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Abonelik Türü',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _subscriptionType,
              items: _subscriptionTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _subscriptionType = newValue!;
                });
                _updateSubscriptionType(); // Seçim yapıldığında güncelle
              },
            ),
          ],
        ),
      ),
    );
  }
}
