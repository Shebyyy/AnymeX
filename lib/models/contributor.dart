class Contributor {
  final String username;
  final String name;
  final String? role;
  final String avatar;
  final String? banner;
  final String profileUrl;
  final bool isCustom;

  // Custom-only fields
  final String? about;
  final String? message;

  // Social links (custom only)
  final String? telegram;
  final String? discord;

  // GitHub fields
  final int? contributions;
  final List<String>? badges;

  Contributor({
    required this.username,
    required this.name,
    this.role,
    required this.avatar,
    this.banner,
    required this.profileUrl,
    this.isCustom = false,
    this.about,
    this.message,
    this.telegram,
    this.discord,
    this.contributions,
    this.badges,
  });

  /// GitHub contributors (API result)
  factory Contributor.fromGitHub(Map<String, dynamic> json) {
    return Contributor(
      username: json["login"],
      name: json["login"],
      role: "Contributor",
      avatar: json["avatar_url"],
      profileUrl: json["html_url"],
      banner: null,
      isCustom: false,

      about: null,
      message: null,

      telegram: null,
      discord: null,

      contributions: json["contributions"],
      badges: ["GitHub Contributor"],
    );
  }

  /// Custom contributors (local JSON)
  factory Contributor.fromCustom(Map<String, dynamic> json) {
    return Contributor(
      username: json["username"],
      name: json["name"],
      role: json["role"],
      avatar: json["avatar"],
      banner: json["banner"],
      profileUrl: json["profileUrl"],
      isCustom: true,

      about: json["about"],
      message: json["message"],

      telegram: json["telegram"],
      discord: json["discord"],

      contributions: null,

      badges: json["badges"] != null
          ? List<String>.from(json["badges"])
          : null,
    );
  }
}
