import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class LocalApi {
  static const String baseUrl =
      'https://filipino-food-api.ryodgie.workers.dev/v1/dishes';

  // GET ALL FILIPINO RECIPES

  Future<List<Meal>> getLocalRecipes() async {
    final List<Meal> allRecipes = [];

    try {
      // ----------------------------------------------------------
      // LOAD FIRST PAGE
      // ----------------------------------------------------------
      // We load Page 1 first because we need the API metadata
      // to know how many total pages there are.
      // ----------------------------------------------------------

      const int limit = 10;
      const int firstPage = 1;

      final firstUrl = Uri.parse(baseUrl).replace(
        queryParameters: {
          'page': firstPage.toString(),
          'limit': limit.toString(),
        },
      );

      print('Loading Filipino recipes - Page 1');

      final firstResponse = await http.get(
        firstUrl,
        headers: {
          'Accept': 'application/json',
        },
      );

      print(
        'Status Code: ${firstResponse.statusCode}',
      );

      if (firstResponse.statusCode != 200) {
        print('API Error: ${firstResponse.body}');

        throw Exception(
          'Failed to load Filipino recipes: '
          '${firstResponse.statusCode}',
        );
      }

      final firstData = jsonDecode(firstResponse.body);

      final List firstDishes = firstData['data'] ?? [];

      final firstMeta = firstData['meta'];

      int totalPages = 1;

      if (firstMeta != null) {
        totalPages = firstMeta['pages'] ?? 1;
      }

      // Convert Page 1 recipes.
      for (final dish in firstDishes) {
        if (dish is Map<String, dynamic>) {
          allRecipes.add(
            _convertToMeal(dish),
          );
        }
      }

      // ----------------------------------------------------------
      // LOAD REMAINING PAGES AT THE SAME TIME
      // ----------------------------------------------------------

      if (totalPages > 1) {
        final List<int> remainingPages = List.generate(
          totalPages - 1,
          (index) => index + 2,
        );

        final List<List<Meal>> pageResults =
            await Future.wait(
          remainingPages.map(
            (pageNumber) async {
              final url = Uri.parse(baseUrl).replace(
                queryParameters: {
                  'page': pageNumber.toString(),
                  'limit': limit.toString(),
                },
              );

              print(
                'Loading Filipino recipes - Page $pageNumber',
              );

              final response = await http.get(
                url,
                headers: {
                  'Accept': 'application/json',
                },
              );

              print(
                'Status Code: ${response.statusCode}',
              );

              if (response.statusCode != 200) {
                print(
                  'API Error: ${response.body}',
                );

                throw Exception(
                  'Failed to load Filipino recipes: '
                  '${response.statusCode}',
                );
              }

              final data = jsonDecode(response.body);

              final List dishes = data['data'] ?? [];

              final List<Meal> pageRecipes = [];

              for (final dish in dishes) {
                if (dish is Map<String, dynamic>) {
                  pageRecipes.add(
                    _convertToMeal(dish),
                  );
                }
              }

              return pageRecipes;
            },
          ),
        );

        // Add all recipes from the remaining pages.
        for (final pageRecipes in pageResults) {
          allRecipes.addAll(pageRecipes);
        }
      }

      print(
        'Total Filipino recipes loaded: '
        '${allRecipes.length}',
      );

      return allRecipes;
    } catch (e) {
      print(
        'Error loading Filipino recipes: $e',
      );

      rethrow;
    }
  }

  // CONVERT API DATA TO MEAL

  Meal _convertToMeal(
    Map<String, dynamic> dish,
  ) {
    final List<String> ingredients = [];

    // INGREDIENTS

    final mainIngredients =
        dish['main_ingredients'];

    if (mainIngredients is List) {
      for (final ingredient in mainIngredients) {
        ingredients.add(
          ingredient.toString(),
        );
      }
    }

    // OCCASIONS

    final List<String> occasions = [];

    final occasionData =
        dish['occasion'];

    if (occasionData is List) {
      for (final occasion in occasionData) {
        occasions.add(
          occasion.toString(),
        );
      }
    }

    // FLAVOR PROFILE

    final List<String> flavorProfile = [];

    final flavorData =
        dish['flavor_profile'];

    if (flavorData is List) {
      for (final flavor in flavorData) {
        flavorProfile.add(
          flavor.toString(),
        );
      }
    }

    // COOKING METHOD

    final List<String> cookingMethods = [];

    final cookingData =
        dish['cooking_method'];

    if (cookingData is List) {
      for (final method in cookingData) {
        cookingMethods.add(
          method.toString(),
        );
      }
    }

    // TAGS

    final List<String> tags = [];

    final tagData = dish['tags'];

    if (tagData is List) {
      for (final tag in tagData) {
        tags.add(
          tag.toString(),
        );
      }
    }

    // CREATE MEAL

    return Meal.local(
      id: dish['id']?.toString() ?? '',

      name: dish['name']?.toString() ??
          'Unknown Filipino Dish',

      // IMPORTANT:
      // The API provides image_url.
      image: dish['image_url']?.toString(),

      category: _getCategory(dish),

      area: dish['origin_region']?.toString() ??
          'Philippines',

      // IMPORTANT:
      // This API does NOT provide actual cooking instructions.
      instructions: null,

      // This is the actual description from the API.
      description:
          dish['description']?.toString(),

      occasions: occasions,

      flavorProfile: flavorProfile,

      cookingMethods: cookingMethods,

      tags: tags,

      ingredients: ingredients,

      // The API does not provide measurements.
      measurements: const [],

      servings: 4,
    );
  }

  // CATEGORY

  String _getCategory(
    Map<String, dynamic> dish,
  ) {
    final type = dish['type'];

    if (type is List && type.isNotEmpty) {
      return type.first.toString();
    }

    return 'Filipino';
  }

  // SEARCH FILIPINO RECIPES

  Future<List<Meal>> searchLocalRecipes(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return getLocalRecipes();
    }

    final recipes =
        await getLocalRecipes();

    final searchQuery =
        query.trim().toLowerCase();

    return recipes.where((meal) {
      final name =
          meal.name.toLowerCase();

      final category =
          meal.category?.toLowerCase() ?? '';

      final area =
          meal.area?.toLowerCase() ?? '';

      final ingredients =
          meal.ingredients
              .join(' ')
              .toLowerCase();

      final description =
          meal.description?.toLowerCase() ?? '';

      return name.contains(searchQuery) ||
          category.contains(searchQuery) ||
          area.contains(searchQuery) ||
          ingredients.contains(searchQuery) ||
          description.contains(searchQuery);
    }).toList();
  }

  // RANDOM FILIPINO RECIPE

  Future<Meal?> getRandomMeal() async {
    try {
      final url = Uri.parse(
        '$baseUrl/random',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      print(
        'Random recipe status: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load random Filipino recipe',
        );
      }

      final data =
          jsonDecode(response.body);

      final dish =
          data['data'] ?? data;

      if (dish is Map<String, dynamic>) {
        return _convertToMeal(dish);
      }

      return null;
    } catch (e) {
      print(
        'Error loading random Filipino recipe: $e',
      );

      return null;
    }
  }

  // GET SINGLE FILIPINO RECIPE

  Future<Meal?> getMealDetails(
    String id,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      print(
        'Recipe details status: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(response.body);

      final dish =
          data['data'] ?? data;

      if (dish is Map<String, dynamic>) {
        return _convertToMeal(dish);
      }

      return null;
    } catch (e) {
      print(
        'Error loading recipe details: $e',
      );

      return null;
    }
  }
}