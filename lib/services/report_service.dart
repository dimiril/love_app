import '../core/constants/api_urls.dart';
import 'base_service.dart';

class ReportService extends BaseService {
  Future<bool> sendReport({
    required int userId,
    required int reportableId,
    required String reportableType, // نمرر هنا 'video' أو 'post' أو 'user'
    required String reason,
  }) async {
    final response = await safePost(
      ApiUrls.submitReport,
      data: {
        'user_id': userId,
        'reportable_id': reportableId,
        'reportable_type': reportableType,
        'reason': reason,
      },
    );
    return response != null && (response.statusCode == 201 || response.statusCode == 200);
  }
}