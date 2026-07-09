import 'dart:convert';

import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FaqItem {
  final int id;
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String? ?? 'general',
    );
  }
}

const _faqJsonUrl =
    'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/faq.json';

class SettingsFaq extends StatefulWidget {
  const SettingsFaq({super.key});

  @override
  State<SettingsFaq> createState() => _SettingsFaqState();
}

class _SettingsFaqState extends State<SettingsFaq> {
  List<FaqItem>? _faqItems;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFaq();
  }

  Future<void> _fetchFaq() async {
    try {
      final response = await http.get(Uri.parse(_faqJsonUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final faqList = data['faq'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _faqItems =
                faqList.map((e) => FaqItem.fromJson(e as Map<String, dynamic>)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to fetch FAQ (HTTP ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching FAQ: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showFaqAnswer(BuildContext context, FaqItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: context.colors.outline.opaque(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadow.opaque(0.15),
                blurRadius: 32,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.colors.onSurface.opaque(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.outline.opaque(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: context.colors.onSurface,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.colors.onSurface.opaque(0.7),
                        size: 20,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Markdown(
                  controller: scrollController,
                  data: item.answer,
                  selectable: true,
                  shrinkWrap: false,
                  styleSheet: MarkdownStyleSheet(
                    h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                    h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                    h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                    p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          letterSpacing: 0.2,
                          color: context.colors.onSurface.opaque(0.85),
                        ),
                    listBullet:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.colors.onSurface,
                            ),
                    code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          backgroundColor:
                              context.colors.surfaceContainerHighest,
                          color: context.colors.onSurface,
                        ),
                    blockquote:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: context.colors.onSurface.opaque(0.7),
                            ),
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(Uri.parse(href),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listPadding = getResponsiveValue(context,
        mobileValue: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
        desktopValue: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0));

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'FAQ'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError(listPadding)
                      : _buildFaqList(listPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(EdgeInsets padding) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64,
                color: context.colors.onSurface.opaque(0.15, iReallyMeanIt: true)),
            const SizedBox(height: 16),
            Text(
              'Failed to load FAQ',
              style: TextStyle(
                fontSize: 16,
                color: context.colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.onSurface.opaque(0.35, iReallyMeanIt: true),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchFaq();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqList(EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a question to view the answer',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.onSurface.opaque(0.5, iReallyMeanIt: true),
            ),
          ),
          const SizedBox(height: 16),
          ...(_faqItems ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _FaqTile(
              item: item,
              index: index,
              onTap: () => _showFaqAnswer(context, item),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  final int index;
  final VoidCallback onTap;

  const _FaqTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 12 : 0),
        topRight: Radius.circular(isFirst ? 12 : 0),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: isFirst
                ? BorderSide.none
                : BorderSide(
                    color: context.colors.outline.opaque(0.08),
                  ),
            bottom: BorderSide(
              color: context.colors.outline.opaque(0.08),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface.opaque(0.9),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.colors.onSurface.opaque(0.3),
            ),
          ],
        ),
      ),
    );
  }
}