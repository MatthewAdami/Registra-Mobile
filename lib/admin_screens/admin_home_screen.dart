import 'package:final_project/screens/login_screen.dart';

import 'admin_eventlist_screen.dart';
import 'admin_qrscanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _showSplash = true;
  String adminName = "";

  @override
  void initState() {
    super.initState();
    _showAdminSplash();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        adminName = prefs.getString('fullName') ?? "Admin";
      });
    }
  }

  Future<void> _showAdminSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');
      bool hadRememberMe = savedEmail != null && savedPassword != null;

      await prefs.clear();

      if (hadRememberMe) {
        await prefs.setString('saved_email', savedEmail!);
        await prefs.setString('saved_password', savedPassword!);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Splash ──────────────────────────────────────────────────────────────
    if (_showSplash) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: _AdminSplashBody(),
      );
    }

    // ── Main screen ─────────────────────────────────────────────────────────
    // Use a plain white Scaffold so there is never a black gap anywhere.
    // The gradient is painted via extendBodyBehindAppBar so it runs from the
    // very top of the screen (behind the AppBar) all the way to the bottom.
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Solid white fallback — prevents any black showing through
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Fully transparent so the gradient shows through behind it
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Force dark icons/text for contrast against the light gradient
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Admin Dashboard'),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.account_circle),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      // The gradient Container is the direct child of Scaffold body.
      // Setting height to double.infinity makes it always fill the full screen,
      // even when the scrollable content inside is shorter than the viewport.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDEEEFF), // light blue at top
              Colors.white,      // white at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: _AdminHomeBody(
            adminName: adminName,
            onBuildCard: _buildFeatureCard,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SvgPicture.asset(
                        icon,
                        width: 40,
                        height: 40,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Body extracted so LayoutBuilder gets clean constraints ───────────────────
class _AdminHomeBody extends StatelessWidget {
  final String adminName;
  final Widget Function({
    required String title,
    required String description,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) onBuildCard;

  const _AdminHomeBody({
    required this.adminName,
    required this.onBuildCard,
  });

  @override
  Widget build(BuildContext context) {
    // FIX 2: Use MediaQuery for width — this is the true usable width BEFORE
    // any padding is applied, so we can compute exact card sizes ourselves.
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    // Horizontal padding for the page
    final hPad = screenWidth < 360 ? 16.0 : 24.0;

    // FIX 2 (cont.): Compute card width explicitly.
    // availableWidth = screen - (left pad + right pad)
    // For 2-column grid: each card = (availableWidth - gutter) / 2
    const double gutter = 16.0;
    final int columns = isWide ? 4 : 2;
    final double availableWidth = screenWidth - (hPad * 2);
    final double cardWidth =
        (availableWidth - (gutter * (columns - 1))) / columns;
    // Aspect ratio derived from card width so height is always proportional
    const double cardHeight = 160.0; // fixed comfortable height
    final double cardAspectRatio = cardWidth / cardHeight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome header ──────────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              adminName.isNotEmpty
                  ? 'Welcome, $adminName!'
                  : 'Welcome Back!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your events and scan QR codes',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // ── Feature cards ───────────────────────────────────────────────
          // FIX 2: GridView uses the computed aspect ratio — cards can never
          // exceed the available width.
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            mainAxisSpacing: gutter,
            crossAxisSpacing: gutter,
            childAspectRatio: cardAspectRatio,
            children: [
              onBuildCard(
                title: 'QR Scanner',
                description: 'Scan event QR codes',
                icon: 'assets/images/qr.svg',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminQrscannerScreen(),
                    ),
                  );
                },
              ),
              onBuildCard(
                title: 'Events',
                description: 'View ongoing events',
                icon: 'assets/images/receipt.svg',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminEventlistScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Extra bottom breathing room
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Splash body ──────────────────────────────────────────────────────────────
class _AdminSplashBody extends StatelessWidget {
  const _AdminSplashBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final logoSize = (constraints.maxHeight * 0.18).clamp(80.0, 160.0);
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/icpeplogolatest.svg',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Loading your admin panel...',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}