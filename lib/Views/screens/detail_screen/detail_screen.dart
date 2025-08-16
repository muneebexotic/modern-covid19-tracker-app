import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:covid19_tracker_flutter/Controllers/detail_controller.dart';
import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/country_header.dart';
import 'widgets/overview_tab.dart';
import 'widgets/trends_tab.dart';
import 'widgets/vaccination_tab.dart';
import 'package:covid19_tracker_flutter/Services/vaccination_service.dart';
import 'package:covid19_tracker_flutter/Utils/app_strings.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';

/// The DetailScreen now uses GetX for the controller.
/// It expects a [CountryDetail] instance passed via arguments or constructor.
class DetailScreen extends StatefulWidget {
  final CountryDetail countryDetail;

  const DetailScreen({Key? key, required this.countryDetail}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DetailController controller;
  final FavoritesController favoritesController =
      Get.find<FavoritesController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    controller = DetailController(
      vaccinationService: VaccinationService(),
      countryDetail: widget.countryDetail,
    );
    // If you use GetX dependency injection you can do: Get.put(controller)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header (flag, name, actions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Obx(
                () => CountryHeader(
                  countryName: widget.countryDetail.name,
                  flagUrl: widget.countryDetail.flagUrl,
                  onBack: () => Navigator.of(context).pop(),
                  onShare: () {
                    final text = controller.buildShareText();
                    Share.share(text);
                  },
                  isFavorite: favoritesController.isFavorite(
                    widget.countryDetail.name,
                  ),
                  onToggleFavorite: () => favoritesController.toggleFavorite(
                    widget.countryDetail.name,
                  ),
                  riskLevel: controller.riskLevel,
                  riskColor: controller.riskColor(context),
                ),
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // slightly smaller text
                  ),
                  labelPadding: const EdgeInsets.symmetric(vertical: 6),
                  indicatorSize: TabBarIndicatorSize.tab, // pill fills full tab
                  tabs: const [
                    Tab(text: AppStrings.overview),
                    Tab(text: AppStrings.trends),
                    Tab(text: AppStrings.vaccination),
                  ],
                ),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(
                    countryDetail: widget.countryDetail,
                    controller: controller,
                  ),
                  TrendsTab(
                    countryDetail: widget.countryDetail,
                    controller: controller,
                  ),
                  VaccinationTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// small helper extension to let short lambda usage (avoids import)
extension _Let<T> on T {
  R let<R>(R Function(T it) op) => op(this);
}
