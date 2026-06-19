// Mapper for bank name to logo image path
class BankLogoMapper {
  static const Map<String, String> _logoMap = {
    'Abay Bank': 'images/abay.jpg',
    'Addis Bank S.C.': 'images/addis.jpg',
    'Ahadu Bank': 'images/ahadu.jpg',
    'Amhara Bank': 'images/amara.jpg',
    'Awash Bank': 'images/Awash.png',
    'Bank of Abyssinia': 'images/abyssinia.jpg',
    'Birhan Bank': 'images/birhan.jpg',
    'Bunna Bank': 'images/bunna.jpg',
    'Commercial Bank of Ethiopia': 'images/cbe.png',
    'Cooperative Bank of Oromia': 'images/coop.jpg',
    'Dashen Bank': 'images/dashen.png',
    'Global Bank Ethiopia': 'images/global.jpg',
    'Enat Bank': 'images/enat.jpg',
    'Gadda Bank': 'images/geda.jpg',
    'Goh Betoch Bank': 'images/goh.jpg',
    'Hibret Bank': 'images/hibret.jpg',
    'Hijira Bank': 'images/hijra.jpg',
    'Lion International Bank': 'images/lion.jpg',
    'Nib International Bank': 'images/nib.jpg',
    'Oromia Bank': 'images/oro.jpg',
    'Rammis Bank': 'images/ramis.jpg',
  };

  static String getLogo(String bankName) {
    return _logoMap[bankName] ?? 'images/default.png'; // fallback
  }
}
