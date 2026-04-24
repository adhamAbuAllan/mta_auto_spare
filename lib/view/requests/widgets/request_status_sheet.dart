import 'package:flutter/material.dart';

import '../../../localization/app_localizations_x.dart';
import '../../../models/models.dart';

Future<PartRequestStatus?> showRequestStatusSheet(
  BuildContext context, {
  required List<PartRequestStatus> statuses,
  required PartRequest request,
}) {
  return showModalBottomSheet<PartRequestStatus>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                context.l10n.changeStatus,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(request.displayTitle),
            ),
            for (final status in statuses)
              ListTile(
                leading: Icon(
                  request.status == status.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(status.label),
                subtitle: Text(status.code),
                onTap: () => Navigator.of(context).pop(status),
              ),
          ],
        ),
      );
    },
  );
}
