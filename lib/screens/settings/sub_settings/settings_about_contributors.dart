import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';

import 'package:anymex/models/contributor.dart';
import 'package:anymex/controllers/contributors/contributor_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';

const String defaultBannerUrl = "https://i.ibb.co/8DtGFx0z/test.jpg";

class ContributorsPage extends StatefulWidget {
  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  late Future<List<Contributor>> future;

  @override
  void initState() {
    super.initState();
    future = ContributorController.getContributors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contributors")),
      body: FutureBuilder<List<Contributor>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: GestureDetector(
                  onTap: () => _openContributor(c),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: NetworkImage(
                          (c.banner != null && c.banner!.isNotEmpty)
                              ? c.banner!
                              : defaultBannerUrl,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.black.withOpacity(0.45),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(c.avatar),
                          ),
                          const SizedBox(width: 14),

                          // Name + role + contributions
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (c.role != null)
                                  Text(
                                    c.role!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                if (c.contributions != null)
                                  Text(
                                    "${c.contributions} contributions",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  //  Badge Colors
  // ---------------------------------------------------------
  Color _badgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case "owner":
        return Colors.redAccent;
      case "lead developer":
        return Colors.blueAccent;
      case "admin":
        return Colors.orangeAccent;
      case "moderator":
        return Colors.greenAccent;
      case "github contributor":
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadges(Contributor c) {
    if (c.badges == null || c.badges!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        children: c.badges!.map((badge) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeColor(badge).withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _badgeColor(badge)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                color: _badgeColor(badge),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------
  //  Fullscreen Avatar Preview
  // ---------------------------------------------------------
  void _openAvatarFullscreen(String imageUrl, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: imageUrl,
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  Contributor Bottom Sheet
  // ---------------------------------------------------------
  void _openContributor(Contributor c) {
    AnymexSheet.custom(
      SingleChildScrollView(
        child: Column(
          children: [
            // -------------------------
            // Banner
            // -------------------------
            Image.network(
              (c.banner != null && c.banner!.isNotEmpty)
                  ? c.banner!
                  : defaultBannerUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 16),

            // -------------------------
            // GLOBAL PADDING STARTS HERE
            // -------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Avatar (zoomable)
                  GestureDetector(
                    onTap: () => _openAvatarFullscreen(c.avatar, context),
                    child: Hero(
                      tag: c.avatar,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(c.avatar),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Role
                  if (c.role != null)
                    Text(
                      c.role!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Badges
                  _buildBadges(c),

                  // Contributions
                  if (c.contributions != null)
                    Text(
                      "${c.contributions} commits",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ABOUT
                  if (c.isCustom && c.about != null && c.about!.isNotEmpty)
                    Text(
                      c.about!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // MESSAGE
                  if (c.isCustom && c.message != null && c.message!.isNotEmpty)
                    Text(
                      c.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ---------------------------------------------------------
                  // SOCIAL LINKS SECTION (Custom only)
                  // ---------------------------------------------------------
                  if (c.isCustom &&
                      ((c.telegram != null && c.telegram!.isNotEmpty) ||
                          (c.discord != null && c.discord!.isNotEmpty)))
                    Column(
                      children: [
                        const Text(
                          "Social Links",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (c.telegram != null &&
                                c.telegram!.isNotEmpty)
                              IconButton(
                                icon: Image.network(
                                  "https://files.catbox.moe/8quut6.png",
                                  width: 32,
                                  height: 32,
                                ),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(c.telegram!),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),

                            if (c.discord != null &&
                                c.discord!.isNotEmpty)
                              IconButton(
                                icon: Image.network(
                                  "https://files.catbox.moe/n69e8g.png",
                                  width: 32,
                                  height: 32,
                                ),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(c.discord!),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),

                  // ---------------------------------------------------------
                  // VIEW PROFILE BUTTON (Premium style)
                  // ---------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(c.profileUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "View Profile",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      context,
    );
  }
}
