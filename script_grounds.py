import re

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/screens/grounds/grounds_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'final ground =\s*state\.grounds\[index\] as Map<String, dynamic>;\s*return _StaggeredGroundCard\(\s*index: index,\s*child: Padding\(\s*padding: const EdgeInsets\.only\(\s*bottom: AppSizes\.lg,\s*\),\s*child: GroundCard\(\s*ground: ground,\s*onEdit: \(\) => _openEditFlow\(ground\),\s*onAvailabilityChanged: \(value\) => context\s*\.read<GroundCubit>\(\)\s*\.setGroundAvailability\(\s*ground\[\'id\'\] as String,\s*value,\s*locationId: _selectedLocationId,\s*\),\s*\),\s*\),\s*\);'

replacement = r'''final ground = state.grounds[index] as Map<String, dynamic>;
                          
                          // Extract images from location
                          List<String> locImages = [];
                          if (_selectedLocationId != null && locations.isNotEmpty) {
                            try {
                              final loc = locations.firstWhere((l) => l['id'] == _selectedLocationId);
                              if (loc['location_images'] != null) {
                                final imgs = loc['location_images'] as List;
                                locImages = imgs.map((e) => e['image_url'].toString()).toList();
                              }
                            } catch (_) {}
                          }

                          return _StaggeredGroundCard(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.lg,
                              ),
                              child: GroundCard(
                                ground: ground,
                                images: locImages,
                                onEdit: () => _openEditFlow(ground),
                                onAvailabilityChanged: (value) => context
                                    .read<GroundCubit>()
                                    .setGroundAvailability(
                                      ground['id'] as String,
                                      value,
                                      locationId: _selectedLocationId,
                                    ),
                              ),
                            ),
                          );'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/screens/grounds/grounds_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
