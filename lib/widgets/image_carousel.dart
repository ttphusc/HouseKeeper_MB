import 'dart:async';
import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageList;
  final double height;
  final BoxFit fit;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final BorderRadius? borderRadius;
  final Function(int)? onPageChanged;
  final double viewportFraction;

  const ImageCarousel({
    Key? key,
    required this.imageList,
    this.height = 200.0,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.borderRadius,
    this.onPageChanged,
    this.viewportFraction = 1.0,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.imageList.length - 1) {
          _pageController.nextPage(
            duration: widget.autoPlayAnimationDuration,
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: widget.autoPlayAnimationDuration,
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount:
                widget.imageList.length > 0 ? widget.imageList.length : 3,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index);
              }
            },
            itemBuilder: (context, index) {
              if (widget.imageList.isEmpty) {
                // Show placeholder if no images
                return _buildPlaceholder(index);
              }

              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                  child: Image.asset(
                    widget.imageList[index],
                    fit: widget.fit,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                          "Error loading image: ${widget.imageList[index]} - $error");
                      return _buildPlaceholder(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              widget.imageList.length > 0 ? widget.imageList.length : 3,
              (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFF46DFB1)
                    : Colors.grey.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(int index) {
    // Banner colors for placeholders
    final List<Color> bannerColors = [
      Color(0xFF46DFB1),
      Color(0xFF15919B),
      Color(0xFF9BE6D7),
    ];

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Container(
          color: bannerColors[index % bannerColors.length],
          child: Center(
            child: Icon(
              Icons.home,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
