// Add this new widget for the alumni details page
import 'package:flutter/material.dart';
import 'package:nitd_code/models/user_model.dart';
import 'package:nitd_code/ui/pallete.dart';

class AlumniLocationDetailsPage extends StatelessWidget {
  final List<UserModel> alumni;
  final String location;

  const AlumniLocationDetailsPage({
    super.key,
    required this.alumni,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
          onPressed: () {
            Navigator.pop(context);
          },
          splashRadius: 24,
          tooltip: 'Back',
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Pallete.gradient1,
              Pallete.gradient2,
              Pallete.gradient3,
            ],
          ).createShader(bounds),
          child: const Text(
            'Alumni from ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Pallete.whiteColor, // gets masked by the gradient
              letterSpacing: 1.2,
            ),
          ),
        ),
        titleTextStyle: const TextStyle(color: Pallete.whiteColor),
      ),
      body: ListView.builder(
        itemCount: alumni.length,
        itemBuilder: (context, index) {
          final alumniMember = alumni[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Pallete.borderColor),
              gradient: LinearGradient(
                colors: [
                  Pallete.gradient1.withOpacity(0.2),
                  Pallete.gradient2.withOpacity(0.15),
                  Pallete.gradient3.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                alumniMember.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Pallete.whiteColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('School: ${alumniMember.school}',
                      style: TextStyle(
                          color: Pallete.whiteColor.withOpacity(0.85))),
                  Text('Email: ${alumniMember.email}',
                      style: TextStyle(
                          color: Pallete.whiteColor.withOpacity(0.75))),
                  Text('Contact: ${alumniMember.contactNumber}',
                      style: TextStyle(
                          color: Pallete.whiteColor.withOpacity(0.75))),
                ],
              ),
              onTap: () => _showAlumniDetails(context, alumniMember),
            ),
          );
        },
      ),
    );
  }

  void _showAlumniDetails(BuildContext context, UserModel alumni) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Pallete.borderColor),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Pallete.gradient1, Pallete.gradient2],
          ).createShader(bounds),
          child: Text(
            alumni.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              detailText('Location: ${alumni.location}'),
              detailText('School: ${alumni.school}'),
              detailText('Email: ${alumni.email}'),
              detailText('Contact: ${alumni.contactNumber}'),
              detailText('Starting Year: ${alumni.startingYear}'),
              detailText('End Year: ${alumni.endYear}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Pallete.gradient2),
            ),
          ),
        ],
      ),
    );
  }

  Widget detailText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: TextStyle(
            color: Pallete.whiteColor.withOpacity(0.85),
            fontSize: 16,
          ),
        ),
      );
}
