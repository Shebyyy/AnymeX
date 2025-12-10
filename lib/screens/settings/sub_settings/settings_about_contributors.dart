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

              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(c.avatar)),
                title: Text(c.name),
                subtitle: Text(c.role ?? "Contributor"),
                onTap: () => _openContributor(c),
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
  //  FULLSCREEN AVATAR (ZOOMABLE)
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
  //  Contributor Popup Sheet
  // ---------------------------------------------------------
  void _openContributor(Contributor c) {
    AnymexSheet.custom(
      SingleChildScrollView(
        child: Column(
          children: [
            // Banner
            Image.network(
              (c.banner != null && c.banner!.isNotEmpty)
                  ? c.banner!
                  : defaultBannerUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 16),

            // Avatar → Fullscreen zoom on tap
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
            ),

            // Role
            if (c.role != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  c.role!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

            // Badges
            _buildBadges(c),

            // GitHub commits
            if (c.contributions != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "${c.contributions} commits",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ABOUT
            if (c.isCustom && c.about != null && c.about!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  c.about!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // MESSAGE
            if (c.isCustom && c.message != null && c.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  c.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Open Profile Button
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    final url = Uri.parse(c.profileUrl);
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "View Profile",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      context,
    );
  }
}
