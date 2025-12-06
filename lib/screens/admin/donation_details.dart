import 'package:flutter/material.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationDetails extends StatefulWidget {
  final String donationID;
  const DonationDetails({super.key, required this.donationID});

  @override
  State<DonationDetails> createState() => _DonationDetailsState();
}

class _DonationDetailsState extends State<DonationDetails> {
  late Future<Donation> _futureDonation;

  @override
  void initState() {
    super.initState();
    _futureDonation = DonationService().fetchDonation(widget.donationID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Donation>(
        future: _futureDonation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Donation not found.'));
          }

          final d = snapshot.data!;
          print('DEBUG imagePaths = ${d.imagePaths}');

          final bool isPending = d.status == 'Pending';

          final commentsText =
              (d.comments == null || d.comments!.trim().isEmpty)
              ? "N/A"
              : d.comments!;

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('${d.itemType} Donation'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Item Name: ${d.itemName}'),
                        Text('Donor Name: ${d.donorName}'),
                        Text('Donor Contact: ${d.donorContact}'),
                        Text('Condition: ${d.condition}'),
                        Text('Description: ${d.description ?? "N/A"}'),
                        Text('Quantity: ${d.quantity ?? 1}'),
                        Text('Submitted on: ${d.submissionDate}'),
                        Text('Status: ${d.status}'),
                        Text('Comments: $commentsText'),
                      ],
                    ),
                  ),

                  if (d.imagePaths != null && d.imagePaths!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: d.imagePaths!.length,
                          itemBuilder: (context, index) {
                            final url = d.imagePaths![index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.network(
                                url,
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.greenAccent,
                          ),
                        ),
                        onPressed: isPending
                            ? () async {
                                await DonationService().approveDonation(d.id!);
                                setState(() {
                                  _futureDonation = DonationService()
                                      .fetchDonation(d.id!);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Donation approved successfully.',
                                    ),
                                  ),
                                );
                              }
                            : null,

                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.redAccent,
                          ),
                        ),
                        onPressed: isPending
                            ? () async {
                                await DonationService().rejectDonation(d.id!);
                                setState(() {
                                  _futureDonation = DonationService()
                                      .fetchDonation(d.id!);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Donation rejected successfully.',
                                    ),
                                  ),
                                );
                              }
                            : null,

                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
