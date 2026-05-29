import 'app_localizations.dart';

/// Localized label for [profiles.role] values.
String localizedProfileRole(AppLocalizations loc, String role) {
  switch (role) {
    case 'moderator':
      return loc.roleModerator;
    case 'scholar':
      return loc.roleScholar;
    case 'admin':
      return loc.roleAdmin;
    case 'superadmin':
      return loc.roleSuperadmin;
    case 'user':
    default:
      return loc.roleUser;
  }
}

/// e.g. "Role: Admin"
String profileRoleLine(AppLocalizations loc, String role) =>
    loc.profileRole(localizedProfileRole(loc, role));
