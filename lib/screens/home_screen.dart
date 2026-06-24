import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:telebirrbybr7/constants.dart';
import 'package:telebirrbybr7/widgets/balance_info.dart';
import 'package:telebirrbybr7/widgets/grid_content.dart';
import 'package:telebirrbybr7/widgets/notification_area.dart';
import 'package:telebirrbybr7/widgets/transaction%20detail.dart';
import 'package:telebirrbybr7/widgets/user_introduction.dart';
import 'package:telebirrbybr7/widgets/transaction_records_page.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      appBar: AppBar(
  // REDUCED HEIGHT: Setting toolbarHeight to 45 (Standard is 56)
  toolbarHeight: 40, 
  systemOverlayStyle: const SystemUiOverlayStyle(
    statusBarColor: Color.fromRGBO(140, 199, 63, 1),
    statusBarIconBrightness: Brightness.dark,
  ),
  backgroundColor: Colors.white,
  elevation: 0, // Optional: flattens the bar for a cleaner look
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Image.asset(
        'images/ethio.png',
        width: 80, // Reduced from 100 to fit the shorter bar
      ),
      Image.asset(
        'images/telebirr.png',
        width: 50, // Reduced from 60 to fit the shorter bar
      )
    ],
  ),
),

      body: Column(
        children: [
          Stack(
            children: [
              Container(
  height: 220,
  width: double.infinity,
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage('images/Bg1.png'),
      fit: BoxFit.cover,
    ),
  ),
  child: Container(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              UserIntroduction(),
              NotificationArea(),
            ],
          ),

          Transform.translate(
  offset: const Offset(0, -1),
  child: Column(
    children: [
      BalanceInfo(
        label: 'Balance (ETB) ',
        balanceFontSize: 25,
        labelFontSize: 17,
      ),
       const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BalanceInfo(
            label: 'Endekise (ETB) ',
            balanceFontSize: 11,
            labelFontSize: 17,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          BalanceInfo(
            label: 'Reward (ETB) ',
            balanceFontSize: 11,
            labelFontSize: 17,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ],
      ),
    ],
  ),
),

        ],
      ),
    ),
  ), 
),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 15,
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(251, 187, 71, 0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(100),
                      topRight: Radius.circular(100),
                    ),
                  ),
                  child: Marquee(
                    text: 'ONE APP FOR ALL YOUR NEEDS!',
                    blankSpace: 400,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, right: 8, top: 5, bottom: 10),
                child: Column(
                  children: [
                    GridContent(
                      gridIcon: topGridIcon,
                      gridLabel: topGridLabel,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    CarouselSlider(
  options: CarouselOptions(
    autoPlay: true,
    // CHANGED: 21/9 is taller than 39/9. Lowering the first number adds height.
    aspectRatio: 30 / 9, 
    // ADDED: 1.0 makes the banner take up the full width of the screen
    viewportFraction: 0.9, 
    onPageChanged: (index, reason) {
      setState(() {
        _currentIndex = index;
      });
    },
  ),
  items: carouselImages.map((image) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          // CHANGED: Reduced or removed margin to make it appear wider
          margin: const EdgeInsets.symmetric(horizontal: 5.0), 
          decoration: const BoxDecoration(color: Colors.transparent),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Optional: rounds the banner corners
            child: FittedBox(
              fit: BoxFit.fill, // Ensures the image stretches to fill the new size
              child: image,
            ),
          ),
        );
      },
    );
  }).toList(),
),

                    ImageSliderIndicator(
                      carouselImages: carouselImages,
                      currentIndex: _currentIndex,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: TransactionRecordsPage(),
                    ),
                    GridContent(
                      gridIcon: bottomGridIcon,
                      gridLabel: bottomGridLabel,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.07,
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      
            
   
    );
  }
}

class ImageSliderIndicator extends StatelessWidget {
  const ImageSliderIndicator({
    super.key,
    required this.carouselImages,
    required int currentIndex,
  }) : _currentIndex = currentIndex;

  final List<Image> carouselImages;
  final int _currentIndex;

  @override
  Widget build(BuildContext context) {
    const color = Color.fromRGBO(141, 199, 63, 1);
    const ringSize = 8.0;      // outer circle size
    const innerDotSize = 4.0;   // inner dot size

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(carouselImages.length, (i) {
          final isActive = i == _currentIndex;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.0),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? innerDotSize : 0,
                height: isActive ? innerDotSize : 0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DropDownLang extends StatelessWidget {
  const DropDownLang({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      underline: const SizedBox(), // removes default underline
      hint: SizedBox(
        width: 40, // IMPORTANT: limits width so marquee can scroll
        height: 18,
        child: Marquee(
          text: 'English',
          blankSpace: 30,
          velocity: 20,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 10,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.white,
        size: 20,
      ),
      items: const [],
      onChanged: (value) {},
    );
  }
}
