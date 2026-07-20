import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final employee = appState.employee;
    final info = appState.personalInfo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Personal information',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Editing is not available in this preview'),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        employee.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${employee.role} · ${employee.department} · ${employee.employeeId}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Basic details',
              rows: [
                _InfoRow('Date of birth', info.dateOfBirth),
                _InfoRow('Gender', info.gender),
                _InfoRow('Marital status', info.maritalStatus),
                _InfoRow('Nationality', info.nationality),
                _InfoRow('NRIC', info.nric),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Contact',
              rows: [
                _InfoRow('Work email', info.workEmail),
                _InfoRow('Mobile', info.mobile),
                _InfoRow('Address', info.address),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Emergency contact',
              rows: [
                _InfoRow('Name', info.emergencyContactName),
                _InfoRow('Relationship', info.emergencyContactRelationship),
                _InfoRow('Phone', info.emergencyContactPhone),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Employment',
              rows: [
                _InfoRow('Department', info.department),
                _InfoRow('Position', info.position),
                _InfoRow('Join date', info.joinDate),
                _InfoRow('Employment type', info.employmentType),
                _InfoRow('Reporting to', info.reportingTo),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Statutory',
              rows: [
                _InfoRow('EPF no.', info.epfNumber),
                _InfoRow('SOCSO no.', info.socsoNumber),
                _InfoRow('Income tax (PCB)', info.incomeTaxNumber),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                'Statutory and employment details are managed by HR. To update them, tap Edit or contact your HR admin.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < rows.length - 1
                          ? const Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)),
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rows[i].label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            rows[i].value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
