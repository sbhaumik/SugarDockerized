# Zscaler Certificates

Place your Zscaler certificates in this directory:

1. `zscaler-root-ca.crt` - Zscaler Root CA certificate
2. `zscaler-intermediate-ca.crt` - Zscaler Intermediate CA certificate

## Certificate Format
The certificates should be in PEM format (.crt or .pem files).

## Obtaining Certificates
You can usually download these from your Zscaler admin portal or get them from your IT department.

Common Zscaler certificate URLs (if accessible):
- Root CA: Usually available from Zscaler support or admin portal
- Intermediate CA: Usually available from Zscaler support or admin portal

## Alternative: Extract from Browser
If you can access HTTPS sites through Zscaler in your browser:
1. Visit any HTTPS site
2. Click on the lock icon in the address bar
3. View certificate details
4. Export the Zscaler root and intermediate certificates