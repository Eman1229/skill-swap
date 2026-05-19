import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class CreateSessionScreen extends StatefulWidget {
  final SwapModel swap;
  const CreateSessionScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '1 hour');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  bool _loading = false;

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = _auth.currentUser?.uid;
      
      // 1. Create session doc
      final sessionRef = _db.collection('swaps').doc(widget.swap.id).collection('sessions').doc();
      await sessionRef.set({
        'swapId': widget.swap.id,
        'title': _titleController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'duration': _durationController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Send invite to chat
      if (widget.swap.conversationId.isNotEmpty) {
        await _db.collection('conversations').doc(widget.swap.conversationId).collection('messages').add({
          'senderId': uid,
          'type': 'session_invite',
          'sessionId': sessionRef.id,
          'swapId': widget.swap.id,
          'title': _titleController.text.trim(),
          'date': Timestamp.fromDate(_selectedDate),
          'duration': _durationController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _db.collection('conversations').doc(widget.swap.conversationId).update({
          'lastMessage': 'Session Invite: ${_titleController.text.trim()}',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        final nav = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        nav.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('session_invite_sent'.tr()), backgroundColor: const Color(0xFF00C2FF)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('create_session'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('session_title'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(_titleController, 'session_title_hint'.tr(), Icons.title_rounded),
              const SizedBox(height: 24),
              Text('duration'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(_durationController, 'duration_hint'.tr(), Icons.timer_outlined),
              const SizedBox(height: 24),
              Text('date_and_time'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              _buildDateTimePicker(),
              const SizedBox(height: 48),
              _loading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF)))
                : _PrimaryBtn(label: 'send_invitation'.tr(), onTap: _createSession),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF00C2FF), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) => v == null || v.isEmpty ? 'required_field'.tr() : null,
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF00C2FF), size: 20),
            const SizedBox(width: 16),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
