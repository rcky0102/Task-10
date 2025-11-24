import 'package:cloud_firestore/cloud_firestore.dart';

class CrudService {
  final CollectionReference items = FirebaseFirestore.instance.collection(
    'items',
  );

  Future<void> addItem(String name, int quantity) {
    //CREATE
    return items.add({
      'name': name,
      'quantity': quantity,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getItems() {
    //READ
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateItem(String id, String name, int quantity) {
    //UPDATE
    return items.doc(id).update({'name': name, 'quantity': quantity});
  }

  Future<void> deleteItem(String id) {
    //DELETE
    return items.doc(id).delete();
  }
}
