import 'package:flutter/foundation.dart';
import '../../account/account_manager.dart';
import '../../instance/instance_manager.dart';
import '../theme/background_manager.dart';

class BAMainPageViewModel extends ChangeNotifier {
  final AccountManager _accountManager;
  final InstanceManager _instanceManager;
  final BackgroundManager _backgroundManager;

  // UI状态
  int _currentPage = 0;
  String? _selectedAccountName;
  bool _isLoading = true;
  int _instanceCount = 0;
  int _activeDownloads = 0;
  
  // 资源数据（从配置获取或使用默认值）
  int _stamina = 100;
  int _maxStamina = 132;
  int _credits = 0;
  int _pyroxene = 0;
  double _expProgress = 0.72;
  
  // 任务和通知数据
  int _missionProgress = 0;
  int _missionTotal = 8;
  int _mailCount = 6;

  BAMainPageViewModel({
    required AccountManager accountManager,
    required InstanceManager instanceManager,
    required BackgroundManager backgroundManager,
  })  : _accountManager = accountManager,
        _instanceManager = instanceManager,
        _backgroundManager = backgroundManager {
    _loadData();
  }

  // Getters
  int get currentPage => _currentPage;
  String? get selectedAccountName => _selectedAccountName;
  bool get isLoading => _isLoading;
  int get instanceCount => _instanceCount;
  int get activeDownloads => _activeDownloads;
  int get stamina => _stamina;
  int get maxStamina => _maxStamina;
  int get credits => _credits;
  int get pyroxene => _pyroxene;
  double get expProgress => _expProgress;
  int get missionProgress => _missionProgress;
  int get missionTotal => _missionTotal;
  int get mailCount => _mailCount;

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadAccountData(),
        _loadInstanceData(),
        _loadResourceData(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAccountData() async {
    try {
      final selectedAccount = await _accountManager.getSelectedAccount();
      _selectedAccountName = selectedAccount?.username ?? 'Sensei';
    } catch (e) {
      _selectedAccountName = 'Sensei';
    }
    notifyListeners();
  }

  Future<void> _loadInstanceData() async {
    try {
      await _instanceManager.initialize();
      _instanceCount = _instanceManager.instances.length;
    } catch (e) {
      _instanceCount = 0;
    }
    notifyListeners();
  }

  Future<void> _loadResourceData() async {
    try {
      _stamina = _accountManager.getResource('stamina') ?? 100;
      _maxStamina = _accountManager.getResource('maxStamina') ?? 132;
      _credits = _accountManager.getResource('credits') ?? 35426147;
      _pyroxene = _accountManager.getResource('pyroxene') ?? 666;
      _expProgress = (_accountManager.getResource('expProgress') ?? 72) / 100;
      _missionProgress = _accountManager.getResource('missionProgress') ?? 2;
      _missionTotal = _accountManager.getResource('missionTotal') ?? 8;
      _mailCount = _accountManager.getResource('mailCount') ?? 6;
    } catch (e) {
    }
    notifyListeners();
  }

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void refresh() {
    _isLoading = true;
    notifyListeners();
    _loadData();
  }

  void dispose() {
    super.dispose();
  }
}