import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX
import '../../../controllers/user_controller.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the instance of UserController which is registered with Get.put() or similar
    // We use .instance since UserController provides a static getter for it:
    // static UserController get instance => Get.find();
    final UserController uc = UserController.instance; 

    return Scaffold(
      // appBar: AppBar(title: const Text("Friend Requests")),
      
      // Use Obx to rebuild the widget whenever uc.friendRequests (an RxList) changes
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () async => await uc.fetchFriendRequests(),
          
          // Check if the list is empty
          child: uc.friendRequests.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No pending requests'),
                    )),
                  ],
                )
              // If not empty, build the list
              : ListView.builder(
                  // No need for uc.friendRequests.length because Obx will handle updates
                  itemCount: uc.friendRequests.length,
                  itemBuilder: (_, i) {
                    final req = uc.friendRequests[i];
                    return ListTile(
                      title: Text(req.name),
                      subtitle: Text(req.email),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          // Button to accept request
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => uc.acceptRequest(req.uid),
                          ),
                          // Button to decline request
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => uc.declineRequest(req.uid),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}