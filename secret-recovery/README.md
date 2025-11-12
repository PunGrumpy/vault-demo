> [!IMPORTANT]
> Please run [setup.sh](../setup.sh) to setup the environment. Before you run the [setup.sh](./setup.sh) for setup the demo environment!

# 💾 Secret Recovery Demo

สาธิตการใช้งาน HashiCorp Vault สำหรับการสร้าง snapshot และการกู้คืนข้อมูล (disaster recovery) พร้อมการใช้งาน Secret Engines หลายประเภท

## 🚀 Quick Start

```bash
./setup.sh
```

สคริปต์จะสร้าง secret engines, demo secrets และ snapshot อัตโนมัติ

> [!WARN]
> ตอนนี้ Leader, Followers เป็น `http` ซึ่งถ้า API เข้าสู่ Leader จะทำงานได้ปกติ แต่ถ้า API เข้าสู่ Followers จะทำให้เกิดปัญหา ERROR Protocol downgrade detected.

## 📖 Demo Scenarios

### Scenario 1: Disaster Recovery with Snapshots

**ปัญหา**: ต้องการสำรองข้อมูล Vault ทั้งหมดเพื่อกู้คืนเมื่อเกิด disaster

**วิธีแก้**: ใช้ Vault snapshot เพื่อบันทึกสถานะทั้งหมดของ Vault

- ✅ สร้าง snapshot ที่มี timestamp: `vault-snapshot-YYYYMMDDHHMMSS.snap`
- ✅ Snapshot ประกอบด้วย secrets, policies, และ configuration ทั้งหมด

**ทดสอบ**:

```bash
# สร้าง snapshot
vault operator raft snapshot save ./vault-snapshot-$(date +%Y%m%d%H%M%S).snap

# ตรวจสอบ snapshot
vault operator raft snapshot inspect vault-snapshot-*.snap

# กู้คืนจาก snapshot (⚠️ จะเขียนทับข้อมูลปัจจุบัน)
vault operator raft snapshot restore vault-snapshot-*.snap
```

### Scenario 2: Multiple Secret Engines

**ปัญหา**: ต้องการใช้ Vault เก็บข้อมูลหลายประเภท (secrets, certificates, encrypted data)

**วิธีแก้**: ใช้ Secret Engines หลายประเภทตาม use case

#### KV Secret Engine (v1)

- **Path**: `secret-recovery`
- **ใช้สำหรับ**: เก็บ application secrets แบบ key-value
- **Demo Secrets**:
  - `secret-recovery/development/database`
  - `secret-recovery/staging/database`
  - `secret-recovery/production/database`

#### PKI Secret Engine

- **Path**: `pki`
- **ใช้สำหรับ**: การจัดการและสร้าง X.509 certificates
- **Demo**: สร้าง Root CA certificate (TTL: 10 ปี)

**ทดสอบ**:

```bash
# อ่าน KV secrets
vault kv get secret-recovery/production/database

# ดู PKI configuration
vault read pki/config/urls

# ดู root certificate
cat ca_cert.pem
```

#### Transform Secret Engine

- **Path**: `transform`
- **ใช้สำหรับ**: Format-preserving encryption (FPE)
- **Demo**: สร้าง role `payments` สำหรับเข้ารหัสหมายเลขบัตรเครดิต

**ทดสอบ** (ต้องใช้ Vault Enterprise):

```bash
# ทดสอบ encoding
vault write transform/encode/payments value=4532-1234-5678-9010

# ทดสอบ decoding
vault write transform/decode/payments value=<encoded-value>
```

### Scenario 3: Snapshot Recovery Workflow

**ปัญหา**: ต้องการทดสอบ disaster recovery workflow

**วิธีแก้**: สร้าง snapshot → ลบข้อมูล → Restore จาก snapshot

**ทดสอบ**:

```bash
# 1. สร้าง snapshot
./setup.sh

# 2. ตรวจสอบว่ามี secrets
vault kv get secret-recovery/production/database

# 3. ลบ secrets (จำลอง disaster)
./cleanup.sh

# 4. Restore จาก snapshot
vault operator raft snapshot restore vault-snapshot-*.snap

# 5. ตรวจสอบว่า secrets กลับมาแล้ว
vault kv get secret-recovery/production/database
```

## 🔐 Secret Engines

| Engine        | Path              | Version    | Use Case                     |
| ------------- | ----------------- | ---------- | ---------------------------- |
| **KV**        | `secret-recovery` | v1         | เก็บ application secrets     |
| **PKI**       | `pki`             | -          | จัดการ X.509 certificates    |
| **Transform** | `transform`       | Enterprise | Format-preserving encryption |

## 📸 Snapshot Operations

### สร้าง Snapshot

```bash
vault operator raft snapshot save ./vault-snapshot-$(date +%Y%m%d%H%M%S).snap
```

### ตรวจสอบ Snapshot

```bash
vault operator raft snapshot inspect vault-snapshot-*.snap
```

### กู้คืนจาก Snapshot

⚠️ **คำเตือน**: การ restore จะเขียนทับข้อมูลทั้งหมดใน Vault

```bash
# หยุด Vault server ก่อน (ถ้ากำลังทำงานอยู่)
vault operator raft snapshot restore vault-snapshot-*.snap
```

## 🧹 Cleanup

```bash
./cleanup.sh
```

ลบ secrets, PKI configuration, และ Transform engine configuration ทั้งหมด

⚠️ **คำเตือน**: การรัน cleanup จะลบ secrets ทั้งหมดอย่างถาวร ตรวจสอบให้แน่ใจว่าคุณมี snapshot ไว้สำหรับการกู้คืน

## 📝 หมายเหตุ

- ต้องใช้ **Vault Enterprise** สำหรับ Transform Secret Engine
- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรัน `setup.sh`
- Snapshot files จะถูก ignore โดย git (ดูใน `.gitignore`)
- Passwords และ credentials เป็นตัวอย่างเท่านั้น

## 🔗 ดูเพิ่มเติม

- [Vault KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv)
- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Vault Transform Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/transform)
- [Vault Snapshot Operations](https://developer.hashicorp.com/vault/docs/commands/operator/raft)
- [Vault Disaster Recovery](https://developer.hashicorp.com/vault/docs/operations/disaster-recovery)
