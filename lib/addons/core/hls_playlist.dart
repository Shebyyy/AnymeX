/// Minimal HLS playlist model, just enough to cut a time range out of a VOD
/// stream: segment list with durations, AES-128 keys and fMP4 init maps.
class HlsKey {
  final String method; // NONE | AES-128 | SAMPLE-AES ...
  final Uri? uri;
  final String? ivHex; // 0x... as written in the playlist

  const HlsKey({required this.method, this.uri, this.ivHex});

  bool get isAes128 => method == 'AES-128';
}

class HlsSegment {
  final Uri uri;
  final double duration;

  /// Start offset from the beginning of the playlist, in seconds.
  final double start;
  final int mediaSequence;
  final HlsKey? key;
  final Uri? initUri; // EXT-X-MAP
  final bool hasByteRange;

  const HlsSegment({
    required this.uri,
    required this.duration,
    required this.start,
    required this.mediaSequence,
    this.key,
    this.initUri,
    this.hasByteRange = false,
  });

  double get end => start + duration;
}

class HlsVariant {
  final Uri uri;
  final int bandwidth;
  const HlsVariant(this.uri, this.bandwidth);
}

class HlsMediaPlaylist {
  final List<HlsSegment> segments;
  final bool isVod;
  const HlsMediaPlaylist(this.segments, {required this.isVod});

  double get totalDuration => segments.isEmpty ? 0 : segments.last.end;
}

bool isMasterPlaylist(String text) => text.contains('#EXT-X-STREAM-INF');

final RegExp _attr = RegExp(r'([A-Z0-9-]+)=("[^"]*"|[^,]*)');

Map<String, String> _parseAttributes(String s) {
  final out = <String, String>{};
  for (final m in _attr.allMatches(s)) {
    var v = m.group(2)!;
    if (v.startsWith('"') && v.endsWith('"')) v = v.substring(1, v.length - 1);
    out[m.group(1)!] = v;
  }
  return out;
}

List<HlsVariant> parseMasterPlaylist(String text, Uri base) {
  final lines = text.split(RegExp(r'\r?\n'));
  final out = <HlsVariant>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
    final attrs = _parseAttributes(line.substring('#EXT-X-STREAM-INF:'.length));
    final bw = int.tryParse(attrs['BANDWIDTH'] ?? '') ?? 0;
    for (var j = i + 1; j < lines.length; j++) {
      final next = lines[j].trim();
      if (next.isEmpty || next.startsWith('#')) continue;
      out.add(HlsVariant(base.resolve(next), bw));
      break;
    }
  }
  return out;
}

HlsMediaPlaylist parseMediaPlaylist(String text, Uri base) {
  final lines = text.split(RegExp(r'\r?\n'));
  var mediaSequence = 0;
  var isVod = false;
  HlsKey? key;
  Uri? init;
  double? pendingDuration;
  var pendingByteRange = false;
  var clock = 0.0;
  final segments = <HlsSegment>[];
  var index = 0;

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
      mediaSequence =
          int.tryParse(line.substring('#EXT-X-MEDIA-SEQUENCE:'.length)) ?? 0;
    } else if (line.startsWith('#EXT-X-PLAYLIST-TYPE:')) {
      isVod = line.contains('VOD');
    } else if (line.startsWith('#EXT-X-ENDLIST')) {
      isVod = true;
    } else if (line.startsWith('#EXT-X-KEY:')) {
      final a = _parseAttributes(line.substring('#EXT-X-KEY:'.length));
      final method = a['METHOD'] ?? 'NONE';
      key = method == 'NONE'
          ? null
          : HlsKey(
              method: method,
              uri: a['URI'] == null ? null : base.resolve(a['URI']!),
              ivHex: a['IV'],
            );
    } else if (line.startsWith('#EXT-X-MAP:')) {
      final a = _parseAttributes(line.substring('#EXT-X-MAP:'.length));
      if (a['URI'] != null) init = base.resolve(a['URI']!);
    } else if (line.startsWith('#EXTINF:')) {
      final v = line.substring('#EXTINF:'.length).split(',').first;
      pendingDuration = double.tryParse(v.trim());
    } else if (line.startsWith('#EXT-X-BYTERANGE:')) {
      pendingByteRange = true;
    } else if (!line.startsWith('#')) {
      final d = pendingDuration;
      if (d == null) continue;
      segments.add(
        HlsSegment(
          uri: base.resolve(line),
          duration: d,
          start: clock,
          mediaSequence: mediaSequence + index,
          key: key,
          initUri: init,
          hasByteRange: pendingByteRange,
        ),
      );
      clock += d;
      index++;
      pendingDuration = null;
      pendingByteRange = false;
    }
  }
  return HlsMediaPlaylist(segments, isVod: isVod);
}

/// Segments that overlap `[startSec, endSec)`.
List<HlsSegment> selectSegments(
  HlsMediaPlaylist playlist,
  double startSec,
  double endSec,
) {
  return playlist.segments
      .where((s) => s.end > startSec && s.start < endSec)
      .toList();
}

/// Rewrites every URI of a playlist (segment lines plus `URI="..."`
/// attributes of EXT-X-KEY / EXT-X-MAP / EXT-X-MEDIA ...) through [map].
/// Relative URIs are resolved against [base] first.
String rewritePlaylistUris(
  String text,
  Uri base,
  String Function(Uri absolute) map,
) {
  final uriAttr = RegExp(r'URI="([^"]*)"');
  final out = <String>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trimRight();
    if (line.isEmpty) {
      out.add(line);
    } else if (line.startsWith('#')) {
      out.add(
        line.replaceAllMapped(uriAttr, (m) {
          final abs = base.resolve(m.group(1)!);
          return 'URI="${map(abs)}"';
        }),
      );
    } else {
      out.add(map(base.resolve(line.trim())));
    }
  }
  return out.join('\n');
}
