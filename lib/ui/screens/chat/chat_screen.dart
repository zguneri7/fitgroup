import 'package:fitgroup/services/group_service.dart';
import 'package:fitgroup/services/session_service.dart';
import 'package:flutter/material.dart';

class ChatMessage {
  const ChatMessage({
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    required this.isSystem,
    this.messageId,
    this.userId,
  });

  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isSystem;
  final int? messageId;
  final int? userId;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _messageController = TextEditingController();

  List<GroupInfo> _groups = [];
  final Map<int, List<ChatMessage>> _groupMessages = <int, List<ChatMessage>>{};
  final Map<int, int> _unreadCounts = <int, int>{};
  GroupDetail? _activeGroupDetail;
  int? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    if (!SessionService.isLoggedIn) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final groups = await _groupService.fetchMyGroups();

    if (!mounted) {
      return;
    }

    final previewMessages = <int, List<ChatMessage>>{};
    final unreadCounts = <int, int>{};
    for (final group in groups) {
      final preview = _buildPreviewMessages(group);
      previewMessages[group.id] = preview;
      unreadCounts[group.id] = preview.where((item) => !item.isMe && !item.isSystem).length;
    }

    setState(() {
      _groups = groups;
      _groupMessages
        ..clear()
        ..addAll(previewMessages);
      _unreadCounts
        ..clear()
        ..addAll(unreadCounts);
      _isLoading = false;
    });
  }

  Future<void> _openConversation(GroupInfo group) async {
    setState(() {
      _selectedGroupId = group.id;
      _isLoading = true;
    });

    final detail = await _groupService.fetchGroupDetail(groupId: group.id);

    if (!mounted) {
      return;
    }

    // Load messages from backend
    final backendMessages = await _loadGroupMessages(group.id);

    final messages = backendMessages.isNotEmpty
        ? backendMessages
        : _buildSeedMessages(group, detail);

    setState(() {
      _activeGroupDetail = detail;
      _groupMessages[group.id] = messages;
      _unreadCounts[group.id] = 0;
      _isLoading = false;
    });
  }

  Future<List<ChatMessage>> _loadGroupMessages(int groupId) async {
    try {
      final response = await _groupService.fetchGroupMessages(groupId: groupId);
      return response
          .map(
            (msg) {
              final userId = _toInt(msg['user_id']);
              final messageId = _toInt(msg['id']);

              return ChatMessage(
                senderName: (msg['full_name'] ?? msg['email'] ?? 'Unknown').toString(),
                text: (msg['text'] ?? '').toString(),
                timestamp: DateTime.tryParse((msg['created_at'] ?? '').toString()) ?? DateTime.now(),
                isMe: userId != null && userId == SessionService.userId,
                isSystem: false,
                messageId: messageId,
                userId: userId,
              );
            },
          )
          .toList();
    } catch (e) {
      return <ChatMessage>[];
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  void _closeConversation() {
    setState(() {
      _selectedGroupId = null;
      _activeGroupDetail = null;
      _messageController.clear();
    });
  }

  List<ChatMessage> _buildSeedMessages(GroupInfo group, GroupDetail? detail) {
    final now = DateTime.now();
    final members = detail?.members ?? const <GroupMember>[];

    return [
      ChatMessage(
        senderName: 'FitGroup',
        text: '${group.name} grubuna hos geldin. Burada sadece bu grubun sohbeti gorunur.',
        timestamp: now.subtract(const Duration(minutes: 24)),
        isMe: false,
        isSystem: true,
      ),
      if (members.length > 1)
        ChatMessage(
          senderName: members[1].displayName,
          text: 'Olculeri girdim, bugun grafiklere de bakabiliriz.',
          timestamp: now.subtract(const Duration(minutes: 17)),
          isMe: false,
          isSystem: false,
        ),
      ChatMessage(
        senderName: SessionService.fullName ?? 'Ben',
        text: 'Tamam, ben de birazdan verilerimi girecegim.',
        timestamp: now.subtract(const Duration(minutes: 11)),
        isMe: true,
        isSystem: false,
      ),
    ];
  }

  List<ChatMessage> _buildPreviewMessages(GroupInfo group) {
    final now = DateTime.now();
    return [
      ChatMessage(
        senderName: 'FitGroup',
        text: '${group.name} sohbetine girerek mesajlasmaya basla.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isMe: false,
        isSystem: true,
      ),
      ChatMessage(
        senderName: group.name,
        text: 'Bugun olculeri girmeyi unutma.',
        timestamp: now.subtract(const Duration(minutes: 8)),
        isMe: false,
        isSystem: false,
      ),
    ];
  }

  Future<void> _sendMessage() async {
    final groupId = _selectedGroupId;
    if (groupId == null) {
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();

    try {
      // Send to backend
      await _groupService.sendGroupMessage(groupId: groupId, text: text);

      // Load updated messages from backend
      final messages = await _loadGroupMessages(groupId);

      if (!mounted) {
        return;
      }

      setState(() {
        _groupMessages[groupId] = messages;
        _unreadCounts[groupId] = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gonderilirken hata: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildConversationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Mesajlasmak icin once bir gruba katilmalisin. Group sekmesinden grup olusturabilir veya kod ile katilabilirsin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = _groups[index];
        final messages = _groupMessages[group.id] ?? const <ChatMessage>[];
        final last = messages.isNotEmpty ? messages.last : null;
        final unreadCount = _unreadCounts[group.id] ?? 0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openConversation(group),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE6F3EA),
                    child: Text(
                      group.name.isEmpty ? 'G' : group.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2E7D4F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          last?.text ?? 'Sohbeti acmak icin dokun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        last == null ? group.code : _formatTime(last.timestamp),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D4F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationView() {
    final groupId = _selectedGroupId;
    if (groupId == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final group = _groups.firstWhere((item) => item.id == groupId);
    final messages = _groupMessages[groupId] ?? const <ChatMessage>[];

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF183B28), Color(0xFF2E7D4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_activeGroupDetail?.members.length ?? 0} uye',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _MemberAvatarStack(members: _activeGroupDetail?.members ?? const <GroupMember>[]),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Bu grupta henuz mesaj yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: '${group.name} grubuna mesaj yaz',
                      filled: true,
                      fillColor: const Color(0xFFF4F7F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D4F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inConversation = _selectedGroupId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: AppBar(
        title: Text(inConversation ? 'Grup Sohbeti' : 'Sohbetler'),
        leading: inConversation
            ? IconButton(
                onPressed: _closeConversation,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Sohbet listesine don',
              )
            : null,
      ),
      body: inConversation ? _buildConversationView() : _buildConversationList(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isSystem
        ? const Color(0xFFE8F4EC)
        : message.isMe
            ? const Color(0xFFDDF2E3)
            : Colors.white;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe && !message.isSystem)
              Text(
                message.senderName,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D4F)),
              ),
            if (!message.isMe && !message.isSystem) const SizedBox(height: 4),
            Text(message.text),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.members});

  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final preview = members.take(4).toList();
    return SizedBox(
      width: 34 + (preview.length - 1) * 18,
      height: 34,
      child: Stack(
        children: [
          for (var i = 0; i < preview.length; i++)
            Positioned(
              left: i * 18,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE6F3EA),
                  child: Text(
                    _initial(preview[i].displayName),
                    style: const TextStyle(
                      color: Color(0xFF2E7D4F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'U';
    }

    return trimmed[0].toUpperCase();
  }
}
