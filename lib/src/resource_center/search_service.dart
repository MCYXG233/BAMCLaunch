import 'dart:async';
import 'dart:math';
import 'models.dart';

/// 搜索服务
class SearchService {
  static SearchService? _instance;

  factory SearchService() {
    return _instance ??= SearchService._internal();
  }

  SearchService._internal();

  static SearchService get instance => _instance ??= SearchService._internal();

  static void reset() {
    _instance = null;
  }

  // 模拟数据
  final List<Map<String, dynamic>> _mockData = _generateMockData();

  /// 搜索资源
  Future<SearchResult> search(SearchParams params) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    var results = _mockData.where((item) {
      // 搜索词过滤
      if (params.query.isNotEmpty) {
        final name = item['name'] as String;
        if (!name.toLowerCase().contains(params.query.toLowerCase())) {
          return false;
        }
      }

      // 类型过滤
      if (params.type != null) {
        final type = item['type'] as ResourceType;
        if (type != params.type) {
          return false;
        }
      }

      return true;
    }).toList();

    // 排序
    switch (params.sortBy) {
      case 'downloads':
        results.sort((a, b) => (b['downloads'] as int).compareTo(a['downloads'] as int));
        break;
      case 'newest':
        results.sort((a, b) => (b['publishedDate'] as DateTime).compareTo(a['publishedDate'] as DateTime));
        break;
      case 'updated':
        results.sort((a, b) => (b['updatedDate'] as DateTime).compareTo(a['updatedDate'] as DateTime));
        break;
      case 'name':
        results.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
    }

    // 分页
    final startIndex = (params.page - 1) * params.pageSize;
    final pageResults = results.skip(startIndex).take(params.pageSize).toList();

    final resources = pageResults.map((item) => _createResource(item)).toList();

