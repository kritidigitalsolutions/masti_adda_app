# 🛠️ Backend Fix Required: Google Sign-In (Web & Mobile)

## 📌 Problem Summary
When users log in using **Google Sign-In on Web**, the API endpoint returns **500 Internal Server Error**:
- **API Endpoint:** `POST https://goli-doli-ott-backend.vercel.app/api/auth/google-login`
- **Error:** `500 (Internal Server Error) - Server error: the server failed to fulfill an apparently valid request`

---

## 🔍 Root Cause Analysis

1. **Mobile vs Web Token Difference:**
   - **Mobile (Android/iOS):** Sends a standard JWT **Firebase/Google ID Token**.
   - **Web (Flutter Web / Browser):** The OAuth flow provides an OAuth2 **Access Token** (starts with `ya29...`) or web token.

2. **Why 500 Error Occurs:**
   - The backend likely uses `admin.auth().verifyIdToken(idToken)` or `oauth2Client.verifyIdToken({ idToken })`.
   - When an **Access Token** (`ya29...`) is passed to `verifyIdToken()`, the library throws an unhandled exception (e.g., `"Decoding Firebase ID token failed"` or `"Wrong number of segments in token"`).
   - Because the error is not caught / token type is not handled, the server crashes with a **500 Internal Server Error**.

---

## 📤 Request Sent from Frontend (Flutter App & Web)

The frontend sends the following JSON payload in `POST /api/auth/google-login`:

```json
{
  "idToken": "ya29.a0Ac...",
  "token": "ya29.a0Ac...",
  "accessToken": "ya29.a0Ac...",
  "email": "user@gmail.com",
  "name": "User Name",
  "photoUrl": "https://lh3.googleusercontent.com/...",
  "googleId": "10873429384928349",
  "fcmToken": "optional_fcm_token"
}
```

---

## 💡 Solution / Backend Code Implementation (Node.js / Express Example)

Please update the Google Login controller on the backend to handle **both ID Tokens and Access Tokens**:

```javascript
const axios = require('axios');
const { OAuth2Client } = require('google-auth-library');
// const admin = require('firebase-admin'); // If using Firebase Admin

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.googleLogin = async (req, res) => {
  try {
    const { idToken, accessToken, token, email, name, photoUrl, googleId, fcmToken } = req.body;

    const incomingToken = idToken || accessToken || token;

    if (!incomingToken && !email) {
      return res.status(400).json({
        success: false,
        message: "Google token or email is required",
      });
    }

    let userEmail = email;
    let userName = name;
    let userPhoto = photoUrl;
    let userGoogleId = googleId;

    // 1️⃣ Check if token is a Google OAuth Access Token (starts with ya29.)
    if (incomingToken && incomingToken.startsWith('ya29.')) {
      try {
        // Fetch user profile from Google's UserInfo API using Access Token
        const googleRes = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${incomingToken}` },
        });

        if (googleRes.data) {
          userEmail = googleRes.data.email || userEmail;
          userName = googleRes.data.name || userName;
          userPhoto = googleRes.data.picture || userPhoto;
          userGoogleId = googleRes.data.sub || userGoogleId;
        }
      } catch (tokenErr) {
        console.warn("Google UserInfo API verification failed, fallback to payload data:", tokenErr.message);
      }
    } 
    // 2️⃣ If it's a standard JWT ID Token (Mobile / Firebase)
    else if (incomingToken) {
      try {
        // Option A: Using google-auth-library
        /*
        const ticket = await client.verifyIdToken({
          idToken: incomingToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        const payload = ticket.getPayload();
        userEmail = payload.email || userEmail;
        userName = payload.name || userName;
        userPhoto = payload.picture || userPhoto;
        userGoogleId = payload.sub || userGoogleId;
        */

        // Option B: Using Firebase Admin
        /*
        const decoded = await admin.auth().verifyIdToken(incomingToken);
        userEmail = decoded.email || userEmail;
        userName = decoded.name || userName;
        userPhoto = decoded.picture || userPhoto;
        userGoogleId = decoded.uid || userGoogleId;
        */
      } catch (verifyErr) {
        console.warn("verifyIdToken failed, fallback to payload:", verifyErr.message);
      }
    }

    if (!userEmail) {
      return res.status(400).json({
        success: false,
        message: "Could not retrieve user email from Google",
      });
    }

    // 3️⃣ Find or Create User in Database
    let user = await User.findOne({ email: userEmail.toLowerCase() });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await User.create({
        email: userEmail.toLowerCase(),
        name: userName || "Google User",
        profileImage: userPhoto || "",
        googleId: userGoogleId || "",
        authProvider: "google",
        isProfileComplete: true, // Google users already have verified name & email
        fcmToken: fcmToken || "",
      });
    } else {
      // Update existing user details if missing
      if (!user.name && userName) user.name = userName;
      if (!user.profileImage && userPhoto) user.profileImage = userPhoto;
      if (!user.googleId && userGoogleId) user.googleId = userGoogleId;
      if (fcmToken) user.fcmToken = fcmToken;
      await user.save();
    }

    // 4️⃣ Generate App JWT Token
    const appToken = generateJwtToken(user._id);

    // 5️⃣ Return Success Response
    return res.status(200).json({
      success: true,
      message: isNewUser ? "User registered successfully" : "Login successful",
      token: appToken,
      isNewUser: isNewUser,
      profileComplete: true,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || "",
        profileImage: user.profileImage || "",
        authProvider: user.authProvider || "google",
        isProfileComplete: user.isProfileComplete ?? true,
      },
    });

  } catch (error) {
    console.error("Google Login Error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error during Google login",
      error: error.message,
    });
  }
};
```

---

## 📥 Expected Response Format (Status 200 OK)

```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "isNewUser": false,
  "profileComplete": true,
  "user": {
    "_id": "66f1234567890abcdef12345",
    "name": "John Doe",
    "email": "johndoe@gmail.com",
    "phone": "",
    "profileImage": "https://lh3.googleusercontent.com/a/...",
    "authProvider": "google",
    "isProfileComplete": true
  }
}
```

---

## ✅ Summary of Action Items for Backend
1. Wrap token verification in a `try...catch` block to prevent unhandled 500 server crashes.
2. Check if token begins with `ya29.` (OAuth Access Token from Web) and verify via `https://www.googleapis.com/oauth2/v3/userinfo`.
3. If user signs in via Google, auto-populate `name`, `email`, and `profileImage`, and mark `isProfileComplete: true` / `profileComplete: true`.
4. Return `token`, `user`, and `profileComplete: true` in the response body.
