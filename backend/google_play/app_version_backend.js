const { getAndroidPublisher, PACKAGE_NAME } = require('./google_play_client');

/**
 * GET /app-version
 * Returns the latest app version info from Google Play
 * Used to enforce mandatory updates before login
 */
async function getAppVersion(req, res) {
  try {
    const clientVersionCode = parseInt(req.headers['x-app-version-code'] || '0');
    const clientVersion = req.headers['x-app-version'] || '1.0.0';
    
    // Minimum version that supports update check (version 14 / 1.0.1)
    const MIN_UPDATE_CHECK_VERSION = 14;
    
    // Skip update check for older versions that don't support the new flow
    if (clientVersionCode < MIN_UPDATE_CHECK_VERSION) {
      return res.json({
        success: true,
        skipUpdateCheck: true,
        latestVersion: {
          versionCode: clientVersionCode,
          versionName: clientVersion,
          isMandatory: false,
        },
      });
    }

    const androidPublisher = getAndroidPublisher();
    
    // Create an edit session
    const editResponse = await androidPublisher.edits.insert({
      packageName: PACKAGE_NAME,
    });
    const editId = editResponse.data.id;

    try {
      // Get the latest production track release
      const { data } = await androidPublisher.edits.tracks.list({
        packageName: PACKAGE_NAME,
        editId: editId,
      });

      // Find the production track
      const productionTrack = data.tracks?.find(track => track.track === 'production');
      
      if (!productionTrack || !productionTrack.releases || productionTrack.releases.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'No production release found',
        });
      }

      // Get the latest release (first one is usually the latest)
      const latestRelease = productionTrack.releases[0];
      
      // Extract version code and name
      const versionCode = latestRelease.versionCodes?.[0];
      const versionName = latestRelease.name;
      
      if (!versionCode) {
        return res.status(404).json({
          success: false,
          error: 'No version code found in latest release',
        });
      }

      res.json({
        success: true,
        latestVersion: {
          versionCode: versionCode,
          versionName: versionName,
          isMandatory: latestRelease.status !== 'inProgress', // Consider completed releases as mandatory
        },
      });
    } finally {
      // Always delete the edit to clean up
      await androidPublisher.edits.delete({
        packageName: PACKAGE_NAME,
        editId: editId,
      }).catch(() => {
        // Ignore delete errors
      });
    }
  } catch (error) {
    console.error('Error fetching app version:', error);
    
    // For development environments without Google Play credentials, 
    // return a response that allows the app to proceed
    if (error.message && error.message.includes('No Google Play Developer API credentials')) {
      return res.json({
        success: true,
        latestVersion: {
          versionCode: 0, // No update required
          versionName: 'dev',
          isMandatory: false,
        },
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch app version from Google Play',
    });
  }
}

module.exports = getAppVersion;