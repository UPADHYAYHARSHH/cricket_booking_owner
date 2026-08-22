import 'dart:async';
import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/widgets/app_network_image.dart';

class GroundImageCarousel extends StatefulWidget {
  final List<String> images;
  final String fallbackImageUrl;
  final double height;
  final BorderRadius? borderRadius;
  final bool showGradient;
  final bool allowFullScreen;

  const GroundImageCarousel({
    super.key,
    required this.images,
    required this.fallbackImageUrl,
    this.height = 160,
    this.borderRadius,
    this.showGradient = true,
    this.allowFullScreen = false,
  });

  @override
  State<GroundImageCarousel> createState() => _GroundImageCarouselState();
}

class _GroundImageCarouselState extends State<GroundImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final imageCount = widget.images.isNotEmpty ? widget.images.length : 1;
      if (imageCount > 1 && _pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= imageCount) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.images.isNotEmpty
        ? widget.images
        : [
            widget.fallbackImageUrl.isNotEmpty
                ? widget.fallbackImageUrl
                : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e"
          ];

    return Stack(
      children: [
        // Image Slider
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: widget.allowFullScreen ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => _FullScreenImageViewer(
                          images: displayImages,
                          initialIndex: index,
                        ),
                      ),
                    );
                  } : null,
                  child: AppNetworkImage(
                    imageUrl: displayImages[index],
                    height: widget.height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ),

        // Dark Gradient Overlay for better visibility of indicator and badges
        if (widget.showGradient)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // Center Dot Indicator
        if (displayImages.length > 1)
          Positioned(
            bottom: 12,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentPage == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      if (_currentPage == index)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: AppNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }
}
