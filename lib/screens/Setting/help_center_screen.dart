import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class HelpCenterScreen extends StatefulWidget {
  HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';

  final List<String> _categories = [
    'General Inquiry',
    'Technical Issue',
    'Swap Dispute',
    'Account & Security',
    'Feedback & Suggestion',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I swap skills?',
      'a': 'Browse through the listings on the Home Screen. If you see a skill you want to learn, tap on it and select "Propose Swap". Start a conversation with the user to outline what you will teach each other, and tap "Confirm Swap" once both parties agree!'
    },
    {
      'q': 'Is Skill Swap completely free?',
      'a': 'Yes, absolutely! Skill Swap is built on a direct barter peer-to-peer learning model. You share your expertise in exchange for learning something new. No financial transactions are involved.'
    },
    {
      'q': 'How do I change my offered skills?',
      'a': 'Go to Settings, tap on "Profile Information". From there you can edit your current listings, offer new skills, or update your experience details.'
    },
    {
      'q': 'What should I do if a user is offensive or inactive?',
      'a': 'You can open the user\'s profile or chat, click the options menu (three dots), and select "Report User". Our support team monitors reports and takes appropriate action within 24 hours to keep the community safe.'
    },
    {
      'q': 'Can I offer multiple skills at the same time?',
      'a': 'Yes, you can list as many skills as you want. Simply tap the "+" FAB button on the home screen to create additional offer cards.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'help_center_title'.tr(),
          style:  TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          dividerColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          tabs: [
            Tab(text: 'faqs'.tr()),
            Tab(text: 'contact_support'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQsTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQsTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildSearchBoxMock(),
        SizedBox(height: 24),
        Text(
          'frequently_asked'.tr(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 14),
        ..._faqs.map((faq) => _buildFAQTile(faq['q']!, faq['a']!)),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSearchBoxMock() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'search_questions'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
        iconColor: Theme.of(context).colorScheme.primary,
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        title: Text(
          question,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'submit_ticket'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'help_desk_reply'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12),
            ),
            SizedBox(height: 24),
            _buildDropdownField(),
            SizedBox(height: 16),
            _buildTextField(
              controller: _subjectController,
              label: 'subject'.tr(),
              hint: 'e.g. Chat is not loading',
              validator: (v) => v == null || v.trim().isEmpty ? 'Subject is required' : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _messageController,
              label: 'message_description'.tr(),
              hint: 'Describe your issue in detail...',
              maxLines: 5,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please describe your query' : null,
            ),
            SizedBox(height: 32),
            _buildSubmitButton(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'issue_category'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary),
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedCategory = newValue);
                }
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 14),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Color(0xFFFF3B3B)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'submit_support_ticket'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  void _submitTicket() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'ticket_submitted'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'Your query has been logged under Reference #${(100000 + (DateTime.now().millisecond * 8)).toString()}.\n\nOur team will contact you at your registered email address shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to settings
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('return_to_settings'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
