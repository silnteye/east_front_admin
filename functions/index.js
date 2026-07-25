const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyOnNewPost = onDocumentCreated("posts/{postId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }
  
  const post = snapshot.data();
  const title = post.title || "New Post Published";
  const description = post.description || "Check out the latest news on East Front.";
  const type = post.type || "text";

  const message = {
    notification: {
      title: title,
      body: description.length > 100 ? description.substring(0, 97) + "..." : description,
    },
    data: {
      postId: event.params.postId,
      type: type,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    },
    topic: "new_posts"
  };

  try {
    const response = await getMessaging().send(message);
    console.log("Successfully sent notification:", response);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});
