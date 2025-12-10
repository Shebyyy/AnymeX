import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:anymex/models/contributor.dart';

class ContributorController {
  static const gitHubApi =
      "https://api.github.com/repos/RyanYuuki/AnymeX/contributors";

  /// Load custom contributors (local JSON)
  static Future<List<Contributor>> loadCustom() async {
    final jsonStr =
        await rootBundle.loadString("assets/data/custom_contributors.json");

    final data = json.decode(jsonStr);
    return List<Contributor>.from(
      data.map((e) => Contributor.fromCustom(e)),
    );
  }

  /// Load GitHub contributors and filter bots
  static Future<List<Contributor>> loadGitHub() async {
    final res = await http.get(Uri.parse(gitHubApi));

    if (res.statusCode != 200) {
      return [];
    }

    final data = json.decode(res.body);

    return List<Contributor>.from(
      data.map((e) {
        // Fix: contributions sometimes string or null
        if (e["contributions"] != null) {
          e["contributions"] = e["contributions"] is int
              ? e["contributions"]
              : int.tryParse(e["contributions"].toString());
        }
        return Contributor.fromGitHub(e);
      }).where(
        (c) {
          final u = c.username.toLowerCase();

          return !u.contains("bot") &&
              !u.contains("actions") &&
              u != "github-actions" &&
              u != "actions-user" &&
              !u.contains("copilot");
        },
      ),
    );
  }

  /// Merge custom + GitHub contributors
  static Future<List<Contributor>> getContributors() async {
    final custom = await loadCustom();
    final github = await loadGitHub();

    final customUsernames =
        custom.map((c) => c.username.toLowerCase()).toSet();

    final filteredGithub = github.where(
      (c) => !customUsernames.contains(c.username.toLowerCase()),
    );

    return [...custom, ...filteredGithub];
  }
}
