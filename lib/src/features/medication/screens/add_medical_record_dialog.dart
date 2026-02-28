import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/medical_record_service.dart';

class AddMedicalRecordDialog extends StatefulWidget {
  final String patientId;
  final String currentUserRole;

  const AddMedicalRecordDialog({Key? key, required this.patientId, required this.currentUserRole}) : super(key: key);

  @override
  _AddMedicalRecordDialogState createState() => _AddMedicalRecordDialogState();
}

class _AddMedicalRecordDialogState extends State<AddMedicalRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  
  DateTime _recordDate = DateTime.now();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // Need this for Web
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      
      // Check size (e.g. max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        setState(() {
          _uploadError = "File size exceeds 5MB limit.";
          _selectedFile = null;
        });
        return;
      }
      
      setState(() {
        _selectedFile = file;
        _uploadError = null;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _recordDate) {
      setState(() {
         _recordDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null) {
        setState(() => _uploadError = "Please select a file to upload.");
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      try {
        await MedicalRecordService().addMedicalRecord(
          elderlyId: widget.patientId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          hospitalName: _hospitalController.text.trim(),
          doctorName: _doctorController.text.trim(),
          recordDate: _recordDate,
          uploadedByRole: widget.currentUserRole,
          fileBytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          fileSize: _selectedFile!.size,
          fileType: _selectedFile!.extension ?? '',
        );

        if (mounted) {
           Navigator.of(context).pop();
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medical record uploaded successully.")));
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Medical Record'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_uploadError != null)
                  Container(
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(_uploadError!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Record Title *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hospitalController,
                  decoration: const InputDecoration(labelText: 'Hospital / Clinic Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(labelText: 'Doctor Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of Record', border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM dd, yyyy').format(_recordDate)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile != null ? _selectedFile!.name : 'No file selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_isUploading) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          child: const Text('Upload'),
        )
      ],
    );
  }
}
