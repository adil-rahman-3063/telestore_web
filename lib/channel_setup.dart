import 'package:flutter/material.dart';
import 'api_service.dart';
import 'core/theme/colors.dart';
import 'main_scaffold.dart';
import 'core/widgets/glass_snackbar.dart';

class ChannelSetupPage extends StatefulWidget {
  const ChannelSetupPage({super.key});

  @override
  State<ChannelSetupPage> createState() => _ChannelSetupPageState();
}

class _ChannelSetupPageState extends State<ChannelSetupPage> {
  final TextEditingController _channelIdController = TextEditingController();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    GlassSnackBar.show(
      context, 
      message, 
      type: isError ? GlassSnackBarType.error : GlassSnackBarType.success,
    );
  }

  void _onSavePressed() async {
    final inputText = _channelIdController.text.trim();
    if (inputText.isEmpty) {
      _showSnackBar('Please enter your Channel ID or paste the JSON', isError: true);
      return;
    }

    // Smart parsing: Extract ID if they pasted the whole JSON
    // Telegram channel IDs always start with -100 followed by numbers.
    String channelId = inputText;
    final regex = RegExp(r'-100\d+');
    final match = regex.firstMatch(inputText);
    
    if (match != null) {
      channelId = match.group(0)!;
    } else if (!inputText.startsWith('-100')) {
      _showSnackBar('Invalid ID. It should start with -100', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final userId = await ApiService.getUserId();
    if (userId == null) {
      _showSnackBar('User not found. Please log in again.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final success = await ApiService.setChannel(userId, channelId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await ApiService.saveChannelId(channelId);
      if (!mounted) return;
      
      _showSnackBar('Storage Channel Linked Successfully!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScaffold()),
      );
    } else {
      _showSnackBar('Failed to save channel. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Link your Storage',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TeleStore uses a private Telegram Channel as your infinite cloud drive.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey800 : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.grey700 : AppColors.primaryLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.looks_one_rounded,
                                  color: isDark ? Colors.white : AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Create a new Private Channel in Telegram.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark ? Colors.white : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.looks_two_rounded,
                                  color: isDark ? Colors.white : AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Add @ShowJsonBot as an Administrator.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark ? Colors.white : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.looks_3_rounded,
                                  color: isDark ? Colors.white : AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'The bot will immediately send a JSON message. Copy that entire message and paste it below!',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark ? Colors.white : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Paste JSON or Channel ID',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _channelIdController,
                        maxLines: 4,
                        minLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste the message from @ShowJsonBot here...',
                          filled: true,
                          fillColor: isDark ? AppColors.grey800 : Colors.white,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSavePressed,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save & Continue'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
