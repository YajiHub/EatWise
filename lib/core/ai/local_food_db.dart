class VerifiedFoodBaseline {
  final String canonicalName;
  final List<String> searchNames;
  final String category;
  final double calPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? gramsPerServing;
  final String? servingDescription;
  final String dataSource;

  const VerifiedFoodBaseline({
    required this.canonicalName,
    required this.searchNames,
    required this.category,
    required this.calPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.gramsPerServing,
    this.servingDescription,
    this.dataSource = 'FNRI',
  });

  double get caloriesPerServing {
    if (gramsPerServing == null || gramsPerServing! <= 0) return calPer100g;
    return calPer100g * (gramsPerServing! / 100);
  }
}

const verifiedFoodBaselines = <VerifiedFoodBaseline>[
  // ═══ BREAKFAST & EGGS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Boiled Egg',
    searchNames: ['boiled egg', 'boiled eggs', 'egg', 'eggs', 'itlog', 'nilagang itlog', 'hard boiled egg', 'soft boiled egg'],
    category: 'breakfast',
    calPer100g: 155, proteinPer100g: 12.6, carbsPer100g: 1.1, fatPer100g: 10.6,
    gramsPerServing: 50, servingDescription: '1 large egg (~50g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fried Egg (Sunny Side Up)',
    searchNames: ['fried egg', 'sunny side up', 'sunny side egg', 'pritong itlog', 'sunny-side egg', 'fried eggs'],
    category: 'breakfast',
    calPer100g: 196, proteinPer100g: 13.6, carbsPer100g: 0.8, fatPer100g: 15.0,
    gramsPerServing: 50, servingDescription: '1 egg (~50g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Pandesal',
    searchNames: ['pandesal', 'pan de sal', 'filipino bread roll', 'pandesal bread'],
    category: 'breakfast',
    calPer100g: 290, proteinPer100g: 9.0, carbsPer100g: 56.0, fatPer100g: 3.5,
    gramsPerServing: 35, servingDescription: '1 piece (~35g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Tapsilog',
    searchNames: ['tapsilog', 'tapsilog with sunny side egg', 'tapsi meal', 'tapa sinangag itlog', 'beef tapsilog'],
    category: 'breakfast',
    calPer100g: 175, proteinPer100g: 8.5, carbsPer100g: 16.5, fatPer100g: 8.0,
    gramsPerServing: 330, servingDescription: '1 full plate (~330g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Arroz Caldo',
    searchNames: ['arroz caldo', 'arrozcaldo', 'lugaw with chicken', 'chicken porridge', 'lugaw with egg', 'congee'],
    category: 'soup',
    calPer100g: 75, proteinPer100g: 4.0, carbsPer100g: 11.0, fatPer100g: 1.8,
    gramsPerServing: 300, servingDescription: '1 bowl (~300g)',
    dataSource: 'FNRI',
  ),

  // ═══ GRAINS & RICE ═══
  VerifiedFoodBaseline(
    canonicalName: 'White Rice (steamed)',
    searchNames: ['rice', 'white rice', 'steamed rice', 'kanin', 'plain rice', 'cooked rice', 'kaning puti'],
    category: 'grains',
    calPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28.0, fatPer100g: 0.3,
    gramsPerServing: 160, servingDescription: '1 cup cooked',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Garlic Rice (Sinangag)',
    searchNames: ['garlic rice', 'sinangag', 'fried rice', 'garlic fried rice', 'sinangag na kanin'],
    category: 'grains',
    calPer100g: 180, proteinPer100g: 3.2, carbsPer100g: 30.0, fatPer100g: 6.5,
    gramsPerServing: 160, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Brown Rice (steamed)',
    searchNames: ['brown rice', 'unpolished rice', 'red rice', 'whole grain rice', 'pinawa'],
    category: 'grains',
    calPer100g: 123, proteinPer100g: 2.7, carbsPer100g: 25.6, fatPer100g: 0.9,
    gramsPerServing: 160, servingDescription: '1 cup cooked',
    dataSource: 'USDA',
  ),

  // ═══ CHICKEN & POULTRY ═══
  VerifiedFoodBaseline(
    canonicalName: 'Chicken Adobo',
    searchNames: ['adobo', 'adobong manok', 'chicken adobo', 'chicken in soy sauce', 'chicken adobo sa toyo'],
    category: 'poultry',
    calPer100g: 205, proteinPer100g: 20.0, carbsPer100g: 2.5, fatPer100g: 12.0,
    gramsPerServing: 150, servingDescription: '1 serving (1 leg quarter)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fried Chicken (leg quarter)',
    searchNames: ['fried chicken', 'jollibee chicken', 'chicken joy', 'fried chicken leg', 'crispy chicken', 'pritong manok', 'chicken leg quarter'],
    category: 'poultry',
    calPer100g: 260, proteinPer100g: 20.0, carbsPer100g: 7.0, fatPer100g: 17.0,
    gramsPerServing: 150, servingDescription: '1 leg quarter',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Grilled Chicken Breast (skinless)',
    searchNames: ['chicken breast', 'grilled chicken', 'roasted chicken breast', 'skinless chicken', 'chicken breast fillet', 'inihaw na manok'],
    category: 'poultry',
    calPer100g: 165, proteinPer100g: 31.0, carbsPer100g: 0.0, fatPer100g: 3.6,
    gramsPerServing: 100, servingDescription: '1 small breast (~3 oz)',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Chicken Tinola',
    searchNames: ['tinola', 'tinolang manok', 'chicken tinola', 'chicken ginger soup', 'tinola soup', 'tinolang manok'],
    category: 'soup',
    calPer100g: 100, proteinPer100g: 12.0, carbsPer100g: 3.0, fatPer100g: 4.0,
    gramsPerServing: 250, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Chicken Inasal',
    searchNames: ['chicken inasal', 'grilled chicken inasal', 'inasal na manok', 'bacolod chicken', 'chicken bbq inasal'],
    category: 'poultry',
    calPer100g: 200, proteinPer100g: 23.0, carbsPer100g: 2.0, fatPer100g: 11.0,
    gramsPerServing: 150, servingDescription: '1 leg quarter',
    dataSource: 'FNRI',
  ),

  // ═══ PORK DISHES ═══
  VerifiedFoodBaseline(
    canonicalName: 'Pork Adobo',
    searchNames: ['adobong baboy', 'pork adobo', 'adobong barrio', 'pork belly adobo', 'baboy adobo'],
    category: 'pork',
    calPer100g: 280, proteinPer100g: 18.0, carbsPer100g: 1.5, fatPer100g: 23.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Lechon Kawali',
    searchNames: ['lechon kawali', 'crispy pork belly', 'chicharon kawali', 'deep fried pork belly', 'crispy pata slices'],
    category: 'pork',
    calPer100g: 380, proteinPer100g: 15.0, carbsPer100g: 0.0, fatPer100g: 35.0,
    gramsPerServing: 100, servingDescription: '3 pieces (~100g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Lechon (Roasted Pig)',
    searchNames: ['lechon', 'roasted pig', 'lechon baboy', 'roasted pork', 'cebu lechon', 'litson'],
    category: 'pork',
    calPer100g: 310, proteinPer100g: 22.0, carbsPer100g: 0.0, fatPer100g: 24.0,
    gramsPerServing: 100, servingDescription: '3 slices (~100g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Sizzling Sisig',
    searchNames: ['sisig', 'pork sisig', 'sizzling sisig', 'chopped pork', 'sisig baboy', 'pampanga sisig'],
    category: 'pork',
    calPer100g: 320, proteinPer100g: 20.0, carbsPer100g: 3.0, fatPer100g: 25.0,
    gramsPerServing: 150, servingDescription: '1 sizzling plate',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Pork BBQ (stick)',
    searchNames: ['pork bbq', 'bbq stick', 'barbecue', 'pork skewer', 'inihaw na baboy', 'bbq pork stick'],
    category: 'pork',
    calPer100g: 250, proteinPer100g: 16.0, carbsPer100g: 8.0, fatPer100g: 16.0,
    gramsPerServing: 80, servingDescription: '1 stick (~80g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Tocino',
    searchNames: ['tocino', 'sweet pork', 'cured pork', 'pork tocino', 'tocino baboy'],
    category: 'pork',
    calPer100g: 280, proteinPer100g: 14.0, carbsPer100g: 12.0, fatPer100g: 18.0,
    gramsPerServing: 100, servingDescription: '3-4 slices',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Longganisa',
    searchNames: ['longganisa', 'longanisa', 'spanish sausage', 'longganisang baboy', 'filipino sausage', 'lucban longganisa'],
    category: 'pork',
    calPer100g: 290, proteinPer100g: 12.0, carbsPer100g: 4.0, fatPer100g: 24.0,
    gramsPerServing: 65, servingDescription: '1 piece (~65g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Beef Tapa',
    searchNames: ['tapa', 'beef tapa', 'cured beef', 'tapsi', 'tapsilog meat', 'bistek tapa'],
    category: 'pork',
    calPer100g: 250, proteinPer100g: 22.0, carbsPer100g: 5.0, fatPer100g: 15.0,
    gramsPerServing: 100, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),

  // ═══ SOUPS & STEWS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Sinigang na Baboy',
    searchNames: ['sinigang', 'sinigang na baboy', 'pork sinigang', 'tamarind soup', 'sour soup', 'sinigang soup'],
    category: 'soup',
    calPer100g: 130, proteinPer100g: 11.0, carbsPer100g: 7.0, fatPer100g: 5.0,
    gramsPerServing: 250, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Sinigang na Hipon',
    searchNames: ['sinigang na hipon', 'shrimp sinigang', 'tamarind shrimp', 'hipon sinigang'],
    category: 'soup',
    calPer100g: 85, proteinPer100g: 14.0, carbsPer100g: 3.0, fatPer100g: 2.0,
    gramsPerServing: 250, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Sinigang na Isda',
    searchNames: ['sinigang na isda', 'fish sinigang', 'bangus sinigang', 'fish tamarind', 'isda sinigang'],
    category: 'soup',
    calPer100g: 95, proteinPer100g: 15.0, carbsPer100g: 2.0, fatPer100g: 3.0,
    gramsPerServing: 250, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Kare-Kare',
    searchNames: ['kare kare', 'kare-kare', 'peanut stew', 'oxtail stew', 'oxtail kare kare', 'peanut sauce stew'],
    category: 'soup',
    calPer100g: 210, proteinPer100g: 14.0, carbsPer100g: 10.0, fatPer100g: 15.0,
    gramsPerServing: 200, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Bulalo',
    searchNames: ['bulalo', 'beef bone marrow soup', 'beef shank soup', 'bulalo soup', 'bone marrow stew'],
    category: 'soup',
    calPer100g: 140, proteinPer100g: 18.0, carbsPer100g: 1.0, fatPer100g: 6.0,
    gramsPerServing: 300, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Nilagang Baka',
    searchNames: ['nilaga', 'nilagang baka', 'boiled beef', 'beef nilaga', 'beef stew', 'nilagang beef'],
    category: 'soup',
    calPer100g: 120, proteinPer100g: 16.0, carbsPer100g: 4.0, fatPer100g: 4.0,
    gramsPerServing: 300, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Menudo',
    searchNames: ['menudo', 'pork menudo', 'pork liver stew', 'menudo baboy'],
    category: 'soup',
    calPer100g: 180, proteinPer100g: 13.0, carbsPer100g: 8.0, fatPer100g: 11.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Caldereta',
    searchNames: ['caldereta', 'beef caldereta', 'spiced meat stew', 'kaldereta', 'goat caldereta', 'beef stew tomato'],
    category: 'soup',
    calPer100g: 190, proteinPer100g: 15.0, carbsPer100g: 7.0, fatPer100g: 12.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Dinuguan',
    searchNames: ['dinuguan', 'pork blood stew', 'chocolate meat', 'dinuguan baboy', 'blood stew'],
    category: 'soup',
    calPer100g: 160, proteinPer100g: 14.0, carbsPer100g: 3.0, fatPer100g: 9.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),

  // ═══ NOODLES & RICE DISHES ═══
  VerifiedFoodBaseline(
    canonicalName: 'Pancit Canton',
    searchNames: ['pancit canton', 'canton noodles', 'pancit', 'stir fried noodles', 'canton pancit', 'filipino chow mein'],
    category: 'noodles',
    calPer100g: 195, proteinPer100g: 7.0, carbsPer100g: 24.0, fatPer100g: 8.0,
    gramsPerServing: 200, servingDescription: '1 plate',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Pancit Bihon',
    searchNames: ['pancit bihon', 'bihon', 'thin noodles', 'rice noodles', 'bihon guisado', 'pancit sotanghon'],
    category: 'noodles',
    calPer100g: 165, proteinPer100g: 5.0, carbsPer100g: 27.0, fatPer100g: 3.5,
    gramsPerServing: 200, servingDescription: '1 plate',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Lumpiang Shanghai',
    searchNames: ['lumpiang shanghai', 'lumpia', 'spring roll', 'fried spring roll', 'shanghai', 'lumpia shanghai'],
    category: 'noodles',
    calPer100g: 240, proteinPer100g: 8.0, carbsPer100g: 18.0, fatPer100g: 14.0,
    gramsPerServing: 35, servingDescription: '1 piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Lumpiang Sariwa',
    searchNames: ['lumpiang sariwa', 'fresh lumpia', 'vegetable lumpia', 'sariwang lumpia', 'fresh spring roll'],
    category: 'noodles',
    calPer100g: 130, proteinPer100g: 5.0, carbsPer100g: 16.0, fatPer100g: 4.0,
    gramsPerServing: 150, servingDescription: '1 roll',
    dataSource: 'FNRI',
  ),

  // ═══ VEGETABLES & SIDES ═══
  VerifiedFoodBaseline(
    canonicalName: 'Pinakbet',
    searchNames: ['pinakbet', 'pakbet', 'vegetable medley', 'mixed vegetables', 'pinakbet ilocano', 'pakbet ilocano'],
    category: 'vegetables',
    calPer100g: 75, proteinPer100g: 3.5, carbsPer100g: 10.0, fatPer100g: 3.0,
    gramsPerServing: 200, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Chopsuey',
    searchNames: ['chopsuey', 'chop suey', 'stir-fried vegetables', 'mixed vegetable stir fry', 'chopseuy'],
    category: 'vegetables',
    calPer100g: 65, proteinPer100g: 5.0, carbsPer100g: 7.0, fatPer100g: 2.5,
    gramsPerServing: 200, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Laing',
    searchNames: ['laing', 'taro leaves in coconut', 'gabi leaves', 'laing na gabi', 'spicy taro leaves'],
    category: 'vegetables',
    calPer100g: 170, proteinPer100g: 4.0, carbsPer100g: 8.0, fatPer100g: 14.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Bicol Express',
    searchNames: ['bicol express', 'spicy coconut pork', 'gata with pork', 'spicy pork in coconut', 'bicol express recipe'],
    category: 'vegetables',
    calPer100g: 250, proteinPer100g: 15.0, carbsPer100g: 4.0, fatPer100g: 19.0,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Monggo (Ginisang Munggo)',
    searchNames: ['mongo', 'monggo', 'mung bean', 'ginisang munggo', 'mung bean soup', 'munggo guisado'],
    category: 'vegetables',
    calPer100g: 115, proteinPer100g: 8.5, carbsPer100g: 13.0, fatPer100g: 3.5,
    gramsPerServing: 200, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Ensaladang Talong',
    searchNames: ['ensaladang talong', 'eggplant salad', 'grilled eggplant', 'talong salad', 'inihaw na talong ensalada'],
    category: 'vegetables',
    calPer100g: 95, proteinPer100g: 3.0, carbsPer100g: 10.0, fatPer100g: 5.0,
    gramsPerServing: 150, servingDescription: '1 serving (1 medium eggplant)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Ginisang Ampalaya',
    searchNames: ['ginisang ampalaya', 'ampalaya', 'bitter gourd', 'bitter melon stir fry', 'ampalaya with egg'],
    category: 'vegetables',
    calPer100g: 60, proteinPer100g: 4.0, carbsPer100g: 6.0, fatPer100g: 2.5,
    gramsPerServing: 150, servingDescription: '1 serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Ginataang Kalabasa',
    searchNames: ['ginataang kalabasa', 'squash in coconut milk', 'kalabasa sa gata', 'coconut squash'],
    category: 'vegetables',
    calPer100g: 120, proteinPer100g: 3.0, carbsPer100g: 12.0, fatPer100g: 7.0,
    gramsPerServing: 200, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),

  // ═══ FISH & SEAFOOD ═══
  VerifiedFoodBaseline(
    canonicalName: 'Inihaw na Bangus',
    searchNames: ['inihaw na bangus', 'grilled bangus', 'grilled milkfish', 'inihaw na isda', 'ihaw na bangus'],
    category: 'seafood',
    calPer100g: 160, proteinPer100g: 20.0, carbsPer100g: 0.0, fatPer100g: 8.0,
    gramsPerServing: 150, servingDescription: 'half fish',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Daing na Bangus',
    searchNames: ['daing na bangus', 'salted dried milkfish', 'dried bangus', 'marinated milkfish', 'tuyong bangus'],
    category: 'seafood',
    calPer100g: 200, proteinPer100g: 20.0, carbsPer100g: 1.0, fatPer100g: 12.0,
    gramsPerServing: 120, servingDescription: '1 piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fried Tilapia',
    searchNames: ['tilapia', 'fried tilapia', 'pritong tilapia', 'tilapia fillet', 'tilapia fish'],
    category: 'seafood',
    calPer100g: 185, proteinPer100g: 21.0, carbsPer100g: 0.0, fatPer100g: 10.0,
    gramsPerServing: 150, servingDescription: '1 medium fish',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fried Galunggong',
    searchNames: ['galunggong', 'fried galunggong', 'mackerel', 'round scad', 'gg galunggong'],
    category: 'seafood',
    calPer100g: 200, proteinPer100g: 23.0, carbsPer100g: 0.0, fatPer100g: 11.0,
    gramsPerServing: 80, servingDescription: '1 piece (~80g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Tuyo (Dried Fish)',
    searchNames: ['tuyo', 'dried fish', 'tuyong isda', 'dried herring', 'bulad', 'dried salted fish'],
    category: 'seafood',
    calPer100g: 290, proteinPer100g: 40.0, carbsPer100g: 0.0, fatPer100g: 13.0,
    gramsPerServing: 30, servingDescription: '1 piece (~30g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Sardinas (Canned in Tomato Sauce)',
    searchNames: ['sardines', 'sardinas', 'canned sardines', 'sardines in tomato', '555 sardines', 'liga sardines'],
    category: 'seafood',
    calPer100g: 185, proteinPer100g: 18.0, carbsPer100g: 2.0, fatPer100g: 11.0,
    gramsPerServing: 155, servingDescription: '1 can (155g)', 
    dataSource: 'USDA',
  ),

  // ═══ BREAKFAST ITEMS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Boiled Egg',
    searchNames: ['egg', 'boiled egg', 'itlog', 'chicken egg', 'hard boiled egg', 'itlog na pinakuluan', 'pinakuluang itlog'],
    category: 'breakfast',
    calPer100g: 155, proteinPer100g: 12.6, carbsPer100g: 1.1, fatPer100g: 10.6,
    gramsPerServing: 50, servingDescription: '1 medium',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fried Egg',
    searchNames: ['fried egg', 'pritong itlog', 'sunny side up', 'prito itlog', 'sunny side egg', 'itlog na prito'],
    category: 'breakfast',
    calPer100g: 196, proteinPer100g: 13.6, carbsPer100g: 0.8, fatPer100g: 15.0,
    gramsPerServing: 50, servingDescription: '1 egg (fried in oil)',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Pandesal',
    searchNames: ['pandesal', 'pan de sal', 'bread roll', 'filipino bread roll', 'pandisal', 'breakfast roll'],
    category: 'breakfast',
    calPer100g: 280, proteinPer100g: 8.0, carbsPer100g: 50.0, fatPer100g: 5.0,
    gramsPerServing: 25, servingDescription: '1 small piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Hotdog (Tender Juicy)',
    searchNames: ['hotdog', 'tender juicy', 'sausage', 'filipino hotdog', 'red hotdog', 'purefoods hotdog'],
    category: 'breakfast',
    calPer100g: 290, proteinPer100g: 11.0, carbsPer100g: 2.0, fatPer100g: 26.0,
    gramsPerServing: 60, servingDescription: '1 regular piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Champorado',
    searchNames: ['champorado', 'chocolate rice porridge', 'champorado with milk', 'tsamporado', 'chocolate porridge'],
    category: 'breakfast',
    calPer100g: 120, proteinPer100g: 3.0, carbsPer100g: 24.0, fatPer100g: 2.5,
    gramsPerServing: 200, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Lugaw (Rice Porridge)',
    searchNames: ['lugaw', 'congee', 'goto', 'rice porridge', 'arroz caldo', 'plain lugaw', 'lugaw with egg'],
    category: 'breakfast',
    calPer100g: 75, proteinPer100g: 3.0, carbsPer100g: 13.0, fatPer100g: 0.8,
    gramsPerServing: 300, servingDescription: '1 bowl',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Corned Beef',
    searchNames: ['corned beef', 'canned corned beef', 'corned beef guisado', 'purefoods corned beef', 'karne norte'],
    category: 'breakfast',
    calPer100g: 250, proteinPer100g: 15.0, carbsPer100g: 1.0, fatPer100g: 20.0,
    gramsPerServing: 100, servingDescription: 'half can (~100g)',
    dataSource: 'USDA',
  ),

  // ═══ FRUITS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Banana (Lakatan)',
    searchNames: ['banana', 'saging', 'yellow banana', 'lakatan', 'saging na hinog', 'banana fruit'],
    category: 'fruits',
    calPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23.0, fatPer100g: 0.3,
    gramsPerServing: 120, servingDescription: '1 medium',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Banana Cue',
    searchNames: ['banana cue', 'bananaq', 'fried banana', 'carmelized banana', 'saging na prito', 'banana cue stick'],
    category: 'fruits',
    calPer100g: 200, proteinPer100g: 1.5, carbsPer100g: 36.0, fatPer100g: 7.0,
    gramsPerServing: 90, servingDescription: '1 stick (2 pieces)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Mango (Carabao)',
    searchNames: ['mango', 'green mango', 'mangga', 'carabao mango', 'philippine mango', 'hinog na mangga'],
    category: 'fruits',
    calPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15.0, fatPer100g: 0.4,
    gramsPerServing: 165, servingDescription: '1 medium',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Apple',
    searchNames: ['apple', 'mansanas', 'red apple', 'green apple', 'apple fruit'],
    category: 'fruits',
    calPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14.0, fatPer100g: 0.2,
    gramsPerServing: 182, servingDescription: '1 medium',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Orange / Dalandan',
    searchNames: ['orange', 'dalandan', 'kahel', 'citrus', 'sintunis', 'orange fruit'],
    category: 'fruits',
    calPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12.0, fatPer100g: 0.1,
    gramsPerServing: 131, servingDescription: '1 medium',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Pineapple',
    searchNames: ['pineapple', 'pinya', 'ananas', 'pineapple chunks', 'pinya fruit'],
    category: 'fruits',
    calPer100g: 50, proteinPer100g: 0.5, carbsPer100g: 13.0, fatPer100g: 0.1,
    gramsPerServing: 165, servingDescription: '1 cup cubed',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Watermelon',
    searchNames: ['watermelon', 'pakwan', 'water melon', 'pakwan fruit'],
    category: 'fruits',
    calPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 8.0, fatPer100g: 0.2,
    gramsPerServing: 300, servingDescription: '1 cup cubed',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Papaya',
    searchNames: ['papaya', 'papaya fruit', 'ripe papaya', 'hinog na papaya'],
    category: 'fruits',
    calPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 11.0, fatPer100g: 0.3,
    gramsPerServing: 140, servingDescription: '1 cup cubed',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Avocado',
    searchNames: ['avocado', 'alligator pear', 'abokado', 'avocado fruit'],
    category: 'fruits',
    calPer100g: 160, proteinPer100g: 2.0, carbsPer100g: 9.0, fatPer100g: 15.0,
    gramsPerServing: 100, servingDescription: 'half medium',
    dataSource: 'USDA',
  ),

  // ═══ DESSERTS & SWEETS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Turon',
    searchNames: ['turon', 'banana lumpia', 'fried spring roll banana', 'turon saging', 'banana turon', 'turon na saging'],
    category: 'desserts',
    calPer100g: 320, proteinPer100g: 2.0, carbsPer100g: 45.0, fatPer100g: 14.0,
    gramsPerServing: 50, servingDescription: '1 piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Taho',
    searchNames: ['taho', 'silken tofu', 'tofu dessert', 'taho with sago', 'soybean dessert'],
    category: 'desserts',
    calPer100g: 90, proteinPer100g: 8.0, carbsPer100g: 16.0, fatPer100g: 1.5,
    gramsPerServing: 240, servingDescription: '1 cup',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Halo-Halo',
    searchNames: ['halo halo', 'halo-halo', 'haluhalo', 'shaved ice dessert', 'mixed dessert', 'halo2x'],
    category: 'desserts',
    calPer100g: 120, proteinPer100g: 2.5, carbsPer100g: 23.0, fatPer100g: 3.5,
    gramsPerServing: 300, servingDescription: '1 regular serving',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Leche Flan',
    searchNames: ['leche flan', 'custard dessert', 'caramel custard', 'flan', 'creme caramel', 'letse plan'],
    category: 'desserts',
    calPer100g: 270, proteinPer100g: 5.0, carbsPer100g: 35.0, fatPer100g: 12.0,
    gramsPerServing: 80, servingDescription: '1 slice',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Ice Cream (Vanilla)',
    searchNames: ['ice cream', 'magnolia ice cream', 'selecta', 'vanilla ice cream', 'sorbetes', 'dirty ice cream'],
    category: 'desserts',
    calPer100g: 195, proteinPer100g: 3.5, carbsPer100g: 23.0, fatPer100g: 10.0,
    gramsPerServing: 100, servingDescription: '1 scoop',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Bibingka',
    searchNames: ['bibingka', 'rice cake', 'bebingka', 'coconut rice cake', 'filipino rice cake'],
    category: 'desserts',
    calPer100g: 330, proteinPer100g: 5.0, carbsPer100g: 50.0, fatPer100g: 12.0,
    gramsPerServing: 100, servingDescription: '1 small piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Puto',
    searchNames: ['puto', 'rice muffin', 'steamed rice cake', 'puto cheese', 'putong bigas'],
    category: 'desserts',
    calPer100g: 230, proteinPer100g: 4.0, carbsPer100g: 45.0, fatPer100g: 3.0,
    gramsPerServing: 50, servingDescription: '1 piece (50g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Ube Halaya',
    searchNames: ['ube halaya', 'purple yam jam', 'ube jam', 'halayang ube', 'ube dessert'],
    category: 'desserts',
    calPer100g: 220, proteinPer100g: 2.5, carbsPer100g: 38.0, fatPer100g: 7.0,
    gramsPerServing: 60, servingDescription: '2 tbsp (~60g)',
    dataSource: 'FNRI',
  ),

  // ═══ BEVERAGES ═══
  VerifiedFoodBaseline(
    canonicalName: 'Black Coffee',
    searchNames: ['coffee', 'black coffee', 'kapeng barako', 'black brewed', 'brewed coffee', 'kape', 'kapeng itim'],
    category: 'beverages',
    calPer100g: 1, proteinPer100g: 0.1, carbsPer100g: 0.0, fatPer100g: 0.0,
    gramsPerServing: 240, servingDescription: '1 cup (240ml)',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: '3-in-1 Coffee Mix',
    searchNames: ['3in1 coffee', '3 in 1', 'kopiko', 'instant coffee', 'nescafe 3in1', 'great taste 3in1', 'coffee mix'],
    category: 'beverages',
    calPer100g: 420, proteinPer100g: 3.0, carbsPer100g: 77.0, fatPer100g: 11.0,
    gramsPerServing: 20, servingDescription: '1 sachet (20g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fresh Milk',
    searchNames: ['milk', 'fresh milk', 'gatas', 'cow milk', 'full cream milk', 'whole milk'],
    category: 'beverages',
    calPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3,
    gramsPerServing: 240, servingDescription: '1 glass (240ml)',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Buko Juice',
    searchNames: ['buko juice', 'coconut juice', 'buko water', 'coconut water', 'fresh buko'],
    category: 'beverages',
    calPer100g: 19, proteinPer100g: 0.7, carbsPer100g: 3.7, fatPer100g: 0.2,
    gramsPerServing: 330, servingDescription: '1 buko (~330ml)',
    dataSource: 'USDA',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Milk Tea',
    searchNames: ['milk tea', 'milktea', 'bubble tea', 'pearl milk tea', 'nai cha', 'cha time', 'milk tea with pearls'],
    category: 'beverages',
    calPer100g: 85, proteinPer100g: 1.5, carbsPer100g: 15.0, fatPer100g: 3.0,
    gramsPerServing: 500, servingDescription: '1 large cup (~500ml)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Sago\'t Gulaman',
    searchNames: ['sagot gulaman', 'sago gulaman', 'sago at gulaman', 'tapioca jelly drink', 'sago jelly drink', 'samalamig'],
    category: 'beverages',
    calPer100g: 70, proteinPer100g: 0.5, carbsPer100g: 17.0, fatPer100g: 0.2,
    gramsPerServing: 350, servingDescription: '1 large cup',
    dataSource: 'FNRI',
  ),

  // ═══ STREET FOOD & SNACKS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Skyflakes Crackers',
    searchNames: ['skyflakes', 'crackers', 'sky flakes', 'salty crackers', 'sky flakes crackers', 'skyflakes biscuit'],
    category: 'snacks',
    calPer100g: 430, proteinPer100g: 7.5, carbsPer100g: 61.0, fatPer100g: 16.0,
    gramsPerServing: 28, servingDescription: '1 piece',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Fishball',
    searchNames: ['fishball', 'fish ball', 'fish balls', 'tusok tusok', 'street fishball'],
    category: 'snacks',
    calPer100g: 150, proteinPer100g: 6.0, carbsPer100g: 23.0, fatPer100g: 2.5,
    gramsPerServing: 15, servingDescription: '1 piece (~15g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Kikiam',
    searchNames: ['kikiam', 'meat roll', 'kikyam', 'ngohiong', 'street kikiam', 'kikiam stick'],
    category: 'snacks',
    calPer100g: 240, proteinPer100g: 8.0, carbsPer100g: 18.0, fatPer100g: 14.0,
    gramsPerServing: 30, servingDescription: '1 piece (~30g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Kwek-Kwek',
    searchNames: ['kwek kwek', 'kwek-kwek', 'tokneneng', 'orange egg', 'battered quail egg', 'quail egg balls'],
    category: 'snacks',
    calPer100g: 180, proteinPer100g: 7.0, carbsPer100g: 15.0, fatPer100g: 9.0,
    gramsPerServing: 30, servingDescription: '1 piece (~30g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Isaw (Grilled Intestine)',
    searchNames: ['isaw', 'grilled intestine', 'pork isaw', 'chicken isaw', 'ihaw isaw', 'street isaw'],
    category: 'snacks',
    calPer100g: 210, proteinPer100g: 12.0, carbsPer100g: 3.0, fatPer100g: 16.0,
    gramsPerServing: 50, servingDescription: '1 stick (~50g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Chicharon',
    searchNames: ['chicharon', 'chicharron', 'pork rinds', 'pork cracklings', 'chicharon baboy', 'chicharon with laman'],
    category: 'snacks',
    calPer100g: 550, proteinPer100g: 35.0, carbsPer100g: 0.0, fatPer100g: 45.0,
    gramsPerServing: 30, servingDescription: '1 small bag (~30g)',
    dataSource: 'FNRI',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Balut',
    searchNames: ['balut', 'balot', 'duck embryo', 'fertilized duck egg', 'balut egg', 'pinoy balut'],
    category: 'snacks',
    calPer100g: 188, proteinPer100g: 14.0, carbsPer100g: 1.0, fatPer100g: 14.0,
    gramsPerServing: 100, servingDescription: '1 piece (~100g)',
    dataSource: 'FNRI',
  ),

  // ═══ COMMON SIDES & CONDIMENTS ═══
  VerifiedFoodBaseline(
    canonicalName: 'Boiled Corn (Mais)',
    searchNames: ['corn', 'mais', 'boiled corn', 'corn on cob', 'sweet corn', 'mais na pinakuluan'],
    category: 'snacks',
    calPer100g: 96, proteinPer100g: 3.4, carbsPer100g: 21.0, fatPer100g: 1.5,
    gramsPerServing: 150, servingDescription: '1 medium ear',
    dataSource: 'USDA',
  ),

  // ═══ FAST FOOD (Philippine chains) ═══
  VerifiedFoodBaseline(
    canonicalName: 'Jollibee Chickenjoy (1pc with rice)',
    searchNames: ['jollibee chickenjoy', 'chicken joy with rice', 'jollibee 1pc', '1pc chicken joy', 'jabee chicken'],
    category: 'poultry',
    calPer100g: 220, proteinPer100g: 14.0, carbsPer100g: 22.0, fatPer100g: 9.0,
    gramsPerServing: 250, servingDescription: '1pc chicken + rice (~250g)',
    dataSource: 'EST',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Jollibee Yumburger',
    searchNames: ['yumburger', 'jollibee burger', 'yum burger', 'jabee burger', 'jollibee yumburger'],
    category: 'snacks',
    calPer100g: 265, proteinPer100g: 12.0, carbsPer100g: 22.0, fatPer100g: 13.0,
    gramsPerServing: 120, servingDescription: '1 burger (~120g)',
    dataSource: 'EST',
  ),
  VerifiedFoodBaseline(
    canonicalName: 'Jollibee Spaghetti',
    searchNames: ['jollibee spaghetti', 'jabee spaghetti', 'filipino spaghetti', 'sweet spaghetti', 'jollibee spag'],
    category: 'noodles',
    calPer100g: 140, proteinPer100g: 5.0, carbsPer100g: 22.0, fatPer100g: 3.5,
    gramsPerServing: 250, servingDescription: '1 regular serving (~250g)',
    dataSource: 'EST',
  ),
];

