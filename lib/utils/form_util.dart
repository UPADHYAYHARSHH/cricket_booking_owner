import 'package:flutter/material.dart';

class FormUtil {
  /// Walks the Element tree starting from the given [context] to find the first
  /// [FormFieldState] that has a validation error, and scrolls to its render object.
  static void scrollToError(BuildContext context) {
    Element? errorElement;

    void findErrorElement(Element element) {
      if (errorElement != null) return; // Already found the first error field

      if (element is StatefulElement && element.state is FormFieldState) {
        final state = element.state as FormFieldState;
        if (state.hasError) {
          errorElement = element;
          return;
        }
      }
      element.visitChildren(findErrorElement);
    }

    context.visitChildElements(findErrorElement);

    if (errorElement != null) {
      Scrollable.ensureVisible(
        errorElement!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2, // Align the field slightly below the top of the viewport
      );
    }
  }
}
