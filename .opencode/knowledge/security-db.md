# 🔒 Security Knowledge Base

> ฐานความรู้ด้านความปลอดภัยสำหรับโปรเจกต์นี้
> อัปเดตโดย Security Researcher Agent ทุกครั้งที่มีการใช้เทคโนโลยีใหม่

---

## 📅 ประวัติการอัปเดต

| วันที่ | เวอร์ชัน | หมายเหตุ |
|--------|---------|----------|
| 2026-05-18 | 1.0.0 | เริ่มต้นสร้างฐานความรู้ |

---

## 🚨 CVEs ล่าสุดที่เกี่ยวข้อง

*(รอการค้นคว้าจาก Security Researcher Agent)*

---

## ⚠️ ช่องโหว่ที่ต้องระวัง

### General Security Best Practices

1. **SQL Injection**
   - ใช้ Parameterized Queries หรือ ORM
   - หลีกเลี่ยงการต่อ String โดยตรงกับ SQL

2. **XSS (Cross-Site Scripting)**
   - Sanitize user input
   - ใช้ Content Security Policy (CSP)

3. **CSRF (Cross-Site Request Forgery)**
   - ใช้ CSRF Tokens
   - ตรวจสอบ Origin header

4. **Authentication & Session Management**
   - เก็บรหัสผ่านด้วย Argon2 หรือ bcrypt
   - ใช้ HTTPS เสมอ
   - กำหนด Session Timeout

5. **Secrets Management**
   - ไม่เก็บ Secrets ในโค้ด
   - ใช้ Environment Variables หรือ Secret Manager

---

## 🛡️ แนวทางป้องกันตามเทคโนโลยี

### Node.js / Express
- ใช้ `helmet` สำหรับ HTTP headers
- ใช้ `express-rate-limit` ป้องกัน Brute Force
- ตรวจสอบ Input ด้วย `joi` หรือ `zod`

### React
- ใช้ DOMPurify สำหรับ sanitization
- หลีกเลี่ยง `dangerouslySetInnerHTML`
- ใช้ CSRF tokens สำหรับ forms

### Database
- ใช้ Prepared Statements
- จำกัดสิทธิ์ของ Database User
- เปิด Encryption at Rest

---

## 📋 Secure Coding Checklist

- [ ] Input Validation
- [ ] Output Encoding
- [ ] Authentication
- [ ] Authorization
- [ ] Session Management
- [ ] Password Storage
- [ ] File Upload Security
- [ ] HTTPS Only
- [ ] Security Headers
- [ ] Logging & Monitoring
- [ ] Error Handling (ไม่เปิดเผยข้อมูลภายใน)

---

## 📚 แหล่งอ้างอิง

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CVE Database](https://cve.mitre.org/)
- [NIST National Vulnerability Database](https://nvd.nist.gov/)

---

*ไฟล์นี้อัปเดตโดยอัตโนมัติโดย Security Researcher Agent*
