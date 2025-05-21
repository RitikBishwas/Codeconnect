import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String name;
  final String email;
  final String school;
  final String location;
  final String? github_url;
  final String? linkedin_url;
  final String? company;
  final String contactNumber;
  final String? profileImage;
  final String? imagePublicId;
  final Timestamp createdAt;
  final String year; // Added the new year field
  final String startingYear; // Added the startingYear field
  final String endYear; // Added the endYear field

  UserModel({
    required this.name,
    required this.email,
    required this.school,
    required this.location,
    this.github_url,
    this.linkedin_url,
    this.company,
    required this.contactNumber,
    required this.profileImage,
    this.imagePublicId,
    required this.createdAt,
    required this.year, // Year is required now
    required this.startingYear, // Starting year is required now
    required this.endYear, // End year is required now
  });

  // Factory constructor to create a UserModel from a Map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      school: map['school'] ?? '',
      location: map['location'] ?? '',
      company: map['company'] ?? '',
      github_url: map['github_url'] ?? '',
      linkedin_url: map['linkedin_url'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      profileImage: map['profileImage'],
      imagePublicId: map['imagePublicId'],
      createdAt: map['createdAt'],
      year: map['year'] ?? '', // Mapping new year field
      startingYear: map['startingYear'] ?? '', // Mapping new startingYear field
      endYear: map['endYear'] ?? '', // Mapping new endYear field
    );
  }

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      email: data['email'] ?? '',
      school: data['school'] ?? '',
      company: data['company'] ?? '',
      github_url: data['github_url'] ?? '',
      linkedin_url: data['linkedin_url'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      profileImage: data['profileImage'] ?? '',
      imagePublicId: data['imagePublicId'] ?? '',
      createdAt: data['createdAt'],
      year: data['year'] ?? '', // Mapping new year field
      startingYear:
          data['startingYear'] ?? '', // Mapping new startingYear field
      endYear: data['endYear'] ?? '', // Mapping new endYear field
    );
  }

  // Convert UserModel to a Map for storing in Firestore or local storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'school': school,
      'location': location,
      'company': company,
      'github_url': github_url,
      'linkedin_url': linkedin_url,
      'contactNumber': contactNumber,
      'profileImage': profileImage,
      'imagePublicId': imagePublicId,
      'year': year, // New field added
      'startingYear': startingYear, // New field added
      'endYear': endYear, // New field added
    };
  }
}
