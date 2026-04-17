# ServisLog+ Security

## Security Architecture

### Hybrid Security Policy (3 Zones)

1. **Public Zone** - No encryption
   - Service names, item prices

2. **Restricted Zone** - Basic encryption  
   - Customer names (encrypted)
   - Phone numbers (encrypted)

3. **Sensitive Zone** - Strict encryption
   - Financial data
   - Service history

## Encryption

- **Algorithm**: AES-GCM 256-bit
- **Key Derivation**: PBKDF2-HMAC-SHA256
- **Iterations**: 100,000 (OWASP compliant)
- **IV**: Random 12-byte per encryption

## Authentication

- Google Sign-In (Firebase Auth)
- PIN (6 digits)
- Biometric (fingerprint/face)
- Session management

## Data Protection

- Secure storage via flutter_secure_storage
- Encrypted local database
- Cloud data encryption

## Security Services

- EncryptionService - AES-GCM
- BiometricService - Fingerprint/Face
- SessionManager - Session lifecycle

---

Last updated: April 2026
