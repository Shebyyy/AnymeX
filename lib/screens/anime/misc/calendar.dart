class BlurAnimeCard extends StatefulWidget {
  final Media data;

  const BlurAnimeCard({super.key, required this.data});

  @override
  State<BlurAnimeCard> createState() => _BlurAnimeCardState();
}

class _BlurAnimeCardState extends State<BlurAnimeCard> {
  RxInt timeLeft = 0.obs;

  @override
  void initState() {
    super.initState();
    timeLeft.value = widget.data.nextAiringEpisode?.timeUntilAiring ?? 0;
    if (timeLeft.value > 0) startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (timeLeft.value > 0) {
          timeLeft.value--;
        } else {
          timer.cancel();
        }
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds <= 0) {
      return 'Aired Already';
    } else {
      int days = seconds ~/ (24 * 3600);
      seconds %= 24 * 3600;
      int hours = seconds ~/ 3600;
      seconds %= 3600;
      int minutes = seconds ~/ 60;
      seconds %= 60;

      List<String> parts = [];
      if (days > 0) parts.add("$days days");
      if (hours > 0) parts.add("$hours hours");
      if (minutes > 0) parts.add("$minutes minutes");
      if (seconds > 0 || parts.isEmpty) parts.add("$seconds seconds");

      return parts.join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(
            () => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.primary)),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: widget.data.cover ?? widget.data.poster,
                radius: 0,
                width: double.infinity,
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: Blur(
                  blur: 4,
                  blurColor: Colors.transparent,
                  child: Container(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkSizedImage(
                  width: getResponsiveSize(context,
                      mobileSize: 120, desktopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 150, desktopSize: 180),
                  radius: 0,
                  imageUrl: widget.data.poster,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 10, desktopSize: 30)),
                        AnymexText(
                          text: widget.data.nextAiringEpisode != null
                              ? "Episode ${widget.data.nextAiringEpisode!.episode}"
                              : "Airing Soon",
                          size: 14,
                          maxLines: 2,
                          color: Theme.of(context).colorScheme.primary,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        AnymexText(
                          text: widget.data.title,
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Obx(() {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AnymexText(
                    text: formatTime(timeLeft.value),
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                    variant: TextVariant.bold,
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
