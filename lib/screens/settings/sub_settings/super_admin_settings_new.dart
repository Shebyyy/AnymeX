import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/common/custom_tiles.dart';
import '../../widgets/common/glow.dart';
import '../../widgets/custom_widgets/custom_text.dart';
import '../../comments/user_role_controller_new.dart';

class SuperAdminSettingsNew extends StatelessWidget {
  const SuperAdminSettingsNew({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleController = Get.find<UserRoleController>();

    if (!userRoleController.isSuperAdmin) {
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
                    "Super Admin Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // User Management Section
              _buildSection(
                context,
                "User Management",
                "Manage roles and permissions",
                [
                  CustomTile(
                    icon: Icons.admin_panel_settings_rounded,
                    title: "Manage Admins & Moderators",
                    description: "Promote, demote, or remove staff members",
                    onTap: () => _showComingSoon(context, "Staff Management"),
                  ),
                  CustomTile(
                    icon: Icons.person_add_rounded,
                    title: "Role Management",
                    description: "Assign and modify user roles",
                    onTap: () => _showComingSoon(context, "Role Management"),
                  ),
                  CustomTile(
                    icon: Icons.block_rounded,
                    title: "Global Bans",
                    description: "Manage banned users globally",
                    onTap: () => _showComingSoon(context, "Global Bans"),
                  ),
                  CustomTile(
                    icon: Icons.visibility_off_rounded,
                    title: "Shadow Bans",
                    description: "Manage shadow-banned users",
                    onTap: () => _showComingSoon(context, "Shadow Bans"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // System Settings Section
              _buildSection(
                context,
                "System Settings",
                "Configure system-wide settings",
                [
                  CustomTile(
                    icon: Icons.comment_rounded,
                    title: "Comment System",
                    description: "Enable/disable comment features globally",
                    onTap: () => _showCommentSystemDialog(context),
                  ),
                  CustomTile(
                    icon: Icons.gavel_rounded,
                    title: "Moderation Rules",
                    description: "Configure automated moderation",
                    onTap: () => _showComingSoon(context, "Moderation Rules"),
                  ),
                  CustomTile(
                    icon: Icons.speed_rounded,
                    title: "Rate Limits",
                    description: "Configure user rate limits",
                    onTap: () => _showComingSoon(context, "Rate Limits"),
                  ),
                  CustomTile(
                    icon: Icons.security_rounded,
                    title: "Security Settings",
                    description: "Manage security policies",
                    onTap: () => _showComingSoon(context, "Security Settings"),
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
                    icon: Icons.report_rounded,
                    title: "Report Queue",
                    description: "Review and handle content reports",
                    onTap: () => _showComingSoon(context, "Report Queue"),
                  ),
                  CustomTile(
                    icon: Icons.delete_sweep_rounded,
                    title: "Content Cleanup",
                    description: "Bulk content management tools",
                    onTap: () => _showComingSoon(context, "Content Cleanup"),
                  ),
                  CustomTile(
                    icon: Icons.filter_list_rounded,
                    title: "Banned Keywords",
                    description: "Manage content filtering keywords",
                    onTap: () => _showComingSoon(context, "Banned Keywords"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Analytics & Monitoring Section
              _buildSection(
                context,
                "Analytics & Monitoring",
                "System insights and monitoring",
                [
                  CustomTile(
                    icon: Icons.analytics_rounded,
                    title: "System Analytics",
                    description: "View platform statistics and trends",
                    onTap: () => _showComingSoon(context, "System Analytics"),
                  ),
                  CustomTile(
                    icon: Icons.history_rounded,
                    title: "Audit Logs",
                    description: "View system audit history",
                    onTap: () => _showComingSoon(context, "Audit Logs"),
                  ),
                  CustomTile(
                    icon: Icons.warning_rounded,
                    title: "Security Alerts",
                    description: "Monitor security threats",
                    onTap: () => _showComingSoon(context, "Security Alerts"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Emergency Controls Section
              _buildSection(
                context,
                "Emergency Controls",
                "Critical system controls",
                [
                  CustomTile(
                    icon: Icons.emergency_rounded,
                    title: "Emergency Mode",
                    description: "Enable emergency maintenance mode",
                    onTap: () => _showEmergencyDialog(context),
                    iconColor: Colors.red,
                  ),
                  CustomTile(
                    icon: Icons.power_settings_new_rounded,
                    title: "System Shutdown",
                    description: "Emergency system shutdown",
                    onTap: () => _showShutdownDialog(context),
                    iconColor: Colors.red,
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
                  "You don't have permission to access Super Admin settings.",
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

  void _showCommentSystemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Comment System Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text("Enable Comments"),
              subtitle: Text("Allow users to post comments"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Enable Voting"),
              subtitle: Text("Allow upvoting and downvoting"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Enable Reporting"),
              subtitle: Text("Allow users to report content"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Auto-moderation"),
              subtitle: Text("Enable automated content moderation"),
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

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("Emergency Mode"),
          ],
        ),
        content: Text(
          "Emergency mode will disable all user interactions and display a maintenance message. This should only be used in critical situations.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Emergency mode activated!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Activate"),
          ),
        ],
      ),
    );
  }

  void _showShutdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("System Shutdown"),
          ],
        ),
        content: Text(
          "This will immediately shut down the entire system. All users will be disconnected. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("System shutdown initiated!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Shutdown"),
          ),
        ],
      ),
    );
  }
}