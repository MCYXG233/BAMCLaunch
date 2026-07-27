import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 账号与档案 - 正版登录 / 外置认证 / 离线账号
class AccountsSection extends StatelessWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '账号与档案',
      breadcrumbs: const ['游戏', '账号与档案'],
      children: [
        SettingsSectionCard(
          title: '微软正版账号',
          titleIcon: Icons.verified_user_outlined,
          children: [
            InfoCard(
              icon: Icons.lightbulb_outline,
              child: Text(
                '全局默认仅有一个生效的登录账号。游戏内可通过暂停菜单切换为本地已登录的其他账号。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SettingRow(
              icon: Icons.person_outline,
              title: '当前登录账号',
              subtitle: '尚未登录',
              onTap: () {},
              trailing: Text(
                '登录',
                style: TextStyle(fontSize: 11, color: SettingsPalette.accent),
              ),
            ),
            ButtonRow(
              icon: Icons.refresh,
              title: '刷新令牌',
              subtitle: '令牌过期后无法启动游戏',
              buttonLabel: '刷新',
              onPressed: () {},
            ),
            SwitchRow(
              icon: Icons.bolt_outlined,
              title: '离线模式登录',
              subtitle: '无需联网验证；适合自建服务器或测试',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '外置认证服务器',
          titleIcon: Icons.shield_outlined,
          children: [
            InfoCard(
              icon: Icons.info_outline,
              child: Text(
                '外置认证（Authlib Injector）允许你登录到第三方服务器的小型账号体系，常用于整合包与自建服务器。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            ButtonRow(
              icon: Icons.add_link,
              title: '添加认证服务器',
              subtitle: '粘贴服务器注册 API 地址以添加',
              buttonLabel: '添加',
              onPressed: () {},
            ),
            DropdownRow(
              icon: Icons.dns_outlined,
              title: '当前使用的认证服务器',
              subtitle: '选择后影响游戏启动时的登录模式',
              value: 'microsoft',
              items: const [
                DropdownMenuItem(value: 'microsoft', child: Text('微软正版')),
                DropdownMenuItem(value: 'offline', child: Text('离线模式')),
              ],
              onChanged: (_) {},
            ),
            ButtonRow(
              icon: Icons.list_alt,
              title: '管理已添加的服务器',
              buttonLabel: '管理',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '离线账号',
          titleIcon: Icons.account_circle_outlined,
          initiallyCollapsed: true,
          children: [
            InfoCard(
              child: Text(
                '离线账号仅在本机有效，不可进入正版服务器。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            ButtonRow(
              icon: Icons.add,
              title: '新建离线账号',
              buttonLabel: '新建',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
