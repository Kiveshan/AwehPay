const admin = require('firebase-admin');
const path = require('path');

// Load Firebase service-account credentials from the JSON file
const serviceAccount = require('../awehpay-firebase-adminsdk-fbsvc-bf97993378.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function updateSubscriptionTiers() {
  console.log('Starting subscription tier update...\n');

  try {
    // Get existing tiers
    const snapshot = await db.collection('subscriptionTiers').get();
    
    if (snapshot.empty) {
      console.log('No existing subscription tiers found. Creating new ones...');
    } else {
      console.log(`Found ${snapshot.docs.length} existing subscription tiers.`);
    }

    // Define the new subscription tiers
    const newTiers = [
      {
        name: 'Basic',
        code: 'basic',
        price: 300,
        currency: 'ZAR',
        billingPeriod: 'monthly',
        setupFee: 0,
        description: 'Essential features for small businesses',
        displayOrder: 1,
        isActive: true,
        isRecommended: false,
        features: [
          'Barcode Scanner Access',
          'Low-stock Alerts',
          'Cash Sales',
          'Net Profit + Analytics',
          'Up to 100 Products',
          '15 Services',
        ],
        limits: {
          maxProducts: 100,
          maxServices: 15,
          maxCardPaymentsPerDay: 150,
          barcodeScannerEnabled: true,
          lowStockAlertsEnabled: true,
          analyticsEnabled: true,
          cashSalesEnabled: true,
          cardPaymentsEnabled: true,
          expenseTrackingEnabled: false,
        },
      },
      {
        name: 'Premium',
        code: 'premium',
        price: 500,
        currency: 'ZAR',
        billingPeriod: 'monthly',
        setupFee: 0,
        description: 'Full insights and unlimited everything',
        displayOrder: 2,
        isActive: true,
        isRecommended: true,
        features: [
          'Barcode Scanner Access',
          'Unlimited Card Payments',
          'Daily Breakdown of Products Sold',
          'Full Insights',
          'Unlimited Fixed Expenses',
          'Unlimited Products and Services',
        ],
        limits: {
          maxProducts: null,
          maxServices: null,
          maxCardPaymentsPerDay: null,
          barcodeScannerEnabled: true,
          lowStockAlertsEnabled: true,
          analyticsEnabled: true,
          cashSalesEnabled: true,
          cardPaymentsEnabled: true,
          expenseTrackingEnabled: true,
        },
      },
    ];

    const now = admin.firestore.FieldValue.serverTimestamp();

    // Update or create each tier
    for (const tier of newTiers) {
      // Check if tier with this code already exists
      const existingQuery = await db
        .collection('subscriptionTiers')
        .where('code', '==', tier.code)
        .get();

      if (!existingQuery.empty) {
        // Update existing tier
        const doc = existingQuery.docs[0];
        console.log(`Updating existing tier: ${tier.name} (ID: ${doc.id})`);
        
        await doc.ref.update({
          ...tier,
          updatedAt: now,
        });
        
        console.log(`✓ Updated ${tier.name} tier successfully`);
      } else {
        // Create new tier
        console.log(`Creating new tier: ${tier.name}`);
        
        const tierRef = db.collection('subscriptionTiers').doc();
        await tierRef.set({
          tierId: tierRef.id,
          ...tier,
          createdBy: 'system',
          updatedBy: 'system',
          createdAt: now,
          updatedAt: now,
        });
        
        console.log(`✓ Created ${tier.name} tier successfully`);
      }
    }

    // Deactivate any other tiers that are not Basic or Premium
    const allTiersSnapshot = await db.collection('subscriptionTiers').get();
    const activeCodes = newTiers.map(t => t.code);
    
    for (const doc of allTiersSnapshot.docs) {
      const tierData = doc.data();
      if (!activeCodes.includes(tierData.code) && tierData.isActive) {
        console.log(`Deactivating tier: ${tierData.name} (ID: ${doc.id})`);
        await doc.ref.update({
          isActive: false,
          updatedAt: now,
        });
        console.log(`✓ Deactivated ${tierData.name} tier successfully`);
      }
    }

    console.log('\n✅ Subscription tiers updated successfully!');
    console.log('\nNew tier structure:');
    console.log('- Basic: R300/month');
    console.log('- Premium: R500/month (Recommended)');
    console.log('\nNote: A 30 day free trial of Premium is available to all new users.');
    
  } catch (error) {
    console.error('Error updating subscription tiers:', error);
    process.exit(1);
  }
}

// Run the update
updateSubscriptionTiers()
  .then(() => {
    console.log('\nMigration completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exit(1);
  });
