const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const STUDENT_EMAIL_DOMAIN = "@students.levelup-26.local";

const JERUSALEM_LOCATIONS = [
  { en: "Abu Ghosh",                 ar: "أبوغوش وما حولها" },
  { en: "Abu Tor - Al-Thawri",       ar: "أبوطور - الثوري" },
  { en: "Al-Eizariya and Abu Dis",   ar: "العيزرية وأبوديس" },
  { en: "Al-Issawiya",               ar: "العيساوية" },
  { en: "Al-Walaja and Beit Sahour", ar: "الولجة وبيت ساحور" },
  { en: "Anata - Shufat Camp",       ar: "عناتا - مخيم شعفاط" },
  { en: "Atarot",                    ar: "عطروت" },
  { en: "At-Tur - Mount of Olives",  ar: "الطور - جبل الزيتون" },
  { en: "Beit Hanina",               ar: "بيت حنينا" },
  { en: "Beit Safafa",               ar: "بيت صفافا" },
  { en: "Jabal Al-Mukaber",          ar: "جبل المكبر" },
  { en: "Kafr Aqab",                 ar: "كفر عقب" },
  { en: "Old City",                  ar: "البلدة القديمة ومحيطها" },
  { en: "Other",                     ar: "غير ذلك" },
  { en: "Out of Jerusalem",          ar: "خارج حدود القدس" },
  { en: "Ras al-Amud",               ar: "رأس العامود" },
  { en: "Sheikh Jarrah",             ar: "الشيخ جراح" },
  { en: "Shu'fat",                   ar: "شعفاط" },
  { en: "Silwan",                    ar: "سلوان" },
  { en: "Sur Baher",                 ar: "صورباهر" },
  { en: "Umm Laysun",                ar: "أم ليسون" },
  { en: "Umm Tuba",                  ar: "أم طوبا" },
  { en: "Wadi al-Joz",               ar: "وادي الجوز" },
];

exports.checkEmailInSystem = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  const email = (request.data.email || "").trim().toLowerCase();
  if (!email) return { found: false };

  const snap = await admin.firestore()
    .collection("users")
    .where("email", "==", email)
    .limit(1)
    .get();

  if (snap.empty) return { found: false };

  const data = snap.docs[0].data();
  if (data.role === "student" || data.isArchived === true) return { found: false };

  return { found: true };
});

