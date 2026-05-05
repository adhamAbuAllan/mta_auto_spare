import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_links.dart';
import '../../localization/app_localizations_x.dart';

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.privacyPolicyDescription,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6A63)),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => openPrivacyPolicy(context),
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(context.l10n.openPrivacyPolicy),
        ),
      ],
    );
  }
}

Future<void> openPrivacyPolicy(BuildContext context) async {
  final didLaunch = await launchUrl(
    AppLinks.privacyPolicy,
    mode: LaunchMode.externalApplication,
  );

  if (!didLaunch && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.couldNotOpenPrivacyPolicy)),
    );
  }
}
