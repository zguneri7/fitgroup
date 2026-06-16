import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Grup ici mesajlasma ekrani yakinda burada olacak.\n\nSu an grup davet linki ve grup detaylari Group sekmesinde hazir.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
