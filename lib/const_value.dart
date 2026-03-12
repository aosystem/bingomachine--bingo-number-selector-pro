
class ConstValue {
  ConstValue._();

  static const int ballCount = 75;

  static const int minQuickDraw = 0;
  static const int maxQuickDraw = 9;
  static const int defaultQuickDraw = 0;

  static const int minAutomaticDrawInterval = 1;
  static const int maxAutomaticDrawInterval = 60;
  static const int defaultAutomaticDrawInterval = 10;

  static const double minTextSizeRatioBall = 0.1;
  static const double maxTextSizeRatioBall = 2.0;
  static const double defaultTextSizeRatioBall = 1.0;

  static const int minTextSizeTable = 8;
  static const int maxTextSizeTable = 100;
  static const int defaultTextSizeTable = 32;

  static const int minTextSizeCard = 8;
  static const int maxTextSizeCard = 100;
  static const int defaultTextSizeCard = 40;

  static const ballImage = '''
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024">
      <defs>
      <radialGradient id="gradation" cx="4207.03" cy="-2361.28" fx="4207.03" fy="-2361.28" r="759.39" gradientTransform="translate(-4275.84 -2532.86) scale(1.14 -1.14)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#e7e7e7"/>
        <stop offset=".52" stop-color="#dcdcdc"/>
        <stop offset=".75" stop-color="#d5d5d5"/>
        <stop offset="1" stop-color="#e1e1e1"/>
      </radialGradient>
      <linearGradient id="gradation2" x1="512" y1="402.03" x2="512" y2="965.65" gradientTransform="translate(0 845.89) scale(1 -1)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#eee"/>
        <stop offset=".49" stop-color="#f3f3f3"/>
        <stop offset="1" stop-color="#fff"/>
      </linearGradient>
      <linearGradient id="gradation3" x1="-2985.24" y1="2118.12" x2="-2985.24" y2="1929.06" gradientTransform="translate(-2473.24 -1171.35) rotate(-180) scale(1 -1)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#e9e9e9"/>
        <stop offset=".09" stop-color="#e8e8e8"/>
        <stop offset="1" stop-color="#e1e1e1"/>
      </linearGradient>
      </defs>
      <path d="M1024,512c0,282.62-229.38,512-512,512S0,794.62,0,512,229.38,0,512,0s512,229.38,512,512Z" fill="url(#gradation)"/>
      <path d="M887.81,324.61c0,145.92-155.14,257.54-375.81,257.54s-375.81-111.62-375.81-257.54S291.84,25.6,512,25.6s375.81,152.58,375.81,299.01Z" fill="url(#gradation2)"/>
      <path d="M245.25,878.59c0-56.83,119.3-102.91,266.75-102.91s266.75,46.08,266.75,102.91-119.3,119.81-266.75,119.81-266.75-62.98-266.75-119.81Z" fill="url(#gradation3)"/>
    </svg>
  ''';

  static const ballImage2 = '''
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024">
      <defs>
      <radialGradient id="gradation" cx="4207.03" cy="-2361.28" fx="4207.03" fy="-2361.28" r="759.39" gradientTransform="translate(-4275.84 -2532.86) scale(1.14 -1.14)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#fd0"/>
        <stop offset=".5" stop-color="#f6d600"/>
        <stop offset=".75" stop-color="#f6d600"/>
        <stop offset="1" stop-color="#fe0"/>
      </radialGradient>
      <linearGradient id="gradation2" x1="512" y1="402.03" x2="512" y2="965.65" gradientTransform="translate(0 845.89) scale(1 -1)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#fe0"/>
        <stop offset=".5" stop-color="#fea"/>
        <stop offset="1" stop-color="#fe0"/>
      </linearGradient>
      <linearGradient id="gradation3" x1="-2985.24" y1="2118.12" x2="-2985.24" y2="1929.06" gradientTransform="translate(-2473.24 -1171.35) rotate(-180) scale(1 -1)" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#fea"/>
        <stop offset="1" stop-color="#fe0"/>
      </linearGradient>
      </defs>
      <path d="M1024,512c0,282.62-229.38,512-512,512S0,794.62,0,512,229.38,0,512,0s512,229.38,512,512Z" fill="url(#gradation)"/>
      <path d="M887.81,324.61c0,145.92-155.14,257.54-375.81,257.54s-375.81-111.62-375.81-257.54S291.84,25.6,512,25.6s375.81,152.58,375.81,299.01Z" fill="url(#gradation2)"/>
      <path d="M245.25,878.59c0-56.83,119.3-102.91,266.75-102.91s266.75,46.08,266.75,102.91-119.3,119.81-266.75,119.81-266.75-62.98-266.75-119.81Z" fill="url(#gradation3)"/>
    </svg>
  ''';

}
