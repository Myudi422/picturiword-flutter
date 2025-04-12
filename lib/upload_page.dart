import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController textController = TextEditingController();
  File? imageFile;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadData() async {
    if (imageFile == null || textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih gambar dan masukkan teks')));
      return;
    }

    final fileName = basename(imageFile!.path);
    final storagePath = 'images/$fileName';

    // Upload image to Supabase Storage
    final response =
        await supabase.storage.from('uploads').upload(storagePath, imageFile!);
    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal upload gambar: ${response.error!.message}')));
      return;
    }

    final imageUrl = supabase.storage.from('uploads').getPublicUrl(storagePath);

    // Insert data into Supabase table
    await supabase
        .from('words')
        .insert({'text': textController.text, 'image_url': imageUrl});

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Berhasil upload!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Kata & Gambar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Masukkan kata'),
            ),
            const SizedBox(height: 10),
            imageFile != null
                ? Image.file(imageFile!,
                    width: 100, height: 100, fit: BoxFit.cover)
                : const Text('Belum ada gambar'),
            ElevatedButton(
                onPressed: pickImage, child: const Text('Pilih Gambar')),
            ElevatedButton(onPressed: uploadData, child: const Text('Upload')),
          ],
        ),
      ),
    );
  }
}
