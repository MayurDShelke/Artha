import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../state/auth_scope.dart';
import '../state/expense_scope.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'categories_screen.dart';
import 'export_report_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final auth = AuthScope.of(context);
    final user = auth.user;
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

    final syncTimeStr = state.lastSyncTime != null
        ? DateFormat('hh:mm a, dd MMM').format(state.lastSyncTime!)
        : 'Never';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // 1. User Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withAlpha(isDark ? 55 : 30),
                      backgroundImage:
                          auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                      child: auth.photoUrl == null
                          ? Icon(
                              user != null ? Icons.person_rounded : Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 34,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            auth.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user != null
                                  ? AppColors.primary.withAlpha(isDark ? 45 : 25)
                                  : Colors.orange.withAlpha(isDark ? 45 : 25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user != null ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                  size: 13,
                                  color: user != null ? AppColors.primary : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user != null ? 'Firebase Cloud Synced' : 'Guest / Local Mode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: user != null ? AppColors.primary : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatSnippet('Expenses', '${state.expenses.length} items', isDark),
                    _buildStatSnippet('Categories', '${state.categories.length} active', isDark),
                    if (user != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger.withAlpha(80)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text('Sign In'),
                        onPressed: () => AuthScreen.show(context, auth),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Cloud Database Sync Card
          _buildSectionHeader('Cloud Database Sync', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 45 : 25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Firebase Firestore Sync',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user != null
                            ? 'Auto-syncs across devices • Last: $syncTimeStr'
                            : 'Sign in to sync your data to cloud',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: state.isSyncing
                        ? null
                        : () async {
                            await state.syncWithCloud();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cloud database synced successfully!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                    child: state.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Organization & Preferences
          _buildSectionHeader('Preferences & Management', isDark),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_rounded, color: AppColors.primary),
                  title: const Text('Categories Manager', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${state.categories.length} categories (Add, edit, color)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                    );
                  },
                ),
                const Divider(),
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

          const SizedBox(height: 20),

          // 4. Data Export & Backup
          _buildSectionHeader('Reports & Backup', isDark),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                  title: const Text('Export Reports (CSV / Print)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Copy CSV for Excel/Sheets or print summary'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => ExportReportSheet.show(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: AppColors.primary),
                  title: const Text('Export JSON Database Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Copy full encrypted database text'),
                  onTap: () {
                    final jsonStr = state.exportBackupJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database JSON copied to clipboard!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined, color: AppColors.primary),
                  title: const Text('Restore from JSON Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste backup text to restore'),
                  onTap: () => _showImportDialog(context, state),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                  title: const Text('Clear All Expenses',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Delete local and cloud records for this user'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Data?'),
                        content: const Text(
                          'Are you sure you want to delete all expenses? This will also remove them from your Firebase cloud database.',
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

          const SizedBox(height: 20),

          // 5. App Info
          Center(
            child: Text(
              'IMREXPENSE • Version 1.0.0\nFirebase Cloud Synced • Local-First',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                height: 1.5,
              ),
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

  Widget _buildStatSnippet(String title, String val, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
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