/// Hardcoded lookup for branded Filipino packaged products.
/// These are exact-match entries for products the AI frequently gets wrong.
/// Sources: actual product labels, Open Food Facts, manufacturer published data.
const brandedProductLookup = <String, BrandedProductData>{
  // ═══ DUTCH MILL ═══
  'dutch mill delight': BrandedProductData(
    productName: 'Dutch Mill Delight Probiotic Drink',
    searchNames: ['dutchmill delight', 'dutch mill delight', 'delight probio', 'dutch mill probiotic'],
    per100ml: BrandedNutritionPer100(cal: 79, protein: 1.6, carbs: 17.8, fat: 0.0),
    servingMl: 400,
    servingDescription: '1 bottle (400ml)',
    source: 'Open Food Facts / Product Label',
  ),
  'dutch mill delight fiber': BrandedProductData(
    productName: 'Dutch Mill Delight Plus Probiotic Fiber',
    searchNames: ['dutch mill fiber', 'dutchmill fiber', 'delight fiber', 'delight plus fiber'],
    per100ml: BrandedNutritionPer100(cal: 79, protein: 1.6, carbs: 17.8, fat: 0.0, fiber: 0.5),
    servingMl: 400,
    servingDescription: '1 bottle (400ml)',
    source: 'Open Food Facts / Product Label',
  ),
  'dutch mill selected': BrandedProductData(
    productName: 'Dutch Mill Selected Fresh Milk',
    searchNames: ['dutch mill selected', 'dutchmill selected', 'dutch mill fresh milk'],
    per100ml: BrandedNutritionPer100(cal: 68, protein: 3.2, carbs: 5.0, fat: 3.8),
    servingMl: 830,
    servingDescription: '1 bottle (830ml)',
    source: 'Open Food Facts',
  ),

  // ═══ NESTLÉ / NIDO ═══
  'nido 3+': BrandedProductData(
    productName: 'Nido 3+ Powdered Milk Drink',
    searchNames: ['nido 3+', 'nido 3 plus', 'nido milk', 'nido powdered milk'],
    per100ml: BrandedNutritionPer100(cal: 67, protein: 2.8, carbs: 8.5, fat: 2.5),
    servingMl: 240,
    servingDescription: '1 glass (240ml prepared)',
    source: 'Nestlé Philippines Label',
  ),
  'nescafe 3-in-1': BrandedProductData(
    productName: 'Nescafe 3-in-1 Original',
    searchNames: ['nescafe 3in1', 'nescafe 3 in 1', 'nescafe original 3in1', 'nescafe stick'],
    per100ml: BrandedNutritionPer100(cal: 54, protein: 0.4, carbs: 11.0, fat: 0.9),
    servingMl: 180,
    servingDescription: '1 sachet (20g + 180ml water)',
    source: 'Nestlé Philippines Label',
  ),

  // ═══ SELECTA / MAGNOLIA ═══
  'selecta ice cream vanilla': BrandedProductData(
    productName: 'Selecta Premium Ice Cream (Vanilla)',
    searchNames: ['selecta ice cream', 'selecta vanilla', 'selecta premium ice cream'],
    per100ml: BrandedNutritionPer100(cal: 210, protein: 3.5, carbs: 24.0, fat: 11.0),
    servingMl: 100,
    servingDescription: '1 scoop (100g)',
    source: 'Selecta Philippines Label',
  ),
  'magnolia ice cream vanilla': BrandedProductData(
    productName: 'Magnolia Ice Cream (Vanilla)',
    searchNames: ['magnolia ice cream', 'magnolia vanilla', 'magnolia ice cream vanilla'],
    per100ml: BrandedNutritionPer100(cal: 200, protein: 3.0, carbs: 23.0, fat: 10.5),
    servingMl: 100,
    servingDescription: '1 scoop (100g)',
    source: 'Magnolia Philippines Label',
  ),
  'selecta choco almond': BrandedProductData(
    productName: 'Selecta Double Dutch Ice Cream',
    searchNames: ['selecta double dutch', 'selecta choco', 'selecta chocolate ice cream'],
    per100ml: BrandedNutritionPer100(cal: 240, protein: 4.0, carbs: 27.0, fat: 13.0),
    servingMl: 100,
    servingDescription: '1 scoop (100g)',
    source: 'Selecta Philippines Label',
  ),

  // ═══ JACK 'n JILL / UNIVERSAL ROBINA ═══
  'jack n jill potato chips': BrandedProductData(
    productName: 'Jack\'n Jill Potato Chips',
    searchNames: ['jack n jill chips', 'potato chips pinoy', 'jack and jill chips', 'jack n jill potatoe chips'],
    per100ml: BrandedNutritionPer100(cal: 530, protein: 6.5, carbs: 51.0, fat: 33.0),
    servingMl: 40,
    servingDescription: '1 small bag (40g)',
    source: 'Universal Robina Label',
  ),
  'nova': BrandedProductData(
    productName: 'Nova Country Cheddar',
    searchNames: ['nova chips', 'nova cheddar', 'nova country cheddar', 'nova cracker'],
    per100ml: BrandedNutritionPer100(cal: 500, protein: 5.0, carbs: 53.0, fat: 30.0),
    servingMl: 45,
    servingDescription: '1 small bag (45g)',
    source: 'Universal Robina Label',
  ),
  'piattos': BrandedProductData(
    productName: 'Piattos (Sour Cream & Onion)',
    searchNames: ['piattos', 'piattos chips', 'piattos sour cream', 'piatos'],
    per100ml: BrandedNutritionPer100(cal: 510, protein: 5.5, carbs: 52.0, fat: 31.0),
    servingMl: 45,
    servingDescription: '1 small bag (45g)',
    source: 'Universal Robina Label',
  ),

  // ═══ COCA-COLA / PEPT ☐
  'coke original': BrandedProductData(
    productName: 'Coca-Cola Original',
    searchNames: ['coke', 'coca cola', 'coke softdrink', 'coca-cola', 'coke soda'],
    per100ml: BrandedNutritionPer100(cal: 42, protein: 0.0, carbs: 10.6, fat: 0.0),
    servingMl: 330,
    servingDescription: '1 can (330ml)',
    source: 'Coca-Cola Label',
  ),
  'coke zero': BrandedProductData(
    productName: 'Coca-Cola Zero Sugar',
    searchNames: ['coke zero', 'coca cola zero', 'coke zero sugar', 'coke diet'],
    per100ml: BrandedNutritionPer100(cal: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0),
    servingMl: 330,
    servingDescription: '1 can (330ml)',
    source: 'Coca-Cola Label',
  ),

  // ═══ SAN MIGUEL ═══
  'san miguel pale pilsen': BrandedProductData(
    productName: 'San Miguel Pale Pilsen',
    searchNames: ['san miguel', 'pale pilsen', 'beer san miguel', 'san miguel beer', 'pale pilsen beer'],
    per100ml: BrandedNutritionPer100(cal: 43, protein: 0.4, carbs: 3.6, fat: 0.0),
    servingMl: 330,
    servingDescription: '1 bottle (330ml)',
    source: 'San Miguel Brewery Label',
  ),
  'san miguel light': BrandedProductData(
    productName: 'San Miguel Light Beer',
    searchNames: ['san miguel light', 'light beer sm', 'sm light beer'],
    per100ml: BrandedNutritionPer100(cal: 26, protein: 0.2, carbs: 1.5, fat: 0.0),
    servingMl: 330,
    servingDescription: '1 bottle (330ml)',
    source: 'San Miguel Brewery Label',
  ),
};

