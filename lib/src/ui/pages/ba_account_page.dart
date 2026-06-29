import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../animations/ba_animations.dart';
import '../components/ba_common_widgets.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../account/skin_manager.dart';
import '../components/ba_login_dialog.dart';
import '../components/ba_notification.dart';
import '../components/ba_dialog.dart';
import '../components/ba_buttons.dart' hide BAIconButton;

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
    if (_selectedAccount != null) {
      // 详情页内刷新皮肤
      setState(() => _isRefreshingSkin = true);
      try {
        final skin = await _skinManager.getSkin(_selectedAccount!, forceRefresh: true);
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

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => const BALoginDialog(),
    ).then((_) {
      _loadAccounts();
    });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: BAColors.primaryOf(context),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _selectedAccount != null
          ? _buildDetailPage(context)
          : _buildListPage(context),
    );
  }

  // ===========================================================================
  // 列表页面
  // ===========================================================================

  Widget _buildListPage(BuildContext context) {
    return Container(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(context),
          const SizedBox(height: 20),
          if (_currentAccount != null) ...[
            _buildCurrentAccountCard(context),
            const SizedBox(height: 20),
          ],
          Expanded(
            child: _buildAccountList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context) {
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
        onTap: _currentAccount != null ? () => _openAccountDetail(_currentAccount!) : null,
        child: Row(
          children: [
            BAAnimations.pulse(
              scaleBegin: 1.0,
              scaleEnd: 1.05,
              glowColor: BAColors.primaryOf(context),
              glowRadius: 10,
              child: _buildAvatar(_currentSkin, 80),
            ),
            const SizedBox(width: 20),
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
                      icon: Icons.arrow_forward_ios,
                      tooltip: '查看详情',
                      iconSize: 16,
                      onTap: () => _openAccountDetail(_currentAccount!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(SkinData? skin, double size) {
    final skinTypeColor = skin?.type == SkinType.alex
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
        child: skin != null
            ? Image.memory(
                skin.imageData.asUint8List(),
                fit: BoxFit.cover,
                errorBuilder: (_, a, b) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
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
    if (_accounts.isEmpty) {
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
              '暂无账户，点击"添加账户"开始',
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(Icons.check_circle, color: BAColors.primaryOf(context), size: 20),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: BAColors.textSecondaryOf(context), size: 14),
          ],
        ),
        onTap: () => _openAccountDetail(account),
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

  // ===========================================================================
  // 详情子页面
  // ===========================================================================

  Widget _buildDetailPage(BuildContext context) {
    final account = _selectedAccount!;
    final isCurrentAccount = account.id == _currentAccount?.id;

    return Container(
      key: const ValueKey('detail'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：返回按钮 + 账号名称
          _buildDetailHeader(context, account),
          const SizedBox(height: 20),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 皮肤预览区域
                  _buildSkinPreview(context, account),
                  const SizedBox(height: 20),
                  // 账号信息卡片
                  _buildAccountInfoCard(context, account, isCurrentAccount),
                  const SizedBox(height: 20),
                  // 操作按钮
                  _buildActionButtons(context, account, isCurrentAccount),
                  const SizedBox(height: 20),
                  // 管理账号列表入口
                  _buildManageAccountsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(BuildContext context, Account account) {
    return Row(
      children: [
        // 返回按钮
        BAIconButton(
          icon: Icons.arrow_back,
          tooltip: '返回账户列表',
          onTap: _backToList,
        ),
        const SizedBox(width: 12),
        // 账号名称
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.username,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: BAColors.textPrimaryOf(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getAccountTypeLabel(account.type),
                style: TextStyle(
                  fontSize: 13,
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildSkinPreview(BuildContext context, Account account) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '皮肤预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          // 皮肤图片
          Center(
            child: _isLoadingDetailSkin
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: BAColors.primaryOf(context),
                      ),
                    ),
                  )
                : BAAnimations.elasticScale(
                    child: _buildLargeSkinPreview(account),
                  ),
          ),
          const SizedBox(height: 16),
          // 皮肤信息
          if (_detailSkin != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _detailSkin!.type == SkinType.alex
                        ? BAColors.secondaryOf(context).withValues(alpha: 0.15)
                        : BAColors.primaryOf(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _detailSkin!.type == SkinType.alex
                          ? BAColors.secondaryOf(context).withValues(alpha: 0.3)
                          : BAColors.primaryOf(context).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _detailSkin!.type == SkinType.alex ? 'Alex 模型' : 'Steve 模型',
                    style: TextStyle(
                      fontSize: 12,
                      color: _detailSkin!.type == SkinType.alex
                          ? BAColors.secondaryOf(context)
                          : BAColors.primaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_detailSkin!.skinUrl != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BAColors.successOf(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '已缓存',
                      style: TextStyle(
                        fontSize: 12,
                        color: BAColors.successOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (!_isLoadingDetailSkin) ...[
            Text(
              '暂无皮肤数据',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLargeSkinPreview(Account account) {
    final skinTypeColor = _detailSkin?.type == SkinType.alex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skinTypeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skinTypeColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _detailSkin != null
            ? Image.memory(
                _detailSkin!.imageData.asUint8List(),
                fit: BoxFit.cover,
                errorBuilder: (_, a, b) => _buildDetailDefaultAvatar(),
              )
            : _buildDetailDefaultAvatar(),
      ),
    );
  }

  Widget _buildDetailDefaultAvatar() {
    return Container(
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: BAColors.primaryOf(context),
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, Account account, bool isCurrentAccount) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账号信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '用户名', account.username),
          if (account.uuid != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(context, 'UUID', account.uuid!),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(context, '账号类型', _getAccountTypeLabel(account.type)),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            '默认账号',
            isCurrentAccount ? '是' : '否',
            valueColor: isCurrentAccount ? BAColors.successOf(context) : null,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            '创建时间',
            _formatDateTime(account.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            '最近使用',
            _formatDateTime(account.lastUsedAt),
          ),
          if (account.type != AccountType.offline) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              '登录状态',
              account.accessToken != null && account.accessToken!.isNotEmpty
                  ? '已登录'
                  : '未登录',
              valueColor: account.accessToken != null && account.accessToken!.isNotEmpty
                  ? BAColors.successOf(context)
                  : BAColors.warningOf(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? BAColors.textPrimaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Account account, bool isCurrentAccount) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '操作',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          // 设为默认
          if (!isCurrentAccount)
            _buildActionButton(
              context,
              icon: Icons.check_circle_outline,
              label: '设为默认账号',
              description: '切换到此账号作为默认启动账号',
              color: BAColors.primaryOf(context),
              onTap: () => _setDefaultAccount(account),
            ),
          if (!isCurrentAccount) const SizedBox(height: 10),
          // 刷新皮肤
          _buildActionButton(
            context,
            icon: Icons.refresh,
            label: '刷新皮肤',
            description: '重新从服务器获取皮肤数据',
            color: BAColors.infoOf(context),
            onTap: _isRefreshingSkin ? null : _refreshSkin,
            isLoading: _isRefreshingSkin,
          ),
          const SizedBox(height: 10),
          // 微软官方皮肤管理
          if (account.type == AccountType.microsoft) ...[
            _buildActionButton(
              context,
              icon: Icons.palette,
              label: '更换皮肤',
              description: '前往 Minecraft 官网更换皮肤',
              color: BAColors.primaryLightOf(context),
              onTap: _openMicrosoftSkinManager,
            ),
            const SizedBox(height: 10),
          ],
          // 删除
          _buildActionButton(
            context,
            icon: Icons.delete_outline,
            label: '删除账号',
            description: '永久删除此账号及其相关数据',
            color: BAColors.dangerOf(context),
            onTap: () => _deleteAccountFromDetail(account),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return BASurfaceCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: BAColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: BAColors.textSecondaryOf(context),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildManageAccountsSection(BuildContext context) {
    // 过滤掉当前查看的账号
    final otherAccounts = _accounts.where((a) => a.id != _selectedAccount?.id).toList();

    if (otherAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '切换账号',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          ...otherAccounts.map((account) {
            final isCurrent = account.id == _currentAccount?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSwitchableAccountTile(context, account, isCurrent),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSwitchableAccountTile(BuildContext context, Account account, bool isCurrent) {
    return BASurfaceCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => _openAccountDetail(account),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
            child: Text(
              account.username.isNotEmpty ? account.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.username,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _getAccountTypeLabel(account.type),
                      style: TextStyle(
                        fontSize: 11,
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: BAColors.successOf(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '默认',
                          style: TextStyle(
                            fontSize: 10,
                            color: BAColors.successOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: BAColors.textSecondaryOf(context),
            size: 14,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
