import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/common/custom_tiles.dart';
import '../../widgets/common/glow.dart';
import '../../widgets/custom_widgets/custom_text.dart';
import '../../comments/user_role_controller_new.dart';

class ModeratorSettingsNew extends StatelessWidget {
  const ModeratorSettingsNew({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleController = Get.find<UserRoleController>();

    if (!userRoleController.isModerator) {
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
                    "Moderator Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Moderation Queue Section
              _buildSection(
                context,
                "Moderation Queue",
                "Review and handle reported content",
                [
                  CustomTile(
                    icon: Icons.report_rounded,
                    title: "Pending Reports",
                    description: "Review unhandled content reports",
                    onTap: () => _showComingSoon(context, "Pending Reports"),
                    iconColor: Colors.orange,
                  ),
                  CustomTile(
                    icon: Icons.priority_high_rounded,
                    title: "High Priority",
                    description: "Urgent reports requiring immediate attention",
                    onTap: () => _showComingSoon(context, "High Priority Reports"),
                    iconColor: Colors.red,
                  ),
                  CustomTile(
                    icon: Icons.history_rounded,
                    title: "Recent Actions",
                    description: "View recent moderation actions",
                    onTap: () => _showComingSoon(context, "Recent Actions"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Actions Section
              _buildSection(
                context,
                "User Actions",
                "Manage user behavior and restrictions",
                [
                  CustomTile(
                    icon: Icons.volume_off_rounded,
                    title: "Mute User",
                    description: "Temporarily silence a user",
                    onTap: () => _showMuteUserDialog(context),
                  ),
                  CustomTile(
                    icon: Icons.warning_rounded,
                    title: "Warn User",
                    description: "Issue a warning to a user",
                    onTap: () => _showWarnUserDialog(context),
                  ),
                  CustomTile(
                    icon: Icons.person_off_rounded,
                    title: "Muted Users",
                    description: "View currently muted users",
                    onTap: () => _showComingSoon(context, "Muted Users"),
                  ),
                  if (userRoleController.isAdmin)
                    CustomTile(
                      icon: Icons.block_rounded,
                      title: "Ban User",
                      description: "Permanently ban a user",
                      onTap: () => _showComingSoon(context, "Ban User"),
                      iconColor: Colors.red,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Comment Actions Section
              _buildSection(
                context,
                "Comment Actions",
                "Manage comment content and threads",
                [
                  CustomTile(
                    icon: Icons.delete_rounded,
                    title: "Delete Comment",
                    description: "Remove inappropriate comments",
                    onTap: () => _showComingSoon(context, "Delete Comment"),
                  ),
                  CustomTile(
                    icon: Icons.lock_rounded,
                    title: "Lock Thread",
                    description: "Prevent further replies to a comment",
                    onTap: () => _showComingSoon(context, "Lock Thread"),
                  ),
                  CustomTile(
                    icon: Icons.push_pin_rounded,
                    title: "Pin Comment",
                    description: "Highlight important comments",
                    onTap: () => _showComingSoon(context, "Pin Comment"),
                  ),
                  CustomTile(
                    icon: Icons.local_offer_rounded,
                    title: "Tag Comment",
                    description: "Add content warnings to comments",
                    onTap: () => _showTagCommentDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tools Section
              _buildSection(
                context,
                "Moderation Tools",
                "Utilities to help with moderation",
                [
                  CustomTile(
                    icon: Icons.search_rounded,
                    title: "User Search",
                    description: "Search for specific users",
                    onTap: () => _showComingSoon(context, "User Search"),
                  ),
                  CustomTile(
                    icon: Icons.content_paste_search_rounded,
                    title: "Content Search",
                    description: "Search comments by content",
                    onTap: () => _showComingSoon(context, "Content Search"),
                  ),
                  CustomTile(
                    icon: Icons.analytics_rounded,
                    title: "Moderation Stats",
                    description: "View your moderation statistics",
                    onTap: () => _showComingSoon(context, "Moderation Stats"),
                  ),
                  CustomTile(
                    icon: Icons.rule_rounded,
                    title: "Moderation Guidelines",
                    description: "Review community guidelines",
                    onTap: () => _showGuidelinesDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Settings Section
              _buildSection(
                context,
                "Settings",
                "Configure your moderation preferences",
                [
                  SwitchListTile(
                    title: Text("Email Notifications"),
                    subtitle: Text("Get notified of new reports"),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: Text("Auto-assign Reports"),
                    subtitle: Text("Automatically get assigned to new reports"),
                    value: false,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: Text("Show Sensitive Content"),
                    subtitle: Text("Display flagged content without blurring"),
                    value: false,
                    onChanged: (value) {},
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
                  "You don't have permission to access Moderator settings.",
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

  void _showMuteUserDialog(BuildContext context) {
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    int selectedDuration = 1; // hours

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Mute User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: "User ID or Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: "Reason for mute",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDuration,
                decoration: InputDecoration(
                  labelText: "Duration",
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text("1 hour")),
                  DropdownMenuItem(value: 6, child: Text("6 hours")),
                  DropdownMenuItem(value: 24, child: Text("1 day")),
                  DropdownMenuItem(value: 168, child: Text("1 week")),
                  DropdownMenuItem(value: 720, child: Text("1 month")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDuration = value!;
                  });
                },
              ),
            ],
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
                  SnackBar(content: Text("User muted successfully!")),
                );
              },
              child: Text("Mute User"),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarnUserDialog(BuildContext context) {
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    String selectedSeverity = "warning";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Warn User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: "User ID or Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: "Warning reason",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSeverity,
                decoration: InputDecoration(
                  labelText: "Warning Severity",
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: "warning", child: Text("Warning")),
                  DropdownMenuItem(value: "final_warning", child: Text("Final Warning")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSeverity = value!;
                  });
                },
              ),
            ],
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
                  SnackBar(content: Text("Warning sent successfully!")),
                );
              },
              child: Text("Send Warning"),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagCommentDialog(BuildContext context) {
    final TextEditingController commentIdController = TextEditingController();
    String selectedTag = "spoiler";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Tag Comment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentIdController,
                decoration: InputDecoration(
                  labelText: "Comment ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTag,
                decoration: InputDecoration(
                  labelText: "Tag Type",
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: "spoiler", child: Text("Spoiler")),
                  DropdownMenuItem(value: "nsfw", child: Text("NSFW")),
                  DropdownMenuItem(value: "warning", child: Text("Warning")),
                  DropdownMenuItem(value: "offensive", child: Text("Offensive")),
                  DropdownMenuItem(value: "spam", child: Text("Spam")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedTag = value!;
                  });
                },
              ),
            ],
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
                  SnackBar(content: Text("Comment tagged successfully!")),
                );
              },
              child: Text("Tag Comment"),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuidelinesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Community Guidelines"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuidelineItem("1. Be Respectful", "Treat all users with kindness and respect."),
              _buildGuidelineItem("2. No Spam", "Don't post repetitive or off-topic content."),
              _buildGuidelineItem("3. No Harassment", "Personal attacks or threats are not allowed."),
              _buildGuidelineItem("4. Mark Spoilers", "Always use spoiler tags for sensitive content."),
              _buildGuidelineItem("5. Stay On Topic", "Keep discussions relevant to the media."),
              _buildGuidelineItem("6. No NSFW", "Explicit content is not allowed."),
              _buildGuidelineItem("7. Follow Terms", "Adhere to platform terms of service."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}