exports.createUser = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  const role = request.data.role;

  if (role === "instructor") {
    if (callerRole !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can create instructors.");
    }
  } else if (role === "student") {
    if (callerRole !== "admin" && callerRole !== "instructor") {
      throw new HttpsError("permission-denied", "Only admins or instructors can create students.");
    }
  } else {
    throw new HttpsError("invalid-argument", "role must be 'instructor' or 'student'.");
  }

  const data = request.data;
  const name = data.name;
  if (!name) {
    throw new HttpsError("invalid-argument", "name is required.");
  }

  let email;
  let password;
  if (role === "student") {
    const username = data.username;
    const pin = data.pinCode;
    if (!username || !pin) {
      throw new HttpsError("invalid-argument", "Students need username and pinCode.");
    }
    email = username.toLowerCase() + STUDENT_EMAIL_DOMAIN;
    password = pin;
  } else {
    email = (data.email || "").trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "Instructors need an email.");
    }
    password = Math.random().toString(36).slice(-10) + "A1!";
  }

  let userRecord;
  let authExists = false;
  try {
    userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });
  } catch (err) {
    if (err.code === "auth/email-already-exists") {
      userRecord = await admin.auth().getUserByEmail(email);
      authExists = true;
    } else {
      throw new HttpsError("internal", "Failed to create account: " + err.message);
    }
  }

  const uid = userRecord.uid;

  if (authExists) {
    const existingDoc = await admin.firestore().collection("users").doc(uid).get();
    if (existingDoc.exists) {
      throw new HttpsError("already-exists", "That username or email is already taken.");
    }
  }
  const userDoc = {
    name: name,
    displayName: name,
    role: role,
    userNumber: data.userNumber || null,
    isArchived: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Build searchKeywords including new fields
  const keywords = name.toLowerCase().split(" ").concat([role]);
  if (data.gender) keywords.push(data.gender.toLowerCase());
  if (data.location) {
    keywords.push(data.location.toLowerCase());
    const locMatch = JERUSALEM_LOCATIONS.find(
      (l) => l.en.toLowerCase() === data.location.toLowerCase() || l.ar === data.location
    );
    if (locMatch) {
      if (locMatch.en.toLowerCase() !== data.location.toLowerCase()) {
        keywords.push(locMatch.en.toLowerCase());
      }
      if (locMatch.ar !== data.location) {
        keywords.push(locMatch.ar.toLowerCase());
      }
    }
  }
  userDoc.searchKeywords = keywords;

  if (role === "student") {
    userDoc.username = data.username.toLowerCase();
    userDoc.levelId = data.levelId || null;
    userDoc.studentNumber = data.studentNumber || null;
    userDoc.createdBy = callerUid;
    userDoc.pinCode = data.pinCode;
    userDoc.gender = data.gender || null;
    userDoc.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : null;
    userDoc.location = data.location || null;
  } else {
    userDoc.assignedLevels = data.assignedLevels || [];
    userDoc.email = email;
    userDoc.phoneNumber = data.phoneNumber || null;
    userDoc.gender = data.gender || null;
    userDoc.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : null;
    userDoc.location = data.location || null;
    userDoc.idNumber = data.idNumber || null;
  }

  await admin.firestore().collection("users").doc(uid).set(userDoc);

  if (role === "instructor") {
    try {
      const resetLink = await admin.auth().generatePasswordResetLink(email);

      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: process.env.GMAIL_USER,
          pass: process.env.GMAIL_PASS,
        },
      });

      await transporter.sendMail({
        from: process.env.GMAIL_USER,
        to: email,
        subject: "Welcome to LevelUp — Set Your Password",
        html: `
          <h2>Welcome to LevelUp, ${name}!</h2>
          <p>Your instructor account has been created.</p>
          <p>Click the link below to set your password and access the platform:</p>
          <a href="${resetLink}" style="
            background-color: #6B21A8;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 8px;
            display: inline-block;
            margin: 16px 0;
          ">Set Your Password</a>
          <p>If the button doesn't work, copy this link: ${resetLink}</p>
          <p>This link expires in 24 hours.</p>
          <br>
          <p>The LevelUp Team</p>
        `,
      });
    } catch (emailError) {
      console.error("Failed to send welcome email:", emailError.message);
      console.error("GMAIL_USER:", process.env.GMAIL_USER ? "SET" : "NOT SET");
      console.error("GMAIL_PASS:", process.env.GMAIL_PASS ? "SET" : "NOT SET");
      // Don't throw — user was created successfully
    }
  }

  return { uid: uid };
});

