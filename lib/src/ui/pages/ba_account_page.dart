import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../animations/ba_animations.dart';
import '../animations/ba_effects.dart';
import '../components/ba_common_widgets.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../account/skin_manager.dart';
import '../components/ba_login_dialog.dart';
import '../components/ba_notification.dart';
import '../components/ba_dialog.dart';

/// 账户中心页面
///
/// 显示账户信息、皮肤预览、账户管理
/// 支持微软官方皮肤更换
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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _initSkinManager();
  }

  Future<void> _initSkinManager() async {
    await _skinManager.initialize();
  }

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

  Future<void> _refreshSkin() async {
    if (_currentAccount == null) return;
    
    setState(() => _isRefreshingSkin = true);
    try {
      final skin = await _skinManager.getSkin(_currentAccount!, forceRefresh: true);
      if (mounted) {
        setState(() => _currentSkin = skin);
        NotificationManager().showSuccess('皮肤已刷新');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('刷新皮肤失败', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingSkin = false);
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => const BALoginDialog(),
    ).then((_) {
      // 关闭对话框后重新加载账户
      _loadAccounts();
    });
  }

  void _showAccountSelector() {
    if (_accounts.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择账户'),
        children: _accounts.map((account) {
          final isSelected = account.uuid == _currentAccount?.uuid;
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              await _accountManager.selectAccount(account.id);
              if (mounted) {
                setState(() => _currentAccount = account);
                _loadCurrentSkin(account);
              }
            },
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 12),
                Text(account.username),
                const Spacer(),
                Text(
                  _getAccountTypeLabel(account.type),
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.microsoft:
        return 'Microsoft';
      case AccountType.offline:
        return '离线';
      case AccountType.authlib:
        return 'Authlib';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          _buildHeader(context),
          const SizedBox(height: 20),

          // 当前账户卡片
          if (_currentAccount != null) ...[
            _buildCurrentAccountCard(context),
            const SizedBox(height: 20),
          ],

          // 账户列表
          Expanded(
            child: _buildAccountList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: BAColors.primaryOf(context),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          '账户中心',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const Spacer(),
        // 添加账户按钮
        ElevatedButton.icon(
          onPressed: _showLoginDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加账户'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BAColors.primaryOf(context),
            foregroundColor: BAColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentAccountCard(BuildContext context) {
    return BAAnimations.gradientBorder(
      borderRadius: 16,
      borderWidth: 2,
      gradientColors: [
        BAColors.primaryOf(context),
        BAColors.secondaryOf(context),
        BAColors.primaryOf(context).withValues(alpha: 0.5),
        BAColors.secondaryOf(context).withValues(alpha: 0.5),
        BAColors.primaryOf(context),
      ],
      child: BASurfaceCard(
        borderRadius: 14,
        showBorder: false,
        padding: const EdgeInsets.all(20),
        shadowColor: BAColors.primaryOf(context).withValues(alpha: 0.15),
        child: Row(
          children: [
            // 头像/皮肤预览（带发光光环）
            BAAnimations.pulse(
              scaleBegin: 1.0,
              scaleEnd: 1.05,
              glowColor: BAColors.primaryOf(context),
              glowRadius: 10,
              child: _buildAvatar(context, 80),
            ),
            const SizedBox(width: 20),

          // 账户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAccount!.username,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                if (_currentAccount!.uuid != null)
                  Text(
                    'UUID: ${_currentAccount!.uuid}',
                    style: TextStyle(
                      fontSize: 12,
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAccountTypeLabel(_currentAccount!.type),
                    style: TextStyle(
                      fontSize: 11,
                      color: BAColors.primaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          Column(
            children: [
              Row(
                children: [
                  BAIconButton(
                    icon: Icons.refresh,
                    tooltip: '刷新皮肤',
                    onTap: _isRefreshingSkin ? null : _refreshSkin,
                  ),
                  const SizedBox(width: 8),
                  BAIconButton(
                    icon: Icons.swap_horiz,
                    tooltip: '切换账户',
                    onTap: _showAccountSelector,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_currentAccount!.type == AccountType.microsoft)
                OutlinedButton.icon(
                  onPressed: _openMicrosoftSkinManager,
                  icon: const Icon(Icons.palette, size: 14),
                  label: const Text('更换皮肤'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BAColors.primaryOf(context),
                    side: BorderSide(color: BAColors.primaryOf(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAvatar(BuildContext context, double size) {
    final skinTypeColor = _currentSkin?.type == SkinType.alex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skinTypeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skinTypeColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _currentSkin != null
            ? Image.memory(
                _currentSkin!.imageData.asUint8List(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(context),
              )
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 40,
        color: BAColors.primaryOf(context),
      ),
    );
  }

  Widget _buildAccountList(BuildContext context) {
    if (_accounts.length <= 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 48,
              color: BAColors.textSecondaryOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无其他账户',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      );
    }

    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所有账户',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: BAAnimations.staggeredEntry(
                children: _accounts.map((account) {
                  final isSelected = account.uuid == _currentAccount?.uuid;
                  return _buildAccountTile(context, account, isSelected);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, Account account, bool isSelected) {
    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? BAColors.primaryOf(context).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? BAColors.primaryOf(context).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
          child: Text(
            account.username.isNotEmpty ? account.username[0].toUpperCase() : '?',
            style: TextStyle(
              color: BAColors.primaryOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account.username,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        subtitle: Text(
          _getAccountTypeLabel(account.type),
          style: TextStyle(
            fontSize: 12,
            color: BAColors.textSecondaryOf(context),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: BAColors.primaryOf(context), size: 20)
            : null,
        onTap: () async {
          await _accountManager.selectAccount(account.id);
          if (mounted) {
            setState(() => _currentAccount = account);
            _loadCurrentSkin(account);
          }
        },
      ),
    );

    if (isSelected) {
      tile = BAAnimations.glow(
        glowColor: BAColors.primaryOf(context),
        maxBlurRadius: 12,
        maxSpreadRadius: 2,
        child: tile,
      );
    }

    return tile;
  }

  /// 打开微软官方皮肤管理器
  ///
  /// 通过微软账户更换皮肤需要使用 Minecraft 官网的皮肤管理页面。
  /// 这里打开浏览器跳转到微软/Minecraft 官方皮肤更换页面。
  Future<void> _openMicrosoftSkinManager() async {
    // Minecraft 官方皮肤管理页面
    // 用户需要登录微软账户后在官网更换皮肤
    const skinManagerUrl = 'https://www.minecraft.net/profile/skin';

    // 显示提示对话框
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
              style: TextStyle(fontSize: 12, color: BAColors.textSecondaryOf(context)),
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
            NotificationManager().showError('无法打开链接', message: '请手动访问 minecraft.net/profile/skin');
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('打开链接失败', message: e.toString());
        }
      }
    }
  }
}

extension on List<int> {
  Uint8List asUint8List() => Uint8List.fromList(this);
}
