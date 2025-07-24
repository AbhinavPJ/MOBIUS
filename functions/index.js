const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const cors = require("cors")({ origin: true }); // Allow all origins for testing purposes

admin.initializeApp();

// Gmail credentials from Firebase Config
const gmailUser = functions.config().gmail.user;
const gmailPass = functions.config().gmail.pass;

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailUser,
    pass: gmailPass,
  },
});

// Create HTTP function to send verification email
exports.sendVerificationEmail = functions.https.onRequest((req, res) => {
  // Use CORS to handle preflight requests
  cors(req, res, async () => {
    // Allow only POST requests
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Ensure the email parameter exists
    const { email } = req.body;

    if (!email) {
      console.log("Error: Missing email parameter in request body");
      return res.status(400).send("Email is required");
    }

    if (typeof email !== "string" || !email.includes('@')) {
      console.log("Error: Invalid email format", email);
      return res.status(400).send("Invalid email format");
    }

    try {
      // Generate email verification link
      const verificationLink = await admin.auth().generateEmailVerificationLink(email);
      
      // Log the verification link to the terminal for debugging
      console.log("Generated verification link:", verificationLink);

      // Email setup
      const mailOptions = {
        from: `Your App <${gmailUser}>`,
        to: email,
        subject: "Verify your email address",
        html: `
          <p>Hello,</p>
          <p>Please verify your email by clicking <a href="${verificationLink}">${verificationLink}</a></p>
        `,
      };

      // Send email
      await transporter.sendMail(mailOptions);
      return res.status(200).send({ success: true });
    } catch (error) {
      console.error("Error sending email:", error);
      return res.status(500).send({ error: error.message });
    }
  });
});
