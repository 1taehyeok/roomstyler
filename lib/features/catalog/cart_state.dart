import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Cart Item Model ---
class CartItem {
  final String id; // Unique ID for the cart item (can be furnitureId + options hash)
  final String furnitureId;
  final String name;
  final String? imageUrl;
  final double price;
  final Map<String, dynamic> selectedOptions;
  final int quantity;

  CartItem({
    required this.id,
    required this.furnitureId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.selectedOptions,
    required this.quantity,
  });

  // Generate a unique ID based on furnitureId and selected options
  static String generateId(String furnitureId, Map<String, dynamic> options) {
    // Sort options by key to ensure consistent ID generation regardless of option order
    final sortedOptions = Map<String, dynamic>.fromEntries(
      options.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    final buffer = StringBuffer();
    sortedOptions.forEach((key, value) {
      buffer.write('$key:$value|'); // Use a delimiter that is unlikely to be in keys/values
    });

    // Remove trailing delimiter by creating a new string
    String optionsString = buffer.toString();
    if (optionsString.endsWith('|') && optionsString.length > 1) { // Check length to avoid empty string error
      optionsString = optionsString.substring(0, optionsString.length - 1);
    }

    // Simple hash generation for demo purposes.
    // Consider using a more robust method like a cryptographic hash for production.
    final optionsHash = optionsString.hashCode;

    return '$furnitureId-$optionsHash';
  }

  // Factory constructor from Firestore data
  // Note: The 'id' is not stored in Firestore and will be generated on load
  factory CartItem.fromJson(Map<String, dynamic> json) {
    final furnitureId = json['furniture_id'] as String? ?? '';
    final selectedOptions = Map<String, dynamic>.from(json['selected_options'] ?? {});
    final id = CartItem.generateId(furnitureId, selectedOptions); // Generate ID on load

    return CartItem(
      id: id, // Use the generated ID
      furnitureId: furnitureId,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      selectedOptions: selectedOptions,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  // Convert to JSON for Firestore (excluding the 'id' field)
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Exclude 'id' field
      'furniture_id': furnitureId,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'selected_options': selectedOptions,
      'quantity': quantity,
    };
  }

  // CopyWith for easy updates
  CartItem copyWith({
    String? id,
    String? furnitureId,
    String? name,
    String? imageUrl,
    double? price,
    Map<String, dynamic>? selectedOptions,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      furnitureId: furnitureId ?? this.furnitureId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      quantity: quantity ?? this.quantity,
    );
  }
}

// --- Cart Notifier ---
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _loadCart();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Load cart from Firestore
  Future<void> _loadCart() async {
    final user = _auth.currentUser;
    if (user == null) {
      // If not logged in, cart remains empty or could use local storage
      // For simplicity, we'll keep it empty for now.
      // You could integrate shared_preferences for local cart persistence.
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).collection('cart').doc('items').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['items'] is List) {
          final List<CartItem> items = (data['items'] as List)
              .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList();
          state = items;
        }
      }
    } catch (e) {
      // Handle error, e.g., log it
      debugPrint("Error loading cart from Firestore: $e");
    }
  }

  // Save cart to Firestore
  Future<void> _saveCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('cart').doc('items').set({
        'items': state.map((item) => item.toJson()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error
      debugPrint("Error saving cart to Firestore: $e");
    }
  }

  // Add item to cart
  void addItem(CartItem newItem) {
    final existingIndex = state.indexWhere((item) => item.id == newItem.id);
    if (existingIndex >= 0) {
      // If item with same ID (furniture + options) exists, update quantity
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + newItem.quantity)
          else
            state[i]
      ];
    } else {
      // Add new item
      state = [...state, newItem];
    }
    // Save to Firestore
    _saveCart();
  }

  // Update item quantity
  void updateItemQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(quantity: newQuantity)
        else
          item
    ];
    _saveCart();
  }

  // Remove item from cart
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
    _saveCart();
  }

  // Clear cart
  void clear() {
    state = [];
    _saveCart();
  }

  // Calculate total price
  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
}

// --- Cart Provider ---
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});