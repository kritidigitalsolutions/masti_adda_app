import 'package:get/get.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

class DetailController extends GetxController {
  final RxBool isInWatchlist = false.obs;
  final RxInt currentImageIndex = 0.obs;

  final Map<String, dynamic> movie = {
    'title': 'Batman',
    'rating': 4.8,
    'reviews': '12.1k',
    'tags': ['BV', 'Drama', 'Thriller', '2024'],
    'description':
        'A gripping story of power, betrayal and survival. Watch how one man rises from the ashes of his past to reclaim his destiny.',
    'image': 'https://picsum.photos/seed/batman/400/500',
    'backdrop': 'https://picsum.photos/seed/batmanback/800/400',
  };

  final List<Map<String, dynamic>> moreLikeThis = List.generate(
    9,
    (i) => {
      'title': i % 2 == 0 ? 'Squid Game' : 'Scarlett',
      'image': 'https://picsum.photos/seed/more$i/200/300',
    },
  );

  void toggleWatchlist() => isInWatchlist.toggle();
  void onImageChanged(int index) => currentImageIndex.value = index;
  void watchNow() {
    Get.toNamed(
      AppRoutes.videoPlayer,
      arguments: {
        'title': movie['title'],
        'backdrop': movie['backdrop'],
      },
    );
  }
}
