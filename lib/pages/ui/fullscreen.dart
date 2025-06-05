import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImage extends StatelessWidget {
  final ImageProvider imageProvider;

  const FullScreenImage({super.key, required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),

          // PhotoView with initial square appearance but full zoom potential
          Center(
            child: Container(
              width: screenWidth,
              height: screenWidth, // Start as a square
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight, // Important to allow zoom beyond square
                  child: PhotoView(
                    imageProvider: imageProvider,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    initialScale: PhotoViewComputedScale.covered, // Fill square initially
                    minScale: PhotoViewComputedScale.covered, // Stay within square at minimum
                    maxScale: PhotoViewComputedScale.covered * 3.0, // Zoom beyond screen
                  ),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}