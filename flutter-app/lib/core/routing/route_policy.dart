import '../../features/auth/domain/auth.dart';
import 'destinations.dart';

/// Route authorization is repeated by use cases; hiding navigation is cosmetic.
Permission? permissionForPath(String path) {
  if (path.startsWith('/employer/candidates/')) {
    return Permission.viewCandidates;
  }
  if (path.startsWith('/candidate/assessments')) {
    return Permission.viewOwnProfile;
  }
  if (path == '/employer/assistant') return Permission.viewCandidates;
  if (path == '/employer/tracking') return Permission.viewCandidates;
  return Destination.values
      .where((d) => d.path == path)
      .firstOrNull
      ?.permission;
}

bool isPublicPath(String path) =>
    {'/', '/login', '/register', '/boot', '/forbidden'}.contains(path);
String? routeRedirect(Uri uri, User? user, {required bool restoring}) {
  if (uri.scheme == 'hrleaders') return normalizeAppLink(uri);
  final path = uri.path;
  if (restoring && path != '/boot') {
    return Uri(
      path: '/boot',
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  if (restoring) return null;
  final requested = uri.queryParameters['from'];
  // Only local absolute paths can become a return destination.
  final target =
      requested != null &&
          requested.startsWith('/') &&
          !requested.startsWith('//') &&
          !isPublicPath(Uri.parse(requested).path)
      ? requested
      : null;
  if (path == '/boot') {
    return user == null
        ? (target == null
              ? '/'
              : Uri(
                  path: '/login',
                  queryParameters: {'from': target},
                ).toString())
        : target ?? homeFor(user);
  }
  if (user == null && !isPublicPath(path)) {
    return Uri(
      path: '/login',
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  if (user != null && (path == '/login' || path == '/register')) {
    return target ?? homeFor(user);
  }
  final required = permissionForPath(path);
  if (user != null && required != null && !user.can(required)) {
    return '/forbidden';
  }
  return null;
}
