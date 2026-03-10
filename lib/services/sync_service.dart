import '../models/category_model.dart';
import '../models/message_model.dart';
import '../utils/db_helper.dart';
import '../utils/shared_pref.dart';
import 'base_service.dart';
import '../core/constants/api_urls.dart';

class SyncService extends BaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> checkAndSync() async {
    try {
      final int currentVersion = SharedPref.getInt('db_content_version') ?? 0;
      final int lastMsgId = await _dbHelper.getLastMessageId();
      final int lastCatId = await _dbHelper.getLastCategoryId();

      final response = await safeGet(
        ApiUrls.syncUrl,
        queryParameters: {
          'version': currentVersion,
          'last_id': lastMsgId,
          'last_cat_id': lastCatId,
        },
      );

      if (response == null || response.data == null) return 0;

      final data = response.data;
      
      // 1. حفظ إعدادات المزامنة الديناميكية
      if (data['sync_config'] != null && data['sync_config']['interval_hours'] != null) {
        int newInterval = data['sync_config']['interval_hours'];
        await SharedPref.setInt('sync_interval_hours', newInterval);
      }

      final int latestVersion = data['latest_version'] ?? 0;

      if (latestVersion > currentVersion) {
        int newItemsCount = 0;

        // 2. مزامنة الأقسام الجديدة (إذا وجدت)
        if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
          final List<CategoryModel> newCategories = (data['categories'] as List)
              .map((c) => CategoryModel.fromMap(c))
              .toList();
          
          await _dbHelper.syncCategories(newCategories);
          newItemsCount += newCategories.length;
        }

        // 3. مزامنة الرسائل الجديدة (إذا وجدت)
        if (data['messages'] != null && (data['messages'] as List).isNotEmpty) {
          final List<MessageModel> newMessages = (data['messages'] as List)
              .map((m) => MessageModel.fromMap(m))
              .toList();

          await _dbHelper.syncMessages(newMessages);
          newItemsCount += newMessages.length;
        }

        // تحديث نسخة البيانات محلياً
        await SharedPref.setInt('db_content_version', latestVersion);
        
        return newItemsCount;
      }
    } catch (e) {
      print('Sync Error: $e');
    }
    return 0;
  }
}
