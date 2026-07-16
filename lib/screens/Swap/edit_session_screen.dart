import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class EditSessionScreen extends StatefulWidget {
  final String swapId;
  final SessionModel session;
  const EditSessionScreen({Key? key, required this.swapId, required this.session}) : super(key: key);

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _agendaController;
  late DateTime _selectedDate;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session.title);
    _durationController = TextEditingController(text: widget.session.duration);
    _meetingLinkController = TextEditingController(text: widget.session.meetingLink);
    _selectedDate = widget.session.date;
    // We need to fetch the agenda from the doc as it might not be in the short model
    _agendaController = TextEditingController();
    _fetchAgenda();
  }

  Future<void> _fetchAgenda() async {
    try {
      final doc = await _db
          .collection('swaps')
          .doc(widget.swapId)
          .collection('sessions')
          .doc(widget.session.id)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['agenda'] != null) {
          setState(() {
            _agendaController.text = data['agenda'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _updateSession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = _auth.currentUser?.uid;
      final sessionTime =
          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}';

      final sessionRef = _db
          .collection('swaps')
          .doc(widget.swapId)
          .collection('sessions')
          .doc(widget.session.id);

      await sessionRef.update({
        'title': _titleController.text.trim(),
        'agenda': _agendaController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'sessionDate': Timestamp.fromDate(_selectedDate),
        'sessionTime': sessionTime,
        'duration': _durationController.text.trim(),
        'meetingLink': _meetingLinkController.text.trim(),
      });

      // Notify other participant about reschedule
      final otherId = uid == widget.session.mentorId
          ? widget.session.learnerId
          : widget.session.mentorId;

      String senderName = 'Someone';
      final senderDoc = await _db.collection('users').doc(uid).get();
      if (senderDoc.exists) {
        senderName = senderDoc.data()?['name'] ?? 'Someone';
      }

      await NotificationService().sendNotification(
        receiverId: otherId,
        type: 'session',
        title:'session_rescheduled_title'.tr(),
        body: '$senderName rescheduled the session "${_titleController.text.trim()}".',
        actionRoute: '/chat',
        actionId: widget.session.swapId,
        data: {
          'swapId': widget.swapId,
          'sessionId': widget.session.id,
          'type': 'session_rescheduled',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('session_updated_rescheduled'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'error'.tr()}: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('delete_session_confirm_title'.tr()),
        content: Text('delete_session_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _loading = true);

    try {
      await _db
          .collection('swaps')
          .doc(widget.swapId)
          .collection('sessions')
          .doc(widget.session.id)
          .delete();

      // Sync swap session counts
      await SkillExchangeService().syncSwapSessionCounts(widget.swapId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('session_deleted_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'error'.tr()} deleting session: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _meetingLinkController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('session_title'.tr(), required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _titleController,
                        'session_title_hint'.tr(),
                        Icons.title_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('duration'.tr(), required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _durationController,
                        'duration_hint'.tr(),
                        Icons.timer_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('meeting_link'.tr(), required: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _meetingLinkController,
                        'meeting_link_hint'.tr(),
                        Icons.link_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('date_and_time'.tr(), required: true),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(),
                      const SizedBox(height: 20),
                      _buildLabel('session_agenda'.tr()),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          _buildAgendaField(),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Icon(
                              Icons.notes_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      _loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _buildSubmitButtons(),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Edit Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            onPressed: _deleteSession,
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          Text('*'.tr(), style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAgendaField() {
    return TextFormField(
      controller: _agendaController,
      maxLines: 5,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'session_agenda_hint'.tr(),
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.only(
          top: 14,
          bottom: 14,
          left: 44,
          right: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('cancel'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF6B8AFF),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: _updateSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Save Changes',
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
