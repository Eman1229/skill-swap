import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Supabase instead of Firebase Storage
import 'dart:io';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class OfferSkillScreen extends StatefulWidget {
  OfferSkillScreen({super.key});

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
    final map = {
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
          fileOptions: FileOptions(upsert: true),
        );
      } else if (file.path != null) {
        await _supabase.storage
            .from('portfolios')
            .upload(
          fileName,
          File(file.path!),
          fileOptions: FileOptions(upsert: true),
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
          SnackBar(
            content: Text('File uploaded successfully ✓'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Color(0xFFFF3B3B),
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
            backgroundColor: Color(0xFFFF3B3B),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding:
                EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('title_label'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'e.g. Web Engineering',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      SizedBox(height: 20),

                      _buildLabel('category_label'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Select a category',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                        validator: (v) =>
                        v == null ? 'Please select a category' : null,
                      ),
                      SizedBox(height: 20),

                      _buildLabel('experience_level'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Your experience level',
                        value: _selectedExperience,
                        items: _experienceLevels,
                        onChanged: (v) =>
                            setState(() => _selectedExperience = v),
                        validator: (v) =>
                        v == null ? 'Please select a level' : null,
                      ),
                      SizedBox(height: 20),

                      _buildLabel('looking_for'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _lookingForController,
                        hint: 'Exchange skill preferences',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter what you want'
                            : null,
                      ),
                      SizedBox(height: 20),

                      _buildLabel('portfolio'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildPortfolioField(),
                      SizedBox(height: 20),

                      _buildLabel('description_label'.tr()),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint:
                        'Describe your skill, experience level and what you can offer…',
                        maxLines: 4,
                      ),
                      SizedBox(height: 36),

                      _buildButtons(),
                      SizedBox(height: 20),
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
            color: _pickedFile != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Paste a link or tap to upload a doc',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _isUploading
                ? Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            )
                : IconButton(
              icon: Icon(Icons.attach_file_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              tooltip: 'Upload portfolio doc',
              onPressed: _pickedFile == null ? _pickAndUploadFile : null,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Color(0xFFFF3B3B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
            ),
          ),
        ),

        // ── Uploaded file chip ──────────────────────────────────────
        if (_pickedFile != null) ...[
          SizedBox(height: 10),
          Container(
            padding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.insert_drive_file_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFile!.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_pickedFile!.size > 0)
                        Text(
                          '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (_isUploading)
                  Text('Uploading…',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, fontSize: 11))
                else if (_uploadedFileUrl != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Uploaded ✓',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary, fontSize: 11)),
                  ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearFile,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF3B3B).withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
            ),
          ),
          SizedBox(width: 14),
          Text('offer_new_skill'.tr(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
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
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        if (required)
          Text(' *',
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
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
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
      dropdownColor: Theme.of(context).colorScheme.surface,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).colorScheme.primary),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFFF3B3B)),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(e,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
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
                  color: Theme.of(context).colorScheme.primary.withAlpha(102)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('cancel'.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
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
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2))
                  : Text('add_skill'.tr(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}
