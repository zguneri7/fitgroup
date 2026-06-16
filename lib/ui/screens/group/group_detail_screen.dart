import 'package:fitgroup/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  final int groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  late Future<GroupDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _groupService.fetchGroupDetail(groupId: widget.groupId);
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = _groupService.fetchGroupDetail(groupId: widget.groupId);
    });
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label panoya kopyalandi.')),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Detayi'),
      ),
      body: FutureBuilder<GroupDetail?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data;
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Grup bilgisi yuklenemedi.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.group.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Grup Kodu: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(detail.group.code),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _copyText(detail.group.code, 'Grup kodu'),
                              child: const Text('Kopyala'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Davet Linki', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        SelectableText(detail.inviteLink),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _copyText(detail.inviteLink, 'Davet linki'),
                              icon: const Icon(Icons.link),
                              label: const Text('Linki Kopyala'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _copyText(detail.inviteMessage, 'Davet metni'),
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Davet Metnini Kopyala'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uyeler (${detail.members.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (detail.members.isEmpty)
                          const Text('Henuz uye yok.')
                        else
                          ...detail.members.map((member) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(member.displayName),
                              subtitle: Text('${member.email}\nKatilma: ${_formatDate(member.joinedAt)}'),
                              isThreeLine: true,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
