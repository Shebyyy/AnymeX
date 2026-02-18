import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AnilistAboutMe extends StatefulWidget {
  final String about;

  const AnilistAboutMe({super.key, required this.about});

  @override
  State<AnilistAboutMe> createState() => _AnilistAboutMeState();
}

class _AnilistAboutMeState extends State<AnilistAboutMe> {
  late final WebViewController _controller;
  bool isLoading = true;
  late String processedContent;

  String _generateHtml() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background color based on theme
    final bgColor = isDark ? '#1e1e2e' : '#f5f5f5';
    final textColor = isDark ? '#ffffff' : '#000000';
    final linkColor = isDark ? '#89b4fa' : '#1e88e5';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Poppins', sans-serif;
            background-color: $bgColor;
            color: $textColor;
            margin: 0;
            padding: 16px;
            font-size: 14px;
            line-height: 1.6;
        }
        
        a {
            color: $linkColor;
            text-decoration: none;
            font-weight: 500;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            display: block;
            margin: 8px 0;
        }
        
        /* Spoiler styling */
        .spoiler {
            margin: 12px 0;
            border: 1px solid ${isDark ? '#313244' : '#e0e0e0'};
            border-radius: 12px;
            overflow: hidden;
            background-color: ${isDark ? '#313244' : '#fafafa'};
        }
        
        .spoiler-button {
            background: none;
            border: none;
            width: 100%;
            padding: 12px 16px;
            text-align: left;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            color: ${isDark ? '#cdd6f4' : '#666666'};
            font-style: italic;
            font-weight: 500;
            font-size: 14px;
        }
        
        .spoiler-button:hover {
            background-color: ${isDark ? '#45475a' : '#f0f0f0'};
        }
        
        .spoiler-button svg {
            width: 16px;
            height: 16px;
            fill: currentColor;
        }
        
        .spoiler-content {
            padding: 16px;
            border-top: 1px solid ${isDark ? '#45475a' : '#e0e0e0'};
            background-color: ${isDark ? '#1e1e2e' : '#ffffff'};
        }
        
        .spoiler-close {
            float: right;
            background: none;
            border: none;
            cursor: pointer;
            padding: 8px;
            color: ${isDark ? '#cdd6f4' : '#666666'};
        }
        
        .spoiler-close:hover {
            opacity: 0.7;
        }
        
        /* Clear fix */
        .clearfix::after {
            content: "";
            clear: both;
            display: table;
        }
        
        /* YouTube embed */
        .youtube-embed {
            margin: 12px 0;
            border-radius: 12px;
            overflow: hidden;
            position: relative;
            cursor: pointer;
        }
        
        .youtube-embed img {
            width: 100%;
            display: block;
            margin: 0;
        }
        
        .youtube-play {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 60px;
            height: 60px;
            background-color: #ff0000;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .youtube-play svg {
            width: 30px;
            height: 30px;
            fill: white;
            margin-left: 4px;
        }
        
        /* Headers */
        h1, h2, h3, h4, h5, h6 {
            color: ${isDark ? '#ffffff' : '#000000'};
            margin-top: 16px;
            margin-bottom: 8px;
            font-weight: 600;
        }
        
        /* Blockquotes */
        blockquote {
            margin: 12px 0;
            padding: 8px 16px;
            background-color: ${isDark ? '#313244' : '#f5f5f5'};
            border-left: 4px solid ${isDark ? '#89b4fa' : '#1e88e5'};
            border-radius: 0 8px 8px 0;
        }
        
        /* Code blocks */
        pre {
            background-color: ${isDark ? '#313244' : '#f5f5f5'};
            padding: 12px;
            border-radius: 8px;
            overflow-x: auto;
        }
        
        code {
            font-family: 'Courier New', monospace;
            font-size: 13px;
        }
        
        /* Tables */
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 12px 0;
        }
        
        th, td {
            border: 1px solid ${isDark ? '#45475a' : '#e0e0e0'};
            padding: 8px;
            text-align: left;
        }
        
        th {
            background-color: ${isDark ? '#313244' : '#f5f5f5'};
        }
        
        /* Lists */
        ul, ol {
            padding-left: 20px;
            margin: 8px 0;
        }
        
        li {
            margin: 4px 0;
        }
        
        /* Horizontal rule */
        hr {
            border: none;
            border-top: 1px solid ${isDark ? '#45475a' : '#e0e0e0'};
            margin: 16px 0;
        }
    </style>
    <script>
        // Spoiler handling
        function toggleSpoiler(id) {
            const content = document.getElementById('spoiler-' + id);
            const button = document.getElementById('spoiler-btn-' + id);
            
            if (content.style.display === 'none' || !content.style.display) {
                content.style.display = 'block';
                button.innerHTML = \`
                    <svg viewBox="0 0 24 24">
                        <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                    </svg>
                    <span>Spoiler — tap to hide</span>
                \`;
            } else {
                content.style.display = 'none';
                button.innerHTML = \`
                    <svg viewBox="0 0 24 24">
                        <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                    </svg>
                    <span>Spoiler — tap to reveal</span>
                \`;
            }
        }
        
        // YouTube click handler
        function openYouTube(id) {
            window.location.href = 'https://www.youtube.com/watch?v=' + id;
        }
        
        // Link click handler
        document.addEventListener('click', function(e) {
            const link = e.target.closest('a');
            if (link && link.href) {
                e.preventDefault();
                window.location.href = link.href;
            }
        });
    </script>
</head>
<body>
    {{CONTENT}}
</body>
</html>
    ''';
  }

  String _preprocessAbout(String raw) {
    var c = raw;

    // Clean up zero-width spaces and other invisible characters
    c = c
        .replaceAll('\u200e', '')
        .replaceAll('\u200f', '')
        .replaceAll('\u200b', '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .replaceAll('\u034f', '')
        .replaceAll('&lrm;', '')
        .replaceAll('&rlm;', '')
        .replaceAll('&#8206;', '')
        .replaceAll('&#8207;', '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll('&thinsp;', '')
        .replaceAll('&emsp;', '')
        .replaceAll('&ensp;', '');

    // Convert imgN(url) to img tags
    c = c.replaceAllMapped(
      RegExp(r'img(\d+)\(([^)]+)\)'),
      (m) => '<img src="${m[2] ?? ''}" width="${m[1] ?? ''}px" style="max-width: ${m[1] ?? '100'}px;">',
    );

    // Convert youtube(url) to YouTube embed
    c = c.replaceAllMapped(
      RegExp(r'youtube\(([^)]+)\)'),
      (m) {
        final raw = (m[1] ?? '').trim();
        final uri = Uri.tryParse(raw);
        final id = uri?.queryParameters['v'] ?? raw;
        return '''
        <div class="youtube-embed" onclick="openYouTube('$id')">
            <img src="https://img.youtube.com/vi/$id/hqdefault.jpg" alt="YouTube video">
            <div class="youtube-play">
                <svg viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z"/>
                </svg>
            </div>
        </div>
        ''';
      },
    );

    // Convert webm(url) to video links
    c = c.replaceAllMapped(
      RegExp(r'webm\(([^)]+)\)'),
      (m) => '<a href="${(m[1] ?? '').trim()}">▶ View video</a>',
    );

    // Convert markdown links [text](url)
    c = c.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '<a href="${m[2] ?? ''}">${m[1] ?? ''}</a>',
    );

    // Handle spoilers with unique IDs
    int spoilerCounter = 0;
    c = c.replaceAllMapped(
      RegExp(r'~!([\s\S]*?)!~'),
      (m) {
        spoilerCounter++;
        final content = m[1] ?? '';
        final id = spoilerCounter;
        return '''
        <div class="spoiler">
            <button id="spoiler-btn-$id" class="spoiler-button" onclick="toggleSpoiler($id)">
                <svg viewBox="0 0 24 24">
                    <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                </svg>
                <span>Spoiler — tap to reveal</span>
            </button>
            <div id="spoiler-$id" class="spoiler-content" style="display: none;">
                $content
            </div>
        </div>
        ''';
      },
    );

    // Handle ~~~ center tags
    c = c.replaceAllMapped(
      RegExp(r'~~~([\s\S]*?)~~~'),
      (m) => '<div style="text-align:center;">${m[1] ?? ''}</div>',
    );
    
    c = c.replaceAllMapped(
      RegExp(r'<center>([\s\S]*?)</center>', caseSensitive: false),
      (m) => '<div style="text-align:center;">${m[1] ?? ''}</div>',
    );

    // Handle align attributes
    c = c.replaceAllMapped(
      RegExp(
        r'<(div|p)(\s[^>]*)?\salign=(["\x27])(\w+)\3([^>]*)>',
        caseSensitive: false,
      ),
      (m) {
        final tag = m[1] ?? 'div';
        final before = m[2] ?? '';
        final align = m[4] ?? 'left';
        final after = m[5] ?? '';
        if (before.contains('style=') || after.contains('style=')) {
          return '<$tag$before$after>';
        }
        return '<$tag$before style="text-align:$align;"$after>';
      },
    );

    // Handle div spoilers
    c = c.replaceAllMapped(
      RegExp(r'<div\s+rel=["\x27]spoiler["\x27][^>]*>([\s\S]*?)</div>',
          caseSensitive: false),
      (m) {
        spoilerCounter++;
        final content = m[1] ?? '';
        final id = spoilerCounter;
        return '''
        <div class="spoiler">
            <button id="spoiler-btn-$id" class="spoiler-button" onclick="toggleSpoiler($id)">
                <svg viewBox="0 0 24 24">
                    <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
                </svg>
                <span>Spoiler — tap to reveal</span>
            </button>
            <div id="spoiler-$id" class="spoiler-content" style="display: none;">
                $content
            </div>
        </div>
        ''';
      },
    );
    
    // If no HTML tags, convert markdown to HTML
    final hasHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(c);
    if (!hasHtml) {
      c = _mdToHtml(c);
    }

    return c;
  }

  String _mdToHtml(String md) {
    final lines = md.split('\n');
    final buffer = StringBuffer();
    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      
      // Skip if already HTML
      if (RegExp(r'^<(div|p|h[1-6]|ul|ol|li|blockquote|br|hr|pre|spoiler|youtube)',
              caseSensitive: false)
          .hasMatch(line)) {
        buffer.writeln(line);
        continue;
      }
      
      // Convert markdown to HTML
      line = line
          .replaceAllMapped(RegExp(r'\*\*\*(.*?)\*\*\*'),
              (m) => '<strong><em>${m[1]}</em></strong>')
          .replaceAllMapped(
              RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>')
          .replaceAllMapped(RegExp(r'_(.*?)_'), (m) => '<em>${m[1]}</em>')
          .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => '<em>${m[1]}</em>')
          .replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => '<del>${m[1]}</del>')
          .replaceAllMapped(
              RegExp(r'`(.*?)`'), (m) => '<code>${m[1]}</code>')
          .replaceAllMapped(
              RegExp(r'^#{5}\s+(.+)$'), (m) => '<h5>${m[1]}</h5>')
          .replaceAllMapped(
              RegExp(r'^#{4}\s+(.+)$'), (m) => '<h4>${m[1]}</h4>')
          .replaceAllMapped(
              RegExp(r'^#{3}\s+(.+)$'), (m) => '<h3>${m[1]}</h3>')
          .replaceAllMapped(
              RegExp(r'^#{2}\s+(.+)$'), (m) => '<h2>${m[1]}</h2>')
          .replaceAllMapped(
              RegExp(r'^#\s+(.+)$'), (m) => '<h1>${m[1]}</h1>');
      
      // Horizontal rules
      if (RegExp(r'^(-{3,}|\*{3,}|(\s*-\s*){3,}|(\s*\*\s*){3,})$')
          .hasMatch(line)) {
        buffer.writeln('<hr>');
        continue;
      }
      
      // Bullet lists
      if (RegExp(r'^[-*+]\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^[-*+]\s+'), '');
        buffer.writeln('<ul><li>$text</li></ul>');
        continue;
      }
      
      // Numbered lists
      if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');
        buffer.writeln('<ol><li>$text</li></ol>');
        continue;
      }
      
      // Blockquote
      if (line.startsWith('&gt;') || line.startsWith('>')) {
        final text = line
            .replaceFirst(RegExp(r'^&gt;\s*'), '')
            .replaceFirst(RegExp(r'^>\s*'), '');
        buffer.writeln('<blockquote>$text</blockquote>');
        continue;
      }
      
      if (RegExp(r'^<h[1-6]>').hasMatch(line)) {
        buffer.writeln(line);
      } else {
        buffer.writeln('<p>$line</p>');
      }
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    processedContent = _preprocessAbout(widget.about);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => isLoading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://www.youtube.com/watch')) {
              launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith('http')) {
              launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final html = _generateHtml().replaceFirst('{{CONTENT}}', processedContent);
      _controller.loadHtmlString(html);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (isLoading)
          Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
