import 'dart:math';
import 'package:flutter/material.dart';
import '../api/local_api.dart';
import '../api/meal_api.dart';
import '../models/meal.dart';
import '../widgets/recipe_card.dart';
import 'search_screen.dart';
import 'recipe_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalApi _localApi = LocalApi();
  final MealApi _mealApi = MealApi();

  List<Meal> _localRecipes = [];
  List<Meal> _foreignRecipes = [];
  Meal? _randomRecipe;

  // Label for the Recipe of the Day source.
  String _randomRecipeSource = '';

  bool _isLoading = true;
  String _selectedTab = 'Local';

  @override
  void initState() {
    super.initState();
    _loadAllRecipes();
  }

  // ============================================================
  // LOAD RECIPES
  // ============================================================

  Future<void> _loadAllRecipes() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Start all API requests at the same time.
      final localFuture = _localApi.getLocalRecipes();
      final foreignFuture = _mealApi.getAllForeignRecipes();
      final randomForeignFuture = _mealApi.getRandomMeal();

      // Wait for all requests to finish.
      final results = await Future.wait<dynamic>([
        localFuture,
        foreignFuture,
        randomForeignFuture,
      ]);

      final local = results[0] as List<Meal>;
      final foreign = results[1] as List<Meal>;
      final randomForeign = results[2] as Meal?;

      // ========================================================
      // RECIPE OF THE DAY
      // ========================================================

      Meal? recipeOfTheDay;
      String recipeSource = '';

      // Randomly choose between Local and Foreign.
      // 50% chance Local
      // 50% chance Foreign
      final chooseLocal = Random().nextBool();

      if (chooseLocal && local.isNotEmpty) {
        // Pick a random LOCAL recipe.
        final randomIndex = Random().nextInt(local.length);

        recipeOfTheDay = local[randomIndex];
        recipeSource = '🇵🇭 LOCAL';
      } else if (randomForeign != null) {
        // Pick FOREIGN recipe.
        recipeOfTheDay = randomForeign;
        recipeSource = '🌍 FOREIGN';
      } else if (local.isNotEmpty) {
        // Fallback to LOCAL if foreign recipe is unavailable.
        final randomIndex = Random().nextInt(local.length);

        recipeOfTheDay = local[randomIndex];
        recipeSource = '🇵🇭 LOCAL';

        
      }

      if (!mounted) return;

      setState(() {
        _localRecipes = local;
        _foreignRecipes = foreign;
        _randomRecipe = recipeOfTheDay;
        _randomRecipeSource = recipeSource;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recipes: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Team_Awa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllRecipes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Random Recipe Banner
                  if (_randomRecipe != null) ...[
                    _buildRandomRecipeBanner(),
                    const SizedBox(height: 24),
                  ],

                  // Tab Selector
                  _buildTabSelector(),
                  const SizedBox(height: 16),

                  // Recipe Grid based on selected tab
                  _buildRecipeGrid(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // RANDOM RECIPE BANNER
  // ============================================================

  Widget _buildRandomRecipeBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              meal: _randomRecipe!,
            ),
          ),
        );
      },
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 34, 255, 89),
              Color.fromARGB(185, 255, 153, 0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 34, 255, 56).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Recipe of the Day label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🌟 RECIPE OF THE DAY 🌟',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Local / Foreign label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _randomRecipeSource,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Recipe name
                  Text(
                    'random',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Recipe category
                  Text(
                    'randomRecipe.name ??',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // View Recipe button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'View Recipe →',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB SELECTOR
  // ============================================================

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
        
          _buildTabButton(
            '🌍 Foreign',
            'Foreign',
          ),
          _buildTabButton(
            '🇵🇭 Local',
            'Local',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BUTTON
  // ============================================================

  Widget _buildTabButton(
    String label,
    String tab,
  ) {
    final isSelected = _selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = tab);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.deepOrange
                    : Colors.grey[600],
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECIPE GRID
  // ============================================================

  Widget _buildRecipeGrid() {
    final recipes = _selectedTab == 'Local'
        ? _localRecipes
        : _foreignRecipes;

    final displayRecipes = recipes.take(20).toList();

    if (displayRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 40,
          ),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No recipes available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayRecipes.length,
      itemBuilder: (context, index) {
        final meal = displayRecipes[index];

        return RecipeCard(
          meal: meal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                  meal: meal,
                ),
              ),
            );
          },
        );
      },
    );
  }
}