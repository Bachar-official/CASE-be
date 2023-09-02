enum Permission { full, upload, update }

Permission getPermissionFromString(String perm) {
  return Permission.values.firstWhere((val) => val.name == perm.toLowerCase(),
      orElse: () => Permission.update);
}

extension Compare on Permission {
  bool get canUpload => _canUpload();
  bool get canUpdate => _canUpdate();
  bool get canManageUsers => _canManageUsers();

  bool _canUpload() {
    if (name == 'full' || name == 'upload') {
      return true;
    }
    return false;
  }

  bool _canUpdate() {
    if (name == 'full' || name == 'update') {
      return true;
    }
    return false;
  }

  bool _canManageUsers() {
    if (name == 'full') {
      return true;
    }
    return false;
  }
}
