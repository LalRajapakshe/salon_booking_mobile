class BranchRecord {
  final int id;
  final int tenantId;
  final String branchCode;
  final String branchName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? phoneNo;
  final String? email;
  final String? managerName;
  final String? highlight;
  final String? photoPath;
  final bool isHeadOffice;
  final bool isActive;
  final bool isCustomerVisible;

  const BranchRecord({
    required this.id,
    required this.tenantId,
    required this.branchCode,
    required this.branchName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.phoneNo,
    this.email,
    this.managerName,
    this.highlight,
    this.photoPath,
    required this.isHeadOffice,
    required this.isActive,
    this.isCustomerVisible = false,
  });
}
