import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.imgUrl});
  final String? imgUrl;

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
          child: Obx(() {
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  key: controller.imageKey.value,
                  imageUrl: imgUrl ?? "",

                  //  CENTERED LOADER
                  progressIndicatorBuilder: (context, url, progress) {
                    return const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },

                  // ❌ ERROR + RETRY BUTTON
                  errorWidget: (context, url, error) {
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
                  },
                ),

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
          }),
        ),
      ),
    );
  }
}

class ImageSectionController extends GetxController {
  final Rx<Key> imageKey = UniqueKey().obs;

  void retry() {
    imageKey.value = UniqueKey();
  }
}
