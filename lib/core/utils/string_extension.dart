extension StringInitials on String {
  /// Mengambil inisial dari sebuah nama (maksimal 2 huruf pertama dari kata-kata).
  String toInitials() {
    final trimmed = trim();
    if (trimmed.isEmpty) return 'U';
    
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
    }
    
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
