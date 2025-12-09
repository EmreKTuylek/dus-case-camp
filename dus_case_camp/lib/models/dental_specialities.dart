enum DentalSpecialty {
  endodontics,
  orthodontics,
  periodontics,
  prosthodontics,
  restorative,
  oral_surgery,
  pedodontics,
  oral_radiology,
  implantology,
  other
}

class DentalSpecialtyConfig {
  static const Map<DentalSpecialty, Map<String, String>> _labels = {
    DentalSpecialty.endodontics: {'en': 'Endodontics', 'tr': 'Endodonti'},
    DentalSpecialty.orthodontics: {'en': 'Orthodontics', 'tr': 'Ortodonti'},
    DentalSpecialty.pedodontics: {'en': 'Pedodontics', 'tr': 'Pedodonti'},
    DentalSpecialty.oral_surgery: {
      'en': 'Oral Surgery',
      'tr': 'Ağız Diş Çene Cerrahisi'
    },
    DentalSpecialty.prosthodontics: {
      'en': 'Prosthodontics',
      'tr': 'Protetik Diş Tedavisi'
    },
    DentalSpecialty.periodontics: {
      'en': 'Periodontics',
      'tr': 'Periodontoloji'
    },
    DentalSpecialty.restorative: {'en': 'Restorative', 'tr': 'Restoratif'},
    DentalSpecialty.oral_radiology: {
      'en': 'Oral Radiology',
      'tr': 'Oral Radyoloji'
    },
    DentalSpecialty.implantology: {'en': 'Implantology', 'tr': 'İmplantoloji'},
    DentalSpecialty.other: {'en': 'Other', 'tr': 'Diğer'},
  };

  static String getLabel(DentalSpecialty s, {String lang = 'tr'}) {
    return _labels[s]?[lang] ?? _labels[s]?['en'] ?? 'Unknown';
  }

  static DentalSpecialty fromKey(String key) {
    return DentalSpecialty.values.firstWhere(
      (e) => e.name == key,
      orElse: () => DentalSpecialty.other,
    );
  }

  // Backward compatibility helper
  static DentalSpecialty guessFromText(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.contains('endo')) return DentalSpecialty.endodontics;
    if (lower.contains('orto') || lower.contains('ortho'))
      return DentalSpecialty.orthodontics;
    if (lower.contains('perio')) return DentalSpecialty.periodontics;
    if (lower.contains('cerrahi') || lower.contains('surg'))
      return DentalSpecialty.oral_surgery;
    if (lower.contains('prote') || lower.contains('prost'))
      return DentalSpecialty.prosthodontics;
    if (lower.contains('restor') || lower.contains('dolgu'))
      return DentalSpecialty.restorative;
    if (lower.contains('ped') ||
        lower.contains('cocuk') ||
        lower.contains('çocuk')) return DentalSpecialty.pedodontics;
    if (lower.contains('rad') || lower.contains('imag'))
      return DentalSpecialty.oral_radiology;
    if (lower.contains('imp')) return DentalSpecialty.implantology;

    // Try direct key match
    for (final s in DentalSpecialty.values) {
      if (s.name == lower) return s;
    }

    return DentalSpecialty.other;
  }
}
