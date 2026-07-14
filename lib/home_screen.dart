import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'models/folder.dart';
import 'models/file_item.dart';
import 'core/theme/colors.dart';
import 'core/widgets/glass_container.dart';
import 'core/widgets/skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _userId;
  List<Folder> _folders = [];
  List<FileItem> _files = [];
  
  List<Folder> _folderStack = [];
  String get currentFolderId => _folderStack.isEmpty ? 'root' : _folderStack.last.id;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    
    final userId = await ApiService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    final parentId = _folderStack.isEmpty ? null : _folderStack.last.id;
    final folderId = _folderStack.isEmpty ? 'root' : _folderStack.last.id;
    
    final folders = await ApiService.getFolders(userId, parentId: parentId);
    final files = await ApiService.getFiles(userId, folderId);
    
    if (mounted) {
      setState(() {
        _userId = userId;
        _folders = folders;
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(FileItem file) async {
    if (_userId == null) return;
    final url = Uri.parse('${ApiService.baseUrl}/download/$_userId/${file.id}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showContextMenu(BuildContext context, {Folder? folder, FileItem? file}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            borderRadius: 24,
            backgroundColor: isDark ? Colors.black.withAlpha(150) : Colors.white.withAlpha(200),
            borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(150),
            blur: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (file != null)
                  ListTile(
                    leading: const Icon(Icons.download_rounded, color: AppColors.primary),
                    title: const Text('Download'),
                    onTap: () {
                      Navigator.pop(context);
                      _downloadFile(file);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(folder: folder, file: file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                  title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(folder: folder, file: file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog({Folder? folder, FileItem? file}) {
    final TextEditingController controller = TextEditingController(text: folder?.name ?? file?.fileName ?? '');
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
                Text('Rename', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
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
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty && _userId != null) {
                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          if (folder != null) {
                            await ApiService.renameFolder(_userId!, folder.id, newName);
                          } else if (file != null) {
                            await ApiService.renameFile(_userId!, file.id, newName);
                          }
                          loadData();
                        }
                      },
                      child: const Text('Save'),
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

  void _showDeleteConfirmation({Folder? folder, FileItem? file}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFolder = folder != null;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            backgroundColor: isDark ? Colors.black.withAlpha(150) : Colors.white.withAlpha(200),
            borderColor: AppColors.error.withAlpha(100),
            blur: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Confirm Deletion', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isFolder 
                    ? 'Are you sure you want to delete the folder "${folder.name}"?\n\nThis will permanently delete ALL files and folders inside it.'
                    : 'Are you sure you want to delete "${file!.fileName}"?',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_userId != null) {
                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          if (folder != null) {
                            await ApiService.deleteFolder(_userId!, folder.id);
                          } else if (file != null) {
                            await ApiService.deleteFile(_userId!, file.id);
                          }
                          loadData();
                        }
                      },
                      child: const Text('Delete'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final folderCrossAxisCount = (width / 180).floor().clamp(2, 6);
    final fileCrossAxisCount = (width / 150).floor().clamp(3, 8);
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icon.png',
                              width: 40,
                              height: 40,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'TeleStore',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ValueListenableBuilder<bool>(
                              valueListenable: ApiService.isConnected,
                              builder: (context, isConnected, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isConnected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_folderStack.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _folderStack.removeLast();
                            });
                            loadData();
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 24,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _folderStack.map((f) => f.name).join(' / '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                if (_isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: folderCrossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Skeleton(),
                        childCount: 6,
                      ),
                    ),
                  )
                else ...[
                  // Folders Section
                  if (_folders.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Folders',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: folderCrossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1, // Perfectly square
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = _folders[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _folderStack.add(folder);
                                });
                                loadData();
                              },
                              onLongPress: () => _showContextMenu(context, folder: folder),
                              onSecondaryTap: () => _showContextMenu(context, folder: folder),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(
                                      Icons.folder_rounded,
                                      size: 40,
                                      color: AppColors.primaryLight,
                                    ),
                                    Text(
                                      folder.name,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _folders.length,
                        ),
                      ),
                    ),
                  ],
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Files Section
                  if (_files.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Files',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: fileCrossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1, // perfectly square
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final file = _files[index];
                            final ext = file.fileName.toLowerCase();
                            final isImage = ext.endsWith('.jpg') || ext.endsWith('.jpeg') || 
                                            ext.endsWith('.png') || ext.endsWith('.gif') || 
                                            ext.endsWith('.webp');
                                            
                            return GestureDetector(
                              onLongPress: () => _showContextMenu(context, file: file),
                              onSecondaryTap: () => _showContextMenu(context, file: file),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isImage && _userId != null)
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '${ApiService.baseUrl}/download/$_userId/${file.id}',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 32,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Expanded(
                                      child: Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 32,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    file.fileName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                          },
                          childCount: _files.length,
                        ),
                      ),
                    ),
                  ],
                  
                  if (_folders.isEmpty && _files.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 64,
                              color: AppColors.grey500.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your storage is empty.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for scrolling
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
