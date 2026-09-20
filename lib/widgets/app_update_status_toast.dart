import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/app_update_availability_service.dart';
import 'package:omisu/services/update_service.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:omisu/widgets/update_dialog.dart';

/// Toast-style banner under the top status HUD when a GitHub APK update exists.
class AppUpdateStatusToast extends StatefulWidget {
  const AppUpdateStatusToast({super.key});

  @override
  State<AppUpdateStatusToast> createState() => _AppUpdateStatusToastState();
}

class _AppUpdateStatusToastState extends State<AppUpdateStatusToast>
    with SingleTickerProviderStateMixin {
  final _service = AppUpdateAvailabilityService.instance;
  late final AnimationController _slide;
  UpdateInfo? _shown;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _service.available.addListener(_onAvailabilityChanged);
    _service.uiTick.addListener(_onAvailabilityChanged);
    _syncFromService();
  }

  @override
  void dispose() {
    _service.available.removeListener(_onAvailabilityChanged);
    _service.uiTick.removeListener(_onAvailabilityChanged);
    _slide.dispose();
    super.dispose();
  }

  void _onAvailabilityChanged() {
    _syncFromService();
  }

  void _syncFromService() {
    final info = _service.available.value;
    final visible = info != null && _service.isBannerVisible;
    if (visible) {
      setState(() => _shown = info);
      _slide.forward();
    } else {
      _slide.reverse().then((_) {
        if (mounted && !_service.isBannerVisible) {
          setState(() => _shown = null);
        }
      });
    }
  }

  Future<void> _openUpdateDialog() async {
    final info = _shown;
    if (info == null || !mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shown == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final labelStyle = omisuRetroLabelStyle(context, size: 10);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic),
          ),
      child: FadeTransition(
        opacity: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openUpdateDialog,
            borderRadius: BorderRadius.circular(4.r),
            child: Container(
              constraints: BoxConstraints(maxWidth: 280.r),
              padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.55),
                  width: 1.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.r),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.system_update_alt,
                    size: 18.r,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 8.r),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocale.updateAvailable.getString(context),
                          style: labelStyle.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _shown!.latestVersion,
                          style: labelStyle.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.r),
                  InkWell(
                    onTap: () {
                      _service.dismissBanner();
                      _syncFromService();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Symbols.close,
                        size: 16.r,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
