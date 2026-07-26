import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';
import '../../components/ba_buttons.dart' hide BAIconButton;
import '../../components/ba_dialog.dart';
import '../../components/ba_login_dialog.dart';
import '../../components/ba_notification.dart';
import '../../../account/account.dart';
import '../../../account/account_manager.dart';
import '../../../account/skin_manager.dart';
import 'detail/account_detail_page.dart';
import 'list/account_list_page.dart';

/// 账户中心页面
///
/// 显示账户信息、皮肤预览、账户管理
/// 支持列表视图和详情子页面切换
class BAAccountPage extends StatefulWidget {
  const BAAccountPage({super.key});

  @override
  State<BAAccountPage> createState() => _BAAccountPageState();
}

class _BAAccountPageState extends State<BAAccountPage> {
  final AccountManager _accountManager = AccountManager();
  final SkinManager _skinManager = SkinManager();

  Account? _currentAccount;
  List<Account> _accounts = [];
  bool _isLoading = true;
  SkinData? _currentSkin;
  bool _isRefreshingSkin = false;

  /// 当前选中查看详情的账号，null 表示显示列表，非 null 表示显示详情
  Account? _selectedAccount;

  /// 详情页的皮肤数据
  SkinData? _detailSkin;
  bool _isLoadingDetailSkin = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _initSkinManager();
  }

  /// 初始化皮肤管理器
  Future<void> _initSkinManager() async {
    try {
      await _skinManager.initialize();
    } catch (_) {
      // 皮肤管理器初始化失败不影响主要功能
    }
  }

  /// 加载账户列表与当前默认账户
  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountManager.getAccounts();
      final selected = await _accountManager.getSelectedAccount();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _currentAccount = selected;
          _isLoading = false;
        });
        if (selected != null) {
          _loadCurrentSkin(selected);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationManager().showError('加载账户失败', message: e.toString());
      }
    }
  }

  /// 加载当前默认账户的皮肤
  Future<void> _loadCurrentSkin(Account account) async {
    try {
      final skin = await _skinManager.getSkin(account);
      if (mounted) {
        setState(() => _currentSkin = skin);
      }
    } catch (e) {
      // 皮肤加载失败，使用默认皮肤
    }
  }

  /// 刷新皮肤（同时支持列表页当前账号与详情页选中账号）
  Future<void> _refreshSkin() async {
    if (_selectedAccount != null) {
      // 详情页内刷新皮肤
      if (!mounted) return;
      setState(() => _isRefreshingSkin = true);
      try {
        final skin = await _skinManager.getSkin(
          _selectedAccount!,
          forceRefresh: true,
        );
        if (mounted) {
          setState(() => _detailSkin = skin);
          NotificationManager().showSuccess('皮肤已刷新');
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('刷新皮肤失败', message: e.toString());
        }
      } finally {
        if (mounted) setState(() => _isRefreshingSkin = false);
      }
    } else if (_currentAccount != null) {
      // 列表页刷新当前账号皮肤
      if (!mounted) return;
      setState(() => _isRefreshingSkin = true);
      try {
        final skin = await _skinManager.getSkin(
          _currentAccount!,
          forceRefresh: true,
        );
        if (mounted) {
          setState(() => _currentSkin = skin);
          NotificationManager().showSuccess('皮肤已刷新');
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('刷新皮肤失败', message: e.toString());
        }
      } finally {
        if (mounted) setState(() => _isRefreshingSkin = false);
      }
    }
  }

  /// 进入详情子页面
  void _openAccountDetail(Account account) {
    setState(() {
      _selectedAccount = account;
      _detailSkin = null;
      _isLoadingDetailSkin = true;
    });
    _loadDetailSkin(account);
  }

  /// 返回列表页面
  void _backToList() {
    setState(() {
      _selectedAccount = null;
      _detailSkin = null;
    });
    // 刷新列表数据
    _loadAccounts();
  }

  /// 切换到指定账户
  ///
  /// 等同于先进入该账户的详情，再触发"设为默认"。
  void _switchToAccount(Account account) {
    _openAccountDetail(account);
  }

  /// 加载详情页皮肤
  Future<void> _loadDetailSkin(Account account) async {
    try {
      final skin = await _skinManager.getSkin(account);
      if (mounted) {
        setState(() {
          _detailSkin = skin;
          _isLoadingDetailSkin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetailSkin = false);
      }
    }
  }

  /// 显示登录对话框
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => const BALoginDialog(),
    ).then((_) {
      _loadAccounts();
    });
  }

  /// 设为默认账号
  Future<void> _setDefaultAccount(Account account) async {
    try {
      await _accountManager.selectAccount(account.id);
      if (mounted) {
        setState(() {
          _currentAccount = account;
        });
        _loadCurrentSkin(account);
        NotificationManager().showSuccess('已设为默认账号');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('操作失败', message: e.toString());
      }
    }
  }

  /// 删除账号（从详情页）
  Future<void> _deleteAccountFromDetail(Account account) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除账号',
      content: '确定要删除账号 "${account.username}" 吗？此操作不可撤销。',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
    );

    if (confirmed != true) return;

    try {
      await _accountManager.removeAccount(account.id);
      if (mounted) {
        NotificationManager().showSuccess('账号已删除');
        _backToList();
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('删除失败', message: e.toString());
      }
    }
  }

  /// 打开微软官方皮肤管理器
  Future<void> _openMicrosoftSkinManager() async {
    const skinManagerUrl = 'https://www.minecraft.net/profile/skin';

    if (!mounted) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: BAColors.primaryOf(context)),
            const SizedBox(width: 8),
            const Text('更换皮肤'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '微软官方皮肤更换步骤：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('1. 点击"前往官网"按钮打开 Minecraft 官网'),
            const SizedBox(height: 4),
            const Text('2. 使用 Microsoft 账户登录'),
            const SizedBox(height: 4),
            const Text('3. 在"个人资料"中上传自定义皮肤'),
            const SizedBox(height: 4),
            const Text('4. 返回启动器并刷新皮肤'),
            const SizedBox(height: 12),
            Text(
              '注意：皮肤更换可能需要几分钟生效。',
              style: TextStyle(
                fontSize: 12,
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('前往官网'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primaryOf(context),
              foregroundColor: BAColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      final uri = Uri.parse(skinManagerUrl);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            NotificationManager().showError(
              '无法打开链接',
              message: '请手动访问 minecraft.net/profile/skin',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('打开链接失败', message: e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: BAColors.primaryOf(context)),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: _selectedAccount != null
          ? RepaintBoundary(
              key: const ValueKey('detail'),
              child: AccountDetailPage(
                selectedAccount: _selectedAccount!,
                currentAccount: _currentAccount,
                allAccounts: _accounts,
                isLoadingDetailSkin: _isLoadingDetailSkin,
                isRefreshingSkin: _isRefreshingSkin,
                detailSkin: _detailSkin,
                onBack: _backToList,
                onAddAccount: _showLoginDialog,
                onRefreshSkin: _refreshSkin,
                onSetDefault: () => _setDefaultAccount(_selectedAccount!),
                onOpenMicrosoftSkinManager: _openMicrosoftSkinManager,
                onDelete: () => _deleteAccountFromDetail(_selectedAccount!),
                onSwitchAccount: _switchToAccount,
              ),
            )
          : RepaintBoundary(
              key: const ValueKey('list'),
              child: AccountListPage(
                currentAccount: _currentAccount,
                accounts: _accounts,
                currentSkin: _currentSkin,
                isRefreshingSkin: _isRefreshingSkin,
                onTapCurrent: () {
                  if (_currentAccount != null) {
                    _openAccountDetail(_currentAccount!);
                  }
                },
                onOpenAccount: _openAccountDetail,
                onRefreshSkin: _refreshSkin,
                onAddAccount: _showLoginDialog,
              ),
            ),
    );
  }
}
