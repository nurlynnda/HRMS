/// Static personal/employment/statutory details shown on the Profile
/// tab's "Personal information" screen. Read-only in this frontend-only
/// phase — editing is out of scope until there's a real backend.
class PersonalInfo {
  final String dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String nric;
  final String workEmail;
  final String mobile;
  final String address;
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;
  final String department;
  final String position;
  final String joinDate;
  final String employmentType;
  final String reportingTo;
  final String epfNumber;
  final String socsoNumber;
  final String incomeTaxNumber;

  const PersonalInfo({
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    required this.nationality,
    required this.nric,
    required this.workEmail,
    required this.mobile,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactRelationship,
    required this.emergencyContactPhone,
    required this.department,
    required this.position,
    required this.joinDate,
    required this.employmentType,
    required this.reportingTo,
    required this.epfNumber,
    required this.socsoNumber,
    required this.incomeTaxNumber,
  });
}
