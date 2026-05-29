# คู่มือการใช้งาน PostgreSQL บน Docker

## 📋 สารบัญ
1. [เริ่มต้นใช้งาน](#เริ่มต้นใช้งาน)
2. [การจัดการ Container](#การจัดการ-container)
3. [การเชื่อมต่อ Database](#การเชื่อมต่อ-database)
4. [คำสั่ง PostgreSQL พื้นฐาน](#คำสั่ง-postgresql-พื้นฐาน)
5. [Backup & Restore](#backup--restore)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## 🚀 เริ่มต้นใช้งาน

### ตรวจสอบ docker-compose.yml
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: premium_postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: t462825*
      POSTGRES_DB: pos_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

volumes:
  postgres_data:
```

### เริ่มต้น Container
```powershell
# ขึ้น container
docker compose up -d

# ตรวจสอบสถานะ
docker compose ps
```

---

## 🐳 การจัดการ Container

### ดูสถานะ
```powershell
# ดู container ที่รันอยู่
docker compose ps

# ดู logs แบบ real-time
docker compose logs -f postgres

# ดู logs ของบางจำนวนบรรทัดเท่านั้น
docker compose logs --tail 50 postgres
```

### เริ่มและหยุด
```powershell
# หยุด container
docker compose down

# เริ่มต้น container ใหม่
docker compose up -d

# Restart container
docker compose restart postgres

# ลบ container และ volume ทั้งหมด (⚠️ ลบข้อมูลด้วย!)
docker compose down -v
```

---

## 🔌 การเชื่อมต่อ Database

### Connection String
```
postgresql://admin:t462825*@localhost:5432/pos_db
```

### เข้า PostgreSQL Shell
```powershell
# วิธีที่ 1: ผ่าน Docker Exec
docker exec -it premium_postgres psql -U admin -d pos_db

# วิธีที่ 2: ผ่าน bash แล้วรัน psql
docker exec -it premium_postgres bash
# แล้วในนั้น: psql -U admin -d pos_db
```

### เชื่อมต่อจาก Tools ภายนอก
**DBeaver / pgAdmin / VS Code Database Extensions:**
- Host: `localhost`
- Port: `5432`
- Username: `admin`
- Password: `t462825*`
- Database: `pos_db`

---

## 📊 คำสั่ง PostgreSQL พื้นฐาน

### ดู Databases ทั้งหมด
```sql
\l
```

### สลับ Database
```sql
\c database_name
```

### ดู Tables ทั้งหมด
```sql
\dt
```

### ดู Columns ของ Table
```sql
\d table_name
```

### สร้าง Table ใหม่
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Insert ข้อมูล
```sql
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');
```

### Query ข้อมูล
```sql
SELECT * FROM users;
SELECT name, email FROM users WHERE id = 1;
```

### Update ข้อมูล
```sql
UPDATE users SET name = 'Jane Doe' WHERE id = 1;
```

### Delete ข้อมูล
```sql
DELETE FROM users WHERE id = 1;
```

### ออกจาก psql
```
\q
```

---

## 💾 Backup & Restore

### Backup Database (เป็น SQL file)
```powershell
# Backup ทั้ง database
docker exec premium_postgres pg_dump -U admin pos_db > backup_pos_db.sql

# Backup เป็น binary format (เร็วกว่า)
docker exec premium_postgres pg_dump -U admin -Fc pos_db > backup_pos_db.dump
```

### Restore Database
```powershell
# Restore จาก SQL file
docker exec -i premium_postgres psql -U admin pos_db < backup_pos_db.sql

# Restore จาก binary format
docker exec -i premium_postgres pg_restore -U admin -d pos_db < backup_pos_db.dump
```

### Backup ทั้ง Server
```powershell
docker exec premium_postgres pg_dumpall -U admin > full_backup.sql
```

---

## 🔧 Troubleshooting

### 1. Connection refused
**ปัญหา:** ไม่สามารถเชื่อมต่อได้
```powershell
# ตรวจสอบ container รันอยู่หรือไม่
docker compose ps

# ดู logs
docker compose logs postgres

# Restart container
docker compose restart postgres
```

### 2. Port already in use
**ปัญหา:** Port 5432 ถูกใช้งานแล้ว
```powershell
# วิธี 1: เปลี่ยน port ใน docker-compose.yml
# ports:
#   - "5433:5432"  # ใช้ 5433 แทน

# วิธี 2: หาว่า process ไหนใช้ port 5432
netstat -ano | findstr :5432
# แล้วลบ process นั้นออก
```

### 3. Password authentication failed
**ปัญหา:** ใส่ password ผิด
```powershell
# ตรวจสอบ docker-compose.yml ว่า password ตรงกับที่ใช้หรือไม่

# หรือเขา container ไปตรวจสอบ environment variables
docker exec premium_postgres env | grep POSTGRES
```

### 4. Container exit immediately
**ปัญหา:** Container หยุดทำงานเหมือนเดิม
```powershell
# ดู error messages
docker compose logs postgres

# ลองสร้าง container ใหม่
docker compose down
docker compose up -d
```

### 5. ลบ Container ที่ติด
```powershell
# Force remove
docker rm -f premium_postgres
docker volume rm tommii-opencode-new-core_postgres_data
```

---

## ✅ Best Practices

### 1. 🔐 ความปลอดภัย Password
**อย่าทำ:**
```yaml
POSTGRES_PASSWORD: t462825*  # เห็นในไฟล์โดยตรง
```

**ทำแบบนี้แทน:**
```yaml
# docker-compose.yml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

```env
# .env (เพิ่มลงใน .gitignore)
POSTGRES_PASSWORD=t462825*
```

### 2. 💾 ทำ Backup อย่างสม่ำเสมอ
```powershell
# สร้าง script backup อัตโนมัติ
# backup.bat (Windows)
@echo off
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
docker exec premium_postgres pg_dump -U admin pos_db > backup_%mydate%.sql
```

### 3. 📝 ตั้งค่า Environment Variables ที่ปลอดภัย
```yaml
environment:
  POSTGRES_USER: ${POSTGRES_USER:-admin}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  POSTGRES_DB: ${POSTGRES_DB:-pos_db}
```

### 4. 🗂️ จัดระเบียบ Volume
```yaml
volumes:
  postgres_data:
    driver: local
```

### 5. 🚨 ใช้ Health Check
```yaml
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U admin"]
    interval: 10s
    timeout: 5s
    retries: 5
```

### 6. 📊 ตั้งค่า Resource Limits
```yaml
postgres:
  resources:
    limits:
      cpus: '1'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

---

## 📞 ติดต่อสำหรับปัญหา

หากมีปัญหาหรือข้อสงสัย:
1. ตรวจสอบ logs: `docker compose logs postgres`
2. ตรวจสอบ connection settings
3. ลอง restart container

---

**สร้างเมื่อ:** 2026-05-29  
**Version:** PostgreSQL 16 Alpine
