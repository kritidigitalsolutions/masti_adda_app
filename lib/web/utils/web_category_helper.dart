import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';

class WebCategoryHelper {
  /// Matches a raw dynamic value (string, map, list) against a CategoryModel
  static bool slugOrNameMatches(dynamic itemValue, CategoryModel cat) {
    if (itemValue == null) return false;

    final catSlug = cat.slug.trim().toLowerCase();
    final catName = cat.name.trim().toLowerCase();
    final catId = cat.id.trim();

    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final cleanSlug = clean(catSlug);
    final cleanName = clean(catName);

    if (itemValue is String) {
      final v = itemValue.trim();
      if (v.isEmpty) return false;
      final vLower = v.toLowerCase();
      final vClean = clean(v);

      if (v == catId ||
          vLower == catSlug ||
          vLower == catName ||
          (cleanSlug.isNotEmpty && vClean == cleanSlug) ||
          (cleanName.isNotEmpty && vClean == cleanName)) {
        return true;
      }
      if (v.contains(',')) {
        for (final part in v.split(',')) {
          final p = part.trim();
          final pLower = p.toLowerCase();
          final pClean = clean(p);
          if (pLower == catSlug ||
              pLower == catName ||
              (cleanSlug.isNotEmpty && pClean == cleanSlug) ||
              (cleanName.isNotEmpty && pClean == cleanName)) {
            return true;
          }
        }
      }
    } else if (itemValue is Map) {
      final id = (itemValue['_id'] ?? itemValue['id'] ?? '').toString().trim();
      final slug = (itemValue['slug'] ?? '').toString().trim();
      final name = (itemValue['name'] ?? '').toString().trim();

      if (id.isNotEmpty && id == catId) return true;
      if (slug.isNotEmpty && slugOrNameMatches(slug, cat)) return true;
      if (name.isNotEmpty && slugOrNameMatches(name, cat)) return true;
    } else if (itemValue is List) {
      for (final sub in itemValue) {
        if (slugOrNameMatches(sub, cat)) return true;
      }
    }
    return false;
  }

  /// Matches a raw dynamic value against a target category/genre string
  static bool stringMatchesCategoryOrGenre(dynamic itemValue, String target) {
    if (itemValue == null) return false;
    final t = target.trim().toLowerCase();
    if (t.isEmpty || t == 'all') return true;

    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanTarget = clean(t);

    if (itemValue is String) {
      final v = itemValue.trim();
      if (v.isEmpty) return false;
      final vLower = v.toLowerCase();
      final vClean = clean(v);

      if (vLower == t ||
          (cleanTarget.isNotEmpty && vClean == cleanTarget) ||
          vLower.contains(t)) {
        return true;
      }
      if (v.contains(',')) {
        for (final part in v.split(',')) {
          final p = part.trim().toLowerCase();
          if (p == t || (cleanTarget.isNotEmpty && clean(p) == cleanTarget)) {
            return true;
          }
        }
      }
    } else if (itemValue is Map) {
      final slug = (itemValue['slug'] ?? '').toString().trim();
      final name = (itemValue['name'] ?? '').toString().trim();
      if (stringMatchesCategoryOrGenre(slug, target)) return true;
      if (stringMatchesCategoryOrGenre(name, target)) return true;
    } else if (itemValue is List) {
      for (final sub in itemValue) {
        if (stringMatchesCategoryOrGenre(sub, target)) return true;
      }
    }
    return false;
  }

  static bool matchesMovie(MovieModel movie, CategoryModel category) {
    for (final c in movie.category) {
      if (slugOrNameMatches(c, category)) return true;
    }
    for (final g in movie.genre) {
      if (slugOrNameMatches(g, category)) return true;
    }
    if (movie.slug.isNotEmpty && slugOrNameMatches(movie.slug, category)) {
      return true;
    }
    return false;
  }

  static bool matchesSeries(Series series, CategoryModel category) {
    for (final c in series.category) {
      if (slugOrNameMatches(c, category)) return true;
    }
    for (final g in series.genre) {
      if (slugOrNameMatches(g, category)) return true;
    }
    if (series.slug.isNotEmpty && slugOrNameMatches(series.slug, category)) {
      return true;
    }
    return false;
  }

  static bool matchesDrama(Microdrama drama, CategoryModel category) {
    for (final c in drama.category) {
      if (slugOrNameMatches(c, category)) return true;
    }
    for (final g in drama.genre) {
      if (slugOrNameMatches(g, category)) return true;
    }
    if (drama.slug.isNotEmpty && slugOrNameMatches(drama.slug, category)) {
      return true;
    }
    return false;
  }
}
