import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/personalization/controllers/update_profile_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UpdateProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(UpdateProfileController());
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final userController = UserController.instance;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Edit Profile',
        showBackArrow: true,
        subtitleBuilder: (_) => const Text(
          'Personal details',
          style: TextStyle(
            color: Color(0xFFD1FAE5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 40,
        ),
        child: Form(
          key: controller.updateFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section Title ────────────────────────────────
              Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // ── Card 1: Names ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.firstName,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (val) =>
                          AppValidator.validateEmptyText('First Name', val),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                        floatingLabelStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: dark
                              ? AppColors.darkInputHint
                              : AppColors.lightInputHint,
                        ),
                        prefixIcon: Icon(
                          Iconsax.user_copy,
                          size: 18,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                        filled: true,
                        fillColor: dark
                            ? AppColors.darkInputFill
                            : AppColors.lightInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark
                                ? AppColors.darkInputBorder
                                : AppColors.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark
                                ? AppColors.darkInputBorder
                                : AppColors.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: controller.lastName,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (val) =>
                          AppValidator.validateEmptyText('Last Name', val),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                        floatingLabelStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: dark
                              ? AppColors.darkInputHint
                              : AppColors.lightInputHint,
                        ),
                        prefixIcon: Icon(
                          Iconsax.user_copy,
                          size: 18,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                        filled: true,
                        fillColor: dark
                            ? AppColors.darkInputFill
                            : AppColors.lightInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark
                                ? AppColors.darkInputBorder
                                : AppColors.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark
                                ? AppColors.darkInputBorder
                                : AppColors.lightInputBorder,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Section Title ────────────────────────────────
              Text(
                'ACADEMIC STREAM',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // ── Card 2: Stream Selection Chips ───────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your academic field for personalized subjects & exams:',
                      style: TextStyle(
                        fontSize: 13,
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _StreamChip(
                              title: 'Natural',
                              subtitle: 'Natural Science',
                              icon: Icons.science_rounded,
                              isSelected:
                                  controller.selectedStream.value == 'natural',
                              onTap: () =>
                                  controller.selectedStream.value = 'natural',
                              dark: dark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StreamChip(
                              title: 'Social',
                              subtitle: 'Social Science',
                              icon: Icons.menu_book_rounded,
                              isSelected:
                                  controller.selectedStream.value == 'social',
                              onTap: () =>
                                  controller.selectedStream.value = 'social',
                              dark: dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Primary Save Button ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isUpdating.value
                        ? null
                        : () => controller.updateProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isUpdating.value
                        ? const AppCircularButtonLoading(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Delete Account Section ───────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: dark ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: dark ? 0.25 : 0.15),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Permanently delete your account, test history, bookmarks, and scores.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => OutlinedButton.icon(
                          onPressed: userController.isDeleting.value
                              ? null
                              : () => userController.showDeleteDialog(),
                          icon: userController.isDeleting.value
                              ? const SizedBox.shrink()
                              : const Icon(
                                  Icons.delete_forever_rounded,
                                  size: 18,
                                  color: Color(0xFFEF4444),
                                ),
                          label: userController.isDeleting.value
                              ? const AppPulsingDots(color: AppColors.error)
                              : const Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                              color: const Color(0xFFEF4444).withValues(
                                alpha: dark ? 0.4 : 0.3,
                              ),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreamChip extends StatelessWidget {
  const _StreamChip({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: dark ? 0.22 : 0.10)
                : (dark
                    ? AppColors.darkInputFill
                    : AppColors.lightInputFill),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.darkInputBorder : AppColors.lightInputBorder),
              width: isSelected ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (dark ? AppColors.darkSurface : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : (dark ? AppColors.darkInputLabel : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (dark ? const Color(0xFF5EEAD4) : AppColors.primary)
                            : (dark ? AppColors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: dark ? AppColors.darkInputLabel : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

