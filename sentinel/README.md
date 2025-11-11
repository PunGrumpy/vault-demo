# 🛡️ Sentinel Demo

สาธิตการใช้งาน HashiCorp Vault พร้อม Sentinel policies สำหรับการควบคุมการเข้าถึง secrets ตามบทบาทและสิทธิ์ของผู้ใช้

## 📋 ภาพรวม

โปรเจกต์นี้สร้าง:

- **3 Users** พร้อมบทบาทที่แตกต่างกัน
- **3 Vault Policies** สำหรับแต่ละบทบาท
- **Demo Secrets** ในหลาย environments
- **Identity Entities** พร้อม metadata สำหรับการควบคุมแบบละเอียด

## 🚀 การใช้งาน

**สำคัญ**: ต้องรันสคริปต์ตามลำดับต่อไปนี้:

### 1. สร้าง Vault Policies

สร้าง Vault policies สำหรับแต่ละบทบาท:

```bash
./policies.sh
```

สคริปต์นี้จะสร้าง policies ต่อไปนี้:

- `junior-dev` - สำหรับ Junior Developer
- `senior-dev` - สำหรับ Senior Developer
- `security-admin` - สำหรับ Security Admin

### 2. สร้าง Users และ Roles

สร้าง users พร้อม identity entities:

```bash
./roles.sh
```

สคริปต์นี้จะสร้าง:

#### 👩‍💻 Alice - Junior Developer

- **Username**: `alice`
- **Password**: `alice123`
- **Policy**: `junior-dev`
- **สิทธิ์**:
  - อ่าน secrets ใน `development` และ `staging` environments
  - อ่าน `production` secrets (แต่ต้องผ่าน Sentinel policy)
- **Identity Metadata**:
  - `role`: junior-engineer
  - `department`: engineering
  - `clearance_level`: 1

#### 👨‍💻 Bob - Senior Developer

- **Username**: `bob`
- **Password**: `bob123`
- **Policy**: `senior-dev`
- **สิทธิ์**:
  - อ่าน secrets ในทุก environments
  - ดู metadata ของ secrets
- **Identity Metadata**:
  - `role`: senior-engineer
  - `department`: engineering
  - `clearance_level`: 3
  - `transaction_limit`: 10000

#### 👨‍🔒 Charlie - Security Admin

- **Username**: `charlie`
- **Password**: `charlie123`
- **Policy**: `security-admin`
- **สิทธิ์**:
  - Full access ถึงทุก secrets (create, read, update, delete, list)
  - จัดการ Sentinel policies

### 3. สร้าง Demo Secrets

สร้าง secrets สำหรับทดสอบ:

```bash
./secrets.sh
```

สคริปต์นี้จะ:

- Enable KV v2 secrets engine ที่ path `secret`
- สร้าง secrets ต่อไปนี้:
  - `secret/development/database` - Database credentials สำหรับ development
  - `secret/staging/database` - Database credentials สำหรับ staging
  - `secret/production/database` - Database credentials สำหรับ production
  - `secret/production/payment-gateway` - Payment gateway credentials
  - `secret/thai-customers/user-123` - Customer PII data

### 4. Apply Sentinel Policies

Apply Sentinel EGP (Endpoint Governing Policies) และ RGP (Role Governing Policies):

```bash
./apply-sentinel-policies.sh
```

สคริปต์นี้จะ apply policies ต่อไปนี้:

#### EGP Policies (Endpoint Governing Policies)

1. **gdpr-residency** - จำกัดการเข้าถึง `secret/data/thai-customers/*`
   - Enforcement: `hard-mandatory`
   - ตรวจสอบ IP address ของผู้ใช้

2. **production-hours** - จำกัดการเข้าถึง `secret/data/production/*`
   - Enforcement: `hard-mandatory`
   - จำกัดเฉพาะเวลาทำการ (9 AM - 6 PM UTC+7) และเฉพาะ senior engineers

3. **transaction-limit** - จำกัดการเข้าถึง `secret/data/production/payment/*`
   - Enforcement: `hard-mandatory`
   - ตรวจสอบ transaction limit จาก entity metadata

#### RGP Policies (Role Governing Policies)

1. **policy-governance** - ควบคุมการจัดการ policies
   - Enforcement: `soft-mandatory`

## 🔍 การทดสอบ

### Login เป็น Alice (Junior Developer)

```bash
vault auth -method=userpass username=alice password=alice123
```

