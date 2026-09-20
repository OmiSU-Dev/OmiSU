import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/widgets/scraper_content.dart';

/// ScreenScraper login/options when the Scraper tab is hidden (Nordi curated).
class ScraperAccountSettingsScreen extends StatelessWidget {
  const ScraperAccountSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ScraperAccountSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back_rounded, size: 22.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocale.screenscraper.getString(context),
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.r),
        ),
      ),
      body: const SafeArea(child: ScraperContent()),
    );
  }
}
