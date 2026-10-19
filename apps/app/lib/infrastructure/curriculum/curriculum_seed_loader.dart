import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/curriculum_competency.dart';
import '../../domain/repositories/curriculum_competency_repository.dart';

/// Carregador responsável por popular a base de competências curriculares oficiais (BNCC)
/// de forma idempotente a partir do arquivo JSON verificado empacotado nos assets.
class CurriculumSeedLoader {
  CurriculumSeedLoader({required this.repository, this.bundle});

  final CurriculumCompetencyRepository repository;
  final AssetBundle? bundle;

  static const String defaultAssetPath = 'assets/curriculum/bncc_seed.json';

  Future<int> loadSeedIfNeeded({
    String assetPath = defaultAssetPath,
    bool force = false,
  }) async {
    final existingCount = await repository.count();
    if (existingCount > 0 && !force) {
      return 0; // Já populado
    }

    final effectiveBundle = bundle ?? rootBundle;
    final jsonString = await effectiveBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    final competencies = jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return CurriculumCompetency.fromJson(map);
    }).toList();

    await repository.saveAll(competencies);
    return competencies.length;
  }
}
