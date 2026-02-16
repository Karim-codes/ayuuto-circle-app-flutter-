import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

class ShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: GlassBottomBar(
        showIndicator: true,
        selectedIconColor: AppColors.textPrimary,
        unselectedIconColor: AppColors.textTertiary,
        textStyle: const TextStyle(fontSize: 11),
        tabs: const [
          GlassBottomBarTab(
            label: 'Home',
            icon: CupertinoIcons.house,
            selectedIcon: CupertinoIcons.house_fill,
            glowColor: Color.fromRGBO(0, 208, 156, 1),
          ),
          GlassBottomBarTab(
            label: 'History',
            icon: CupertinoIcons.doc_text,
            selectedIcon: CupertinoIcons.doc_text_fill,
            glowColor: Color.fromRGBO(0, 208, 156, 1),
          ),
          GlassBottomBarTab(
            label: 'Profile',
            icon: CupertinoIcons.person,
            selectedIcon: CupertinoIcons.person_fill,
            glowColor: Color.fromRGBO(0, 208, 156, 1),
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          // Refresh data when switching tabs
          if (index == 0) {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(profileProvider);
          } else if (index == 1) {
            ref.invalidate(userHistoryProvider);
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        extraButton: GlassBottomBarExtraButton(
          icon: CupertinoIcons.add,
          label: 'New Circle',
          iconColor: AppColors.accent,
          onTap: () => context.push('/create-group'),
        ),
      ),
    );
  }
}
