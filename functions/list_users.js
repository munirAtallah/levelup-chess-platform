const admin = require("firebase-admin");
admin.initializeApp({
  projectId: "levelup-26"
});

const db = admin.firestore();

async function run() {
  console.log("Fetching users...");
  const snapshot = await db.collection("users").get();
  if (snapshot.empty) {
    console.log("No users found.");
    return;
  }
  snapshot.forEach(doc => {
    console.log(`User ID: ${doc.id}, Data:`, doc.data());
  });
}

run().catch(console.error);
