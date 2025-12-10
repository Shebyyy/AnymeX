class Contributor {
  final String username;
  final String name;
  final String? role;
  final String avatar;
  final String? banner;
  final String profileUrl;
  final bool isCustom;

  Contributor({
    required this.username,
    required this.name,
    this.role,
    required this.avatar,
    this.banner,
    required this.profileUrl,
    this.isCustom = false,
  });

  factory Contributor.fromGitHub(Map<String, dynamic> json) {
    return Contributor(
      username: json["login"],
      name: json["login"],
      role: "Contributor",
      avatar: json["avatar_url"],
      profileUrl: json["html_url"],
      isCustom: false,
    );
  }

  factory Contributor.fromCustom(Map<String, dynamic> json) {
    return Contributor(
      username: json["username"],
      name: json["name"],
      role: json["role"],
      avatar: json["avatar"],
      banner: json["banner"],
      profileUrl: json["profileUrl"],
      isCustom: true,
    );
  }
}
