import 'package:matricmate/features/exam/models/result_model.dart';

/// Metadata for a paused test draft enriched with test and subject info.
class PausedTestInfoModel {
  final ResultModel result;
  final String testTitle;
  final int testTime;
  final String testType;
  final String subjectName;
  final bool? subjectIsNatural;
  final bool? subjectIsCommon;

  PausedTestInfoModel({
    required this.result,
    required this.testTitle,
    required this.testTime,
    required this.testType,
    required this.subjectName,
    this.subjectIsNatural,
    this.subjectIsCommon,
  });

  factory PausedTestInfoModel.fromMap(Map<String, dynamic> map) {
    return PausedTestInfoModel(
      result: ResultModel.fromMap(map),
      testTitle: map['test_title'] as String? ?? '',
      testTime: map['test_time'] as int? ?? -1,
      testType: map['test_type'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? '',
      subjectIsNatural: map['subject_is_natural'] != null
          ? (map['subject_is_natural'] == 1)
          : null,
      subjectIsCommon: map['subject_is_common'] != null
          ? (map['subject_is_common'] == 1)
          : null,
    );
  }
}