ทดสอบการเข้าถึง:

```bash
# ✅ ควรทำงานได้
vault kv get secret/development/database
vault kv get secret/staging/database

# ⚠️ ต้องผ่าน Sentinel policy
vault kv get secret/production/database

# ❌ ไม่สามารถเข้าถึงได้
vault kv get secret/production/payment-gateway
```

### Login เป็น Bob (Senior Developer)

```bash
vault auth -method=userpass username=bob password=bob123
```

ทดสอบการเข้าถึง:

```bash
# ✅ ควรเข้าถึงได้ทุกอย่าง
vault kv get secret/development/database
vault kv get secret/staging/database
vault kv get secret/production/database
vault kv get secret/production/payment-gateway
```

### Login เป็น Charlie (Security Admin)

```bash
vault auth -method=userpass username=charlie password=charlie123
```

ทดสอบการเข้าถึง:

```bash
# ✅ Full access
vault kv get secret/development/database
vault kv put secret/test/new-secret key=value
vault kv delete secret/test/new-secret

# ✅ จัดการ Sentinel policies
vault list sys/policies/sentinel
```

## 📄 Policy Files

### Vault Policies (HCL)

#### `policy/junior-dev-policy.hcl`

- อ่าน secrets ใน `development` และ `staging`
- อ่าน `production` secrets (แต่ต้องผ่าน Sentinel)

#### `policy/senior-dev-policy.hcl`

- อ่านและ list secrets ในทุก environments
- ดู metadata ของ secrets

#### `policy/security-admin-policy.hcl`

- Full access ถึงทุก secrets
- จัดการ Sentinel policies (EGP และ RGP)

### Sentinel Policies

#### `production-hours.sentinel`

- จำกัดการเข้าถึง production secrets เฉพาะเวลาทำการ (9 AM - 6 PM UTC+7)
- อนุญาตเฉพาะ senior engineers (`role == "senior-engineer"`)
- ใช้กับ path: `secret/data/production/*`

#### `gdpr-residency.sentinel`

- จำกัดการเข้าถึงข้อมูลลูกค้าไทยตาม IP address
- ตรวจสอบว่า IP address อยู่ใน CIDR ที่อนุญาต
- ใช้กับ path: `secret/data/thai-customers/*`

#### `transaction-limit.sentinel`

- จำกัดจำนวนเงินในการทำธุรกรรม
- ตรวจสอบ `transaction_limit` จาก entity metadata
- เปรียบเทียบกับ `max_amount` ใน request data
- ใช้กับ path: `secret/data/production/payment-gateway`

## 🔐 Identity Entities

โปรเจกต์นี้ใช้ Vault Identity เพื่อ:

- เชื่อมโยง users กับ policies
- เก็บ metadata สำหรับการควบคุมแบบละเอียด
- รองรับการใช้งาน Sentinel policies ที่ตรวจสอบ metadata

## 🧪 Testing Sentinel Policies

โปรเจกต์นี้รวม test cases สำหรับ Sentinel policies ในโฟลเดอร์ `test/`:

- `test/production-hours/` - Test cases สำหรับ production-hours policy
- `test/transaction-limit/` - Test cases สำหรับ transaction-limit policy
- `test/gdpr-residency/` - Test cases สำหรับ gdpr-residency policy

แต่ละโฟลเดอร์มี:
- `success.hcl` - Test case ที่ควรผ่าน
- `fail.hcl` - Test case ที่ควรล้มเหลว
- Mock files (ถ้ามี) - สำหรับทดสอบ imports เช่น `mock-decimal.sentinel`, `mock-sockaddr.sentinel`

## 📝 หมายเหตุ

- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรันสคริปต์
- **ต้องรันตามลำดับ**: `policies.sh` → `roles.sh` → `secrets.sh` → `apply-sentinel-policies.sh`
- Passwords เป็นตัวอย่างเท่านั้น ควรเปลี่ยนใน production
- **สำหรับ Sentinel policies ที่แท้จริง ต้องใช้ Vault Enterprise**
- Sentinel policies จะถูก apply เป็น EGP (Endpoint Governing Policies) และ RGP (Role Governing Policies)

## 🔗 ดูเพิ่มเติม

- [Vault Policies Documentation](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Identity](https://developer.hashicorp.com/vault/docs/concepts/identity)
- [Sentinel Policies](https://developer.hashicorp.com/vault/docs/enterprise/sentinel)