class BrandedNutritionPer100 {
  final double cal;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  const BrandedNutritionPer100({
    required this.cal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
  });
}

class BrandedProductData {
  final String productName;
  final List<String> searchNames;
  final BrandedNutritionPer100 per100ml;
  final double servingMl;
  final String servingDescription;
  final String source;
  const BrandedProductData({
    required this.productName,
    required this.searchNames,
    required this.per100ml,
    required this.servingMl,
    required this.servingDescription,
    required this.source,
  });
}

class LocalFoodMatch {
  final String matchedName;
  final double calPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? gramsPerServing;
  final String? servingDescription;
  final double confidence;
  final String dataSource;

  const LocalFoodMatch({
    required this.matchedName,
    required this.calPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.gramsPerServing,
    this.servingDescription,
    required this.confidence,
    this.dataSource = 'FNRI',
  });
}

class LocalFoodDatabase {
  LocalFoodMatch? search(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.length < 3) return null;

    // Check branded products first (exact match preferred)
    for (final entry in brandedProductLookup.entries) {
      final product = entry.value;
      // Check for exact or very close brand name match
      for (final name in product.searchNames) {
        final matches = normalized == name ||
            (normalized.length >= 4 && normalized.contains(name)) ||
            (name.length >= 4 && normalized.length >= 4 && name.contains(normalized));
        if (matches) {
          return LocalFoodMatch(
            matchedName: product.productName,
            calPer100g: product.per100ml.cal,
            proteinPer100g: product.per100ml.protein,
            carbsPer100g: product.per100ml.carbs,
            fatPer100g: product.per100ml.fat,
            gramsPerServing: product.servingMl,
            servingDescription: product.servingDescription,
            confidence: 0.95,
            dataSource: product.source,
          );
        }
      }
    }

    // Fall back to fuzzy match against generic Filipino baselines
    LocalFoodMatch? best;
    double bestScore = 0;

    for (final food in verifiedFoodBaselines) {
      for (final name in food.searchNames) {
        final score = _matchScore(normalized, name);
        if (score > bestScore) {
          bestScore = score;
          best = LocalFoodMatch(
            matchedName: food.canonicalName,
            calPer100g: food.calPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
            gramsPerServing: food.gramsPerServing,
            servingDescription: food.servingDescription,
            confidence: score,
            dataSource: food.dataSource,
          );
        }
      }
    }

    if (bestScore >= 0.7) return best;
    return null;
  }

  double _matchScore(String query, String name) {
    if (query == name) return 1.0;
    if (name.contains(query)) return 0.85;
    if (query.contains(name)) return 0.80;

    final qWords = query.split(RegExp(r'\s+'));
    final nWords = name.split(RegExp(r'\s+'));
    var matches = 0;
    for (final q in qWords) {
      if (q.length < 3) continue;
      for (final n in nWords) {
        if (n.contains(q) || q.contains(n)) {
          matches++;
          break;
        }
      }
    }
    if (matches == 0) return 0;
    return (matches / qWords.length) * 0.7;
  }
}
