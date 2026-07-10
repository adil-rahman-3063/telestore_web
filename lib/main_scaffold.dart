import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'core/theme/colors.dart';
import 'core/theme/typography.dart';
import 'core/widgets/glass_container.dart';
import 'core/widgets/upload_progress_dialog.dart';
import 'core/widgets/glass_snackbar.dart';
import 'api_service.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0; // 0: Home, 1: Profile
  bool _isAnimating = false;
  
  // Track physical states: 0 = Front, 1 = Back, 2 = Pulled Up
  int _homeState = 0; 
  int _profileState = 1;

  void _onAddFilePressed() async {
    // allowMultiple: true for multi-file selection
    // withData: kIsWeb grabs bytes in memory on Web, but prevents Out-Of-Memory crashes on Android
    FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true, withData: kIsWeb);
    
    if (result != null && result.files.isNotEmpty && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) return;
      
      final String folderId = homeScreenKey.currentState?.currentFolderId ?? 'root';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UploadProgressDialog(
          files: result.files,
          userId: userId,
          folderId: folderId,
          onComplete: (bool hasError) {
            homeScreenKey.currentState?.loadData();
            if (hasError) {
              GlassSnackBar.show(context, 'Some files failed to upload.', type: GlassSnackBarType.error);
            } else {
              GlassSnackBar.show(context, 'All files uploaded successfully!', type: GlassSnackBarType.success);
            }
          },
        ),
      );
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            backgroundColor: isDark ? Colors.black.withAlpha(150) : Colors.white.withAlpha(200),
            borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(150),
            blur: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Folder', style: AppTypography.h2),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Folder Name',
                    filled: true,
                    fillColor: isDark ? Colors.black.withAlpha(50) : Colors.white.withAlpha(150),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.grey600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(context);
                          
                          // Get user ID
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('user_id');
                          if (userId != null) {
                            final String folderId = homeScreenKey.currentState?.currentFolderId ?? 'root';
                            final String? parentId = folderId == 'root' ? null : folderId;
                            
                            final success = await ApiService.createFolder(userId, name, parentId: parentId);
                            if (success) {
                              homeScreenKey.currentState?.loadData();
                            }
                          }
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePage() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    // STEP 1: Pull the front card UP
    setState(() {
      if (_currentIndex == 0) {
        _homeState = 2; // Pull Home up
      } else {
        _profileState = 2; // Pull Profile up
      }
    });

    // Wait for the pull up animation
    await Future.delayed(const Duration(milliseconds: 250));

    // STEP 2: Swap the active index (changes page), swap z-order, and drop into place
    setState(() {
      _currentIndex = _currentIndex == 0 ? 1 : 0;
      
      if (_currentIndex == 0) {
        _homeState = 0; // Home is now Front
        _profileState = 1; // Profile goes to Back
      } else {
        _profileState = 0; // Profile is now Front
        _homeState = 1; // Home goes to Back
      }
    });

    // Wait for the drop animation
    await Future.delayed(const Duration(milliseconds: 350));
    setState(() => _isAnimating = false);
  }

  double _getBottomOffset(int state) {
    if (state == 0) return 0.0;    // Front
    if (state == 1) return 24.0;   // Back
    return 80.0;                   // Pulled Up
  }

  double _getScale(int state) {
    if (state == 0) return 1.0;    // Front
    if (state == 1) return 0.88;   // Back
    return 1.0;                    // Pulled Up (remains full size until it drops)
  }

  double _getOpacity(int state) {
    if (state == 0) return 1.0;    // Front
    if (state == 1) return 0.6;    // Back
    return 1.0;                    // Pulled Up
  }

  @override
  Widget build(BuildContext context) {
    // Determine stack order: the card that is NOT going to be the new front should be painted first (in the back)
    // Actually, if a card is Pulled Up (2), it should be painted ON TOP of the Back card, but when dropping to back, it should go behind.
    // The simplest way to handle Z-order: the FRONT card is painted last. 
    // If pulling up, it was front, so it paints last.
    // When it drops to back, the NEW front card paints last.
    final bool homeIsFront = _homeState == 0 || _homeState == 2;

    return Scaffold(
      body: Stack(
        children: [
          // The background screens (Animated)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _currentIndex == 0
                ? HomeScreen(key: homeScreenKey)
                : const ProfileScreen(key: ValueKey('profile')),
          ),
          
          // The Stacked Floating Nav Bar
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 140, // Expanded height to allow for the "Pull Up" animation
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // LEFT ACTION (Add File) - Only visible on Home
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    bottom: 0,
                    left: _currentIndex == 0 ? 24 : -80, // Slides off-screen when on Profile
                    child: _buildSideAction(Icons.upload_file_rounded, _onAddFilePressed),
                  ),
                  
                  // RIGHT ACTION (Add Folder) - Only visible on Home
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    bottom: 0,
                    right: _currentIndex == 0 ? 24 : -80, // Slides off-screen when on Profile
                    child: _buildSideAction(Icons.create_new_folder_rounded, () {
                      _showCreateFolderDialog(context);
                    }),
                  ),

                  // THE CENTER PILLS
                  GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 50) {
                        _togglePage();
                      }
                    },
                    onTap: _togglePage,
                    child: SizedBox(
                      width: 200, // Constrain width of the tap area
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // PAINT FIRST (BACKGROUND)
                          if (homeIsFront) _buildAnimatedCard(1, _profileState) else _buildAnimatedCard(0, _homeState),
                          
                          // PAINT SECOND (FOREGROUND)
                          if (homeIsFront) _buildAnimatedCard(0, _homeState) else _buildAnimatedCard(1, _profileState),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSideAction(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 100, // Circular
        backgroundColor: isDark ? Colors.black.withAlpha(60) : Colors.white.withAlpha(80),
        borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(120),
        blur: 20.0,
        child: Icon(
          icon,
          color: isDark ? Colors.white : AppColors.primaryDark,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, int cardState) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _getBottomOffset(cardState),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        scale: _getScale(cardState),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _getOpacity(cardState),
          child: _buildPill(index),
        ),
      ),
    );
  }

  Widget _buildPill(int index) {
    final isHome = index == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 100, // fully pill shaped
      backgroundColor: isDark ? Colors.black.withAlpha(60) : Colors.white.withAlpha(80),
      borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(120),
      blur: 20.0, // Increased blur for more glass effect
      child: SizedBox(
        width: 180, // Reduced width to fit the side circles
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHome ? Icons.home_rounded : Icons.person_rounded,
              color: isDark ? Colors.white : AppColors.primaryDark,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              isHome ? 'Homepage' : 'Profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
