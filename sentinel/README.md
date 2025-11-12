# 🛡️ Sentinel Demo

สาธิตการใช้งาน HashiCorp Vault พร้อม Sentinel policies สำหรับการควบคุมการเข้าถึง secrets ตามบทบาทและสิทธิ์ของผู้ใช้

## 📋 ภาพรวม

โปรเจกต์นี้สร้าง:

- **3 Users** พร้อมบทบาทที่แตกต่างกัน
- **3 Vault Policies** สำหรับแต่ละบทบาท
- **Demo Secrets** ในหลาย environments
- **Identity Entities** พร้อม metadata สำหรับการควบคุมแบบละเอียด
- **3 Sentinel Policies** (2 EGP + 1 RGP) สำหรับการควบคุมการเข้าถึงแบบละเอียด

## 🚀 การใช้งาน

### Quick Start

รันสคริปต์เดียวเพื่อ setup ทุกอย่าง:

```bash
./setup.sh
```

สคริปต์นี้จะทำการ:

1. ✅ สร้าง Vault ACL policies (junior-dev, senior-dev, security-admin)
2. ✅ สร้าง users ภายใต้ `auth/userpass` (alice, bob, charlie)
3. ✅ สร้าง Identity entities พร้อม metadata
4. ✅ Enable KV v2 secrets engine และสร้าง demo secrets
5. ✅ Apply Sentinel EGP และ RGP policies

### ตรวจสอบการติดตั้ง

หลังจากรัน `setup.sh` แล้ว คุณสามารถตรวจสอบได้ว่า:

```bash
# ตรวจสอบ policies
vault policy list

# ตรวจสอบ users
vault list auth/userpass/users

# ตรวจสอบ secrets
vault kv list secret/

# ตรวจสอบ Sentinel policies
vault list sys/policies/egp
vault list sys/policies/rgp
```

## 👥 Users และบทบาท

### 👩‍💻 Alice - Junior Developer

- **Username**: `alice`
- **Password**: `alice123`
- **Policy**: `junior-dev`
- **สิทธิ์**:
  - อ่าน secrets ใน `development` และ `staging` environments
  - อ่าน `production` secrets (แต่ต้องผ่าน Sentinel policy `production-hours`)
- **Identity Metadata**:
  - `role`: Junior Developer

### 👨‍💻 Bob - Senior Developer

- **Username**: `bob`
- **Password**: `bob123`
- **Policy**: `senior-dev`
- **สิทธิ์**:
  - อ่านและ list secrets ในทุก environments
  - ดู metadata ของ secrets
- **Identity Metadata**:
  - `role`: Senior Developer

### 👨‍🔒 Charlie - Security Admin

- **Username**: `charlie`
- **Password**: `charlie123`
- **Policy**: `security-admin`
- **สิทธิ์**:
  - Full access ถึงทุก secrets (create, read, update, delete, list)
  - จัดการ Sentinel policies (EGP และ RGP)
- **Identity Metadata**:
  - `role`: Security Admin
  - `name`: Charlie Chan

## 🔐 Demo Secrets

โปรเจกต์นี้สร้าง secrets ต่อไปนี้:

- `secret/development/database` - Database credentials สำหรับ development
- `secret/staging/database` - Database credentials สำหรับ staging
- `secret/production/database` - Database credentials สำหรับ production
- `secret/production/payment-gateway` - Payment gateway credentials
- `secret/thai-customers/user-123` - Customer PII data (GDPR protected)

## 🛡️ Sentinel Policies

### EGP Policies (Endpoint Governing Policies)

#### 1. `production-hours.sentinel`

**Path**: `secret/data/production/*`  
**Enforcement**: `hard-mandatory`

จำกัดการเข้าถึง production secrets โดย:

- ✅ อนุญาตเฉพาะ **เวลาทำการ** (9 AM - 6 PM UTC+7, วันจันทร์-ศุกร์)
- ✅ อนุญาตเฉพาะ **Senior Developers** (`role == "Senior Developer"`)

**Logic**:

- ตรวจสอบว่าเป็นวันทำงาน (Monday-Friday, weekday 1-5)
- ตรวจสอบว่าเป็นเวลาทำการ (UTC+7 = UTC hour 2-11)
- ตรวจสอบ role จาก entity metadata

#### 2. `gdpr-residency.sentinel`

**Path**: `secret/data/thai-customers/*`  
**Enforcement**: `hard-mandatory`

จำกัดการเข้าถึงข้อมูลลูกค้าไทยตาม IP address:

- ✅ อนุญาตเฉพาะ IP address ที่อยู่ใน CIDR `129.41.56.7/32`
- ใช้สำหรับการควบคุม GDPR residency requirements

**Logic**:

- ตรวจสอบ `request.connection.remote_addr` ว่าอยู่ใน CIDR ที่อนุญาต
- ใช้ `sockaddr` import สำหรับการตรวจสอบ CIDR

### RGP Policies (Role Governing Policies)

#### 3. `admin-policy.sentinel`

**Path**: `sys/policies/acl/security-admin`  
**Enforcement**: `soft-mandatory`

ควบคุมการจัดการ security-admin policy:

- ✅ อนุญาตเฉพาะ Security Admin (`role == "Security Admin"`)
- ✅ หรือ entity name เป็น "Charlie Chan"

**Logic**:

- ตรวจสอบ entity metadata หรือ entity name
- ใช้สำหรับ policy governance

## 🔍 การทดสอบ

### Login เป็น Alice (Junior Developer)

```bash
vault login -method=userpass username=alice password=alice123
```

ทดสอบการเข้าถึง:

