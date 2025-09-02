// lib/features/my_page/my_projects_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MyProjectsScreen extends ConsumerStatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  ConsumerState<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends ConsumerState<MyProjectsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedProjectIds = {}; // Store selected document IDs
  
  // Separate the data state from UI state
  List<String> _featuredProjectIds = []; // Store featured project IDs from Firestore
  List<QueryDocumentSnapshot> _orderedDocuments = []; // Store ordered documents
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('내 프로젝트'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    // Start listening to data streams
    _listenToDataStreams(user.uid);
    
    // Build the main UI with the processed data
    // The UI will rebuild when setState is called due to UI state changes
    return Scaffold(
      appBar: _buildAppBar(), // Use a separate method for AppBar
      body: _buildBody(), // Use a separate method for body
    );
  }
  
  // Listen to data streams and update state
  void _listenToDataStreams(String userId) {
    // Fetch user's featured project IDs
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userSnapshot) {
          if (userSnapshot.exists) {
            final userData = userSnapshot.data() as Map<String, dynamic>?;
            final newFeaturedProjectIds = List<String>.from(
                userData?['featuredProjects'] as List<dynamic>? ?? []);
            
            // Only update if the data has changed
            if (!_listsEqual(_featuredProjectIds, newFeaturedProjectIds)) {
              setState(() {
                _featuredProjectIds = newFeaturedProjectIds;
                // Re-order documents if projects are already loaded
                if (_orderedDocuments.isNotEmpty) {
                  _orderedDocuments = _reorderDocuments(_orderedDocuments, _featuredProjectIds);
                }
              });
            }
          } else {
             if (_featuredProjectIds.isNotEmpty) {
               setState(() {
                 _featuredProjectIds = [];
                 // Re-order documents if projects are already loaded
                 if (_orderedDocuments.isNotEmpty) {
                   _orderedDocuments = _reorderDocuments(_orderedDocuments, _featuredProjectIds);
                 }
               });
             }
          }
        }, onError: (error) {
          setState(() {
            _errorMessage = '사용자 데이터 로드 중 오류: $error';
          });
        });

    // Fetch projects
    FirebaseFirestore.instance
        .collection('scenes')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((projectsSnapshot) {
          setState(() {
            _errorMessage = null;
          });
          
          final documents = projectsSnapshot.docs;
          final orderedDocs = _reorderDocuments(documents, _featuredProjectIds);
          
          setState(() {
            _orderedDocuments = orderedDocs;
          });
        }, onError: (error) {
          setState(() {
            _errorMessage = '프로젝트 데이터 로드 중 오류: $error';
          });
        });
  }
  
  // Helper method to reorder documents
  List<QueryDocumentSnapshot> _reorderDocuments(List<QueryDocumentSnapshot> documents, List<String> featuredIds) {
    // Create a map for quick access to documents by ID
    final docMap = {for (var doc in documents) doc.id: doc};

    // Reorder documents: featured first (in order), then the rest by created_at
    final List<QueryDocumentSnapshot> orderedDocuments = [];
    
    // Add featured projects in order
    for (String id in featuredIds) {
      if (docMap.containsKey(id)) {
        orderedDocuments.add(docMap[id]!);
      }
    }
    
    // Add non-featured projects
    for (var doc in documents) {
      if (!featuredIds.contains(doc.id)) {
        orderedDocuments.add(doc);
      }
    }
    
    return orderedDocuments;
  }
  
  // Helper method to compare lists
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Separate AppBar building logic
  AppBar _buildAppBar() {
    return AppBar(
      title: _isSelectionMode
          ? Text('${_selectedProjectIds.length}개 선택됨')
          : const Text('내 프로젝트'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: _isSelectionMode
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _selectedProjectIds.isNotEmpty
                    ? _confirmDeleteSelected
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _enterSelectionMode,
              ),
            ],
    );
  }
  
  // Separate body building logic
  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    
    if (_orderedDocuments.isEmpty) {
      // Check if data is still loading
      // For simplicity, we assume if there's no error and no data, it's loading
      // A more robust solution would track loading state separately
      if (_featuredProjectIds.isEmpty) {
         return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('저장된 프로젝트가 없습니다.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: _orderedDocuments.length,
      itemBuilder: (context, index) {
        final doc = _orderedDocuments[index];
        final scene = Scene.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
        final isFeatured = _featuredProjectIds.contains(doc.id);
        
        return _ProjectCard(
          scene: scene,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedProjectIds.contains(doc.id),
          isFeatured: isFeatured,
          onSelect: () => _toggleSelection(doc.id),
          onTap: () {
            // Navigate to editor with this scene when not in selection mode
            if (!_isSelectionMode) {
              ref.read(currentSceneProvider.notifier).state = scene;
              context.push('/editor', extra: scene.roomId);
            }
          },
          onToggleFeature: () => _toggleFeatured(FirebaseAuth.instance.currentUser!.uid, doc.id, isFeatured),
          onEdit: () {
            ref.read(currentSceneProvider.notifier).state = scene;
            context.push('/editor', extra: scene.roomId);
          },
          onDelete: () => _confirmDelete(context, doc.id, scene),
          onShare: () {
            ref.read(currentSceneProvider.notifier).state = scene;
            context.push('/preview');
          },
          onRename: (newName) => _renameProject(doc.id, newName),
        );
      },
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedProjectIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProjectIds.clear();
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedProjectIds.contains(docId)) {
        _selectedProjectIds.remove(docId);
      } else {
        _selectedProjectIds.add(docId);
      }
    });
  }

  Future<void> _toggleFeatured(String userId, String docId, bool isCurrentlyFeatured) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Check if the user document exists, if not, create it
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        await userDocRef.set({
          'featuredProjects': [],
          // Add other user fields as needed
        });
      }
      
      if (isCurrentlyFeatured) {
        // Remove from featured
        await userDocRef.update({
          'featuredProjects': FieldValue.arrayRemove([docId])
        });
      } else {
        // Add to featured
        await userDocRef.update({
          'featuredProjects': FieldValue.arrayUnion([docId])
        });
      }
      
      // No need to manually update _featuredProjectIds or _orderedDocuments
      // The stream listener will handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('홈 화면 고정 설정 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로젝트 삭제'),
          content: Text('선택한 ${_selectedProjectIds.length}개의 프로젝트를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (String docId in _selectedProjectIds) {
          batch.delete(FirebaseFirestore.instance.collection('scenes').doc(docId));
        }
        await batch.commit();
        
        if (mounted) {
          _exitSelectionMode(); // Exit selection mode after deletion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선택한 프로젝트가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, String docId, Scene scene) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로젝트 삭제'),
          content: Text(
              '정말 "${_getDisplayName(scene)}" 프로젝트를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('scenes').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로젝트가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _renameProject(String docId, String newName) async {
    if (newName.trim().isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('scenes').doc(docId).update({
        'custom_name': newName.trim(),
      });
    } catch (e) {
      debugPrint('이름 변경 중 오류 발생: $e');
    }
  }

  String _getDisplayName(Scene scene) {
    if (scene.customName != null && scene.customName!.isNotEmpty) {
      return scene.customName!;
    }
    return scene.id == 'temp'
        ? '임시 프로젝트'
        : '프로젝트 #${scene.id.substring(0, 8)}';
  }
}