exports.archiveUser = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin" && callerRole !== "instructor") {
    throw new HttpsError("permission-denied", "Only admins or instructors can archive users.");
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  const targetDoc = await admin.firestore()
    .collection("users")
    .doc(uid)
    .get();
  const targetRole = targetDoc.exists ? targetDoc.data().role : null;

  if (callerRole === "instructor" && targetRole !== "student") {
    throw new HttpsError("permission-denied", "Instructors can only archive students.");
  }

  // Disable in Firebase Auth — wrapped in try/catch so Firestore update still runs
  try {
    await admin.auth().updateUser(uid, { disabled: true });
  } catch (authErr) {
    console.error('Failed to disable Auth user (non-fatal):', authErr.message);
    // Continue — still mark as archived in Firestore
  }

  await admin.firestore().collection("users").doc(uid).update({
    isArchived: true,
    archivedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Instructor: remove from every group they belong to
  if (targetRole === "instructor") {
    try {
      const groupsSnap = await admin.firestore()
        .collection("groups")
        .where("instructorIds", "arrayContains", uid)
        .get();
      if (!groupsSnap.empty) {
        const batch = admin.firestore().batch();
        groupsSnap.docs.forEach((doc) => {
          batch.update(doc.ref, {
            instructorIds: admin.firestore.FieldValue.arrayRemove(uid),
          });
        });
        await batch.commit();
      }
    } catch (err) {
      console.error("Failed to remove instructor from groups (non-fatal):", err.message);
    }
  }

  // Student: remove from their group's embedded students array and clear groupId
  if (targetRole === "student") {
    try {
      const groupId = targetDoc.exists ? targetDoc.data().groupId : null;
      if (groupId) {
        const groupDoc = await admin.firestore().collection("groups").doc(groupId).get();
        if (groupDoc.exists) {
          const students = groupDoc.data().students || [];
          const studentEmbed = students.find((s) => s.id === uid);
          const batch = admin.firestore().batch();
          if (studentEmbed) {
            batch.update(admin.firestore().collection("groups").doc(groupId), {
              students: admin.firestore.FieldValue.arrayRemove(studentEmbed),
            });
          }
          batch.update(admin.firestore().collection("users").doc(uid), {
            groupId: admin.firestore.FieldValue.delete(),
          });
          await batch.commit();
        }
      }
    } catch (err) {
      console.error("Failed to remove student from group (non-fatal):", err.message);
    }
  }

  try {
    const callerName = callerDoc.exists
      ? (callerDoc.data().displayName || callerDoc.data().name || "Unknown")
      : "Unknown";
    const callerNumber = callerDoc.exists
      ? (callerDoc.data().userNumber?.toString() || "0")
      : "0";
    const targetName = targetDoc.exists ? (targetDoc.data().name || "") : "";
    const logEntry = {
      action: targetRole === "instructor" ? "Archived instructor" : "Archived student",
      actionCategory: "users",
      performedBy: request.auth.uid,
      performerName: callerName,
      performerRole: callerRole,
      serialNumber: callerNumber,
      targetPersonName: targetName,
      time: admin.firestore.FieldValue.serverTimestamp(),
      preciseTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (targetRole === "instructor") {
      logEntry.details = targetDoc.exists ? (targetDoc.data().email || "") : "";
    }
    if (targetRole === "student") {
      const sNum = targetDoc.exists ? (targetDoc.data().studentNumber || "") : "";
      if (sNum) logEntry.targetStudentNumber = String(sNum);
    }
    await admin.firestore().collection("audit_logs").add(logEntry);
  } catch (logErr) {
    console.error("Failed to write archive audit log (non-fatal):", logErr.message);
  }

  return { success: true };
});

exports.restoreUser = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can restore users.");
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  try {
    await admin.auth().updateUser(uid, { disabled: false });
  } catch (authErr) {
    console.error('Failed to re-enable Auth user (non-fatal):', authErr.message);
  }

  await admin.firestore().collection("users").doc(uid).update({
    isArchived: false,
    archivedAt: admin.firestore.FieldValue.delete(),
  });

  return { success: true };
});

exports.resetStudentPin = onCall({ cors: true, region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin" && callerRole !== "instructor") {
    throw new HttpsError("permission-denied", "Only admins or instructors can reset PINs.");
  }

  const { studentId, newPin } = request.data;
  if (!studentId || !newPin) {
    throw new HttpsError("invalid-argument", "studentId and newPin are required.");
  }
  if (!/^\d{6}$/.test(newPin)) {
    throw new HttpsError("invalid-argument", "PIN must be exactly 6 digits.");
  }

  const studentDoc = await admin.firestore()
    .collection("users")
    .doc(studentId)
    .get();

  if (!studentDoc.exists) {
    throw new HttpsError("not-found", "Student not found.");
  }

  await admin.auth().updateUser(studentId, { password: newPin });

  await admin.firestore().collection("users").doc(studentId).update({
    pinCode: newPin,
  });

  return { success: true };
});

exports.resendWelcomeEmail = onCall({ cors: true, region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can resend welcome emails.");
  }

  const { instructorId } = request.data;
  if (!instructorId) {
    throw new HttpsError("invalid-argument", "instructorId is required.");
  }

  const instructorDoc = await admin.firestore()
    .collection("users")
    .doc(instructorId)
    .get();

  if (!instructorDoc.exists) {
    throw new HttpsError("not-found", "Instructor not found.");
  }

  const name = instructorDoc.data().name;

  // Read the email from Firebase Auth (the canonical source), not Firestore,
  // so a Firestore-only email edit never causes auth/user-not-found here.
  const authUser = await admin.auth().getUser(instructorId);
  const email = authUser.email;

  if (!email) {
    throw new HttpsError("not-found", "Instructor email not found.");
  }

  const resetLink = await admin.auth().generatePasswordResetLink(email);

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.GMAIL_USER,
    to: email,
    subject: "LevelUp — Password Reset Link",
    html: `
      <h2>Hello ${name},</h2>
      <p>Here is your new password reset link:</p>
      <a href="${resetLink}" style="
        background-color: #6B21A8;
        color: white;
        padding: 12px 24px;
        text-decoration: none;
        border-radius: 8px;
        display: inline-block;
        margin: 16px 0;
      ">Set Your Password</a>
      <p>If the button does not work, copy this link: ${resetLink}</p>
      <p>This link expires in 24 hours.</p>
      <br>
      <p>The LevelUp Team</p>
    `,
  });

  return { success: true };
});

