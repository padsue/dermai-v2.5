// Based on diseaseLabelsV3.txt - 20 skin conditions with medical descriptions
// Disease names must match exactly what SeverityHelper.parseDiseaseLabel() returns
final Map<String, List<Map<String, String>>> skinConditionsByCategory = {
  "Infections": [
    {
      "id": "16",
      "name": "Tinea",
      "description":
          "A contagious fungal infection (ringworm) that affects the skin, scalp, or nails. Presents as itchy, red, circular patches with raised borders and clearer centers. Common in warm, moist areas of the body.",
    },
    {
      "id": "19",
      "name": "Warts",
      "description":
          "Small, rough, benign skin growths caused by human papillomavirus (HPV). They appear as raised bumps with a rough texture and can occur anywhere on the body, most commonly on hands and feet.",
    },
  ],
  "Inflammations": [
    {
      "id": "1",
      "name": "Acne",
      "description":
          "A common inflammatory skin condition where hair follicles become clogged with oil and dead skin cells. Causes pimples, blackheads, whiteheads, and sometimes deeper cysts. Severity ranges from mild (occasional breakouts) to moderate (persistent lesions) to severe (widespread cystic acne with potential scarring).",
    },
    {
      "id": "5",
      "name": "Eczema",
      "description":
          "A chronic inflammatory skin condition (atopic dermatitis) that causes intensely itchy, red, dry, and cracked patches of skin. Can range from moderate (localized patches with redness and scaling) to severe (widespread inflammation, weeping lesions, and significant discomfort). Often worsens with triggers like allergens or stress.",
    },
    {
      "id": "11",
      "name": "Psoriasis",
      "description":
          "A chronic autoimmune condition that speeds up skin cell growth, causing thick, red, scaly patches (plaques) that can be itchy, painful, or burn. Most commonly appears on elbows, knees, scalp, and lower back. Severity varies from moderate localized plaques to widespread involvement.",
    },
    {
      "id": "12",
      "name": "Rosacea",
      "description":
          "A chronic inflammatory skin condition that primarily affects the face, causing persistent redness, visible blood vessels, and sometimes acne-like pimples. May range from mild (occasional flushing and slight redness) to moderate (persistent facial redness with visible vessels and bumps). Common triggers include sun, stress, and certain foods.",
    },
    {
      "id": "8",
      "name": "Lupus",
      "description":
          "A severe autoimmune disease that can affect the skin and other organs. Cutaneous lupus causes characteristic butterfly-shaped rashes on the face, discoid lesions (round, scaly patches), or photosensitive rashes. Represents a serious condition requiring medical management.",
    },
  ],
  "Normal": [
    {
      "id": "10",
      "name": "Normal",
      "description":
          "Healthy skin without visible disease, lesions, or abnormal growths. Shows normal color, texture, and appearance. No treatment required.",
    },
  ],
  "Benign Growths": [
    {
      "id": "18",
      "name": "Vitiligo",
      "description":
          "An autoimmune condition that causes loss of skin pigment, resulting in white or light-colored patches on the skin. Occurs when melanocytes (pigment-producing cells) are destroyed. Generally harmless but can affect appearance and may have psychological impact. Usually mild in severity.",
    },
    {
      "id": "9",
      "name": "Mole",
      "description":
          "Harmless clusters of pigmented cells (melanocytes) that appear as small brown or black spots on the skin. Most moles are benign and stable, though they should be monitored for changes in size, shape, color, or texture that might indicate melanoma.",
    },
    {
      "id": "4",
      "name": "Benign Tumors",
      "description":
          "Non-cancerous skin growths that do not invade nearby tissues or spread to other parts of the body. These are generally harmless but may be removed for cosmetic reasons or if they cause discomfort. Moderate in clinical significance.",
    },
    {
      "id": "14",
      "name": "Seborrh Keratoses",
      "description":
          "Common, harmless skin growths that appear waxy, raised, and brown, black, or tan in color. Often described as having a 'stuck-on' appearance. Typically develop with age and are completely benign. Mild in severity with no cancer risk.",
    },
  ],
  "Cancers": [
    {
      "id": "8",
      "name": "Melanoma",
      "description":
          "A severe and potentially life-threatening type of skin cancer that develops from melanocytes (pigment-producing cells). Often appears as an irregular or changing mole with asymmetry, irregular borders, multiple colors, or diameter greater than 6mm. Early detection and treatment are critical as it can spread to other organs.",
    },
    {
      "id": "3",
      "name": "Basal Cell Carcinoma",
      "description":
          "The most common type of skin cancer, arising from basal cells in the lower epidermis. Typically appears as a pearly or waxy bump, flat flesh-colored or brown scar-like lesion. Moderate in severity as it rarely spreads but can cause local tissue damage if untreated. Usually develops on sun-exposed areas.",
    },
    {
      "id": "15",
      "name": "Squamous Cell Carcinoma",
      "description":
          "A severe form of skin cancer that develops from squamous cells in the upper layers of the skin. Appears as firm red nodules, flat lesions with scaly or crusty surfaces, or sores that don't heal. Can spread to other parts of the body if untreated. Common on sun-exposed areas like face, ears, and hands.",
    },
  ],
  "Unclassified": [
    {
      "id": "17",
      "name": "Unknown",
      "description":
          "Skin presentation that cannot be definitively classified into a specific condition category. May require professional dermatological evaluation for accurate diagnosis and appropriate treatment planning.",
    },
  ],
};
