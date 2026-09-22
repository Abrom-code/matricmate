import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/data/repositories/exam/question_report_repository.dart';
import 'package:matricmate/features/exam/models/question_report_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportQuestionBottomSheet extends StatefulWidget {
  final int? questionId;
  final String? challengeQuestionId;
  final int? testId;
  final int? questionNumber;

  const ReportQuestionBottomSheet({
    super.key,
    this.questionId,
    this.challengeQuestionId,
    this.testId,
    this.questionNumber,
  });

  static void show(
    BuildContext context, {
    int? questionId,
    String? challengeQuestionId,
    int? testId,
    int? questionNumber,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportQuestionBottomSheet(
        questionId: questionId,
        challengeQuestionId: challengeQuestionId,
        testId: testId,
        questionNumber: questionNumber,
      ),
    );
  }

  @override
  State<ReportQuestionBottomSheet> createState() =>
      _ReportQuestionBottomSheetState();
}

class _ReportQuestionBottomSheetState extends State<ReportQuestionBottomSheet> {
  final _commentController = TextEditingController();
  final _repository = QuestionReportRepository();
  String _selectedReason = QuestionReportModel.reasons.first.key;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = UserController.instance.user.value.id.isNotEmpty
        ? UserController.instance.user.value.id
        : (Supabase.instance.client.auth.currentUser?.id ?? '');

    if (userId.isEmpty) {
      ToastHelper.warning('Please log in to report questions.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = QuestionReportModel(
        userId: userId,
        questionId: widget.questionId,
        challengeQuestionId: widget.challengeQuestionId,
        testId: widget.testId,
        reason: _selectedReason,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      await _repository.submitReport(report);

      if (mounted) {
        Navigator.of(context).pop();
        ToastHelper.success('Report sent');
      }
    } catch (_) {
      // Toast or error handling inside repository/AppExceptionHandler
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row (without subtitle)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: dark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Iconsax.flag_copy, size: 18, color: Colors.amber),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.questionNumber != null
                      ? 'Report Question #${widget.questionNumber}'
                      : 'Report Question',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flexible scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHAT IS THE ISSUE?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Reason Options List (clean, without subtitles)
                  ...QuestionReportModel.reasons.map((r) {
                    final isSelected = _selectedReason == r.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: InkWell(
                        onTap: () => setState(() => _selectedReason = r.key),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (dark
                                      ? AppColors.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ))
                                : (dark
                                      ? AppColors.darkInputFill
                                      : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (dark
                                        ? AppColors.darkBorder
                                        : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 18,
                                color: isSelected
                                    ? AppColors.primary
                                    : (dark
                                          ? AppColors.darkGrey
                                          : Colors.black38),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? (dark
                                              ? AppColors.white
                                              : AppColors.primary)
                                        : (dark
                                              ? AppColors.white
                                              : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // Optional Comment
                  Text(
                    'ADDITIONAL DETAILS (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Choice B should be correct because...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: dark
                            ? AppColors.darkInputHint
                            : AppColors.lightInputHint,
                      ),
                      filled: true,
                      fillColor: dark
                          ? AppColors.darkInputFill
                          : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? AppColors.darkInputBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? AppColors.darkInputBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      counterStyle: TextStyle(
                        fontSize: 11,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.send_1_copy, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
