# CinemaWeb – Account module

Register (Guest) · Verify OTP · Login · Manage Personal Account (Customer).
Stack: Servlet 6 / JSP + JSTL, Tomcat 10.1.x, SQL Server, BCrypt.

## Run
1. Run `sql/schema.sql` in SQL Server.
2. Edit `src/java/app.properties` (db.user / db.password; mail.* optional).
3. Run the project on Tomcat 10.1 (NetBeans 17 or IntelliJ IDEA with Smart Tomcat). In IntelliJ, the module output directory must be `web/WEB-INF/classes` so Tomcat can load the servlet classes; use context path `/CinemaWeb`.
   - Leave `mail.host` empty to print the OTP in the Tomcat log (dev mode).
4. Open `http://localhost:8080/CinemaWeb/`.

## URLs
| URL | Who | Purpose |
|---|---|---|
| /register | Guest | create account (PENDING) + email OTP |
| /verify-otp | Guest | verify OTP → ACTIVE, resend (60s cooldown) |
| /login, /logout | all | sign in by email or phone |
| /account/profile | Customer | view/edit name, phone, DOB, gender |
| /account/password | Customer | change password |
