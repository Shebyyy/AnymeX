import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/utils/performance.dart';

/// Enhanced novel reader with comprehensive features
class EnhancedNovelReader extends StatefulWidget {
  final NovelReaderController controller;
  
  const EnhancedNovelReader({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<EnhancedNovelReader> createState() => _EnhancedNovelReaderState();
}

class _EnhancedNovelReaderState extends State<EnhancedNovelReader> 
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearchMode = false;
  List<int> _searchResults = [];
  int _currentSearchIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update reading progress based on scroll position
    if (widget.controller.scrollController.hasClients) {
      final offset = widget.controller.scrollController.offset;
      final maxScroll = widget.controller.scrollController.position.maxScrollExtent;
      
      if (maxScroll > 0) {
        final progress = offset / maxScroll;
        widget.controller.progress.value = progress;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _buildContent(),
          _buildTopControls(),
          _buildBottomControls(),
          if (_isSearchMode) _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() => GestureDetector(
      onTap: () => widget.controller.toggleControls(),
      onDoubleTap: () => _toggleFullscreen(),
      child: Container(
        color: _getBackgroundColor(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.05,
                vertical: Get.height * 0.02,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildNovelContent(),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNovelContent() {
    return Obx(() {
      if (widget.controller.loadingState.value == LoadingState.loading) {
        return _buildLoadingView();
      }
      
      if (widget.controller.loadingState.value == LoadingState.error) {
        return _buildErrorView();
      }
      
      return _buildTextContent();
    });
  }

  Widget _buildTextContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: SelectionArea(
        child: _buildStyledText(),
      ),
    );
  }

  Widget _buildStyledText() {
    return Obx(() => Text(
      widget.controller.novelContent.value,
      style: TextStyle(
        fontSize: widget.controller.fontSize.value,
        height: widget.controller.lineHeight.value,
        letterSpacing: widget.controller.letterSpacing.value,
        wordSpacing: widget.controller.wordSpacing.value,
        fontFamily: _getFontFamily(),
        color: _getTextColor(),
      ),
      textAlign: widget.controller.textAlignment,
    ));
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading novel content...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load novel content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your internet connection and try again.',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnymeXButton(
            text: 'Retry',
            onPressed: () => widget.controller.fetchData(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.controller.showControls.value ? 80 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: widget.controller.showControls.value
          ? _buildTopControlsContent()
          : const SizedBox.shrink(),
    ));
  }

  Widget _buildTopControlsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildBackButton(),
          const Spacer(),
          _buildChapterInfo(),
          const Spacer(),
          _buildSearchButton(),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.controller.showControls.value ? 100 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: widget.controller.showControls.value
          ? _buildBottomControlsContent()
          : const SizedBox.shrink(),
    ));
  }

