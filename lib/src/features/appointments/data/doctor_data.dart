class DoctorData {
  static final List<Map<String, dynamic>> doctors = [
    {
      'id': 'd1',
      'name_en': 'Dr. Sarah Smith',
      'name_ml': 'ഡോ. സാറ സ്മിത്ത്',
      'department_en': 'Cardiology',
      'department_ml': 'ഹൃദ്രോഗ വിഭാഗം', // Cardiology in Malayalam
    },
    {
      'id': 'd2',
      'name_en': 'Dr. John Doe',
      'name_ml': 'ഡോ. ജോൺ ഡോ',
      'department_en': 'General Medicine',
      'department_ml': 'പൊതുവായ മരുന്ന്', // General Medicine roughly
    },
    {
      'id': 'd3',
      'name_en': 'Dr. Emily White',
      'name_ml': 'ഡോ. എമിലി വൈറ്റ്',
      'department_en': 'Orthopedics',
      'department_ml': 'അസ്ഥിരോഗ വിഭാഗം', // Orthopedics
    },
    {
      'id': 'd4',
      'name_en': 'Dr. David Brown',
      'name_ml': 'ഡോ. ഡേവിഡ് ബ്രൗൺ',
      'department_en': 'Neurology',
      'department_ml': 'ന്യൂറോളജി', // Neurology
    },
  ];

  static String getDoctorName(String doctorId, String languageCode) {
    final doctor = doctors.firstWhere(
      (d) => d['id'] == doctorId || d['name_en'] == doctorId,
      orElse: () => {},
    );
    if (doctor.isEmpty) return doctorId;

    if (languageCode == 'ml') {
      return doctor['name_ml'] ?? doctor['name_en'];
    }
    return doctor['name_en'];
  }
  
  static String getDoctorDepartment(String englishDepartment, String languageCode) {
    final doctor = doctors.firstWhere(
      (d) => d['department_en'] == englishDepartment,
      orElse: () => {},
    );
    if (doctor.isEmpty) return englishDepartment;

    if (languageCode == 'ml') {
      return doctor['department_ml'] ?? englishDepartment;
    }
    return englishDepartment;
  }
}
