import re

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/widgets/ground_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add the import if not exists
if "import 'ground_image_carousel.dart';" not in content and "import 'package:turfpro_owner/owner_booking/presentation/widgets/ground_image_carousel.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:turfpro_owner/owner_booking/presentation/widgets/ground_image_carousel.dart';")

pattern = r'imageUrl != null.*?_ImagePlaceholder\(name: name, category: category\),'

replacement = r'''GroundImageCarousel(
                    images: images,
                    fallbackImageUrl: imageUrl ?? '',
                    height: 180,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusXl),
                    ),
                  ),'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/widgets/ground_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
