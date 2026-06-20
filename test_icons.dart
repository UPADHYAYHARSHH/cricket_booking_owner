import 'dart:mirrors';
import 'package:hugeicons/hugeicons.dart';

void main() {
  final classMirror = reflectClass(HugeIcons);
  print('Searching HugeIcons fields...');
  
  final matches = <String>[];
  for (var name in classMirror.staticMembers.keys) {
    final nameStr = MirrorSystem.getName(name);
    if (nameStr.toLowerCase().contains('stadium') || 
        nameStr.toLowerCase().contains('court') || 
        nameStr.toLowerCase().contains('pitch') || 
        nameStr.toLowerCase().contains('ground') ||
        nameStr.toLowerCase().contains('sport') ||
        nameStr.toLowerCase().contains('football') ||
        nameStr.toLowerCase().contains('soccer')) {
      matches.add(nameStr);
    }
  }
  
  print('Matches:');
  for (var match in matches) {
    print('  $match');
  }
}
