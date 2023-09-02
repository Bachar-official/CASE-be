enum Permission { full, upload, update }

Permission getPermissionFromString(String perm) {
  return Permission.values.firstWhere((val) => val.name == perm.toLowerCase(),
      orElse: () => Permission.update);
}