exports.updateInstructorEmail = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can update instructor emails.");
  }

  const { instructorId, newEmail } = request.data;
  if (!instructorId || !newEmail) {
    throw new HttpsError("invalid-argument", "instructorId and newEmail are required.");
  }

  const email = newEmail.trim().toLowerCase();

  // Update Firebase Auth — this is what keeps login working
  await admin.auth().updateUser(instructorId, { email });

  // Firestore email is updated by the client alongside the other profile fields
  return { success: true };
});

exports.deleteUserPermanently = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  const callerRole = callerDoc.exists ? callerDoc.data().role : null;

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can permanently delete users.");
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  // Fetch target user data before deleting (needed for audit log)
  const targetDoc = await admin.firestore().collection("users").doc(uid).get();
  const targetData = targetDoc.exists ? targetDoc.data() : null;

  // Delete from Firebase Auth
  try {
    await admin.auth().deleteUser(uid);
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw new HttpsError("internal", "Failed to delete Auth account: " + err.message);
    }
  }

  // Delete from Firestore
  await admin.firestore().collection("users").doc(uid).delete();

  try {
    const callerName = callerDoc.exists
      ? (callerDoc.data().displayName || callerDoc.data().name || "Unknown")
      : "Unknown";
    const callerNumber = callerDoc.exists
      ? (callerDoc.data().userNumber?.toString() || "0")
      : "0";
    await admin.firestore().collection("audit_logs").add({
      action: "Permanently deleted user",
      actionCategory: "users",
      performedBy: request.auth.uid,
      performerName: callerName,
      performerRole: callerRole,
      serialNumber: callerNumber,
      targetPersonName: targetData?.name || "",
      details: targetData?.role || "",
      time: admin.firestore.FieldValue.serverTimestamp(),
      preciseTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (logErr) {
    console.error("Failed to write delete audit log (non-fatal):", logErr.message);
  }

  return { success: true };
});

exports.convertPptxToPdf = onCall({
  cors: ["http://localhost:53996", "http://localhost:5000", /^http:\/\/localhost(:\d+)?$/, "https://levelup-26.web.app", "https://levelup-26.firebaseapp.com"],
  region: "us-central1",
  memory: "2GiB",
  timeoutSeconds: 300,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const storagePath = request.data.storagePath;
  if (!storagePath) {
    throw new HttpsError("invalid-argument", "storagePath is required.");
  }

  const fs = require("fs");
  const path = require("path");
  const os = require("os");
  const { convertDocument } = require("@matbee/libreoffice-converter");

  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);

  const [exists] = await file.exists();
  if (!exists) {
    throw new HttpsError("not-found", "PPTX file not found in Storage.");
  }

  const tempDir = os.tmpdir();
  const filename = path.basename(storagePath);
  const tempPptxPath = path.join(tempDir, filename);

  try {
    // Download PPTX
    await file.download({ destination: tempPptxPath });

    // Read bytes
    const pptxBuffer = fs.readFileSync(tempPptxPath);

    // Convert to PDF
    const result = await convertDocument(pptxBuffer, { outputFormat: "pdf" });
    const pdfBuffer = result.data;

    // Upload PDF back to Storage
    const baseNameWithoutExt = path.basename(storagePath, path.extname(storagePath));
    const pdfStoragePath = `materials/converted_pdfs/${baseNameWithoutExt}.pdf`;

    const pdfFile = bucket.file(pdfStoragePath);
    await pdfFile.save(pdfBuffer, {
      metadata: {
        contentType: "application/pdf",
      },
    });

    // Clean up local temp file
    fs.unlinkSync(tempPptxPath);

    return { pdfPath: pdfStoragePath };
  } catch (error) {
    console.error("PPTX to PDF conversion failed:", error);
    if (fs.existsSync(tempPptxPath)) {
      fs.unlinkSync(tempPptxPath);
    }
    throw new HttpsError("internal", "Failed to convert PPTX: " + error.message);
  }
});