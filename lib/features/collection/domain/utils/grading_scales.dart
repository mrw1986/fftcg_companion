/// Utility class to provide grading scales for different grading companies
class GradingScales {
  /// PSA grading scale - short codes
  static const List<String> psaGrades = [
    'GEM-MT 10',
    'MINT 9',
    'NM-MT 8',
    'NM 7',
    'EX-MT 6',
    'EX 5',
    'VG-EX 4',
    'VG 3',
    'GOOD 2',
    'FR 1.5',
    'PR 1',
  ];

  /// BGS grading scale - short codes
  static const List<String> bgsGrades = [
    'PRISTINE 10',
    'GEM MINT 9.5',
    'MINT 9',
    'NM-MT 8',
    'NM 7',
    'EX-MT 6',
    'EX 5',
    'VG-EX 4',
    'VG 3',
    'GOOD 2',
    'POOR 1',
  ];

  /// CGC grading scale - short codes
  static const List<String> cgcGrades = [
    'GEM MINT 10',
    'MINT 9.9',
    'NM/M 9.8',
    'NM+ 9.6',
    'NM 9.4',
    'NM- 9.2',
    'VF/NM 9.0',
    'VF+ 8.5',
    'VF 8.0',
    'VF- 7.5',
    'FN/VF 7.0',
    'FN+ 6.5',
    'FN 6.0',
    'FN- 5.5',
    'VG/FN 5.0',
    'VG+ 4.5',
    'VG 4.0',
    'VG- 3.5',
    'G/VG 3.0',
    '2.5',
    'G 2.0',
    'G- 1.8',
    'Fa/G 1.5',
    'Fa 1.0',
    'Poor 0.5',
  ];

  /// PSA grading scale - with descriptions (for tooltips/info)
  static const Map<String, String> psaGradeDescriptions = {
    'GEM-MT 10':
        'Virtually perfect card with sharp corners, sharp focus and full original gloss',
    'MINT 9':
        'Superb condition with only one minor flaw like slightly off-center or a minor printing imperfection',
    'NM-MT 8':
        'Super high-end card that appears Mint at first glance but has very slight wax stain, minor printing imperfection, or slightly off-white borders',
    'NM 7':
        'Just a slight surface wear visible upon close inspection with slight wax staining or minor border discoloration',
    'EX-MT 6':
        'Minor surface wear or printing defect with slight notching or minor wax stain',
    'EX 5':
        'Minor rounding of corners with surface wear, minor chipping on edges, and loss of some original gloss',
    'VG-EX 4':
        'Slightly rounded corners with noticeable surface wear and light scratches',
    'VG 3':
        'Some rounding of corners with noticeable surface wear, light scratches, and borders may be somewhat discolored',
    'GOOD 2':
        'Corners show noticeable rounding with scratching, scuffing, and considerable discoloration',
    'FR 1.5':
        'Extreme wear with advanced stages of wear, scuffing, scratching, and staining',
    'PR 1':
        'Exhibits many defects in such an extreme stage that the eye appeal has nearly vanished',
  };

  /// BGS grading scale - with descriptions (for tooltips/info)
  static const Map<String, String> bgsGradeDescriptions = {
    'PRISTINE 10':
        'Perfect card with no imperfections visible under magnification',
    'GEM MINT 9.5': 'Near perfect with only one minor imperfection',
    'MINT 9': 'Nearly flawless with only minor imperfections',
    'NM-MT 8': 'Near Mint-Mint with slight imperfections',
    'NM 7': 'Near Mint with minor border wear or slight diamond cutting',
    'EX-MT 6': 'Excellent-Mint with slight diamond cutting and minor wear',
    'EX 5': 'Excellent with slight diamond cutting and fuzzy corners',
    'VG-EX 4': 'Very Good-Excellent with moderate diamond cutting and notching',
    'VG 3': 'Very Good with moderate diamond cutting and rounded corners',
    'GOOD 2':
        'Good with noticeable diamond cutting and heavily notched corners',
    'POOR 1': 'Poor with heavy diamond cutting and heavily rounded corners',
  };

  /// CGC grading scale - with descriptions (for tooltips/info)
  static const Map<String, String> cgcGradeDescriptions = {
    'GEM MINT 10': 'No evidence of any manufacturing or handling defects',
    'MINT 9.9':
        'Nearly indistinguishable from a 10.0 but with a very minor manufacturing defect',
    'NM/M 9.8':
        'Nearly perfect with negligible handling or manufacturing defects',
    'NM+ 9.6':
        'Very well-preserved with several minor manufacturing or handling defects',
    'NM 9.4':
        'Very well-preserved with minor wear and small manufacturing or handling defects',
    'NM- 9.2':
        'Very well-preserved with some wear and small manufacturing or handling defects',
    'VF/NM 9.0':
        'Very well-preserved with good eye appeal and a number of minor handling and/or manufacturing defects',
    'VF+ 8.5': 'Attractive with a moderate defect or a number of small defects',
    'VF 8.0':
        'Attractive with a moderate defect or an accumulation of small defects',
    'VF- 7.5':
        'Above-average with a moderate defect or an accumulation of small defects',
    'FN/VF 7.0':
        'Above-average with a major defect or an accumulation of small defects',
    'FN+ 6.5': 'Above-average with a major defect and some smaller defects',
    'FN 6.0':
        'Slightly above-average with a major defect and some smaller defects',
    'FN- 5.5': 'Slightly above-average with several moderate defects',
    'VG/FN 5.0': 'Average with several moderate defects',
    'VG+ 4.5': 'Slightly below-average with multiple moderate defects',
    'VG 4.0': 'Below-average with multiple moderate defects',
    'VG- 3.5':
        'Below-average with several major defects or an accumulation of multiple moderate defects',
    'G/VG 3.0':
        'Shows significant evidence of handling with several moderate-to-major defects',
    '2.5':
        'Shows extensive evidence of handling with multiple moderate-to-major defects',
    'G 2.0':
        'Shows extensive evidence of handling with numerous moderate-to-major defects',
    'G- 1.8':
        'Shows extensive evidence of handling with numerous major defects',
    'Fa/G 1.5':
        'Shows extensive evidence of handling with a heavy accumulation of major defects',
    'Fa 1.0': 'Very poorly handled with a heavy accumulation of major defects',
    'Poor 0.5': 'Heavily defaced with a number of major defects',
  };

  /// Get grades for a specific grading company
  static List<String> getGradesForCompany(String company) {
    switch (company) {
      case 'PSA':
        return psaGrades;
      case 'BGS':
        return bgsGrades;
      case 'CGC':
        return cgcGrades;
      default:
        return psaGrades;
    }
  }

  /// Get grade description for a specific grade and company
  static String? getGradeDescription(String company, String grade) {
    switch (company) {
      case 'PSA':
        return psaGradeDescriptions[grade];
      case 'BGS':
        return bgsGradeDescriptions[grade];
      case 'CGC':
        return cgcGradeDescriptions[grade];
      default:
        return null;
    }
  }
}
