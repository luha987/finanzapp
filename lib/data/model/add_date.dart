import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:hive/hive.dart';

part 'add_date.g.dart';

@HiveType(typeId: 1)
class Add_data extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String explain;

  @HiveField(2)
  String amount;

  @HiveField(3)
  String IN;

  @HiveField(4)
  DateTime datetime;

  @HiveField(5)
  String? firebaseKey;

  Add_data(this.IN, this.amount, this.datetime, this.explain, this.name, {this.firebaseKey});

  // Factory constructor to create Add_data from a Map (for Firebase Realtime Database or Firestore)
  factory Add_data.fromMap(Map<dynamic, dynamic> map, String key) {
    return Add_data(
      map['IN'] ?? '',
      map['amount'] ?? '',
      DateTime.parse(map['datetime'] ?? '2000-01-01'),
      map['explain'] ?? '',
      map['name'] ?? '',
      firebaseKey: key,
    );
  }

  // Define fromSnapshot method to convert Firebase Realtime Database or Firestore snapshot to Add_data
  factory Add_data.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Add_data.fromMap(data, snapshot.key ?? '');
  }

  // Getter to retrieve the Firebase key
  String? get getFirebaseKey => firebaseKey;

  // Method to convert Add_data to a Map (for storing in Firebase or other purposes)
  Map<String, dynamic> toFirebaseMap() {
    return {
      'IN': this.IN,
      'amount': this.amount,
      'datetime': this.datetime.toIso8601String(),
      'explain': this.explain,
      'name': this.name,
    };
  }
}
