import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';

/// Small circular Telegram icon button that opens the Telegram support bot.
class TelegramSupportIconButton extends StatelessWidget {
  const TelegramSupportIconButton({
    super.key,
    this.size = 38,
    this.iconSize = 18,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    const telegramBlue = Color(0xFF0284C7);
    const telegramSky = Color(0xFF38BDF8);

    return Tooltip(
      message: 'Support Bot',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ProfileActionsHelper.openTelegramSupport,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [telegramSky, telegramBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: telegramBlue.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.send_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
