import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

/// First name (greetings) and public nickname (leaderboard).
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final _name = TextEditingController(text: widget.c.name);
  late final _nick = TextEditingController(text: widget.c.nickname);

  @override
  void initState() {
    super.initState();
    widget.c.addListener(_syncNick);
  }

  // Mirror the auto-filled nickname into its field.
  void _syncNick() {
    if (_nick.text != widget.c.nickname) _nick.text = widget.c.nickname;
  }

  @override
  void dispose() {
    widget.c.removeListener(_syncNick);
    _name.dispose();
    _nick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => FlowPage(
        header: OnboardingHeader(
          step: widget.nav.step,
          total: widget.nav.total,
          onBack: widget.nav.back,
        ),
        footer: ChunkyButton(label: 'Continue', onPressed: c.namesValid ? widget.nav.next : null),
        children: [
          const SpeechBubble(
            image: 'assets/mascot/cheer.png',
            imageWidth: 92,
            bubbleLift: 18,
            text: "Hey, I'm Tofu! What should I call you?",
          ),
          _Field(
            label: 'Your first name',
            controller: _name,
            onChanged: c.setName,
            hint: 'e.g. Sam',
          ),
          _Field(
            label: 'Leaderboard nickname',
            controller: _nick,
            onChanged: c.setNickname,
            hint: '2–20 letters or numbers',
            help: 'Shown publicly instead of your Google name.',
            error: c.nickname.isEmpty || OnboardingController.validNickname(c.nickname)
                ? null
                : 'Use 2–20 letters, numbers, spaces or . \' -',
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.hint,
    this.help,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final String? help;
  final String? error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(label, style: nunito(15)),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          style: nunito(17),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            errorText: error,
            helperText: help,
            helperStyle: nunito(12, weight: FontWeight.w600, color: AppColors.textMuted),
            enabledBorder: border(AppColors.line),
            focusedBorder: border(AppColors.pink),
            errorBorder: border(AppColors.red),
            focusedErrorBorder: border(AppColors.red),
          ),
        ),
      ],
    );
  }
}
