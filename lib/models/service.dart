import 'package:flutter/material.dart';

class Service {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final IconData? icon;

  Service({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.icon,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}
