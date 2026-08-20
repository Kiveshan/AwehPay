const { getAndroidPublisher, PACKAGE_NAME } = require('./google_play_client');

/**
 * GET /app-version
 * Returns the latest app version info from Google Play
 * Used to enforce mandatory updates before login
 */
async function getAppVersion(req, res) {
  try {
    const androidPublisher = getAndroidPublisher();
    
    // Get the latest production track release
    const { data } = await androidPublisher.edits.tracks.list({
      packageName: PACKAGE_NAME,
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
  } catch (error) {
    console.error('Error fetching app version:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch app version from Google Play',
    });
  }
}

module.exports = getAppVersion;