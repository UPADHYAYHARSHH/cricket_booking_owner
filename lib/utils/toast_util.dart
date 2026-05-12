import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:turfpro_owner/common/constants/colors.dart';

enum ToastType { success, error, warning, info }

class ToastUtil {
  static void show(
    BuildContext context, {
    required String message,
    required ToastType type,
  }) {
    FToast fToast = FToast();
    fToast.init(context);

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        backgroundColor = AppColors.accentOrange;
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        backgroundColor = AppColors.primaryDarkGreen;
        icon = Icons.info_rounded;
        break;
    }

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
    );
  }
}
