import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Web implementation — renders Google's native FedCM sign-in button.
/// This uses Google Identity Services SDK under the hood, which supports
/// Federated Credential Management (FedCM). This is immune to COOP/COEP
/// restrictions because it uses the browser's native credential picker
/// instead of a popup window.
Widget buildGoogleSignInButtonPlatform() {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      theme: web.GSIButtonTheme.outline,
      size: web.GSIButtonSize.large,
      shape: web.GSIButtonShape.rectangular,
      text: web.GSIButtonText.signinWith,
      logoAlignment: web.GSIButtonLogoAlignment.left,
    ),
  );
}
