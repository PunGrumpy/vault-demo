# 🔐 Vault Demo

โปรเจกต์สาธิตการใช้ HashiCorp Vault พร้อม Sentinel policies สำหรับการจัดการ secrets และการควบคุมการเข้าถึงตามบทบาท (Role-Based Access Control)

## 📋 ข้อกำหนดเบื้องต้น (Prerequisites)

- [HashiCorp Vault](https://www.vaultproject.io/downloads) ติดตั้งและรันอยู่
- `vault` CLI ติดตั้งและตั้งค่าแล้ว
- Vault CLI เชื่อมต่อกับ Vault server แล้ว (`vault status` ควรทำงานได้)
- `jq` (สำหรับ JSON parsing) - ติดตั้งด้วย `brew install jq` หรือ `apt-get install jq`

## 🚀 การติดตั้ง (Installation)

### 1. สร้างไฟล์ `.env`

สคริปต์นี้จะสร้างไฟล์ `.env` จากไฟล์ `.env.example` โดยจะถามค่าสำหรับแต่ละตัวแปรแวดล้อม

```bash
./scripts/init.sh
```

### 2. Export ตัวแปรแวดล้อม

#### สำหรับ Fish Shell

```bash
source scripts/export.fish
```

#### สำหรับ Bash/Zsh

```bash
source scripts/export.sh
```

## 📁 โครงสร้างโปรเจกต์

```
vault-demo/
├── README.md                 # ไฟล์นี้
├── scripts/
│   ├── init.sh              # สคริปต์สร้าง .env file
│   ├── export.sh            # Export env vars สำหรับ Bash
│   ├── export.fish          # Export env vars สำหรับ Fish
│   └── log.sh               # ฟังก์ชัน logging utilities
└── sentinel/
    ├── README.md            # คู่มือ Sentinel demo
    ├── roles.sh             # สร้าง users และ roles
    ├── policies.sh          # สร้าง Vault policies
    ├── secrets.sh           # สร้าง demo secrets
    ├── apply-sentinel-policies.sh  # Apply Sentinel EGP และ RGP policies
    ├── production-hours.sentinel   # Sentinel policy สำหรับ production hours
    ├── gdpr-residency.sentinel     # Sentinel policy สำหรับ GDPR residency
    ├── transaction-limit.sentinel  # Sentinel policy สำหรับ transaction limit
    ├── policy/
    │   ├── junior-dev-policy.hcl
    │   ├── senior-dev-policy.hcl
    │   └── security-admin-policy.hcl
    └── test/                # Test cases สำหรับ Sentinel policies
        ├── production-hours/
        ├── transaction-limit/
        └── gdpr-residency/
```

## 🎯 การใช้งาน

### 1. สร้าง Vault Policies

สร้าง Vault policies สำหรับแต่ละบทบาท:

```bash
cd sentinel
./policies.sh
```

### 2. สร้าง Users และ Roles

สร้าง users พร้อม identity entities:

```bash
cd sentinel
./roles.sh
```

### 3. สร้าง Demo Secrets

สร้าง secrets สำหรับทดสอบ:

```bash
cd sentinel
./secrets.sh
```

### 4. Apply Sentinel Policies

Apply Sentinel EGP (Endpoint Governing Policies) และ RGP (Role Governing Policies):

```bash
cd sentinel
./apply-sentinel-policies.sh
```

**หมายเหตุ**: ต้องรันตามลำดับข้างต้น (policies → roles → secrets → sentinel policies)

ดูรายละเอียดเพิ่มเติมใน [sentinel/README.md](./sentinel/README.md)

## 👥 ตัวอย่าง Users

โปรเจกต์นี้สร้าง 3 users พร้อมบทบาทที่แตกต่างกัน:

1. **alice** (Junior Developer)

   - Password: `alice123`
   - Policy: `junior-dev`
   - เข้าถึงได้: `dev/staging` environments เท่านั้น

2. **bob** (Senior Developer)

   - Password: `bob123`
   - Policy: `senior-dev`
   - เข้าถึงได้: ทุก environments

3. **charlie** (Security Admin)
   - Password: `charlie123`
   - Policy: `security-admin`
   - เข้าถึงได้: ทุกอย่าง รวมถึงการจัดการ Sentinel policies

## 🔑 การทดสอบการเข้าถึง

### Login เป็น user

```bash
vault login -method=userpass username=alice password=alice123
```

### อ่าน secret

```bash
vault kv get secret/development/database
vault kv get secret/staging/database
vault kv get secret/production/database  # alice เข้าถึงได้ เฉพาะ production hours เท่านั้น และต้องผ่าน Sentinel policy
```

## 🛡️ Sentinel Policies

โปรเจกต์นี้รวม Sentinel policies ต่อไปนี้:

1. **production-hours.sentinel** - จำกัดการเข้าถึง production secrets เฉพาะเวลาทำการ (9 AM - 6 PM UTC+7) และเฉพาะ senior engineers
2. **gdpr-residency.sentinel** - จำกัดการเข้าถึงข้อมูลลูกค้าไทย (thai-customers) เฉพาะ IP address ที่อนุญาต
3. **transaction-limit.sentinel** - จำกัดจำนวนเงินในการทำธุรกรรมตาม metadata ของ user

ดูรายละเอียดเพิ่มเติมใน [sentinel/README.md](./sentinel/README.md)

## 📚 เอกสารเพิ่มเติม

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Sentinel Policies](https://developer.hashicorp.com/vault/docs/enterprise/sentinel)
- [Vault Policies](https://developer.hashicorp.com/vault/docs/concepts/policies)

## ⚠️ หมายเหตุ

- โปรเจกต์นี้เป็น demo เท่านั้น ไม่ควรใช้ใน production
- Passwords ที่ใช้เป็นตัวอย่างเท่านั้น ควรเปลี่ยนใน production
- ตรวจสอบให้แน่ใจว่า Vault server ทำงานอยู่ก่อนรันสคริปต์
