import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/common/custom_tiles.dart';
import '../../widgets/common/glow.dart';
import '../../widgets/custom_widgets/custom_text.dart';
import '../../comments/user_role_controller_new.dart';

class AdminSettingsNew extends StatelessWidget {
  const AdminSettingsNew({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleController = Get.find<UserRoleController>();

    if (!userRoleController.isAdmin) {
      return _buildAccessDenied(context, colorScheme);
    }

    return Glow(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainer.withOpacity(0.5),
                    ),
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Admin Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Moderation Section
              _buildSection(
                context,
                "Moderation",
                "Content and user moderation tools",
                [
                  CustomTile(
                    icon: Icons.report_rounded,
                    title: "Moderation Queue",
                    description: "Review reported comments and users",
                    onTap: () => _showComingSoon(context, "Moderation Queue"),
                  ),
                  CustomTile(
                    icon: Icons.gavel_rounded,
                    title: "User Moderation",
                    description: "Ban, mute, or warn users",
                    onTap: () => _showComingSoon(context, "User Moderation"),
                  ),
                  CustomTile(
                    icon: Icons.comment_rounded,
                    title: "Comment Moderation",
                    description: "Delete, lock, or pin comments",
                    onTap: () => _showComingSoon(context, "Comment Moderation"),
                  ),
                  CustomTile(
                    icon: Icons.history_rounded,
                    title: "Moderation History",
                    description: "View past moderation actions",
                    onTap: () => _showComingSoon(context, "Moderation History"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Management Section
              _buildSection(
                context,
                "User Management",
                "Manage user accounts and permissions",
                [
                  CustomTile(
                    icon: Icons.people_rounded,
                    title: "User List",
                    description: "View and search all users",
                    onTap: () => _showComingSoon(context, "User List"),
                  ),
                  CustomTile(
                    icon: Icons.block_rounded,
                    title: "Banned Users",
                    description: "Manage banned and shadow-banned users",
                    onTap: () => _showComingSoon(context, "Banned Users"),
                  ),
                  CustomTile(
                    icon: Icons.person_off_rounded,
                    title: "Muted Users",
                    description: "Manage temporarily muted users",
                    onTap: () => _showComingSoon(context, "Muted Users"),
                  ),
                  if (userRoleController.isSuperAdmin)
                    CustomTile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: "Staff Management",
                      description: "Manage moderators and admins",
                      onTap: () => _showComingSoon(context, "Staff Management"),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Content Management Section
              _buildSection(
                context,
                "Content Management",
                "Manage platform content",
                [
                  CustomTile(
                    icon: Icons.delete_sweep_rounded,
                    title: "Bulk Delete",
                    description: "Delete multiple comments at once",
                    onTap: () => _showComingSoon(context, "Bulk Delete"),
                  ),
                  CustomTile(
                    icon: Icons.filter_list_rounded,
                    title: "Content Filters",
                    description: "Manage banned words and phrases",
                    onTap: () => _showComingSoon(context, "Content Filters"),
                  ),
                  CustomTile(
                    icon: Icons.auto_fix_high_rounded,
                    title: "Auto-moderation Rules",
                    description: "Configure automated moderation",
                    onTap: () => _showComingSoon(context, "Auto-moderation Rules"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Analytics Section
              _buildSection(
                context,
                "Analytics",
                "Platform insights and statistics",
                [
                  CustomTile(
                    icon: Icons.analytics_rounded,
                    title: "User Statistics",
                    description: "View user activity and engagement",
                    onTap: () => _showComingSoon(context, "User Statistics"),
                  ),
                  CustomTile(
                    icon: Icons.trending_up_rounded,
                    title: "Content Analytics",
                    description: "Analyze comment trends and patterns",
                    onTap: () => _showComingSoon(context, "Content Analytics"),
                  ),
                  CustomTile(
                    icon: Icons.report_problem_rounded,
                    title: "Report Analytics",
                    description: "View reporting trends and patterns",
                    onTap: () => _showComingSoon(context, "Report Analytics"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // System Settings Section
              _buildSection(
                context,
                "System Settings",
                "Configure system behavior",
                [
                  CustomTile(
                    icon: Icons.speed_rounded,
                    title: "Rate Limits",
                    description: "Configure user rate limits",
                    onTap: () => _showRateLimitsDialog(context),
                  ),
                  CustomTile(
                    icon: Icons.security_rounded,
                    title: "Security Settings",
                    description: "Manage security policies",
                    onTap: () => _showComingSoon(context, "Security Settings"),
                  ),
                  if (userRoleController.isSuperAdmin)
                    CustomTile(
                      icon: Icons.settings_rounded,
                      title: "Global Settings",
                      description: "System-wide configuration",
                      onTap: () => _showComingSoon(context, "Global Settings"),
                    ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context, ColorScheme colorScheme) {
    return Glow(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block_rounded,
                  size: 80,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  "Access Denied",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "You don't have permission to access Admin settings.",
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: () => Get.back(),
                  child: Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainer.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text("This feature is coming soon!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRateLimitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Limit Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Comments per Hour"),
              subtitle: Text("Maximum comments a user can post per hour"),
              trailing: Text("30"),
              onTap: () => _showComingSoon(context, "Edit Comment Limit"),
            ),
            ListTile(
              title: Text("Votes per Hour"),
              subtitle: Text("Maximum votes a user can cast per hour"),
              trailing: Text("100"),
              onTap: () => _showComingSoon(context, "Edit Vote Limit"),
            ),
            ListTile(
              title: Text("Reports per Hour"),
              subtitle: Text("Maximum reports a user can submit per hour"),
              trailing: Text("10"),
              onTap: () => _showComingSoon(context, "Edit Report Limit"),
            ),
            const Divider(),
            SwitchListTile(
              title: Text("Super Admin Exemption"),
              subtitle: Text("Super admins bypass all rate limits"),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
}