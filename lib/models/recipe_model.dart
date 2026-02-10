
class Recipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int cookingTimeMinutes;
  final int calorieCount;
  final String difficulty;
  final List<String> ingredientProductIds;
  final List<String> instructions;
  final double rating;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cookingTimeMinutes,
    required this.calorieCount,
    required this.difficulty,
    required this.ingredientProductIds,
    required this.instructions,
    this.rating = 4.5,
  });

  static List<Recipe> sampleRecipes = [
    const Recipe(
      id: 'r1',
      name: 'Classic Matar Paneer',
      description: 'A popular Indian curry dish made with green peas and paneer.',
      imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',
      cookingTimeMinutes: 40,
      calorieCount: 320,
      difficulty: 'Medium',
      ingredientProductIds: ['1', '8', '11', '17'], // Tomatoes, Peas (ID 8 assumed or will map closest), Onions, Paneer
      instructions: [
        'Heat oil in a pan and sauté spices.',
        'Add chopped onions and sauté until golden brown.',
        'Add tomato puree and cook until oil separates.',
        'Add spices like turmeric, chili powder, and coriander powder.',
        'Add green peas and cook for a few minutes.',
        'Add paneer cubes and simmer for 5-10 minutes.',
        'Garnish with fresh coriander and serve hot.'
      ],
      rating: 4.8,
    ),
    const Recipe(
      id: 'r2',
      name: 'Refreshing Fruit Salad',
      description: 'A healthy and colorful mix of fresh seasonal fruits.',
      imageUrl: 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?w=600', // Fruit salad image
      cookingTimeMinutes: 10,
      calorieCount: 150,
      difficulty: 'Easy',
      ingredientProductIds: ['2', '14', '16', '30'], // Apples, Oranges, Grapes, Pomegranate
      instructions: [
        'Wash all fruits thoroughly.',
        'Chop apples, oranges, and other large fruits into bite-sized pieces.',
        'Mix all fruits in a large bowl.',
        'Add a squeeze of lemon juice or honey for extra flavor.',
        'Serve fresh or delicious chilled.'
      ],
      rating: 4.9,
    ),
    const Recipe(
      id: 'r3',
      name: 'Creamy Spinach Soup',
      description: 'Healthy and nutritious soup made with fresh spinach.',
      imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600', // Reusing spinach img for now or generic green soup
      cookingTimeMinutes: 25,
      calorieCount: 120,
      difficulty: 'Easy',
      ingredientProductIds: ['6', '18', '3'], // Spinach, Butter, Milk
      instructions: [
        'Blanch spinach leaves and blend into a smooth puree.',
        'Melt butter in a pot and add garlic.',
        'Pour in the spinach puree and cook for 5 mins.',
        'Add milk to adjust consistency and bring to a boil.',
        'Season with salt and pepper. Serve hot.'
      ],
      rating: 4.6,
    ),
  ];
}
