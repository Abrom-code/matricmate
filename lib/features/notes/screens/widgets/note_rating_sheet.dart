import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NoteRatingSheet extends StatefulWidget {
  const NoteRatingSheet({
    super.key,
    required this.note,
    this.onRated,
  });

  final NoteModel note;
  final ValueChanged<int>? onRated;

  static Future<int?> show(
    BuildContext context, {
    required NoteModel note,
    ValueChanged<int>? onRated,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteRatingSheet(
        note: note,
        onRated: onRated,
      ),
    );
  }

  @override
  State<NoteRatingSheet> createState() => _NoteRatingSheetState();
}

class _NoteRatingSheetState extends State<NoteRatingSheet> {
  late int _selectedRating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.note.userRating > 0 ? widget.note.userRating : 5;
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent! 🌟';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating < 1 || _selectedRating > 5) return;
    setState(() => _isSubmitting = true);

    final success = await NotesController.instance.rateNote(
      widget.note.id,
      _selectedRating,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onRated?.call(_selectedRating);
        Navigator.of(context).pop(_selectedRating);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final isAlreadyRated = widget.note.isRated;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: dark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),

          // Star badge icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                size: 34,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            isAlreadyRated ? 'Update Your Rating' : 'Rate this Note',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: dark ? AppColors.textWhite : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Note title
          Text(
            widget.note.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'How helpful was this note? Your feedback helps us improve study materials.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: dark ? AppColors.textSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive 5 stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _selectedRating;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedScale(
                      scale: isFilled ? 1.08 : 0.95,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: isFilled
                            ? const Color(0xFFF59E0B)
                            : (dark ? Colors.white30 : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Rating description label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getRatingLabel(_selectedRating),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isAlreadyRated ? 'Close' : 'Maybe Later',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isAlreadyRated ? 'Update Rating' : 'Submit Rating',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
