
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'create_account_screen.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'account_screen.dart';
import 'upload_screen.dart';
import 'locations_screen.dart';
import 'budget_dates_screen.dart';
import 'review_screen.dart';
import 'pay_screen.dart';
import 'driver_sync_screen.dart';

void main() {
  runApp(const InhyloApp());
}

class InhyloApp extends StatelessWidget {
  const InhyloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INHYLO',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),

        '/create-account': (context) =>
            const CreateAccountScreen(),

        '/home': (context) => HomeScreen(
              onNewCampaign: () {
                _startCampaign(context);
              },
              onNavTap: (index) {
                if (index == 1) {
                  Navigator.of(context)
                      .pushReplacementNamed('/reports');
                } else if (index == 2) {
                  Navigator.of(context)
                      .pushReplacementNamed('/account');
                }
              },
            ),

        '/reports': (context) => ReportsScreen(
              brandName: 'INHYLO',
              onHome: () {
                Navigator.of(context)
                    .pushReplacementNamed('/home');
              },
              onAccount: () {
                Navigator.of(context)
                    .pushReplacementNamed('/account');
              },
            ),

        '/account': (context) => AccountScreen(
              brandName: 'INHYLO',
              onHome: () {
                Navigator.of(context)
                    .pushReplacementNamed('/home');
              },
              onReports: () {
                Navigator.of(context)
                    .pushReplacementNamed('/reports');
              },
            ),

        '/driver-sync': (context) =>
            const DriverSyncScreen(
              driverName: 'Priyanka',
              vehicleNumber: 'KA 05 AB 1234',
            ),
      },
    );
  }

  void _startCampaign(BuildContext context) {
    List<AdLocation> selectedLocations = [];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (uploadContext) {
          return UploadAdScreen(
            nextScreenBuilder: (context) {
              return LocationsScreen(
                onNext: (locations) {
                  selectedLocations = locations;
                },
                nextScreenBuilder: (context) {
                  return BudgetDatesScreen(
                    locationCount: selectedLocations.length,
                    onNext: (plan) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ReviewScreen(
                              campaignName: 'My Campaign',
                              videoFileName: 'Uploaded video',
                              videoSeconds: 0,
                              locations: selectedLocations,
                              plan: plan,
                              onDone: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return PayScreen(
                                        campaignName: 'My Campaign',
                                        startDate: plan.startDate,
                                        endDate: plan.endDate,
                                        locationCount:
                                            selectedLocations.length,
                                        budget: plan.budget,
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
