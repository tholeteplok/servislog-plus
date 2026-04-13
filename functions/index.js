const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

/**
 * Ambil IP address dari request secara aman.
 * Mendukung proxy (X-Forwarded-For) dan koneksi langsung.
 */
function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) return forwarded.split(',')[0].trim();
  return req.connection?.remoteAddress || req.ip || 'unknown';
}

// ─────────────────────────────────────────────────────────────
// PHASE 1.1: verifySession Cloud Function (HTTPS)
// ─────────────────────────────────────────────────────────────
// Dipanggil oleh SessionManager._handshakeOnline() di Flutter.
// Memvalidasi:
//   1. Firebase ID Token (sudah login, tidak expired)
//   2. Status akun user (active/disabled)
//   3. Apakah DeviceId cocok dengan activeDeviceId di Firestore
// Return 200 jika valid, 401 jika tidak.
// ─────────────────────────────────────────────────────────────

exports.verifySession = functions
  .runWith({
    timeoutSeconds: 15,
    memory: '256MB',
  })
  .https.onRequest(async (req, res) => {
    // Hanya izinkan POST
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method Not Allowed' });
    }

    const clientIp = getClientIp(req);

    // ── PHASE 1.2: Rate Limiting ──────────────────────────────
    // Menggunakan Firestore sebagai counter dengan TTL 1 menit.
    // Batas: 15 request/menit per IP.
    try {
      const rateLimitRef = db.collection('_rate_limits').doc(`session_${clientIp}`);
      const nowMs = Date.now();
      const windowMs = 60 * 1000; // 1 menit
      const maxRequests = 15;

      const result = await db.runTransaction(async (t) => {
        const doc = await t.get(rateLimitRef);
        let count = 1;
        let windowStart = nowMs;

        if (doc.exists) {
          const data = doc.data();
          // Reset window jika sudah lebih dari 1 menit
          if (nowMs - data.windowStart < windowMs) {
            count = data.count + 1;
            windowStart = data.windowStart;
          }
        }

        t.set(rateLimitRef, {
          count,
          windowStart,
          lastRequest: nowMs,
          ip: clientIp,
        });

        return { count, allowed: count <= maxRequests };
      });

      if (!result.allowed) {
        console.warn(`[RATE_LIMIT] IP ${clientIp} exceeded limit (${result.count} req/min)`);
        return res.status(429).json({
          code: 'rate_limit_exceeded',
          error: 'Terlalu banyak permintaan. Coba lagi dalam 1 menit.',
        });
      }
    } catch (rateError) {
      // Jika rate limit check gagal (mis. Firestore error), biarkan request lanjut
      // agar pengguna tidak diblokir secara salah (Safe-Open policy untuk UX)
      console.error('[RATE_LIMIT_ERROR] Rate limit check failed, proceeding:', rateError.message);
    }

    // ── Ambil ID Token dari Authorization header ──────────────
    const authHeader = req.headers['authorization'] || '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        code: 'missing_token',
        error: 'Authorization token tidak ditemukan.',
      });
    }

    const idToken = authHeader.substring(7);

    try {
      // ── 1. Verifikasi Firebase ID Token ──────────────────────
      const decodedToken = await admin.auth().verifyIdToken(idToken, true); // checkRevoked=true
      const uid = decodedToken.uid;

      // ── 2. Cek Status Akun di Firestore ──────────────────────
      const userDocRef = db.collection('users').doc(uid);
      const userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        console.warn(`[VERIFY_SESSION] User doc not found for uid: ${uid}`);
        return res.status(401).json({ code: 'user_not_found', error: 'Akun tidak ditemukan.' });
      }

      const userData = userDoc.data();
      const accountStatus = userData.status || 'active';

      if (accountStatus === 'disabled' || accountStatus === 'deleted') {
        console.warn(`[VERIFY_SESSION] Account ${uid} is ${accountStatus}`);
        return res.status(401).json({
          code: 'account_disabled',
          error: 'Akun Anda telah dinonaktifkan. Hubungi Owner bengkel.',
        });
      }

      // ── PHASE 1.3: Device Fingerprint Validation ──────────────
      // Memastikan deviceId yang dikirim cocok dengan activeDeviceId di Firestore.
      // Menggunakan multi-factor ID: base deviceId + platform info dari body request.
      const requestBody = req.body || {};
      const clientDeviceId = requestBody.deviceId;
      const clientPlatform = requestBody.platform || 'unknown'; // 'android' | 'ios'
      const clientAppVersion = requestBody.appVersion || 'unknown';

      if (clientDeviceId) {
        const activeDeviceId = userData.activeDeviceId;

        if (activeDeviceId && activeDeviceId !== clientDeviceId) {
          console.warn(
            `[VERIFY_SESSION] Device mismatch for ${uid}: ` +
            `expected=${activeDeviceId}, got=${clientDeviceId}`
          );

          // Log security event ke Firestore
          await db
            .collection('bengkel')
            .doc(userData.bengkelId || 'unknown')
            .collection('security_audit_logs')
            .add({
              type: 'device_mismatch',
              uid,
              expectedDeviceId: activeDeviceId,
              attemptedDeviceId: clientDeviceId,
              platform: clientPlatform,
              clientIp,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              severity: 'high',
            });

          return res.status(401).json({
            code: 'device_mismatch',
            error: 'Sesi tidak valid. Perangkat ini bukan perangkat aktif Anda.',
          });
        }
      }

      // ── 3. Update lastSeen & session metadata ─────────────────
      await userDocRef.update({
        'activeDeviceInfo.lastSeen': admin.firestore.FieldValue.serverTimestamp(),
        lastHandshakeAt: admin.firestore.FieldValue.serverTimestamp(),
        lastHandshakePlatform: clientPlatform,
        lastHandshakeAppVersion: clientAppVersion,
      });

      // ── 4. Return success ─────────────────────────────────────
      return res.status(200).json({
        code: 'session_valid',
        uid,
        role: decodedToken.role || userData.role || 'staff',
        bengkelId: decodedToken.bengkelId || userData.bengkelId || '',
        serverTime: Date.now(),
      });

    } catch (error) {
      if (error.code === 'auth/id-token-revoked') {
        return res.status(401).json({ code: 'token_revoked', error: 'Token telah dicabut.' });
      }
      if (error.code === 'auth/id-token-expired') {
        return res.status(401).json({ code: 'token_expired', error: 'Token sudah kadaluarsa.' });
      }
      if (error.code === 'auth/user-disabled') {
        return res.status(401).json({ code: 'user_disabled', error: 'Akun dinonaktifkan.' });
      }
      console.error('[VERIFY_SESSION] Error:', error.message, error.code);
      return res.status(500).json({ code: 'internal_error', error: 'Terjadi kesalahan server.' });
    }
  });


