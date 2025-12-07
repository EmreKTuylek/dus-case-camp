const admin = require("firebase-admin");
const serviceAccount = require("../../service-account-key.json"); // User needs to provide this

// Initialize Firebase Admin
// Note: For local emulator, we don't strictly need the service account if we set FIRESTORE_EMULATOR_HOST
if (process.env.FIRESTORE_EMULATOR_HOST) {
    admin.initializeApp({
        projectId: "dus-case-camp-placeholder",
    });
} else {
    try {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
    } catch (e) {
        console.error("Error initializing Firebase Admin. Make sure 'service-account-key.json' exists in the root if running against production.", e);
        process.exit(1);
    }
}

const db = admin.firestore();

async function seed() {
    console.log("Starting seed...");

    // 1. Users
    const users = [
        {
            id: "student1",
            fullName: "Ahmet Yilmaz",
            email: "ahmet@example.com",
            role: "student",
            school: "Istanbul University",
            yearOfStudy: 4,
            totalPoints: 150,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
        },
        {
            id: "student2",
            fullName: "Ayse Demir",
            email: "ayse@example.com",
            role: "student",
            school: "Hacettepe University",
            yearOfStudy: 5,
            totalPoints: 200,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
        },
        {
            id: "teacher1",
            fullName: "Dr. Mehmet Oz",
            email: "mehmet@example.com",
            role: "teacher",
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
        },
    ];

    for (const user of users) {
        await db.collection("users").doc(user.id).set(user);
        console.log(`Created user: ${user.fullName}`);
    }

    // 2. Weeks
    const weeks = [
        {
            id: "week1",
            title: "Week 1 - Endodontics Cases",
            startDate: admin.firestore.Timestamp.fromDate(new Date("2023-10-01")),
            endDate: admin.firestore.Timestamp.fromDate(new Date("2023-10-08")),
            isActive: false,
            caseCount: 2,
        },
        {
            id: "week2",
            title: "Week 2 - Periodontology Cases",
            startDate: admin.firestore.Timestamp.fromDate(new Date("2023-10-09")),
            endDate: admin.firestore.Timestamp.fromDate(new Date("2023-10-16")),
            isActive: true,
            caseCount: 2,
        },
    ];

    for (const week of weeks) {
        await db.collection("weeks").doc(week.id).set(week);
        console.log(`Created week: ${week.title}`);
    }

    // 3. Cases
    const cases = [
        {
            id: "case1",
            weekId: "week1",
            title: "Complex Root Canal",
            description: "A 45-year-old patient presents with severe pain in tooth #36...",
            speciality: "Endodontics",
            level: "hard",
            mediaUrls: ["https://example.com/xray1.jpg"],
            createdBy: "teacher1",
            createdAt: admin.firestore.Timestamp.now(),
        },
        {
            id: "case2",
            weekId: "week1",
            title: "Broken Instrument",
            description: "Management of a separated instrument in the mesial root...",
            speciality: "Endodontics",
            level: "medium",
            mediaUrls: [],
            createdBy: "teacher1",
            createdAt: admin.firestore.Timestamp.now(),
        },
        {
            id: "case3",
            weekId: "week2",
            title: "Aggressive Periodontitis",
            description: "25-year-old male with rapid bone loss...",
            speciality: "Periodontology",
            level: "hard",
            mediaUrls: [],
            createdBy: "teacher1",
            createdAt: admin.firestore.Timestamp.now(),
        },
        {
            id: "case4",
            weekId: "week2",
            title: "Gingival Recession",
            description: "Treatment planning for Miller Class II recession...",
            speciality: "Periodontology",
            level: "easy",
            mediaUrls: [],
            createdBy: "teacher1",
            createdAt: admin.firestore.Timestamp.now(),
        },
    ];

    for (const c of cases) {
        await db.collection("cases").doc(c.id).set(c);
        console.log(`Created case: ${c.title}`);
    }

    console.log("Seeding complete!");
}

seed().catch(console.error);
