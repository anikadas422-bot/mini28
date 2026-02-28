import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../medication/screens/medical_records_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailScreen({Key? key, required this.patientData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String patientId = patientData['uid'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: patientId.isEmpty 
          ? const Center(child: Text("Missing Patient ID"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading data."));
                }

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Merge initial data (from list) with fresh real-time data from Firestore
                final data = Map<String, dynamic>.from(patientData);
                if (snapshot.hasData && snapshot.data!.exists) {
                   data.addAll(snapshot.data!.data() as Map<String, dynamic>);
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // 1. Basic Details Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        color: Colors.teal.shade50,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.teal,
                              child: Text(
                                (data['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['name'] ?? 'Unknown Patient',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              data['uniqueId'] ?? 'No ID',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            
                            // Wrap Contact and Address inside a cohesive card
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade200)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _DetailRow(icon: Icons.cake, label: 'Age', value: data['age']?.toString() ?? 'Not provided'),
                                    const Divider(),
                                    _DetailRow(icon: Icons.person, label: 'Gender', value: data['gender'] ?? 'Not provided'),
                                    const Divider(),
                                    _DetailRow(icon: Icons.phone, label: 'Contact Number', value: data['phone'] ?? 'Not provided'),
                                    const Divider(),
                                    _DetailRow(icon: Icons.location_on, label: 'Address', value: data['address'] ?? 'Not provided'),
                                    const Divider(),
                                    _DetailRow(icon: Icons.emergency, label: 'Emergency Contact', value: data['emergencyContact'] ?? 'Not provided'),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      // Sections Wrap
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. Medical Overview Section
                            const Text("Medical Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _DetailRow(icon: Icons.bloodtype, label: 'Blood Group', value: data['bloodGroup'] ?? 'Not provided', iconColor: Colors.red),
                                    const Divider(),
                                    _DetailRow(icon: Icons.medical_services, label: 'Primary Condition', value: data['conditions'] ?? 'None recorded', iconColor: Colors.blue),
                                    const Divider(),
                                    _DetailRow(icon: Icons.sick, label: 'Chronic Diseases', value: data['chronicDiseases'] ?? 'None recorded', iconColor: Colors.purple),
                                    const Divider(),
                                    _DetailRow(icon: Icons.warning, label: 'Known Allergies', value: data['allergies'] ?? 'None recorded', iconColor: Colors.orange),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            
                            // 3. Appointments Module
                            const Text("Doctor & Appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 12),
                            _AppointmentsSection(patientId: patientId),

                            const SizedBox(height: 24),

                            // 4. Medical Records Button (Navigate inside context)
                            const Text("Documents & Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MedicalRecordsScreen(patientId: patientId))
                                  );
                                },
                                icon: const Icon(Icons.folder_shared),
                                label: const Text("View & Upload Medical Records"),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade900,
                                    side: BorderSide(color: Colors.blue.shade200),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }
          )
    );
  }
}

class _AppointmentsSection extends StatelessWidget {
  final String patientId;

  const _AppointmentsSection({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Error loading appointments"),
          ));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No doctor appointments scheduled.", style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final doctorName = data['doctorName'] ?? 'Unknown Doctor';
              final department = data['department'] ?? 'General';
              final hospitalName = data['hospitalName'] ?? 'CareNow Hospital';
              final date = (data['appointmentDate'] as Timestamp).toDate();
              final status = data['status'] ?? 'pending';
              
              Color statusColor = Colors.grey;
              if (status == 'approved' || status == 'serving' || status == 'waiting') statusColor = Colors.green;
              if (status == 'pending') statusColor = Colors.orange;
              if (status == 'rejected') statusColor = Colors.red;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: statusColor),
                ),
                title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$department • $hospitalName"),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date), style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              );
            }).toList()
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _DetailRow({required this.icon, required this.label, required this.value, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right),
          )
        ],
      ),
    );
  }
}
