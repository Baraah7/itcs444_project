//Review + approve donations
import 'package:flutter/material.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/screens/admin/donation_details.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationList extends StatefulWidget {
  const DonationList({super.key, required this.donations});

  final List<Donation> donations;

  @override
  State<DonationList> createState() => _DonationListState();
}

class _DonationListState extends State<DonationList> {
  List<String> filterOps = ['Pending', 'Approved', 'Rejected'];
  String? filterVal;

  DateTime todaysDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final day = todaysDate.day;
    final month = todaysDate.month;
    final year = todaysDate.year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Management'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 15,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownMenu(
                  initialSelection: filterVal,
                  dropdownMenuEntries: filterOps.map((item) {
                    return DropdownMenuEntry(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    setState(() {
                      filterVal = value;
                    });
                  },
                ),
                Text(
                  'Today\'s date: $day-$month-$year',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            Align(
              alignment: Alignment.topLeft,
              child: Text(
                filterVal == null ? 'All Donations:' : '$filterVal Donations:',
                style: const TextStyle(fontSize: 20),
              ),
            ),

            //donations
            Expanded(
              child: FutureBuilder<List<Donation>>(
                future: DonationService().fetchAllDonations(),
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
                              Text('Submitted on: ${d.submissionDate}'),
                              Text('Status: ${d.status}'),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DonationDetails(donationID: d.id!),
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
