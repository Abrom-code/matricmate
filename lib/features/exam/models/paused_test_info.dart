import 'package:matricmate/features/exam/models/result_model.dart';

/// A single in-progress (paused) test draft, enriched with display info
/// (title, time, type, subject name) pulled in via a join so the paused
/// list screen doesn't need extra round-trips per item.
class PausedTestInfoModel {
  final ResultModel result;
  final String testTitle;
  final int testTime;
  final String testType;
  final String subjectName;

  PausedTestInfoModel({
    required this.result,
    required this.testTitle,
    required this.testTime,
    required this.testType,
    required this.subjectName,
  });

  factory PausedTestInfoModel.fromMap(Map<String, dynamic> map) {
    return PausedTestInfoModel(
      result: ResultModel.fromMap(map),
      testTitle: map['test_title'] as String? ?? '',
      testTime: map['test_time'] as int? ?? -1,
      testType: map['test_type'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? '',
    );
  }
}
