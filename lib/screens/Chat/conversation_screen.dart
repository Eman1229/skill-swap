import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';

class ConversationScreen extends StatefulWidget {
  final SwapListing swap;
  ConversationScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;

  Stream<bool> get _onlineStream {
    final otherId = widget.swap.userId ?? '';
    if (otherId.isEmpty) return Stream.value(false);
    return _db
        .collection('users')
        .doc(otherId)
        .snapshots()
        .map((doc) => (doc.data()?['isOnline'] as bool?) ?? false);
  }

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  // FIXED: Always check participants pair first to prevent duplicate
  // conversations when the same user has multiple skill listings.
  Future<void> _initConversation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final otherId = widget.swap.userId ?? '';

    // Step 1: Always search by participants pair first.
    // This guarantees two users always share one single conversation,
    // regardless of which skill listing was clicked.
    if (otherId.isNotEmpty) {
      final query = await _db
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();

      for (final doc in query.docs) {
        final participants =
        List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherId)) {
          // Found existing conversation → reuse it
          setState(() => _conversationId = doc.id);
          return;
        }
      }
    }

    // Step 2: Only fall back to swap.id if it looks like a real conversation
    // doc. Validate that BOTH uids are in that document's participants.
    if (widget.swap.id.isNotEmpty && otherId.isNotEmpty) {
      final directDoc = await _db
          .collection('conversations')
          .doc(widget.swap.id)
          .get();
      if (directDoc.exists) {
        final participants =
        List<String>.from(directDoc.data()?['participants'] ?? []);
        if (participants.contains(uid) && participants.contains(otherId)) {
          setState(() => _conversationId = directDoc.id);
          return;
        }
      }
    }

    // Step 3: No existing conversation → will be created on first message
    setState(() => _conversationId = '');
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid ?? '';
    final otherId = widget.swap.userId ?? widget.swap.id;

    if (_conversationId == null || _conversationId!.isEmpty) {
      final senderName =
      _auth.currentUser?.displayName?.trim().isNotEmpty == true
          ? _auth.currentUser!.displayName!
          : _auth.currentUser?.email?.split('@').first ?? 'User';

      final ref = await _db.collection('conversations').add({
        'participants': [uid, otherId],
        'otherUserId': otherId,
        'senderName': senderName,
        'otherName': widget.swap.name,
        'skill': widget.swap.offering,
        'wanting': widget.swap.wanting,
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });
      setState(() => _conversationId = ref.id);
    }

    await _db
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .add({
      'senderId': uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    await _db
        .collection('conversations')
        .doc(_conversationId)
        .update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmSwap(
      String offering, String wanting, String senderId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _conversationId == null) return;

    try {
      await _db.collection('swaps').doc().set({
        'mentorId': senderId,
        'learnerId': uid,
        'mentorName': widget.swap.name,
        'learnerName': _auth.currentUser?.displayName ?? 'Learner',
        'skillName': offering,
        'status': 'ongoing',
        'progress': 0.0,
        'conversationId': _conversationId,
        'completedSessions': 0,
        'totalSessions': 10,
        'participants': [uid, senderId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (wanting.isNotEmpty) {
        await _db.collection('swaps').add({
          'mentorId': uid,
          'learnerId': senderId,
          'mentorName': _auth.currentUser?.displayName ?? 'Mentor',
          'learnerName': widget.swap.name,
          'skillName': wanting,
          'status': 'ongoing',
          'progress': 0.0,
          'conversationId': _conversationId,
          'completedSessions': 0,
          'totalSessions': 10,
          'participants': [uid, senderId],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _db
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'senderId': uid,
        'text': 'I have confirmed the Skill Swap! Let\'s start learning. 🚀',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Swap Relationship Created!'),
              backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _acceptSession(String sessionId, String swapId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _conversationId == null) return;

    try {
      await _db
          .collection('swaps')
          .doc(swapId)
          .collection('sessions')
          .doc(sessionId)
          .update({'status': 'accepted'});

      await _db
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'senderId': uid,
        'text': 'I\'ve accepted the session invitation! See you then. 👋',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Session accepted!'),
              backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _sendSwapProposal() async {
    if (_conversationId == null || _conversationId!.isEmpty) return;
    final uid = _auth.currentUser?.uid ?? '';

    await _db
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .add({
      'senderId': uid,
      'type': 'swap_proposal',
      'offering': widget.swap.offering,
      'wanting': widget.swap.wanting,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('conversations')
        .doc(_conversationId)
        .update({
      'lastMessage': 'Skill Swap Proposal',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _navigateBack() => Navigator.pop(context);

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<bool>(
              stream: _onlineStream,
              builder: (context, snap) {
                final isOnline = snap.data ?? false;
                return _buildHeader(isOnline);
              },
            ),
            Expanded(
              child: _conversationId == null
                  ? Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary))
                  : _conversationId!.isEmpty
                  ? _buildEmptyChat()
                  : StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('conversations')
                    .doc(_conversationId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(
                    includeMetadataChanges: true),
                builder: (context, snap) {
                  if (snap.connectionState ==
                      ConnectionState.waiting &&
                      !snap.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary));
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _buildEmptyChat();
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback(
                          (_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _DateChip(
                            label: 'TODAY');
                      }
                      final d = docs[i - 1].data()
                      as Map<String, dynamic>;
                      final isMine =
                          d['senderId'] == uid;
                      final type =
                          d['type'] as String? ?? 'text';

                      if (type == 'swap_proposal') {
                        return _SwapProposalCard(
                          offering:
                          d['offering'] ?? '',
                          wanting: d['wanting'] ?? '',
                          senderName: widget.swap.name,
                          senderId:
                          d['senderId'] ?? '',
                          onConfirm: (o, w, s) =>
                              _confirmSwap(o, w, s),
                        );
                      }

                      if (type == 'session_invite') {
                        return _SessionInviteCard(
                          sessionId:
                          d['sessionId'] ?? '',
                          swapId: d['swapId'] ?? '',
                          title: d['title'] ?? '',
                          date:
                          d['date'] as Timestamp?,
                          duration:
                          d['duration'] ?? '',
                          senderId:
                          d['senderId'] ?? '',
                          onAccept: (sid, swid) =>
                              _acceptSession(
                                  sid, swid),
                        );
                      }

                      return _MessageBubble(
                        text: d['text'] as String? ??
                            '',
                        isMine: isMine,
                        timestamp: d['timestamp']
                        as Timestamp?,
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isOnline) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
            ),
          ),
          SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.swap.imageUrl == null
                      ? widget.swap.avatarColor
                      : null,
                  shape: BoxShape.circle,
                ),
                child: widget.swap.imageUrl != null
                    ? ClipOval(
                  child: Image.network(
                    widget.swap.imageUrl!,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(widget.swap.initials,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                )
                    : Center(
                  child: Text(widget.swap.initials,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.swap.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Color(0xFF22C55E)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? Color(0xFF22C55E)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.swap.offering,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call_rounded,
                color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded,
                color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: Theme.of(context).colorScheme.primary, size: 30),
          ),
          SizedBox(height: 14),
          Text(
            'Start chatting with ${widget.swap.name}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _sendSwapProposal,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Icon(Icons.add_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _msgController,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_msgController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date chip ────────────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        padding:
        EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
        ),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final Timestamp? timestamp;

  _MessageBubble({
    required this.text,
    required this.isMine,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
    timestamp != null ? _fmt(timestamp!.toDate()) : '';

    return Align(
      alignment:
      isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth:
                MediaQuery.of(context).size.width * 0.72),
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.symmetric(
                horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isMine
                  ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Color(0xFF6B8AFF)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isMine ? null : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              border: isMine
                  ? null
                  : Border.all(
                  color: Theme.of(context).colorScheme.primary
                      .withOpacity(0.1)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMine ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                bottom: 6, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outlineVariant, fontSize: 10)),
                if (isMine) ...[
                  SizedBox(width: 4),
                  Icon(Icons.done_all_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ── Swap Proposal card ───────────────────────────────────────────────
class _SwapProposalCard extends StatelessWidget {
  final String offering;
  final String wanting;
  final String senderName;
  final String senderId;
  final Function(String, String, String) onConfirm;

  _SwapProposalCard({
    required this.offering,
    required this.wanting,
    required this.senderName,
    required this.senderId,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMine =
        FirebaseAuth.instance.currentUser?.uid == senderId;

    return Container(
      margin: EdgeInsets.symmetric(
          vertical: 10, horizontal: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 14),
                SizedBox(width: 6),
                Text('SKILL SWAP PROPOSAL',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          SizedBox(height: 14),
          Text(offering,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text('$senderName\'s expertise',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('FOR',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              Expanded(
                  child: Divider(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08))),
            ],
          ),
          SizedBox(height: 10),
          Text(wanting,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 16),
          if (!isMine)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () =>
                    onConfirm(offering, wanting, senderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(
                      vertical: 12),
                ),
                child: Text('CONFIRM SWAP DETAILS',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5)),
              ),
            )
          else
            Text('Waiting for response...',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ── Session Invite card ──────────────────────────────────────────────
class _SessionInviteCard extends StatelessWidget {
  final String sessionId;
  final String swapId;
  final String title;
  final Timestamp? date;
  final String duration;
  final String senderId;
  final Function(String, String) onAccept;

  _SessionInviteCard({
    required this.sessionId,
    required this.swapId,
    required this.title,
    this.date,
    required this.duration,
    required this.senderId,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMine =
        FirebaseAuth.instance.currentUser?.uid == senderId;
    final dateStr = date != null
        ? '${date!.toDate().day}/${date!.toDate().month}/${date!.toDate().year} at ${TimeOfDay.fromDateTime(date!.toDate()).format(context)}'
        : 'TBD';

    return Container(
      margin: EdgeInsets.symmetric(
          vertical: 10, horizontal: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.secondary, Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 14),
                SizedBox(width: 6),
                Text('SESSION INVITATION',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  color: Theme.of(context).colorScheme.secondary, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(dateStr,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.secondary, size: 16),
              SizedBox(width: 8),
              Text(duration,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
          SizedBox(height: 20),
          if (!isMine)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.secondary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => onAccept(sessionId, swapId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(
                      vertical: 12),
                ),
                child: Text('ACCEPT INVITATION',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            )
          else
            Text('Invitation sent',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}