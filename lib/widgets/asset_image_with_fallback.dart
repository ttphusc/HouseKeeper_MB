import 'package:flutter/material.dart';

class AssetImageWithFallback extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AssetImageWithFallback({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Use a simple Container with an icon for small heights or a more complete message for larger spaces
        final bool isSmallHeight = height != null && height! < 100;

        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: isSmallHeight
              ? Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: (height ?? 24) * 0.6,
                    color: Colors.grey[600],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      if (height == null || height! > 120)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Không tìm thấy hình ảnh',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
