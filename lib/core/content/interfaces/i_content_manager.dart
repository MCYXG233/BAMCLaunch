import '../models/content_models.dart';

abstract class IContentManager {
  Future<SearchResult> searchContent(SearchQuery query);

  Future<ContentInstallResult> installContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  });

  Future<ContentInstallResult> updateContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  });

  Future<void> uninstallContent(String contentId, ContentType type);

  Future<List<ContentItem>> getInstalledContent(ContentType type);

  Future<List<ContentItem>> checkForUpdates(ContentType type);

  Future<List<ConflictInfo>> checkConflicts(ContentItem item);

  Future<DependencyInfo> checkDependencies(ContentItem item);

  Future<List<ContentDependency>> resolveDependencies(List<ContentDependency> dependencies);

  Future<void> installDependencies(List<ContentDependency> dependencies);

  Future<ContentItem> getContentDetails(String contentId, ContentSource source);

  Future<List<ContentItem>> getPopularContent(ContentType type, {int limit = 10});

  Future<List<ContentItem>> getFeaturedContent(ContentType type, {int limit = 10});

  Future<void> refreshContentCache();

  Future<bool> isContentInstalled(String contentId, ContentType type);

  Future<String?> getInstalledVersion(String contentId, ContentType type);

  Future<void> validateContentIntegrity(String contentId, ContentType type);
}