import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  final String userId;

  SubscriptionManagementScreen({required this.userId});

  @override
  _SubscriptionManagementScreenState createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  String _selectedSubscriptionType = 'basic'; // Varsayılan değer
  final List<String> _subscriptionTypes = ['basic', 'premium']; // Abonelik tipleri

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionType();
  }

  Future<void> _fetchSubscriptionType() async {
    DatabaseEvent event = await FirebaseDatabase.instance.ref('users/${widget.userId}').once();
    final userData = event.snapshot.value as Map<dynamic, dynamic>;

    setState(() {
      _selectedSubscriptionType = userData['subscriptionType'] ?? 'none'; // Abonelik tipini kontrol et
    });
  }

  Future<void> _updateSubscription(String subscriptionType) async {
    await FirebaseDatabase.instance.ref('users/${widget.userId}/subscriptionType').set(subscriptionType);
    setState(() {
      _selectedSubscriptionType = subscriptionType;
    });
  }

  Future<void> _cancelSubscription() async {
    // Aboneliği iptal etme işlemi
    await FirebaseDatabase.instance.ref('users/${widget.userId}/subscriptionType').set('none'); // Veya 'basic' gibi bir değer
    setState(() {
      _selectedSubscriptionType = 'none'; // İptal edildiğini göster
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Abonelik Yönetimi')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Mevcut Abonelik Tipi: $_selectedSubscriptionType'),
            DropdownButton<String>(
              value: _selectedSubscriptionType,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateSubscription(newValue);
                }
              },
              items: _subscriptionTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cancelSubscription,
              child: Text('Aboneliği İptal Et'),
            ),
          ],
        ),
      ),
    );
  }
}
