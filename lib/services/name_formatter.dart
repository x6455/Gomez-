class NameFormatter {
  static String format(String name) {
    final initials = ['MR', 'MRS', 'MISS', 'MS', 'DR', 'PROF'];
    final words = name.trim().split(' ');

    if (words.isNotEmpty && initials.contains(words.first.toUpperCase())) {
      return words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    } else {
      return name.toUpperCase();
    }
  }
}
