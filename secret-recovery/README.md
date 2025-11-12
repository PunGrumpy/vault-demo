# 💾 Secret Recovery Demo

สาธิตการใช้งาน HashiCorp Vault สำหรับการสร้าง snapshot และการกู้คืนข้อมูล (disaster recovery) พร้อมการใช้งาน Secret Engines หลายประเภท

## 📋 ภาพรวม

โปรเจกต์นี้สร้าง:

- **KV Secret Engine** (v1) - สำหรับเก็บ secrets แบบ key-value
- **PKI Secret Engine** - สำหรับการจัดการใบรับรอง (certificates)
- **Transform Secret Engine** - สำหรับการเข้ารหัสแบบ format-preserving encryption (FPE)
- **Vault Snapshots** - สำหรับการสำรองข้อมูลและกู้คืน

## 🚀 การใช้งาน

### Quick Start

รันสคริปต์เดียวเพื่อ setup ทุกอย่าง:

```bash
./setup.sh
```

สคริปต์นี้จะทำการ:

1. ✅ Enable Secret Engines:

   - `secret-recovery` (KV v1) - สำหรับเก็บ application secrets
   - `pki` - สำหรับการจัดการ certificates
   - `transform` - สำหรับ format-preserving encryption

2. ✅ สร้าง Demo Secrets:

   - Database credentials สำหรับ development, staging, และ production
   - PKI root CA certificate
   - Transform role สำหรับ payment processing

3. ✅ สร้าง Snapshot:
   - สร้างไฟล์ snapshot ที่มี timestamp: `vault-snapshot-YYYYMMDDHHMMSS.snap`

### ตรวจสอบการติดตั้ง

หลังจากรัน `setup.sh` แล้ว คุณสามารถตรวจสอบได้ว่า:

```bash
# ตรวจสอบ secret engines
vault secrets list

# ตรวจสอบ KV secrets
vault kv list secret-recovery/

# ตรวจสอบ PKI configuration
vault read pki/config/urls

# ตรวจสอบ Transform role
vault read transform/role/payments

# ตรวจสอบ snapshot files
ls -lh vault-snapshot-*.snap
```

## 🔐 Demo Secrets

โปรเจกต์นี้สร้าง secrets ต่อไปนี้:

### KV Secrets

| Path                                   | Username    | Password                 |
| -------------------------------------- | ----------- | ------------------------ |
| `secret-recovery/development/database` | `dev_user`  | `dev_pass_123`           |
| `secret-recovery/staging/database`     | `stg_user`  | `stg_pass_456`           |
| `secret-recovery/production/database`  | `prod_user` | `prod_pass_SUPER_SECRET` |

### PKI Resources

- **Root CA Certificate**: สร้างและบันทึกไว้ที่ `ca_cert.pem`
- **TTL**: 10 ปี (87600 ชั่วโมง)
- **Certificate URLs**:
  - Issuing Certificates: `http://127.0.0.1:8200/v1/pki/ca`
  - CRL Distribution Points: `http://127.0.0.1:8200/v1/pki/crl`

### Transform Resources

- **Role**: `transform/role/payments`
- **Transformation**: `transform/transformations/fpe/ccn-fpe`
  - Template: `ccn` (Credit Card Number)
  - Tweak Source: `internal`
  - Allowed Roles: `payments`

## 📸 Snapshot Recovery

Snapshot files (`vault-snapshot-*.snap`) ประกอบด้วยข้อมูลสำรองทั้งหมดของ Vault ณ เวลาที่สร้าง

### การสร้าง Snapshot

Snapshot จะถูกสร้างอัตโนมัติเมื่อรัน `setup.sh` หรือสามารถสร้างได้ด้วยตนเอง:

```bash
vault operator raft snapshot save ./vault-snapshot-$(date +%Y%m%d%H%M%S).snap
```

### การกู้คืนจาก Snapshot

⚠️ **คำเตือน**: การ restore snapshot จะเขียนทับข้อมูลทั้งหมดใน Vault ปัจจุบัน

```bash
# หยุด Vault server ก่อน (ถ้ากำลังทำงานอยู่)
vault operator raft snapshot restore vault-snapshot-YYYYMMDDHHMMSS.snap
```

### ตรวจสอบ Snapshot

```bash
# ดูข้อมูล snapshot
vault operator raft snapshot inspect vault-snapshot-YYYYMMDDHHMMSS.snap
```

## 🧹 Cleanup

เพื่อลบ resources และ secrets ทั้งหมดที่สร้างขึ้น:

```bash
./cleanup.sh
```

สคริปต์นี้จะทำการ:

1. ✅ ลบ KV secrets ทั้งหมด
2. ✅ ลบ PKI configuration
3. ✅ ลบ Transform engine configuration
4. ✅ ลบไฟล์ certificate ที่สร้างขึ้น

⚠️ **คำเตือน**: การรัน cleanup script จะลบ secrets ทั้งหมดอย่างถาวร ตรวจสอบให้แน่ใจว่าคุณมี snapshot ไว้สำหรับการกู้คืน

## 📁 โครงสร้างไฟล์

```
secret-recovery/
├── README.md                    # ไฟล์นี้
├── setup.sh                     # สคริปต์สำหรับ setup
├── cleanup.sh                   # สคริปต์สำหรับ cleanup
├── .gitignore                   # Git ignore rules
└── vault-snapshot-*.snap       # Snapshot files (ถูกสร้างอัตโนมัติ)
```

## 🔍 การทดสอบ

### ทดสอบ KV Secrets

