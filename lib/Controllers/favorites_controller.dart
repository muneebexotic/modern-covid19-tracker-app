import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FavoritesController extends GetxController {
  final _box = GetStorage();
  final _key = 'favorites';

  RxList<String> favoriteCountries = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  void loadFavorites() {
    List<String> stored = (_box.read(_key) as List<dynamic>?)?.cast<String>() ?? [];
    favoriteCountries.assignAll(stored);
  }

  void toggleFavorite(String countryName) {
    if (favoriteCountries.contains(countryName)) {
      favoriteCountries.remove(countryName);
    } else {
      favoriteCountries.add(countryName);
    }
    _box.write(_key, favoriteCountries.toList());
  }

  bool isFavorite(String countryName) {
    return favoriteCountries.contains(countryName);
  }
}