class Customer {
  final int id;
  final String customerCode;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String? email;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdDate;

  const Customer({
    required this.id,
    required this.customerCode,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.notes,
    this.isActive = true,
    required this.createdDate,
  });

  String get fullName => '$firstName $lastName';

  Customer copyWith({
    int? id,
    String? customerCode,
    String? firstName,
    String? lastName,
    String? mobileNumber,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? notes,
    bool? isActive,
    DateTime? createdDate,
  }) {
    return Customer(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerCode': customerCode,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'notes': notes,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? 0,
      customerCode: map['customerCode'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      address: map['address'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdDate: DateTime.parse(map['createdDate']),
    );
  }
}