```bash
# อ่าน development database credentials
vault kv get secret-recovery/development/database

# อ่าน staging database credentials
vault kv get secret-recovery/staging/database

# อ่าน production database credentials
vault kv get secret-recovery/production/database
```

### ทดสอบ PKI

```bash
# ดู PKI configuration
vault read pki/config/urls

# ดู root certificate
cat ca_cert.pem

# สร้าง certificate ใหม่ (ตัวอย่าง)
vault write pki/roles/example-dot-com \
    allowed_domains=example.com \
    allow_subdomains=true \
    max_ttl=72h
```

### ทดสอบ Transform Engine

```bash
# ดู Transform role
vault read transform/role/payments

# ทดสอบ encoding (ต้องมี Vault Enterprise)
vault write transform/encode/payments value=4532-1234-5678-9010

# ทดสอบ decoding
vault write transform/decode/payments value=<encoded-value>
```

### ทดสอบ Snapshot

```bash
# สร้าง snapshot ใหม่
vault operator raft snapshot save ./test-snapshot.snap

# ตรวจสอบ snapshot
vault operator raft snapshot inspect ./test-snapshot.snap

# ลบ snapshot ทดสอบ
rm ./test-snapshot.snap
```

## 🔐 Secret Engines ที่ใช้

### KV Secret Engine (v1)

- **Path**: `secret-recovery`
- **Version**: v1 (non-versioned)
- **ใช้สำหรับ**: เก็บ application secrets แบบ key-value

**คำสั่งที่ใช้บ่อย**:

```bash
# อ่าน secret
vault kv get secret-recovery/development/database

# เขียน secret
vault kv put secret-recovery/new/path key=value

# ลบ secret
vault kv delete secret-recovery/path/to/secret
```

### PKI Secret Engine

- **Path**: `pki`
- **ใช้สำหรับ**: การจัดการและสร้าง X.509 certificates

**คุณสมบัติ**:

- Root CA generation
- Certificate signing
- CRL (Certificate Revocation List) management
- TTL: 10 ปี (87600 ชั่วโมง)

### Transform Secret Engine

- **Path**: `transform`
- **ใช้สำหรับ**: Format-preserving encryption (FPE)
- **Template**: Credit Card Number (ccn)

**คุณสมบัติ**:

- รักษารูปแบบของข้อมูลเดิม (เช่น หมายเลขบัตรเครดิต)
- ใช้สำหรับการเข้ารหัสข้อมูลที่ต้องคงรูปแบบไว้

⚠️ **หมายเหตุ**: Transform Secret Engine ต้องใช้ Vault Enterprise

## 🛡️ Security Notes

⚠️ **ข้อควรระวังด้านความปลอดภัย**:

1. **Snapshot Files**: ไฟล์ snapshot มีข้อมูลที่เข้ารหัสของ Vault ควรเก็บรักษาไว้อย่างปลอดภัยและไม่ควร commit ลง git

2. **Demo Credentials**: Credentials ที่สร้างขึ้นใน demo นี้เป็นเพียงตัวอย่างเท่านั้น ไม่ควรใช้ใน production

3. **Certificate Files**: ไฟล์ `ca_cert.pem` เป็น public certificate สามารถแชร์ได้ แต่ต้องแน่ใจว่า private keys ไม่ถูก commit ลง version control

4. **Access Control**: Demo นี้ไม่ได้ตั้งค่า policies หรือ authentication ในการใช้งานจริงควรตั้งค่า access controls ให้เหมาะสม

5. **Snapshot Storage**: ควรเก็บ snapshot ไว้ในที่ปลอดภัยและมีการ backup หลายชุด

## 🔧 Troubleshooting

### Vault ไม่ทำงาน

หากพบ connection errors ให้ตรวจสอบว่า Vault ทำงานอยู่:

```bash
vault status
```

### Permission Denied

ตรวจสอบว่าคุณมี authentication ที่ถูกต้อง:

```bash
# ตรวจสอบ token ปัจจุบัน
vault token lookup

# Login ใหม่
vault auth -method=userpass username=<your-username>
```

### Secret Engine มีอยู่แล้ว

หาก secret engine path มีอยู่แล้ว ต้อง disable ก่อน:

```bash
# ตรวจสอบ secret engines
vault secrets list

# Disable secret engine
vault secrets disable secret-recovery
vault secrets disable pki
vault secrets disable transform
```

### Snapshot ไม่สามารถ restore ได้

- ตรวจสอบว่า Vault server หยุดทำงานแล้ว
- ตรวจสอบว่า snapshot file ไม่เสียหาย
- ตรวจสอบว่า Vault storage backend รองรับ snapshot restore

### Transform Engine ไม่ทำงาน

- ตรวจสอบว่าคุณใช้ Vault Enterprise
- ตรวจสอบว่า Transform engine ถูก enable แล้ว
- ตรวจสอบ license ของ Vault Enterprise

## 📝 หมายเหตุ

- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรันสคริปต์
- **Transform Secret Engine ต้องใช้ Vault Enterprise**
- Snapshot files จะถูก ignore โดย git (ดูใน `.gitignore`)
- Passwords และ credentials เป็นตัวอย่างเท่านั้น ควรเปลี่ยนใน production
- Certificate TTL ถูกตั้งไว้ที่ 10 ปี (87600 ชั่วโมง) สำหรับ demo เท่านั้น

## 🔗 ดูเพิ่มเติม

- [Vault KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv)
- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Vault Transform Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/transform)
- [Vault Snapshot Operations](https://developer.hashicorp.com/vault/docs/commands/operator/raft)
- [Vault Disaster Recovery](https://developer.hashicorp.com/vault/docs/operations/disaster-recovery)