    return SearchResult(
      resources: resources,
      totalResults: results.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  Resource _createResource(Map<String, dynamic> item) {
    return Resource(
      id: item['id'] as String,
      type: item['type'] as ResourceType,
      source: 'modrinth',
      name: item['name'] as String,
      description: item['description'] as String,
      authors: [
        Author(
          id: 'author-1',
          name: item['author'] as String,
        ),
      ],
      categories: [],
      downloads: item['downloads'] as int,
      likes: (item['downloads'] as int) ~/ 100,
      pageUrl: 'https://modrinth.com/mod/${item['id']}',
      publishedDate: item['publishedDate'] as DateTime,
      updatedDate: item['updatedDate'] as DateTime,
      supportedGameVersions: ['1.20.4', '1.20.2', '1.19.4'],
      supportedLoaders: ['fabric', 'forge'],
      iconUrl: item['iconUrl'] as String?,
    );
  }

  static List<Map<String, dynamic>> _generateMockData() {
    final random = Random(42);
    final mods = [
      {'name': 'Sodium', 'description': '高性能渲染引擎，大幅提升帧率', 'type': ResourceType.mod, 'author': 'CaffeineMC', 'downloads': 15000000},
      {'name': 'Iris', 'description': 'Fabric光影兼容核心', 'type': ResourceType.mod, 'author': 'CoderPuppy', 'downloads': 8500000},
      {'name': 'Fabric API', 'description': 'Fabric模组加载器核心API', 'type': ResourceType.mod, 'author': 'Fabric Team', 'downloads': 22000000},
      {'name': 'OptiFine', 'description': 'Minecraft画质与性能优化模组', 'type': ResourceType.mod, 'author': 'sp614x', 'downloads': 35000000},
      {'name': 'JEI', 'description': '物品合成表与浏览', 'type': ResourceType.mod, 'author': 'mezz', 'downloads': 18000000},
      {'name': 'REI', 'description': 'Roughly Enough Items合成表', 'type': ResourceType.mod, 'author': 'shedaniel', 'downloads': 12000000},
      {'name': 'EMI', 'description': '新版合成表与导航', 'type': ResourceType.mod, 'author': 'emilyy', 'downloads': 3500000},
      {'name': 'JourneyMap', 'description': '实时迷你地图', 'type': ResourceType.mod, 'author': 'techbrew', 'downloads': 9500000},
      {'name': 'Xaeros World Map', 'description': '全屏高清地图', 'type': ResourceType.mod, 'author': 'xaero96', 'downloads': 6800000},
      {'name': 'WTHIT', 'description': '游戏内信息HUD', 'type': ResourceType.mod, 'author': 'ldtteam', 'downloads': 4200000},
      {'name': '月光资源包', 'description': '精美的像素风格资源包', 'type': ResourceType.resourcePack, 'author': 'Moonlight Team', 'downloads': 5200000},
      {'name': 'Faithful材质', 'description': '16x高清材质', 'type': ResourceType.resourcePack, 'author': 'Faithful Team', 'downloads': 8900000},
      {'name': 'Sildur光影', 'description': '经典光影包', 'type': ResourceType.resourcePack, 'author': 'Sildur', 'downloads': 12000000},
      {'name': ' Complementary Reimagined', 'description': '现代风格光影', 'type': ResourceType.resourcePack, 'author': ' Complementary Team', 'downloads': 7800000},
      {'name': 'All the Mods 9', 'description': '大型科技魔法整合包', 'type': ResourceType.modpack, 'author': 'ATM Team', 'downloads': 450000},
      {'name': 'Enigmatica 2 Expertskyblock', 'description': '经典科技整合包', 'type': ResourceType.modpack, 'author': 'E2E Team', 'downloads': 680000},
      {'name': 'RLCraft', 'description': '硬核生存整合包', 'type': ResourceType.modpack, 'author': 'Swiamp', 'downloads': 1200000},
      {'name': 'Better MC', 'description': '优化整合包', 'type': ResourceType.modpack, 'author': 'BMC Team', 'downloads': 890000},
      {'name': '小麦娘整合包', 'description': '日系风格整合包', 'type': ResourceType.modpack, 'author': 'Kengami', 'downloads': 320000},
      {'name': "Kitchen's Faithful", 'description': '家具高清材质', 'type': ResourceType.resourcePack, 'author': 'Kitchen', 'downloads': 2100000},
      {'name': 'Continuity', 'description': '连接材质支持', 'type': ResourceType.mod, 'author': 'Pepper', 'downloads': 2800000},
      {'name': 'Indium', 'description': 'Sodium渲染修复', 'type': ResourceType.mod, 'author': 'FlashyReese', 'downloads': 6500000},
      {'name': 'Lithium', 'description': '游戏性能优化', 'type': ResourceType.mod, 'author': 'FlashyReese', 'downloads': 9800000},
      {'name': 'FerriteCore', 'description': '内存优化', 'type': ResourceType.mod, 'author': 'MrMelon54', 'downloads': 4200000},
      {'name': 'AI Importer', 'description': '智能导入工具', 'type': ResourceType.mod, 'author': 'Giselbaer', 'downloads': 1800000},
      {'name': 'BetterF3', 'description': '改进调试信息', 'type': ResourceType.mod, 'author': 'cominixo', 'downloads': 3500000},
      {'name': 'No Chat Reports', 'description': '聊天安全增强', 'type': ResourceType.mod, 'author': 'Aizistral', 'downloads': 5100000},
      {'name': 'C2ME', 'description': '区块加载优化', 'type': ResourceType.mod, 'author': 'rickyzhou', 'downloads': 2900000},
      {'name': 'ModernFix', 'description': '现代化修复优化', 'type': ResourceType.mod, 'author': 'embeddedt', 'downloads': 4100000},
      {'name': 'EntityCulling', 'description': '实体渲染优化', 'type': ResourceType.mod, 'author': 'tr9zw', 'downloads': 5600000},
    ];

    final now = DateTime.now();
    return mods.asMap().entries.map((entry) {
      final index = entry.key;
      final mod = entry.value;
      final daysAgo = random.nextInt(365) + 30;
      final publishedDate = now.subtract(Duration(days: daysAgo + random.nextInt(180)));
      final updatedDate = publishedDate.add(Duration(days: random.nextInt(daysAgo ~/ 2)));

      return {
        'id': 'mod-${index + 1}',
        'name': mod['name'] as String,
        'description': mod['description'] as String,
        'type': mod['type'] as ResourceType,
        'author': mod['author'] as String,
        'downloads': mod['downloads'] as int,
        'publishedDate': publishedDate,
        'updatedDate': updatedDate,
        'iconUrl': _getIconUrlForName(mod['name'] as String),
      };
    }).toList();
  }

  static String? _getIconUrlForName(String name) {
    const slugMap = <String, String>{
      'Sodium': 'AANobbMI',
      'Iris': 'ssVbK79L',
      'Fabric API': 'P7dR8mSH',
      'OptiFine': 'OptiFine',
      'JEI': 'u6dRKWWv',
      'REI': 'nfn13YXA',
      'JourneyMap': 'lHFcaTgW',
      'Lithium': 'gvQ3B7qL',
    };
    final slug = slugMap[name];
    if (slug == null) return null;
    return 'https://cdn.modrinth.com/data/$slug/images/icon.png';
  }
}
