import 'package:flutter/material.dart';
import 'package:anymex/widgets/comments/comments_widget.dart';

class CommentsExamplePage extends StatelessWidget {
  const CommentsExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Example 1: Anime comments
            Container(
              margin: const EdgeInsets.all(16),
              child: CommentsWidget(
                mediaId: '12345', // AniList anime ID
                mediaType: 'anime',
                mediaTitle: 'Attack on Titan',
              ),
            ),
            
            // Example 2: Manga comments
            Container(
              margin: const EdgeInsets.all(16),
              child: CommentsWidget(
                mediaId: '67890', // AniList manga ID
                mediaType: 'manga',
                mediaTitle: 'One Piece',
              ),
            ),
            
            // Example 3: Novel comments
            Container(
              margin: const EdgeInsets.all(16),
              child: CommentsWidget(
                mediaId: '11111', // AniList novel ID
                mediaType: 'novel',
                mediaTitle: 'Light Novel Example',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of using comments in a modal/dialog
class CommentsModal extends StatelessWidget {
  final String mediaId;
  final String mediaType;
  final String mediaTitle;

  const CommentsModal({
    Key? key,
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(
                    'Comments - $mediaTitle',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
            const Divider(),
            
            // Comments content
            Expanded(
              child: CommentsWidget(
                mediaId: mediaId,
                mediaType: mediaType,
                mediaTitle: mediaTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of how to show comments modal
void showCommentsModal(
  BuildContext context, {
  required String mediaId,
  required String mediaType,
  required String mediaTitle,
}) {
  showDialog(
    context: context,
    builder: (context) => CommentsModal(
      mediaId: mediaId,
      mediaType: mediaType,
      mediaTitle: mediaTitle,
    ),
  );
}