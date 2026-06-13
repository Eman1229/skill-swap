import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/services/notification_service.dart';

class CreateSessionScreen extends StatefulWidget {
  final SwapModel swap;
  CreateSessionScreen({Key? key, required this.swap}) : super(key: key);

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
  final TextEditingController _agendaController = TextEditingController(); // NEW
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));

  bool _loading = false;

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = _auth.currentUser?.uid;
      debugPrint('=== CREATE SESSION CALLED ===');
      debugPrint('uid = $uid');
      debugPrint('swap.id = ${widget.swap.id}');
      debugPrint('swap.conversationId = ${widget.swap.conversationId}');
      debugPrint('swap.mentorId = ${widget.swap.mentorId}');
      debugPrint('swap.learnerId = ${widget.swap.learnerId}');

      final mentorId = widget.swap.mentorId;
      final learnerId = widget.swap.learnerId;
      final sessionTime =
          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}';

      // 1. Create session doc
      final sessionRef = _db
          .collection('swaps')
          .doc(widget.swap.id)
          .collection('sessions')
          .doc();
      await sessionRef.set({
        'sessionId': sessionRef.id,
        'swapId': widget.swap.id,
        'title': _titleController.text.trim(),
        'agenda': _agendaController.text.trim(), // NEW
        'date': Timestamp.fromDate(_selectedDate),
        'sessionDate': Timestamp.fromDate(_selectedDate),
        'sessionTime': sessionTime,
        'duration': _durationController.text.trim(),
        'meetingLink': _meetingLinkController.text.trim(),
        'mentorId': mentorId,
        'learnerId': learnerId,
        'participantIds': [mentorId, learnerId],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Session doc created: ${sessionRef.id}');

      // 2. Find conversationId
      String conversationId = widget.swap.conversationId;
      debugPrint('conversationId from swap model = "$conversationId"');

      if (conversationId.isEmpty) {
        debugPrint('conversationId is empty — searching Firestore...');
        final query = await _db
            .collection('conversations')
            .where('participants', arrayContains: uid)
            .get();

        debugPrint('Total conversations found for uid: ${query.docs.length}');

        for (final doc in query.docs) {
          final participants =
          List<String>.from(doc.data()['participants'] ?? []);
          debugPrint('Checking convo ${doc.id} — participants: $participants');
          if (participants.contains(mentorId) &&
              participants.contains(learnerId)) {
            conversationId = doc.id;
            debugPrint('MATCH FOUND — conversationId: $conversationId');
            await _db.collection('swaps').doc(widget.swap.id).update({
              'conversationId': conversationId,
            });
            debugPrint('Saved conversationId back to swap doc');
            break;
          }
        }

        if (conversationId.isEmpty) {
          debugPrint('ERROR: No matching conversation found!');
          debugPrint('mentorId=$mentorId learnerId=$learnerId uid=$uid');
        }
      }

      debugPrint('Final conversationId = "$conversationId"');

      // 3. Send invite message to chat
      if (conversationId.isNotEmpty) {
        debugPrint('Sending session_invite message to chat...');
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
          'agenda': _agendaController.text.trim(), // NEW
          'date': Timestamp.fromDate(_selectedDate),
          'sessionDate': Timestamp.fromDate(_selectedDate),
          'sessionTime': sessionTime,
          'duration': _durationController.text.trim(),
          'meetingLink': _meetingLinkController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint('session_invite message sent successfully!');

        await _db
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': 'Session Invite: ${_titleController.text.trim()}',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });

        final otherId = uid == widget.swap.mentorId
            ? widget.swap.learnerId
            : widget.swap.mentorId;
        debugPrint('Sending notification to otherId = $otherId');

        NotificationService().sendNotification(
          receiverId: otherId,
          type: 'session',
          title: 'New Session Invitation',
          body:
          'You received a new session invite: "${_titleController.text.trim()}"',
          deepLinkScreen: 'chat',
          referenceId: conversationId,
          actionRoute: '/chat',
          actionId: conversationId,
          data: {
            'conversationId': conversationId,
            'sessionId': sessionRef.id,
            'swapId': widget.swap.id,
            'senderName': widget.swap.mentorName,
            'type': 'session',
          },
        );
        debugPrint('Notification sent!');
      } else {
        debugPrint('ERROR: conversationId is still empty — message NOT sent!');
      }

      if (mounted) {
        final nav = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('session_invite_sent'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR in _createSession: $e');
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
    _agendaController.dispose(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'create_session'.tr(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'session_title'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildTextField(
                _titleController,
                'session_title_hint'.tr(),
                Icons.title_rounded,
              ),
              SizedBox(height: 24),
              Text(
                'duration'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildTextField(
                _durationController,
                'duration_hint'.tr(),
                Icons.timer_outlined,
              ),
              SizedBox(height: 24),
              Text(
                'Meeting Link',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildTextField(
                _meetingLinkController,
                'Zoom, Google Meet, Teams, or other URL',
                Icons.link_rounded,
              ),
              SizedBox(height: 24),
              Text(
                'date_and_time'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildDateTimePicker(),
              SizedBox(height: 24),

              // ── Session Agenda (NEW) ──────────────────────────────
              Text(
                'Session Agenda',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                  ),
                ),
                child: TextFormField(
                  controller: _agendaController,
                  maxLines: 4,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What would you like to focus on...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      fontSize: 14,
                    ),
                    prefixIcon: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 1,
                      child: Padding(
                        padding: EdgeInsets.only(left: 14, top: 14),
                        child: Icon(
                          Icons.notes_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              // ─────────────────────────────────────────────────────

              SizedBox(height: 48),
              _loading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
                  : _PrimaryBtn(
                label: 'send_invitation'.tr(),
                onTap: _createSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.05),
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.outlineVariant,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) =>
        v == null || v.isEmpty ? 'required_field'.tr() : null,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.05),
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
                fontSize: 15,
              ),
            ),
            Spacer(),
            Icon(
              Icons.edit_calendar_rounded,
              color: Theme.of(context).colorScheme.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}