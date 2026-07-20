import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:skill_swap/utils/user_display_name.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

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
  final TextEditingController _durationController = TextEditingController(
    text: '1 hour',
  );
  final TextEditingController _meetingLinkController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));

  bool _loading = false;

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = _auth.currentUser?.uid;
      final mentorId = widget.swap.mentorId;
      final learnerId = widget.swap.learnerId;
      final sessionTime =
          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}';

      final sessionRef = _db
          .collection('swaps')
          .doc(widget.swap.id)
          .collection('sessions')
          .doc();

      final realMentorName = await UserDisplayName.resolve(
        _db,
        mentorId,
        fallback: UserDisplayName.isUsable(widget.swap.mentorName)
            ? widget.swap.mentorName.trim()
            : '',
        authDisplayName: uid == mentorId
            ? _auth.currentUser?.displayName
            : null,
      );
      final realLearnerName = await UserDisplayName.resolve(
        _db,
        learnerId,
        fallback: UserDisplayName.isUsable(widget.swap.learnerName)
            ? widget.swap.learnerName.trim()
            : '',
        authDisplayName: uid == learnerId
            ? _auth.currentUser?.displayName
            : null,
      );

      await sessionRef.set({
        'sessionId': sessionRef.id,
        'swapId': widget.swap.id,
        'title': _titleController.text.trim(),
        'agenda': _agendaController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'sessionDate': Timestamp.fromDate(_selectedDate),
        'sessionTime': sessionTime,
        'duration': _durationController.text.trim(),
        'meetingLink': _meetingLinkController.text.trim(),
        'mentorId': mentorId,
        'learnerId': learnerId,
        'mentorName': realMentorName, // ✅ saves mentor name
        'learnerName': realLearnerName, // ✅ saves learner name
        'participantIds': [mentorId, learnerId],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sync swap session counts
      await SkillExchangeService().syncSwapSessionCounts(widget.swap.id);

      String conversationId = widget.swap.conversationId;

      if (conversationId.isEmpty) {
        final query = await _db
            .collection('conversations')
            .where('participants', arrayContains: uid)
            .get();

        for (final doc in query.docs) {
          final participants = List<String>.from(
            doc.data()['participants'] ?? [],
          );
          if (participants.contains(mentorId) &&
              participants.contains(learnerId)) {
            conversationId = doc.id;
            await _db.collection('swaps').doc(widget.swap.id).update({
              'conversationId': conversationId,
            });
            break;
          }
        }
      }

      if (conversationId.isNotEmpty) {
        await _db
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add({
              'senderId': uid,
              'type': 'session_invite',
              'sessionId': sessionRef.id,
              'swapId': widget.swap.id,
              'title': _titleController.text.trim(),
              'agenda': _agendaController.text.trim(),
              'date': Timestamp.fromDate(_selectedDate),
              'sessionDate': Timestamp.fromDate(_selectedDate),
              'sessionTime': sessionTime,
              'duration': _durationController.text.trim(),
              'meetingLink': _meetingLinkController.text.trim(),
              'timestamp': FieldValue.serverTimestamp(),
            });

        await _db.collection('conversations').doc(conversationId).update({
          'lastMessage': 'Session Invite: ${_titleController.text.trim()}',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });

        final otherId = uid == widget.swap.mentorId
            ? widget.swap.learnerId
            : widget.swap.mentorId;

        final rawSenderName = uid == widget.swap.mentorId
            ? realMentorName
            : realLearnerName;
        final senderName = UserDisplayName.isUsable(rawSenderName)
            ? rawSenderName
            : 'Someone';

        NotificationService().sendNotification(
          receiverId: otherId,
          type: 'session',
          title: 'New Session Invitation',
          body: '$senderName sent you a class invitation.',
          deepLinkScreen: 'chat',
          referenceId: conversationId,
          actionRoute: '/chat',
          actionId: conversationId,
          data: {
            'conversationId': conversationId,
            'sessionId': sessionRef.id,
            'swapId': widget.swap.id,
            'senderName': senderName,
            'type': 'session',
          },
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('session_invite_sent'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('session_title'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildTextField(
                        _titleController,
                        'session_title_hint'.tr(),
                        Icons.title_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      SizedBox(height: 20),
                      _buildLabel('duration'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildTextField(
                        _durationController,
                        'duration_hint'.tr(),
                        Icons.timer_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      SizedBox(height: 20),
                      _buildLabel('meeting_link'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildTextField(
                        _meetingLinkController,
                        'meeting_link_hint'.tr(),
                        Icons.link_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'required_field'.tr()
                            : null,
                      ),
                      SizedBox(height: 20),
                      _buildLabel('date_and_time'.tr(), required: true),
                      SizedBox(height: 8),
                      _buildDateTimePicker(),
                      SizedBox(height: 20),
                      _buildLabel('session_agenda'.tr()),
                      SizedBox(height: 8),
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
                      SizedBox(height: 36),
                      _loading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : _buildSubmitButton(),
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
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 14),
          Text(
            'create_session'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          Text(' *', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
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
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.65),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
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
          borderSide: BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
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
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.65),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.only(
          top: 14,
          bottom: 14,
          left: 44,
          right: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
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
          borderSide: BorderSide(color: Color(0xFFFF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
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
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 16),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            Spacer(),
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

  Widget _buildSubmitButton() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(102),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ElevatedButton(
              onPressed: _createSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'send_invitation'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
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
