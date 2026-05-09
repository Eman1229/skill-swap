import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Chat/chat_screen.dart';

class ConversationScreen extends StatefulWidget {
  final SwapListing swap;

  const ConversationScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;

  // ── Real-time online status listener ─────────────────────────────
  Stream<bool> get _onlineStream {
    final otherId = widget.swap.userId ?? widget.swap.id;
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

  // ── Create or fetch existing conversation doc ────────────────────
  Future<void> _initConversation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final otherId = widget.swap.userId ?? widget.swap.id;

    final query = await _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in query.docs) {
      final participants =
      List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherId)) {
        setState(() => _conversationId = doc.id);
        return;
      }
    }

    // If no existing conversation found, set to empty string to stop loading spinner
    setState(() => _conversationId = '');
  }

  // ── Send a message ───────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid ?? '';
    final otherId = widget.swap.userId ?? widget.swap.id;

    if (_conversationId == null || _conversationId!.isEmpty) {
      final ref = await _db.collection('conversations').add({
        'participants': [uid, otherId],
        'otherName': widget.swap.name,
        'skill': widget.swap.offering,
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      setState(() => _conversationId = ref.id);
    }

    final msgRef = _db
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages');

    await msgRef.add({
      'senderId': uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    await _db.collection('conversations').doc(_conversationId).update({
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send Skill Swap Proposal card ────────────────────────────────
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

  // ── Navigate back to chat list ────────────────────────────────────
  void _navigateBackToChat() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
          (route) => false,
    );
  }

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
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header with real-time online status ────────────────
            StreamBuilder<bool>(
              stream: _onlineStream,
              builder: (context, snap) {
                final isOnline = snap.data ?? false;
                return _buildHeader(isOnline);
              },
            ),

            // ── Messages ───────────────────────────────────────────
            Expanded(
              child: _conversationId == null
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00C2FF)))
                  : (_conversationId!.isEmpty
                  ? _buildEmptyChat()
                  : StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('conversations')
                    .doc(_conversationId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(includeMetadataChanges: true),
                builder: (context, snap) {
                  if (snap.connectionState ==
                      ConnectionState.waiting && !snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C2FF)));
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _buildEmptyChat();
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _DateChip(label: 'TODAY');
                      final d = docs[i - 1].data()
                      as Map<String, dynamic>;
                      final isMine = d['senderId'] == uid;
                      final type = d['type'] as String? ?? 'text';

                      if (type == 'swap_proposal') {
                        return _SwapProposalCard(
                          offering: d['offering'] ?? '',
                          wanting: d['wanting'] ?? '',
                          senderName: widget.swap.name,
                        );
                      }

                      return _MessageBubble(
                        text: d['text'] as String? ?? '',
                        isMine: isMine,
                        timestamp: d['timestamp'] as Timestamp?,
                      );
                    },
                  );
                },
              )),
            ),

            // ── Input bar ──────────────────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Back button — pops to ChatScreen to show updated list
          GestureDetector(
            onTap: _navigateBackToChat,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar + online dot
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.swap.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(widget.swap.initials,
                      style: const TextStyle(
                          color: Colors.white,
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
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.swap.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.swap.offering,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call + Video icons
          IconButton(
            icon: const Icon(Icons.call_rounded,
                color: Color(0xFF00C2FF), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded,
                color: Color(0xFF00C2FF), size: 22),
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
              color: const Color(0xFF1E293B),
              border: Border.all(
                  color: const Color(0xFF00C2FF).withOpacity(0.2)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF00C2FF), size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Start chatting with ${widget.swap.name}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
              color: const Color(0xFF00C2FF).withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Swap proposal button
          GestureDetector(
            onTap: _sendSwapProposal,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00C2FF).withOpacity(0.2)),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF00C2FF), size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFF00C2FF).withOpacity(0.2)),
              ),
              child: TextField(
                controller: _msgController,
                style:
                const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle:
                  TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_msgController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
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
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF00C2FF).withOpacity(0.15)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white38,
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

  const _MessageBubble({
    required this.text,
    required this.isMine,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null ? _fmt(timestamp!.toDate()) : '';

    return Align(
      alignment:
      isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isMine ? null : const Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              border: isMine
                  ? null
                  : Border.all(
                  color:
                  const Color(0xFF00C2FF).withOpacity(0.1)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr,
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 10)),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded,
                      color: Color(0xFF00C2FF), size: 13),
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

// ── Swap Proposal card (in-chat) ─────────────────────────────────────
class _SwapProposalCard extends StatelessWidget {
  final String offering;
  final String wanting;
  final String senderName;

  const _SwapProposalCard({
    required this.offering,
    required this.wanting,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.swap_horiz_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'SKILL SWAP PROPOSAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            offering,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$senderName\'s expertise',
            style:
            const TextStyle(color: Colors.white38, fontSize: 12),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.08))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('FOR',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.08))),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            wanting,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Swap confirmed! 🎉'),
                    backgroundColor: Color(0xFF00C2FF),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'CONFIRM SWAP DETAILS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}