import 'package:flutter/material.dart';

/// A simple page of headings and text, used for Privacy and Help.
class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<(String, String)> sections; // (heading, text)

  factory InfoPageScreen.privacy() => const InfoPageScreen(
    title: 'Privacy',
    sections: [
      (
        'Who can see reports',
        'Everyone with an ALU account can see reports, so problems are visible and people can tap Me too instead of reporting the same thing twice.',
      ),
      (
        'Anonymous reports',
        'When you report anonymously, other students see "Anonymous student" instead of your name. Your name is not even stored on the report itself.',
      ),
      (
        'What staff can see',
        'Campus staff can see who sent every report, including anonymous ones. This lets them follow up with you and stops people misusing anonymity.',
      ),
      (
        'Photos',
        'Photos are shrunk before upload and stored securely. Please avoid photographing people\'s faces or private documents.',
      ),
      (
        'Your account',
        'Only ALU emails can register, and every email must be verified. You are asked to log in every time the app opens.',
      ),
    ],
  );

  factory InfoPageScreen.help() => const InfoPageScreen(
    title: 'Help & how it works',
    sections: [
      (
        'Reporting an issue',
        'Tap the blue + button, choose a category, describe the problem, pick the location and add a photo if you can. If the category isn\'t listed, choose Other and type it.',
      ),
      (
        'Urgency',
        'Low and Medium are for everyday problems. High is for problems affecting many people. Use Emergency only when someone could get hurt right now.',
      ),
      (
        'Me too',
        'Already reported? Open the report and tap Me too. Staff see how many students are affected, and you get the updates too.',
      ),
      (
        'Statuses',
        'Submitted: received. In review: staff are checking it. In progress: someone is fixing it. Resolved: fixed. Rejected: not something campus staff can act on, with a note explaining why.',
      ),
      (
        'Editing and deleting',
        'You can edit or delete your report while it is still Submitted. Once staff start reviewing it, it stays as it is.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final (heading, text) = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: TextStyle(height: 1.55, color: scheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}
