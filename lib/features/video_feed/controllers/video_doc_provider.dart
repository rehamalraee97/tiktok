// video_doc_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

 final videoDocProvider = StreamProvider.family<
    DocumentSnapshot<Map<String, dynamic>>, String>(
      (ref, videoId) {
    return FirebaseFirestore.instance
        .collection('videos')
        .doc(videoId)
        .snapshots();
  },
);
