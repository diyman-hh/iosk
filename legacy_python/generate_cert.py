from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.x509.oid import NameOID
import datetime
import os

def generate_fake_p12():
    # 1. Generate Private Key
    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    # 2. Generate Self-Signed Certificate
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"California"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, u"Cupertino"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"TrollStore User"),
        x509.NameAttribute(NameOID.COMMON_NAME, u"Fake Dev Certificate"),
    ])
    
    cert = x509.CertificateBuilder().subject_name(
        subject
    ).issuer_name(
        issuer
    ).public_key(
        key.public_key()
    ).serial_number(
        x509.random_serial_number()
    ).not_valid_before(
        datetime.datetime.utcnow()
    ).not_valid_after(
        # Valid for 10 years
        datetime.datetime.utcnow() + datetime.timedelta(days=3650)
    ).add_extension(
        x509.BasicConstraints(ca=True, path_length=None), critical=True,
    ).sign(key, hashes.SHA256())

    # 3. Export as P12
    p12_data = serialization.pkcs12.serialize_key_and_certificates(
        name=b"FakeCert",
        key=key,
        cert=cert,
        cas=None,
        encryption_algorithm=serialization.BestAvailableEncryption(b"123456")
    )

    # 4. Save to ipa directory
    output_path = "ipa/fake_cert.p12"
    with open(output_path, "wb") as f:
        f.write(p12_data)
    
    print(f"✅ 成功生成伪造证书: {output_path}")
    print("🔑 密码 (Password): 123456")

if __name__ == "__main__":
    generate_fake_p12()
