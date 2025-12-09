//Review + approve donations
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/screens/shared/donation_form.dart';
import 'package:itcs444_project/screens/user/user_donation_details.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationHistory extends StatefulWidget {
  const DonationHistory({super.key});

  @override
  State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
  List<String> filterOps = ['All', 'Pending', 'Approved', 'Rejected'];
  String? filterVal;
  final user = FirebaseAuth.instance.currentUser;
  late final uid = user?.uid;

  DateTime todaysDate = DateTime.now();
  late final day = todaysDate.day;
  late final month = todaysDate.month;
  late final year = todaysDate.year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 15,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Donations', style: const TextStyle(fontSize: 20)),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DonationForm()),
                    );
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filterVal == null
                      ? 'All Donations:'
                      : '$filterVal Donations:',
                  style: const TextStyle(fontSize: 16),
                ),

                DropdownMenu(
                  initialSelection: filterVal,
                  dropdownMenuEntries: filterOps.map((item) {
                    return DropdownMenuEntry(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    setState(() {
                      filterVal = (value == 'All') ? null : value;
                    });
                  },
                ),
              ],
            ),

            //donations
            Expanded(
              child: FutureBuilder<List<Donation>>(
                future: DonationService().fetchDonationsByUserId(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No donations found."));
                  }

                  final allDonations = snapshot.data!;

                  // Optional: filter by status if you want only pending
                  final donations = allDonations
                      .where(
                        (d) =>
                            (filterVal == null) ||
                            (filterVal != null &&
                                d.status.toLowerCase() ==
                                    filterVal!.toLowerCase()),
                      )
                      .toList();

                  if (donations.isEmpty) {
                    return const Center(
                      child: Text('No donations matching the filter.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final d = donations[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            IconData(
                              d.iconCode ??
                                  defaultIconCodes[d.itemType] ??
                                  Icons.help_outline.codePoint,
                              fontFamily: 'MaterialIcons',
                            ),
                          ),

                          title: Text('${d.itemType} Donation'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Donor Name: ${d.donorName}'),
                              Text('Submitted on: $day-$month-$year'),
                              Text('Status: ${d.status}'),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDonationDetails(donationID: d.id!),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_right),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
