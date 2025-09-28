const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'captain-truck-242e5',
  storageBucket: 'captain-truck-242e5.appspot.com'
});

const bucket = admin.storage().bucket();

async function uploadLogo() {
  try {
    console.log('📤 Uploading app logo to Firebase Storage...');
    
    // Path to your logo
    const logoPath = '../assets/images/logo.png';
    const destinationPath = 'assets/logo.png';
    
    // Upload file
    await bucket.upload(logoPath, {
      destination: destinationPath,
      metadata: {
        metadata: {
          contentType: 'image/png',
        },
      },
      public: true, // Make it publicly accessible
    });
    
    // Get the public URL
    const file = bucket.file(destinationPath);
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: '03-09-2491', // Far future date
    });
    
    console.log('✅ Logo uploaded successfully!');
    console.log('🌐 Public URL:', url);
    console.log('');
    console.log('📋 The Cloud Functions will now use your app logo in notifications!');
    
  } catch (error) {
    console.error('❌ Error uploading logo:', error);
  }
}

// Run the upload
uploadLogo();