  Widget _buildBottomControlsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavigationButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: () => _scrollToTop(),
          ),
          _buildNavigationButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: () => _scrollToBottom(),
          ),
          _buildProgressButton(),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildChapterInfo() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chapter ${widget.controller.currentChapter.value.number}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.controller.currentChapter.value.title ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ));
  }

  Widget _buildSearchButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () => _toggleSearch(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: PopupMenuButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'bookmark',
            child: const Text('Bookmark'),
            onTap: () => _addBookmark(),
          ),
          PopupMenuItem(
            value: 'share',
            child: const Text('Share'),
            onTap: () => _shareContent(),
          ),
          PopupMenuItem(
            value: 'export',
            child: const Text('Export'),
            onTap: () => _exportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildProgressButton() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(widget.controller.progress.value * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  Widget _buildSettingsButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () => _showSettings(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search in chapter...',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              onChanged: (value) => _performSearch(value),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _toggleSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _searchResults.isEmpty
          ? const Center(
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildSearchResultItem(index);
              },
            ),
    );
  }

  Widget _buildSearchResultItem(int index) {
    return ListTile(
      leading: const Icon(Icons.search, color: Colors.white),
      title: Text(
        'Result ${index + 1}',
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () => _goToSearchResult(index),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.controller.themeMode.value) {
      case 0: // Light
        return Colors.white;
      case 1: // Dark
        return Colors.black87;
      case 2: // Sepia
        return const Color(0xFFF4E8D0);
      default:
        return Colors.white;
    }
  }

  Color _getTextColor() {
    switch (widget.controller.themeMode.value) {
      case 0: // Light
        return Colors.black87;
      case 1: // Dark
        return Colors.white;
      case 2: // Sepia
        return Colors.black87;
      default:
        return Colors.black87;
    }
  }

  String _getFontFamily() {
    switch (widget.controller.fontFamily.value) {
      case 'Roboto':
        return 'Roboto';
      case 'Open Sans':
        return 'OpenSans';
      case 'Lato':
        return 'Lato';
      case 'Merriweather':
        return 'Merriweather';
      case 'Crimson Text':
        return 'Crimson Text';
      case 'Libre Baskerville':
        return 'Libre Baskerville';
      default:
        return 'System';
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchResults.clear();
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }
    
    // Simple search implementation
    final content = widget.controller.novelContent.value.toLowerCase();
    final searchQuery = query.toLowerCase();
    
    _searchResults.clear();
    int index = content.indexOf(searchQuery);
    while (index != -1) {
      _searchResults.add(index);
      index = content.indexOf(searchQuery, index + 1);
    }
  }

  void _goToSearchResult(int index) {
    if (index < _searchResults.length) {
      _scrollController.animateTo(
        _searchResults[index].toDouble(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleFullscreen() {
    // Implement fullscreen toggle
  }

  void _addBookmark() {
    // Implement bookmark functionality
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      const SnackBar(content: 'Bookmark saved'),
    );
  }

  void _shareContent() {
    // Implement share functionality
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      const SnackBar(content: 'Share functionality coming soon'),
    );
  }

  void _exportContent() {
    // Implement export functionality
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      const SnackBar(content: 'Export functionality coming soon'),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: _scaffoldKey.currentContext!,
      isScrollControlled: true,
      builder: (context) => _buildSettingsPanel(context),
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildSettingsHeader(context),
          Expanded(child: _buildSettingsContent(context)),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined),
          const SizedBox(width: 12),
          Text(
            'Reading Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFontSettings(context),
          const SizedBox(height: 24),
          _buildThemeSettings(context),
          const SizedBox(height: 24),
          _buildLayoutSettings(context),
        ],
      ),
    );
  }

  Widget _buildFontSettings(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          title: 'Font Size',
          value: widget.controller.fontSize.value,
          min: 12.0,
          max: 24.0,
          onChanged: (value) => widget.controller.fontSize.value = value,
        ),
        _buildSliderTile(
          title: 'Line Height',
          value: widget.controller.lineHeight.value,
          min: 1.2,
          max: 2.0,
          onChanged: (value) => widget.controller.lineHeight.value = value,
        ),
        _buildFontSelector(context),
      ],
    ));
  }

  Widget _buildThemeSettings(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildThemeChip('Light', 0),
            _buildThemeChip('Dark', 1),
            _buildThemeChip('Sepia', 2),
          ],
        ),
      ],
    ));
  }

  Widget _buildLayoutSettings(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          title: 'Background Opacity',
          value: widget.controller.backgroundOpacity.value,
          min: 0.3,
          max: 1.0,
          onChanged: (value) => widget.controller.backgroundOpacity.value = value,
        ),
      ],
    ));
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFontSelector(BuildContext context) {
    return Obx(() => DropdownButtonFormField<String>(
      value: widget.controller.fontFamily.value,
      decoration: const InputDecoration(
        labelText: 'Font Family',
        border: OutlineInputBorder(),
      ),
      items: widget.controller.availableFonts.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(font),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          widget.controller.fontFamily.value = value;
        }
      },
    ));
  }

  Widget _buildThemeChip(String label, int value) {
    return Obx(() => FilterChip(
      label: Text(label),
      selected: widget.controller.themeMode.value == value,
      onSelected: () => widget.controller.themeMode.value = value,
      backgroundColor: widget.controller.themeMode.value == value
          ? Theme.of(Get.context!).primaryColor.withOpacity(0.2)
          : null,
    ));
  }
}