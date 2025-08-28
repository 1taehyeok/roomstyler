// lib/features/editor/editor_constants.dart

/// Constants used within the editor feature for consistent sizing and behavior.
class EditorConstants {
  // --- Editor Canvas ---
  /// The base size (width and height) used for calculating furniture item positions and sizes on the canvas.
  static const double itemBaseSize = 100.0;

  // --- Wishlist Panel ---
  /// The height of the wishlist panel when it is open.
  static const double wishlistPanelOpenHeight = 200.0;

  /// The height of the wishlist panel when it is closed.
  static const double wishlistPanelClosedHeight = 0.0;

  /// The animation duration for opening/closing the wishlist panel.
  static const Duration wishlistPanelAnimationDuration = Duration(milliseconds: 300);

  // --- Wishlist Panel Trash Icon ---
  /// The size of the trash icon within the wishlist panel.
  static const double wishlistTrashIconSize = 40.0;

  /// The radius of the trash icon's interactive area for drag-to-delete.
  static const double wishlistTrashIconRadius = wishlistTrashIconSize / 2;

  /// The width of the container holding the trash icon in the wishlist panel.
  static const double wishlistTrashContainerWidth = 50.0;

  /// The height of the container holding the trash icon in the wishlist panel.
  static const double wishlistTrashContainerHeight = 50.0;

  /// The bottom padding for positioning the trash icon container within the wishlist panel.
  static const double wishlistTrashPositionedBottom = 10.0;

  // --- Bottom Button Bar ---
  /// The height of the bottom button bar containing undo/redo/wishlist buttons.
  static const double bottomButtonBarHeight = 60.0;

  /// The vertical offset for positioning the wishlist panel above the bottom button bar.
  static const double wishlistPanelBottomOffset = bottomButtonBarHeight;
}