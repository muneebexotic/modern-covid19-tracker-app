import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _box.read(_key) ?? false;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _box.write(_key, isDarkMode.value);
  }
}