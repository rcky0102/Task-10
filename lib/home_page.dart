import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crud_service.dart';
import 'Login.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  final Color darkGrey = const Color(0xFF2E2E2E);
  final Color lightGrey = const Color(0xFFF2F2F2);

  File? selectedImageFile;
  String? selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,

      appBar: AppBar(
        title: const Text(
          "Firebase Adaya",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkGrey,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: darkGrey,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No items found", style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              var data = item.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: data['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.grey),

                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    "Quantity: ${data['quantity']}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => openEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =========================
  // DELETE ITEM
  // =========================
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete item"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // ADD ITEM
  // =========================
  void openAddDialog() {
    nameCtrl.clear();
    qtyCtrl.clear();
    selectedImageFile = null;
    selectedImageUrl = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                if (selectedImageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedImageFile!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text("Upload Image"),
                  onPressed: () async {
                    final picked = await service.pickImageForAddItem();
                    if (picked != null) {
                      setStateDialog(() {
                        selectedImageFile = picked.file;
                        selectedImageUrl = picked.url;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              child: const Text("Save"),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  service.addItemWithImage(
                    nameCtrl.text,
                    int.parse(qtyCtrl.text),
                    selectedImageUrl,
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // EDIT ITEM
  // =========================
  void openEditDialog(DocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    selectedImageUrl = item['image_url']; // existing saved URL
    selectedImageFile = null; // no local file yet

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedImageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedImageFile!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (selectedImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      selectedImageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Change Image"),
                  onPressed: () async {
                    final picked = await service.pickImageForAddItem();
                    if (picked != null) {
                      setStateDialog(() {
                        selectedImageFile = picked.file;
                        selectedImageUrl = picked.url;
                      });
                    }
                  },
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              child: const Text("Update"),
              onPressed: () async {
                await service.updateItemWithImage(
                  item.id,
                  nameCtrl.text,
                  int.parse(qtyCtrl.text),
                  selectedImageUrl,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
