import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Uploads incident photos to Supabase Storage.
class StorageService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Uploads the photo and returns its public link.
  Future<String> uploadIncidentPhoto({
    required XFile photo,
    required String userId,
  }) async {
    final bytes = await photo.readAsBytes();
    final isPng = photo.name.toLowerCase().endsWith('.png');
    final extension = isPng ? 'png' : 'jpg';

    // e.g. incidents/abc123/1730632210000.jpg
    final path =
        'incidents/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final bucket = _client.storage.from(SupabaseConfig.photoBucket);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: isPng ? 'image/png' : 'image/jpeg',
        upsert: false,
      ),
    );
    return bucket.getPublicUrl(path);
  }
}