class _ProjectCard extends StatefulWidget {
  final Scene scene;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isFeatured;
  final VoidCallback onSelect;
  final VoidCallback onTap; // Add onTap callback
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onToggleFeature;
  final Function(String) onRename;

  const _ProjectCard({
    required this.scene,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isFeatured,
    required this.onSelect,
    required this.onTap, // Add onTap to constructor
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onToggleFeature,
    required this.onRename,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _getDisplayName());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getDisplayName() {
    if (widget.scene.customName != null &&
        widget.scene.customName!.isNotEmpty) {
      return widget.scene.customName!;
    }
    return widget.scene.id == 'temp'
        ? '임시 프로젝트'
        : '프로젝트 #${widget.scene.id.substring(0, 8)}';
  }

  Future<void> _showRenameDialog() async {
    _nameController.text = _getDisplayName();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로젝트 이름 변경'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "새 이름 입력"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  widget.onRename(_nameController.text.trim());
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('yyyy-MM-dd').format(widget.scene.createdAt);

    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: widget.isSelectionMode ? widget.onSelect : widget.onTap,
            onLongPress: widget.isSelectionMode
                ? null
                : () {
                    // Show a bottom sheet with options
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('이름 변경'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showRenameDialog();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.share),
                                title: const Text('공유'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onShare();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  widget.isFeatured
                                      ? Icons.star
                                      : Icons.star_border,
                                  color:
                                      widget.isFeatured ? Colors.yellow : null,
                                ),
                                title: Text(widget.isFeatured
                                    ? '홈 화면에서 고정 해제'
                                    : '홈 화면에 고정'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onToggleFeature();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete,
                                    color: Colors.red),
                                title: const Text('삭제',
                                    style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onDelete();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.image, size: 32, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${widget.scene.layout.length} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: widget.onEdit,
                            tooltip: '편집',
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: widget.onShare,
                            tooltip: '공유',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          if (widget.isFeatured)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 16, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}