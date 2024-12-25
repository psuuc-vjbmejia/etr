import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateResumePage extends StatefulWidget {
  final Function(String, String) onSave;

  const CreateResumePage({super.key, required this.onSave});

  @override
  State<CreateResumePage> createState() => _CreateResumePageState();
}

class _CreateResumePageState extends State<CreateResumePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  final pdf = pw.Document();

  Future<void> generatePdf(String name, String experience) async {
    try {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
              child: pw.Column(
            children: [
              pw.Text('Resume of $name',
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text('Experience:', style: const pw.TextStyle(fontSize: 18)),
              pw.Text(experience),
            ],
          ));
        },
      ));

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/resume.pdf');
      await file.writeAsBytes(await pdf.save());

      print('file.path' + file.path);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              filePath: file.path,
              pdf: pdf,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Resume')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Resume Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Name:'),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Experience:'),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your experience',
                ),
                maxLines: 4, // Allow multiline input
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text;
                  String experience = experienceController.text;
                  if (name.isEmpty || experience.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill out all fields')),
                    );
                    return;
                  }

                  widget.onSave(name, experience);
                  generatePdf(name, experience);
                  // Navigator.pop(context); // Return to the previous screen
                },
                child: const Text('Generate Resume'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final pw.Document pdf;

  const PdfViewerScreen({super.key, required this.filePath, required this.pdf});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  void initState() {
    requestStoragePermission();
    setState(() {});
  }

  Future<bool> requestStoragePermission() async {
    // Request storage permission
    var status = await Permission.manageExternalStorage.request();

    // Handle the status
    if (status.isGranted) {
      print("Storage permission granted.");
      return true;
    } else if (status.isDenied) {
      print("Storage permission denied. Please enable it in settings.");
      await openAppSettings();
      return false;
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permission is permanently denied
      print("Storage permission permanently denied. Opening settings.");
      await openAppSettings();
      return false;
    }
    return false;
  }

  Future<void> downLoadPdf() async {
    // Request storage permission
    if (await requestStoragePermission()) {
      // Get the downloads directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (downloadsDirectory.existsSync()) {
        final file = File('${downloadsDirectory.path}/resume.pdf');

        // Save the PDF file
        await file.writeAsBytes(await widget.pdf.save());

        print('PDF saved to ${file.path}');
      } else {
        print('Downloads directory not found');
      }
    } else {
      print('Storage permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Resume')),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: widget.filePath,
            ),
          ),
          SizedBox(
            height: 40,
          ),
          ElevatedButton(
              onPressed: () {
                downLoadPdf();
              },
              child: const Text('Down Load Resume')),
          SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }
}
