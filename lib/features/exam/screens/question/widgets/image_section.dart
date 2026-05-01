import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.imgUrl});
  final String? imgUrl;

  Future<File?> _loadImage() async {
    if (imgUrl == null || imgUrl!.isEmpty) return null;

    try {
      final file = await DefaultCacheManager().getSingleFile(imgUrl!);
      return file;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageSectionController(), tag: imgUrl);

    return GestureDetector(
      onTap: () => AppHelperFuntions.showImageZoom(
        context,
        imgUrl ?? "",
        isAssetImage: false,
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<File?>(
            future: _loadImage(),
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
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Failed to load image",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: controller.retry,
                        child: const Text("Retry"),
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

                  // zoom icon
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
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

class ImageSectionController extends GetxController {
  Future<void> retry() async {
    final isConnected = await NetworkManager.instance.hasRealInternet();

    if (!isConnected) {
      ToastHelper.warning("No Internet!");
      return;
    }

    // force rebuild by updating tag-based dependency
    update();
  }
}