```bash
# ✅ ควรทำงานได้
vault kv get secret/development/database
vault kv get secret/staging/database

# ⚠️ ต้องผ่าน Sentinel policy (production-hours)
# จะผ่านได้เฉพาะเวลาทำการ หรือเป็น Senior Developer
# Alice เป็น Junior Developer ดังนั้นจะผ่านได้เฉพาะเวลาทำการ
vault kv get secret/production/database

# ❌ ไม่สามารถเข้าถึงได้ (ไม่มีสิทธิ์ใน policy)
vault kv get secret/production/payment-gateway
vault kv get secret/thai-customers/user-123
```

### Login เป็น Bob (Senior Developer)

```bash
vault login -method=userpass username=bob password=bob123
```

ทดสอบการเข้าถึง:

```bash
# ✅ ควรเข้าถึงได้ทุกอย่าง (ถ้าผ่าน Sentinel policies)
vault kv get secret/development/database
vault kv get secret/staging/database

# ✅ เข้าถึงได้เฉพาะเวลาทำการ (9 AM - 6 PM UTC+7, Mon-Fri)
vault kv get secret/production/database
vault kv get secret/production/payment-gateway

# ⚠️ ต้องผ่าน Sentinel policy (gdpr-residency)
# จะผ่านได้เฉพาะ IP address ที่อนุญาต
vault kv get secret/thai-customers/user-123
```

### Login เป็น Charlie (Security Admin)

```bash
vault login -method=userpass username=charlie password=charlie123
```

ทดสอบการเข้าถึง:

```bash
# ✅ Full access
vault kv get secret/development/database
vault kv put secret/test/new-secret key=value
vault kv delete secret/test/new-secret

# ✅ จัดการ Sentinel policies
vault list sys/policies/egp
vault list sys/policies/rgp
vault read sys/policies/egp/production-hours
```

## 📄 Policy Files

### Vault ACL Policies

สคริปต์ `setup.sh` สร้าง policies ต่อไปนี้:

#### `junior-dev`

```hcl
path "secret/data/development/*" {
  capabilities = ["read", "list"]
}
path "secret/data/staging/*" {
  capabilities = ["read", "list"]
}
path "secret/data/production/*" {
  capabilities = ["read"]
}
```

#### `senior-dev`

```hcl
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list"]
}
```

#### `security-admin`

```hcl
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/policies/egp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/policies/rgp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

### Sentinel Policies

#### `production-hours.sentinel`

- จำกัดการเข้าถึง production secrets เฉพาะเวลาทำการ (9 AM - 6 PM UTC+7)
- อนุญาตเฉพาะ senior engineers (`role == "Senior Developer"`)
- ใช้กับ path: `secret/data/production/*`

#### `gdpr-residency.sentinel`

- จำกัดการเข้าถึงข้อมูลลูกค้าไทยตาม IP address
- ตรวจสอบว่า IP address อยู่ใน CIDR ที่อนุญาต (`129.41.56.7/32`)
- ใช้กับ path: `secret/data/thai-customers/*`

#### `admin-policy.sentinel`

- ควบคุมการจัดการ security-admin policy
- ตรวจสอบ entity role หรือ name
- ใช้กับ path: `sys/policies/acl/security-admin`

## 🧪 Testing Sentinel Policies

โปรเจกต์นี้รวม test cases สำหรับ Sentinel policies ในโฟลเดอร์ `test/`:

- `test/production-hours/` - Test cases สำหรับ production-hours policy
  - `success.hcl` - Test case ที่ควรผ่าน
  - `fail.hcl` - Test case ที่ควรล้มเหลว
- `test/gdpr-residency/` - Test cases สำหรับ gdpr-residency policy
  - `success.hcl` - Test case ที่ควรผ่าน
  - `fail.hcl` - Test case ที่ควรล้มเหลว
  - `mock-sockaddr.sentinel` - Mock สำหรับ sockaddr import
- `test/admin-policy/` - Test cases สำหรับ admin-policy
  - `success.hcl` - Test case ที่ควรผ่าน
  - `fail.hcl` - Test case ที่ควรล้มเหลว

### รัน Tests

```bash
# ตัวอย่าง: ทดสอบ production-hours policy
sentinel test production-hours.sentinel

# ทดสอบทุก policies
sentinel test *.sentinel
```

## 🔐 Identity Entities

โปรเจกต์นี้ใช้ Vault Identity เพื่อ:

- เชื่อมโยง users กับ policies
- เก็บ metadata สำหรับการควบคุมแบบละเอียด
- รองรับการใช้งาน Sentinel policies ที่ตรวจสอบ metadata

Identity entities ถูกสร้างพร้อมกับ users และเชื่อมโยงผ่าน entity aliases

## 📝 หมายเหตุ

- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรันสคริปต์
- **สำหรับ Sentinel policies ที่แท้จริง ต้องใช้ Vault Enterprise**
- Sentinel policies จะถูก apply เป็น EGP (Endpoint Governing Policies) และ RGP (Role Governing Policies)
- Passwords เป็นตัวอย่างเท่านั้น ควรเปลี่ยนใน production
- IP address ใน `gdpr-residency.sentinel` เป็นตัวอย่าง ควรปรับตามความต้องการจริง

## 🔗 ดูเพิ่มเติม

- [Vault Policies Documentation](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Identity](https://developer.hashicorp.com/vault/docs/concepts/identity)
- [Sentinel Policies](https://developer.hashicorp.com/vault/docs/enterprise/sentinel)
- [Sentinel Language Documentation](https://docs.hashicorp.com/sentinel)
