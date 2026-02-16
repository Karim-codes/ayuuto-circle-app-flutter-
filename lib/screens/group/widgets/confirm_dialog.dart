import 'package:flutter/cupertino.dart';
import '../../../config/theme.dart';

Future<bool?> showConfirmDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Confirm',
            style: TextStyle(color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
}
