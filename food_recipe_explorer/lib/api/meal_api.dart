import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class MealApi {
  static const String baseUrl =
      'https://www.themealdb.com/api/json/v1/1';

  Future<List<Meal>> searchMeals(String query) async {
    final url = Uri.parse(
      '$baseUrl/search.php?s=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['meals'] == null) return [];

      return (data['meals'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList();
    }

    throw Exception('Failed to load recipes');
  }

  Future<Meal?> getMealDetails(String id) async {
    final url = Uri.parse(
      '$baseUrl/lookup.php?i=$id',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['meals'] == null) return null;

      return Meal.fromJson(data['meals'][0]);
    }

    throw Exception('Failed to load recipe details');
  }

  Future<List<Meal>> getMealsByCategory(
    String category,
  ) async {
    final url = Uri.parse(
      '$baseUrl/filter.php?c=${Uri.encodeComponent(category)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load category');
    }

    final data = jsonDecode(response.body);

    if (data['meals'] == null) return [];

    final List meals = data['meals'];

    // Get all recipe details AT THE SAME TIME.
    final results = await Future.wait(
      meals.map(
        (meal) async {
          try {
            return await getMealDetails(
              meal['idMeal'].toString(),
            );
          } catch (e) {
            return null;
          }
        },
      ),
    );

    return results
        .whereType<Meal>()
        .toList();
  }

  Future<List<String>> getCategories() async {
    final url = Uri.parse(
      '$baseUrl/categories.php',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['categories'] == null) return [];

      return (data['categories'] as List)
          .map(
            (category) =>
                category['strCategory'] as String,
          )
          .toList();
    }

    throw Exception('Failed to load categories');
  }

  Future<List<Meal>> getAllForeignRecipes() async {
    // Get categories first.
    final categories = await getCategories();

    final limitedCategories =
        categories.take(5).toList();

    // Load all 5 categories AT THE SAME TIME.
    final categoryResults = await Future.wait(
      limitedCategories.map(
        (category) async {
          try {
            return await getMealsByCategory(
              category,
            );
          } catch (e) {
            return <Meal>[];
          }
        },
      ),
    );

    // Remove duplicate recipes.
    final Map<String, Meal> uniqueMeals = {};

    for (final meals in categoryResults) {
      for (final meal in meals) {
        if (meal.ingredients.isNotEmpty) {
          uniqueMeals[meal.id] = meal;
        }
      }
    }

    return uniqueMeals.values.toList();
  }

  Future<Meal?> getRandomMeal() async {
    final url = Uri.parse(
      '$baseUrl/random.php',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['meals'] == null) return null;

      return Meal.fromJson(
        data['meals'][0],
      );
    }

    throw Exception(
      'Failed to load random recipe',
    );
  }
}