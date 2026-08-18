import 'package:flutter/material.dart';

/// A purchasable/cosmetic color palette for vehicles. Skins only change
/// vehicle colors - they never affect gameplay or difficulty.
class CarSkin {
    final String id;
    final String name;
    final int price;
    final List<Color> palette;

    const CarSkin({
          required this.id,
          required this.name,
          required this.price,
          required this.palette,
    });
}

const List<CarSkin> kCarSkins = [
    CarSkin(
          id: 'classic',
          name: 'Classic',
          price: 0,
          palette: [
                  Color(0xFFE63946),
                  Color(0xFFF4A261),
                  Color(0xFF2A9D8F),
                  Color(0xFF457B9D),
                  Color(0xFF8338EC),
                  Color(0xFFFFB703),
                  Color(0xFF06D6A0),
                  Color(0xFFEF476F),
                  Color(0xFF3A86FF),
                  Color(0xFFFB5607),
                  Color(0xFF9B5DE5),
                  Color(0xFF00BBF9),
                ],
        ),
    CarSkin(
          id: 'neon',
          name: 'Neon Nights',
          price: 150,
          palette: [
                  Color(0xFFFF006E),
                  Color(0xFF8338EC),
                  Color(0xFF3A86FF),
                  Color(0xFFFB5607),
                  Color(0xFFFFBE0B),
                  Color(0xFF06D6A0),
                  Color(0xFFFF4D6D),
                  Color(0xFF7209B7),
                  Color(0xFF4CC9F0),
                  Color(0xFFF15BB5),
                  Color(0xFF00F5D4),
                  Color(0xFF9B5DE5),
                ],
        ),
    CarSkin(
          id: 'pastel',
          name: 'Pastel Dream',
          price: 150,
          palette: [
                  Color(0xFFFFADAD),
                  Color(0xFFFFD6A5),
                  Color(0xFFFDFFB6),
                  Color(0xFFCAFFBF),
                  Color(0xFF9BF6FF),
                  Color(0xFFA0C4FF),
                  Color(0xFFBDB2FF),
                  Color(0xFFFFC6FF),
                  Color(0xFFFFB4A2),
                  Color(0xFFB5EAD7),
                  Color(0xFFC7CEEA),
                  Color(0xFFE2F0CB),
                ],
        ),
    CarSkin(
          id: 'sunset',
          name: 'Sunset Boulevard',
          price: 200,
          palette: [
                  Color(0xFFF94144),
                  Color(0xFFF3722C),
                  Color(0xFFF8961E),
                  Color(0xFFF9844A),
                  Color(0xFFF9C74F),
                  Color(0xFF90BE6D),
                  Color(0xFF43AA8B),
                  Color(0xFF4D908E),
                  Color(0xFF577590),
                  Color(0xFF277DA1),
                  Color(0xFFEF476F),
                  Color(0xFFFFD166),
                ],
        ),
  ];

CarSkin skinById(String id) => kCarSkins.firstWhere(
        (s) => s.id == id,
        orElse: () => kCarSkins.first,
      );
