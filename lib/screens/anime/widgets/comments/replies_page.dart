import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';

class RepliesPage extends StatelessWidget {
  final Media media;
  final String rootCommentId;
  final String rootAuthor;

  const RepliesPage({
    super.key,
    required this.media,
    required this.rootCommentId,
    required this.rootAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(title: 'Replies to $rootAuthor'),
            Expanded(
              child: CommentSection(
                media: media,
                rootCommentId: rootCommentId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
