import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Supabase instead of Firebase Storage
import 'dart:io';

class OfferSkillScreen extends StatefulWidget {
  const OfferSkillScreen({super.key});

  @override
  State<OfferSkillScreen> createState() => _OfferSkillScreenState();
}

class _OfferSkillScreenState extends State<OfferSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client; // ✅ Supabase client

  final _titleController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedExperience;
  bool _isLoading = false;

  // ── Portfolio upload state ────────────────────────────────────────
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _uploadedFileUrl;

  final List<String> _categories = [
    'Creative & Design',
    'Tech & Digital',
    'Entrepreneurship',
    'Professional Growth',
    'Language',
    'Music & Art',
    'Lifestyle',
    'Tutoring',
  ];

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  String _mapCategory(String label) {
    const map = {
      'Creative & Design': 'Design',
      'Tech & Digital': 'Coding',
      'Music & Art': 'Music',
    };
    return map[label] ?? label;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lookingForController.dispose();
    _portfolioController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ Upload portfolio to Supabase Storage
  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _pickedFile = file;
      _isUploading = true;
      _portfolioController.clear();
    });

    try {
      final uid = _auth.currentUser?.uid ?? 'anon';
      final fileName =
          'portfolios/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // ✅ Upload to Supabase Storage bucket 'portfolios'
      if (file.bytes != null) {
        await _supabase.storage
            .from('portfolios')
            .uploadBinary(
          fileName,
          file.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else if (file.path != null) {
        await _supabase.storage
            .from('portfolios')
            .upload(
          fileName,
          File(file.path!),
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        throw 'File data not found';
      }

      // ✅ Get public URL instantly — no retry needed with Supabase
      final url = _supabase.storage
          .from('portfolios')
          .getPublicUrl(fileName);

      setState(() {
        _uploadedFileUrl = url;
        _portfolioController.text = url;
        _isUploading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully ✓'),
            backgroundColor: Color(0xFF00C2FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: const Color(0xFFFF3B3B),
          ),
        );
      }
    }
  }

  // ── Remove uploaded file ─────────────────────────────────────────
  void _clearFile() {
    setState(() {
      _pickedFile = null;
      _uploadedFileUrl = null;
      _portfolioController.clear();
    });
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      String name = (user?.displayName?.isNotEmpty == true)
          ? user!.displayName!
          : user?.email?.split('@').first ?? 'Anonymous';
      String? imageUrl = user?.photoURL;

      // Fetch the most up-to-date profile name and picture from their existing listings if available
      if (user?.uid != null) {
        final existingListings = await _db
            .collection('swapListings')
            .where('userId', isEqualTo: user!.uid)
            .limit(1)
            .get();
        if (existingListings.docs.isNotEmpty) {
          final data = existingListings.docs.first.data();
          if (data['name'] != null && (data['name'] as String).isNotEmpty) {
            name = data['name'] as String;
          }
          if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty) {
            imageUrl = data['imageUrl'] as String;
          }
        }
      }

      await _db.collection('swapListings').add({
        'name': name,
        'imageUrl': imageUrl,
        'offering': _titleController.text.trim(),
        'wanting': _lookingForController.text.trim(),
        'Category': _mapCategory(_selectedCategory!),
        'experienceLevel': _selectedExperience,
        'portfolio': _portfolioController.text.trim(),
        'portfolioType': _uploadedFileUrl != null ? 'file' : 'link',
        'description': _descriptionController.text.trim(),
        'Rating': 0.0,
        'Reviews': 0,
        'is Live': false,
        'userId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF3B3B),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Title', required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'e.g. Web Engineering',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Category', required: true),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Select a category',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                        validator: (v) =>
                        v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Experience level', required: true),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Your experience level',
                        value: _selectedExperience,
                        items: _experienceLevels,
                        onChanged: (v) =>
                            setState(() => _selectedExperience = v),
                        validator: (v) =>
                        v == null ? 'Please select a level' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel("I'm looking for", required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _lookingForController,
                        hint: 'Exchange skill preferences',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter what you want'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Portfolio', required: true),
                      const SizedBox(height: 8),
                      _buildPortfolioField(),
                      const SizedBox(height: 20),

                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint:
                        'Describe your skill, experience level and what you can offer…',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 36),

                      _buildButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Portfolio field ──────────────────────────────────────────────
  Widget _buildPortfolioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _portfolioController,
          readOnly: _pickedFile != null,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Portfolio link or document is required'
              : null,
          style: TextStyle(
            color: _pickedFile != null ? Colors.white54 : Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Paste a link or tap to upload a doc',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _isUploading
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFF00C2FF),
                  strokeWidth: 2,
                ),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.attach_file_rounded,
                  color: Color(0xFF00C2FF), size: 20),
              tooltip: 'Upload portfolio doc',
              onPressed: _pickedFile == null ? _pickAndUploadFile : null,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Color(0xFF00C2FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
            ),
          ),
        ),

        // ── Uploaded file chip ──────────────────────────────────────
        if (_pickedFile != null) ...[
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF00C2FF).withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C2FF).withAlpha(31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insert_drive_file_rounded,
                      color: Color(0xFF00C2FF), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFile!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_pickedFile!.size > 0)
                        Text(
                          '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (_isUploading)
                  const Text('Uploading…',
                      style: TextStyle(
                          color: Color(0xFF00C2FF), fontSize: 11))
                else if (_uploadedFileUrl != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C2FF).withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Uploaded ✓',
                        style: TextStyle(
                            color: Color(0xFF00C2FF), fontSize: 11)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearFile,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B).withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFFFF3B3B), size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Text('Offer New Skill',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        if (required)
          const Text(' *',
              style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C2FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: const Color(0xFF1E293B),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF00C2FF)),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: const Color(0xFF00C2FF).withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C2FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(e,
            style: const TextStyle(
                color: Colors.white, fontSize: 14)),
      ))
          .toList(),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: const Color(0xFF00C2FF).withAlpha(102)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Add Skill',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}