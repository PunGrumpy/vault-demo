> [!IMPORTANT]
> Please run [setup.sh](../setup.sh) to setup the environment. Before you run the [setup.sh](./setup.sh) for setup the demo environment!

# 🛡️ Sentinel Demo

สาธิตการใช้งาน HashiCorp Vault Sentinel policies สำหรับการควบคุมการเข้าถึง secrets แบบละเอียดตามบทบาท เวลา และที่ตั้ง

## 🚀 Quick Start

```bash
./setup.sh
```

สคริปต์จะสร้าง users, policies, secrets และ Sentinel policies ทั้งหมดให้อัตโนมัติ

## 📖 Demo Scenarios

### Scenario 1: Production Access Control

**ปัญหา**: ต้องการจำกัดการเข้าถึง production secrets เฉพาะเวลาทำการ หรือ senior engineers

**วิธีแก้**: ใช้ Sentinel EGP policy `production-hours`

- ✅ **Senior Developers** เข้าถึงได้ตลอดเวลา
- ✅ **Junior Developers** เข้าถึงได้เฉพาะเวลาทำการ (9 AM - 6 PM UTC+7, Mon-Fri)

**ทดสอบ**:

```bash
# Login เป็น Alice (Junior Developer)
vault login -method=userpass username=alice password=alice123

# ✅ เข้าถึงได้เฉพาะเวลาทำการ
vault kv get secret/production/database

# Login เป็น Bob (Senior Developer)
vault login -method=userpass username=bob password=bob123

# ✅ เข้าถึงได้ตลอดเวลา
vault kv get secret/production/database
```

### Scenario 2: GDPR Data Residency

**ปัญหา**: ข้อมูลลูกค้าไทยต้องเข้าถึงได้เฉพาะจาก IP address ที่อนุญาต (GDPR compliance)

**วิธีแก้**: ใช้ Sentinel EGP policy `gdpr-residency`

- ✅ ตรวจสอบ IP address จาก `request.connection.remote_addr`
- ✅ อนุญาตเฉพาะ IP ที่อยู่ใน CIDR `129.41.56.7/32`

**ทดสอบ**:

```bash
# Login เป็น Bob (Senior Developer)
vault login -method=userpass username=bob password=bob123

# ⚠️ จะผ่านได้เฉพาะ IP address ที่อนุญาต
vault kv get secret/thai-customers/user-123
```

### Scenario 3: Policy Governance

**ปัญหา**: ต้องการควบคุมการแก้ไข security-admin policy เฉพาะ Security Admin

**วิธีแก้**: ใช้ Sentinel RGP policy `admin-policy`

- ✅ อนุญาตเฉพาะ entity ที่มี `role == "Security Admin"` หรือ `name == "Charlie Chan"`

**ทดสอบ**:

```bash
# Login เป็น Charlie (Security Admin)
vault login -method=userpass username=charlie password=charlie123

# ✅ สามารถจัดการ policies ได้
vault policy read security-admin
vault list sys/policies/egp
```

## 👥 Users

| User        | Role             | Password     | สิทธิ์                                             |
| ----------- | ---------------- | ------------ | -------------------------------------------------- |
| **alice**   | Junior Developer | `alice123`   | อ่าน dev/staging, อ่าน production (เฉพาะเวลาทำการ) |
| **bob**     | Senior Developer | `bob123`     | อ่านทุก secrets (ต้องผ่าน Sentinel)                |
| **charlie** | Security Admin   | `charlie123` | Full access + จัดการ Sentinel policies             |

## 🔐 Secrets

- `secret/development/database` - Development DB credentials
- `secret/staging/database` - Staging DB credentials
- `secret/production/database` - Production DB credentials (protected by `production-hours`)
- `secret/production/payment-gateway` - Payment gateway (protected by `production-hours`)
- `secret/thai-customers/user-123` - Thai customer PII (protected by `gdpr-residency`)

## 🛡️ Sentinel Policies

### EGP (Endpoint Governing Policies)

#### `production-hours`

- **Path**: `secret/data/production/*`
- **Enforcement**: `hard-mandatory`
- **Logic**: อนุญาตเฉพาะเวลาทำการ (9 AM - 6 PM UTC+7, Mon-Fri) หรือ Senior Developers

#### `gdpr-residency`

- **Path**: `secret/data/thai-customers/*`
- **Enforcement**: `hard-mandatory`
- **Logic**: อนุญาตเฉพาะ IP address ที่อยู่ใน CIDR `129.41.56.7/32`

### RGP (Role Governing Policies)

#### `admin-policy`

- **Path**: `sys/policies/acl/security-admin`
- **Enforcement**: `soft-mandatory`
- **Logic**: อนุญาตเฉพาะ Security Admin (`role == "Security Admin"` หรือ `name == "Charlie Chan"`)

## 🧪 Testing

```bash
# ทดสอบ Sentinel policies
sentinel test
```

## 📝 หมายเหตุ

- ต้องใช้ **Vault Enterprise** สำหรับ Sentinel policies
- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรัน `setup.sh`
- Passwords และ IP addresses เป็นตัวอย่างเท่านั้น
