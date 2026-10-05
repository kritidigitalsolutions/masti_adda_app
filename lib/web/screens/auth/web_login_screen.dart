import 'package:flutter/material.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/screens/auth/web_login_dialog.dart';

class WebLoginScreen extends StatelessWidget {
  const WebLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebMainLayout(
      activeRoute: WebRoutes.login,
      showFooter: true,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: WebLoginDialog(),
        ),
      ),
    );
  }
}
