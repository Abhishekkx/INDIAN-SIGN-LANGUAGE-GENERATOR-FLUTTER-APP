import 'package:flutter/material.dart';

class GestureGalleryScreen extends StatelessWidget {
  const GestureGalleryScreen({super.key});

  final List<GestureItem> gestures = const [
    GestureItem(
      name: 'Hello',
      imagePath: 'assets/gestures/HI.jpg',
    ),
    GestureItem(
      name: 'NAMASTE',
      imagePath: 'assets/gestures/NAMASTE.jpg',
    ),
    GestureItem(
      name: 'WRONG',
      imagePath: 'assets/gestures/WRONG.jpg',
    ),
    GestureItem(
      name: 'GOOD',
      imagePath: 'assets/gestures/GOOD.jpg',
    ),
    GestureItem(
      name: 'PERFECT',
      imagePath: 'assets/gestures/PERFECT.jpg',
    ),
    GestureItem(
      name: 'PROMISE',
      imagePath: 'assets/gestures/PROMISE.jpg',
    ),
    GestureItem(name: 'A', imagePath: 'assets/gestures/A.jpg'),
    GestureItem(name: 'B', imagePath: 'assets/gestures/B.jpg'),
    GestureItem(name: 'C', imagePath: 'assets/gestures/C.jpg'),
    GestureItem(name: 'D', imagePath: 'assets/gestures/D.jpg'),
    GestureItem(name: 'E', imagePath: 'assets/gestures/E.jpg'),
    GestureItem(name: 'F', imagePath: 'assets/gestures/F.jpg'),
    GestureItem(name: 'G', imagePath: 'assets/gestures/G.jpg'),
    GestureItem(name: 'H', imagePath: 'assets/gestures/H.jpg'),
    GestureItem(name: 'I', imagePath: 'assets/gestures/I.jpg'),
    GestureItem(name: 'J', imagePath: 'assets/gestures/J.jpg'),
    GestureItem(name: 'K', imagePath: 'assets/gestures/K.jpg'),
    GestureItem(name: 'L', imagePath: 'assets/gestures/L.jpg'),
    GestureItem(name: 'M', imagePath: 'assets/gestures/M.jpg'),
    GestureItem(name: 'N', imagePath: 'assets/gestures/N.jpg'),
    GestureItem(name: 'O', imagePath: 'assets/gestures/O.jpg'),
    GestureItem(name: 'P', imagePath: 'assets/gestures/P.jpg'),
    GestureItem(name: 'Q', imagePath: 'assets/gestures/Q.jpg'),
    GestureItem(name: 'R', imagePath: 'assets/gestures/R.jpg'),
    GestureItem(name: 'S', imagePath: 'assets/gestures/S.jpg'),
    GestureItem(name: 'T', imagePath: 'assets/gestures/T.jpg'),
    GestureItem(name: 'U', imagePath: 'assets/gestures/U.jpg'),
    GestureItem(name: 'V', imagePath: 'assets/gestures/V.jpg'),
    GestureItem(name: 'X', imagePath: 'assets/gestures/X.jpg'),
    GestureItem(name: 'Y', imagePath: 'assets/gestures/Y.jpg'),
    GestureItem(name: 'Z', imagePath: 'assets/gestures/Z.jpg'),



    // Add more gestures as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISL Gesture Gallery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: gestures.length,
        itemBuilder: (context, index) {
          return GestureCard(gesture: gestures[index]);
        },
      ),
    );
  }
}

class GestureItem {
  final String name;
  final String imagePath;

  const GestureItem({
    required this.name,
    required this.imagePath,
  });
}

class GestureCard extends StatelessWidget {
  final GestureItem gesture;

  const GestureCard({
    super.key,
    required this.gesture,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => GestureDetailDialog(gesture: gesture),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  gesture.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                gesture.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GestureDetailDialog extends StatelessWidget {
  final GestureItem gesture;

  const GestureDetailDialog({
    super.key,
    required this.gesture,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.asset(
              gesture.imagePath,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gesture.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}