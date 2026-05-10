import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? pageName;
  final String? userName;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final bool isRoot;

  const CommonAppBar({
    super.key,
    this.title = "MediConnect",
    this.pageName,
    this.userName,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBackTap,
    this.onRefresh,
    this.onLogout,
    this.isRoot = false,
  });

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _CommonAppBarState extends State<CommonAppBar> {
  String? _loadedUserName;

  @override
  void initState() {
    super.initState();
    if (widget.userName == null) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loadedUserName = prefs.getString('user_name');
      });
    }
  }

  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return "";
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = theme.appBarTheme.backgroundColor ?? theme.cardColor;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.55);

    String? displayUserName = widget.userName ?? _loadedUserName;
    String displaySubtitle = "";

    if (widget.subtitle != null) {
      displaySubtitle = widget.subtitle!;
    } else if (widget.pageName != null && displayUserName != null) {
      displaySubtitle = "${widget.pageName} • ${_capitalize(displayUserName)}";
    } else if (widget.pageName != null) {
      displaySubtitle = widget.pageName!;
    } else if (displayUserName != null) {
      displaySubtitle = _capitalize(displayUserName);
    }

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: barColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            children: [
              if (!widget.isRoot && (widget.showBackButton || Navigator.canPop(context)))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                  onPressed: widget.onBackTap ?? () => Navigator.pop(context),
                )
              else
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: barColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image.asset(
                      "assets/images/img.png",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.local_hospital, color: primaryColor),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (displaySubtitle.isNotEmpty)
                    // التعديل السحري هنا: FittedBox هتصغر الخط بدل ما تنزل سطر وتبوظ الارتفاع
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displaySubtitle,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Dark / Light mode toggle ──
              _ThemeToggleButton(),
              if (widget.actions != null) ...widget.actions!,
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryColor, size: 20),
                  onPressed: widget.onRefresh,
                ),
              if (widget.onLogout != null)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  onPressed: widget.onLogout,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated sun/moon toggle button that listens directly to [ThemeService].
class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        final isDark = ThemeService().isDarkMode;
        return Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(isDark),
                color: isDark
                    ? const Color(0xFFFBBF24) // amber sun
                    : const Color(0xFF64748B), // slate moon
                size: 20,
              ),
            ),
            onPressed: ThemeService().toggleTheme,
          ),
        );
      },
    );
  }
}