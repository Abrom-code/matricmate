import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ImageSection extends StatefulWidget {
  const ImageSection({super.key, required this.imgUrl});
  final String? imgUrl;

  @override
  State<ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection> {
  late Future<File?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<File?> _loadImage() async {
    if (widget.imgUrl == null || widget.imgUrl!.isEmpty) return null;

    try {
      final file = await DefaultCacheManager().getSingleFile(widget.imgUrl!);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> retry() async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      ToastHelper.warning('No Internet!');
      return;
    }

    setState(() {
      _imageFuture = _loadImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final isConnected = await NetworkManager.instance.isConnected();

        if (!isConnected) {
          ToastHelper.warning('No Internet!');
          return;
        }

        AppHelperFunctions.showImageZoom(
          context,
          widget.imgUrl ?? '',
          isAssetImage: false,
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<File?>(
            future: _imageFuture, // ✅ cached future (no flicker)
            builder: (context, snapshot) {
              // LOADING
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              // ERROR / NO IMAGE
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: AppColors.darkGrey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Failed to load image',
                        style: TextStyle(color: AppColors.darkGrey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // SUCCESS
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(snapshot.data!, fit: BoxFit.cover),

                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
