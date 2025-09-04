import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/state/wishlist_provider.dart';
import 'package:roomstyler/features/catalog/cart_state.dart'; // Import cart state

class FurnitureDetailScreen extends ConsumerStatefulWidget {
  final String furnitureId;
  const FurnitureDetailScreen({super.key, required this.furnitureId});

  @override
  ConsumerState<FurnitureDetailScreen> createState() => _FurnitureDetailScreenState();
}

class _FurnitureDetailScreenState extends ConsumerState<FurnitureDetailScreen> {
  Furniture? _furniture;
  bool _isLoading = true;
  String? _selectedColor;
  String? _selectedSize; // e.g., 'S', 'M', 'L' or custom dimensions
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadFurniture();
  }

  Future<void> _loadFurniture() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('furnitures')
          .doc(widget.furnitureId)
          .get();

      if (doc.exists) {
        setState(() {
          _furniture = Furniture.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          _isLoading = false;
          // Set default selections if options are available
          // For simplicity, we'll assume color and size are stored as lists in the Furniture model
          // You might need to adjust this based on your actual data structure
          // e.g., _selectedColor = _furniture?.availableColors?.first;
          // e.g., _selectedSize = _furniture?.availableSizes?.first;
        });
      } else {
        // Handle furniture not found
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가구 정보를 찾을 수 없습니다.')),
          );
          context.pop(); // Go back if furniture not found
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가구 정보 로드 중 오류가 발생했습니다: $e')),
        );
        context.pop();
      }
    }
  }

  void _addToCart() {
    if (_furniture == null) return;

    // Prepare selected options map
    final selectedOptions = <String, dynamic>{};
    if (_selectedColor != null) selectedOptions['color'] = _selectedColor;
    if (_selectedSize != null) selectedOptions['size'] = _selectedSize;

    // Generate a unique ID for the cart item
    final cartItemId = CartItem.generateId(_furniture!.id, selectedOptions);

    // Add to cart using the CartNotifier
    ref.read(cartProvider.notifier).addItem(
      CartItem(
        id: cartItemId, // Pass the generated ID
        furnitureId: _furniture!.id,
        name: _furniture!.name,
        imageUrl: _furniture!.imageUrl,
        price: _furniture!.price,
        selectedOptions: selectedOptions,
        quantity: _quantity,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_furniture!.name}이(가) 장바구니에 추가되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_furniture?.name ?? '가구 상세'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _furniture == null
              ? const Center(child: Text('가구 정보를 불러올 수 없습니다.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Image
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: CachedNetworkImage(
                          imageUrl: _furniture!.imageUrl ?? '',
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Product Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _furniture!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${NumberFormat('#,##0').format(_furniture!.price)}원',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            // Description
                            const Text('제품 설명', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _furniture!.material.isNotEmpty
                                  ? '소재: ${_furniture!.material}'
                                  : '소재 정보가 없습니다.',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '색상: ${_furniture!.color.isNotEmpty ? _furniture!.color : '색상 정보가 없습니다.'}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '치수: ${_furniture!.width} x ${_furniture!.depth} x ${_furniture!.height} cm',
                            ),
                            const SizedBox(height: 16),
                            // Options (Color)
                            // For simplicity, we'll use a dropdown. In a real app, you might use chips or swatches.
                            // You would need to define availableColors in your Furniture model.
                            // This is a placeholder implementation.
                            /*
                            const Text('색상 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: _selectedColor,
                              hint: const Text('색상 선택'),
                              isExpanded: true,
                              items: _furniture?.availableColors?.map((color) {
                                return DropdownMenuItem(
                                  value: color,
                                  child: Text(color),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedColor = newValue;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Options (Size)
                            const Text('사이즈 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: _selectedSize,
                              hint: const Text('사이즈 선택'),
                              isExpanded: true,
                              items: _furniture?.availableSizes?.map((size) {
                                return DropdownMenuItem(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSize = newValue;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            */
                            // Quantity Selector
                            const Text('수량', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _quantity > 1
                                      ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text('$_quantity'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Wishlist Button
                            Consumer(
                              builder: (context, ref, child) {
                                final wishlist = ref.watch(wishlistProvider);
                                final isWishlisted = wishlist.any((item) => item.id == _furniture!.id);
                                return IconButton(
                                  icon: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    color: isWishlisted ? Colors.red : null,
                                  ),
                                  onPressed: () {
                                    ref.read(wishlistProvider.notifier).toggleItem(_furniture!.id);
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Add to Wishlist if not already
                                  final wishlist = ref.read(wishlistProvider);
                                  final isWishlisted = wishlist.any((item) => item.id == _furniture!.id);
                                  if (!isWishlisted) {
                                    ref.read(wishlistProvider.notifier).toggleItem(_furniture!.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('찜 목록에 추가되었습니다.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('이미 찜한 제품입니다.')),
                                    );
                                  }
                                },
                                child: const Text('찜하기'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: _addToCart,
                                child: const Text('장바구니에 담기'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}