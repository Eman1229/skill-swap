import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────
// OFFER SKILL SCREEN
// Saves a new swap listing to Firestore → triggers HomeScreen's
// real-time listener → auto-navigates to SwappingAvailable.
// ─────────────────────────────────────────────────────────────────────
class OfferSkillScreen extends StatefulWidget {
  const OfferSkillScreen({Key? key}) : super(key: key);

  @override
  State<OfferSkillScreen> createState() => _OfferSkillScreenState();
}

class _OfferSkillScreenState extends State<OfferSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Controllers ─────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedExperience;
  bool _isLoading = false;

  // ── Dropdown options ─────────────────────────────────────────────
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

  // Map UI category labels → Firestore category values (must match
  // the values you query in SwappingAvailable._swapsStream)
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

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      final name = (user?.displayName?.isNotEmpty == true)
          ? user!.displayName!
          : user?.email?.split('@').first ?? 'Anonymous';

      await _db.collection('swapListings').add({
        'name': name,
        'offering': _titleController.text.trim(),
        'wanting': _lookingForController.text.trim(),
        'Category': _mapCategory(_selectedCategory!),
        'experienceLevel': _selectedExperience,
        'portfolio': _portfolioController.text.trim(),
        'description': _descriptionController.text.trim(),
        'Rating': 0.0,
        'Reviews': 0,
        'is Live': false,
        'userId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      // Pop back — HomeScreen listener will auto-navigate to SwappingAvailable
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF3B3B),
        ),
      );
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
            // ── Header ──────────────────────────────────────────────
            _buildHeader(),

            // ── Form ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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

                      // Category
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

                      // Experience Level
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

                      // Looking For
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

                      // Portfolio
                      _buildLabel('Portfolio', required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _portfolioController,
                        hint: 'Your skill portfolio (link or description)',
                        suffix: const Icon(Icons.attach_file_rounded,
                            color: Color(0xFF00C2FF), size: 18),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Portfolio is required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint:
                        'Describe your skill, experience level and what you can offer…',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 36),

                      // Buttons
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

  // ── Sub-widgets ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Offer New Skill',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        hintStyle:
        const TextStyle(color: Colors.white38, fontSize: 13),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF00C2FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFFFF3B3B)),
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
        hintStyle:
        const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF00C2FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFFFF3B3B)),
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
        // Cancel
        Expanded(
          child: OutlinedButton(
            onPressed:
            _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: const Color(0xFF00C2FF).withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Add Skill
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Add Skill',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
