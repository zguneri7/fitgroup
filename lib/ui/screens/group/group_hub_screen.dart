import 'package:fitgroup/services/group_service.dart';
import 'package:fitgroup/services/session_service.dart';
import 'package:fitgroup/ui/screens/group/group_detail_screen.dart';
import 'package:flutter/material.dart';

class GroupHubScreen extends StatefulWidget {
  const GroupHubScreen({super.key});

  @override
  State<GroupHubScreen> createState() => _GroupHubScreenState();
}

class _GroupHubScreenState extends State<GroupHubScreen> {
  final GroupService _groupService = GroupService();
  List<GroupInfo> _groups = [];
  int? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    final groups = await _groupService.fetchMyGroups();

    if (!mounted) {
      return;
    }

    setState(() {
      _groups = groups;
      if (_groups.isEmpty) {
        _selectedGroupId = null;
      } else {
        final hasSelected = _selectedGroupId != null && _groups.any((group) => group.id == _selectedGroupId);
        _selectedGroupId = hasSelected ? _selectedGroupId : _groups.first.id;
      }
      _isLoading = false;
    });
  }

  Future<void> _showCreateGroupDialog() async {
    if (!SessionService.isLoggedIn) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup oluşturmak için önce giriş yapmalısın.')),
      );
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grup Olustur'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Grup adi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgec'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Olustur'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final result = await _groupService.createGroup(name: name);
    final created = result.group;
    if (!mounted) {
      return;
    }

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Grup olusturulamadi.')),
      );
      return;
    }

    SessionService.activeGroupId = created.id;
    SessionService.activeGroupName = created.name;
    SessionService.activeGroupCode = created.code;

    await _loadGroups();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grup olusturuldu. Kod: ${created.code}')),
    );
  }

  Future<void> _showJoinGroupDialog() async {
    if (!SessionService.isLoggedIn) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gruba katılmak için önce giriş yapmalısın.')),
      );
      return;
    }

    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gruba Katil'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Grup kodu'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgec'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Katil'),
            ),
          ],
        );
      },
    );

    if (code == null || code.isEmpty) {
      return;
    }

    final result = await _groupService.joinGroup(code: code);
    final joined = result.group;
    if (!mounted) {
      return;
    }

    if (joined == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Grup bulunamadi.')),
      );
      return;
    }

    SessionService.activeGroupId = joined.id;
    SessionService.activeGroupName = joined.name;
    SessionService.activeGroupCode = joined.code;

    await _loadGroups();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gruba katildin: ${joined.name}')),
    );
  }

  void _openGroupDetail() {
    if (_selectedGroupId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupId: _selectedGroupId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Bilgileri')),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showCreateGroupDialog,
                    child: const Text('Grup Olustur'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showJoinGroupDialog,
                    child: const Text('Gruba Katil'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_groups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henuz gruba dahil degilsin. Grup olustur veya kod ile katil.'),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Aktif Grup',
                  border: OutlineInputBorder(),
                ),
                items: _groups.map((group) {
                  return DropdownMenuItem<int>(
                    value: group.id,
                    child: Text('${group.name} (${group.code})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGroupDetail,
                  icon: const Icon(Icons.groups),
                  label: const Text('Secili Grubun Detayina Git'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
