/// `00-12-30` style stamp used in clip file names.
String formatClipStamp(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}-${two(d.inMinutes.remainder(60))}-${two(d.inSeconds.remainder(60))}';
}

String _sanitize(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
  return cleaned;
}

/// Builds a safe file name such as `One_Piece_EP5_00-12-30.mp4`.
String clipFileName({
  required String title,
  required String episode,
  required Duration start,
  required String extension,
  int maxTitleLength = 60,
}) {
  var t = _sanitize(title);
  if (t.length > maxTitleLength) t = t.substring(0, maxTitleLength);
  if (t.isEmpty) t = 'Clip';
  final ep = _sanitize(episode);
  final epPart = ep.isEmpty ? '' : '_EP$ep';
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  return '$t${epPart}_${formatClipStamp(start)}.$ext';
}
