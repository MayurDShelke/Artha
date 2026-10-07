import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/auth_scope.dart';
import '../state/expense_scope.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const currencies = [
      ('₹', 'Indian Rupee (INR)'),
      ('\$', 'US Dollar (USD)'),
      ('€', 'Euro (EUR)'),
      ('£', 'British Pound (GBP)'),
      ('¥', 'Japanese Yen (JPY)'),
      ('AED', 'UAE Dirham (AED)'),
      ('C\$', 'Canadian Dollar (CAD)'),
      ('A\$', 'Australian Dollar (AUD)'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 0. Account & Firebase Auth Section
          _buildSectionHeader('Account & Cloud Sync', isDark),
          Builder(builder: (context) {
            final auth = AuthScope.of(context);
            final user = auth.user;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withAlpha(isDark ? 50 : 30),
                    backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                    child: auth.photoUrl == null
                        ? Icon(
                            user != null ? Icons.person_rounded : Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withAlpha(80)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Sign Out'),
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out successfully')),
                          );
                        }
                      },
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Sign In'),
                      onPressed: () => AuthScreen.show(context, auth),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // 1. Preferences Section
          _buildSectionHeader('Preferences', isDark),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                  title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Current: ${state.currencySymbol}'),
                  trailing: DropdownButton<String>(
                    value: currencies.any((c) => c.$1 == state.currencySymbol)
                        ? state.currencySymbol
                        : '₹',
                    underline: const SizedBox.shrink(),
                    items: currencies.map((c) {
                      return DropdownMenuItem(
                        value: c.$1,
                        child: Text('${c.$1} - ${c.$2}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) state.setCurrencySymbol(val);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    state.themeMode == ThemeMode.dark
                        ? 'Dark Mode'
                        : state.themeMode == ThemeMode.light
                            ? 'Light Mode'
                            : 'System Default',
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: state.themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) state.setThemeMode(val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Data Persistence & Backup Section
          _buildSectionHeader('Data Management & Backup', isDark),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: AppColors.primary),
                  title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Copy complete database backup to clipboard'),
                  onTap: () {
                    final jsonStr = state.exportBackupJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full database JSON copied to clipboard!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined, color: AppColors.primary),
                  title: const Text('Restore from JSON Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste backup text to restore data'),
                  onTap: () => _showImportDialog(context, state),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                  title: const Text('Clear All Expenses', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Delete all expense records and start fresh'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Data?'),
                        content: const Text(
                          'Are you sure you want to delete all expenses? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await state.clearAllData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All expenses cleared')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Application Info Section
          _buildSectionHeader('About IMREXPENSE', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(isDark ? 50 : 30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IMREXPENSE',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Version 1.0.0 • Local-First Architecture',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A fast, private, and flexible personal expense tracker with unlimited historical date tracking, multi-year analytics, and rolling filter horizons.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, ExpenseState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste the JSON backup text below:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(hintText: '{\n  "version": 1,\n  "expenses": ...\n}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final success = await state.importBackupJson(text);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Backup restored successfully!' : 'Invalid backup format!'),
                    backgroundColor: success ? AppColors.primary : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