// ─────────────────────────────────────────────────────────────
// PHASE 1.1b: setRole Cloud Function (Role Management)
// Dipanggil oleh Owner untuk menetapkan role staf.
// ─────────────────────────────────────────────────────────────

exports.setRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Endpoint requires authentication!');
  }

  if (context.auth.token.role !== 'owner') {
    throw new functions.https.HttpsError('permission-denied', 'Only owners can assign roles.');
  }

  const { uid, role, bengkelId } = data;

  if (!uid || !role || !bengkelId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters.');
  }

  // Validasi role yang diizinkan
  const allowedRoles = ['owner', 'admin', 'mekanik', 'staff'];
  if (!allowedRoles.includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', `Role '${role}' tidak diizinkan.`);
  }

  try {
    await admin.auth().setCustomUserClaims(uid, { role, bengkelId });

    // Log aksi ke Firestore: audit trail
    await db
      .collection('bengkel')
      .doc(bengkelId)
      .collection('security_audit_logs')
      .add({
        type: 'role_assignment',
        targetUid: uid,
        newRole: role,
        assignedByUid: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        severity: 'medium',
      });

    return { message: `Success! User ${uid} assigned as ${role} for bengkel ${bengkelId}` };
  } catch (error) {
    console.error('Error setting custom claims:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// ─────────────────────────────────────────────────────────────
// CLEANUP: Rate Limit Data (dipanggil otomatis setiap jam)
// Menghapus data rate limiting yang sudah kedaluwarsa (> 5 menit)
// agar Firestore tidak penuh dengan data sementara.
// ─────────────────────────────────────────────────────────────

exports.cleanupRateLimits = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (_context) => {
    const cutoff = Date.now() - 5 * 60 * 1000; // 5 menit lalu
    const snapshot = await db
      .collection('_rate_limits')
      .where('lastRequest', '<', cutoff)
      .get();

    if (snapshot.empty) {
      console.log('[CLEANUP] No stale rate limit docs found.');
      return null;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    console.log(`[CLEANUP] Deleted ${snapshot.docs.length} stale rate limit docs.`);
    return null;
  });
