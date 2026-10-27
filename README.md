# CinemaWeb – Account module

Register (Guest) · Verify OTP · Login · Manage Personal Account (Customer).
Stack: Servlet 6 / JSP + JSTL, Tomcat 10.1.x, SQL Server, BCrypt.

## Run
1. Clone the repository and create your local `src/java/app.properties` from `src/java/app.properties.example`. Do not use another developer's file.
2. Only run `sql/new.sql` on a new, empty database named `CinemaDB`. If `CinemaDB` already exists, drop it and create an empty database, or skip the `CREATE DATABASE` command at the start of the script because its MDF/LDF paths may not match your machine. **Do not run any other old SQL files afterward.**
3. Ensure SQL Server TCP/IP is enabled on port 1433, SQL Server Authentication is enabled, and the account in `app.properties` is enabled.
4. Verify login with these seeded accounts (password `123456`): `admin@cinema.vn`, `manager@cinema.vn`, `staff@cinema.vn`, `khach1@gmail.com`, `khach2@gmail.com`.
5. Run the project on Tomcat 10.1 (NetBeans 17 or IntelliJ IDEA with Smart Tomcat). In IntelliJ, the module output directory must be `web/WEB-INF/classes` so Tomcat can load the servlet classes; use context path `/CinemaWeb`.
   - Leave `mail.host` empty to print the OTP in the Tomcat log (dev mode).
6. Open `http://localhost:8080/CinemaWeb/`.

If login fails, check the Tomcat log: `Login failed for user 'sa'` means the password in `app.properties` is wrong; `Invalid object name` means the database was not fully created; a normal “sai thông tin” page with the seeded accounts means the database contains different accounts, so recreate it and run `new.sql`.

The committed `app.properties` previously contained a machine-specific password and has been removed from version control, but that password remains in Git history. Rotate it with the password owner; rewriting history requires agreement from the whole team.

## URLs
| URL | Who | Purpose |
|---|---|---|
| /register | Guest | create account (PENDING) + email OTP |
| /verify-otp | Guest | verify OTP → ACTIVE, resend (60s cooldown) |
| /login, /logout | all | sign in by email or phone |
| /account/profile | Customer | view/edit name, phone, DOB, gender |
| /account/password | Customer | change password |
