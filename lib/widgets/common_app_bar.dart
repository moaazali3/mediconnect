import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? pageName;
  final String? userName;
  final String? subtitle; // إضافة subtitle مجدداً لدعم الحالات الخاصة مثل التواريخ
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;

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
  });

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(75);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 75,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              children: [
                if (widget.showBackButton || Navigator.canPop(context))
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                    onPressed: widget.onBackTap ?? () => Navigator.pop(context),
                  )
                else
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
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
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (displaySubtitle.isNotEmpty)
                        Text(
                          displaySubtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.actions != null) ...widget.actions!,
                if (widget.onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: primaryColor),
                    onPressed: widget.onRefresh,
                  ),
                if (widget.onLogout != null)
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: widget.onLogout,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
