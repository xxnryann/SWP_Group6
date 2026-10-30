# Ghi chu cho AI Code

Agent doc file nay TRUOC moi luot. Viet vao day nhung thu no khong the tu doan
ra tu ma — moi dong o day tiet kiem cho ban hang chuc buoc mo mam.

Ma nguon nam trong thu muc con `SWP_Group6-feature-dev-work/` (Java 17, JSP/Servlet Jakarta 6, Tomcat 10.1, SQL Server `CinemaWebDB`).

## Chay du an

Chay trong `SWP_Group6-feature-dev-work/` (PowerShell):
- Build:  `powershell -ExecutionPolicy Bypass -File scripts\build.ps1`
- Deploy: `powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -TomcatHome "<thu muc Tomcat 10.1>" -Context <ten-context>`
- Tao DB: `$env:SQLCMDPASSWORD='<mat khau>'; sqlcmd -S localhost,1433 -U sa -f 65001 -i sql\new.sql` (DROP + tao lai toan bo `CinemaWebDB`)
- Doi chieu / cap nhat stored procedure voi `sql/new.sql`: `scripts\compare-procedures.ps1` (them `-Sync` de tao lai)
- Cau hinh: sao chep `src/java/app.properties.example` -> `src/java/app.properties` (file nay bi .gitignore, KHONG commit)

## Test (HTTP end-to-end, khong co unit test)

```
scripts\test-smoke.ps1                  # nhanh, chi doc
scripts\test-booking-flow.ps1           # GHI du lieu vao CSDL
scripts\test-booking-errors.ps1         # GHI du lieu vao CSDL
scripts\test-admin-manager-staff.ps1    # GHI du lieu, tu don phan ZZTEST
```
Bien moi truong dung chung (xem `scripts/lib/test-config.ps1`): `CINEMA_BASE_URL` (khong dat thi tu thu
`http://localhost:9999/CinemaTest` roi `http://localhost:8080/CinemaWeb`), `CINEMA_TEST_PASSWORD`,
`CINEMA_DB_WINAUTH=1` hoac `CINEMA_DB_USER` / `CINEMA_DB_PASSWORD`.
Cac bai test booking/admin ghi vao CSDL dang dung — chay tren CSDL rieng cho kiem thu, khong chay tren du lieu demo.

## Bay da gap

- `sqlcmd` can co `-I` (QUOTED_IDENTIFIER) khi chay script dung filtered index / computed column, va `-f 65001` khi nap file co tieng Viet.
- Sau khi deploy ma 500 hang loat: xoa `work\Catalina\localhost\<context>` roi `touch WEB-INF\web.xml`.
- CSS cu do cache trinh duyet: Ctrl+Shift+R.
- PowerShell 5.1: file `.ps1` co tieng Viet phai co BOM UTF-8 (`scripts\ensure-utf8-bom.ps1`). Khong co `-Form`, khong dung `&&`.
- Hoan tien chi ghi o dong Payment goc (`refunded_amount` cong don). KHONG them dong Payment moi cho lan hoan.
- Mat khau SQL khong duoc dua qua `-P` tren dong lenh; dung `SQLCMDPASSWORD` (helper `Get-SqlCmdAuth`).

## Quy uoc

- Khong tu chay git commit/push — nguoi dung se yeu cau ("commit len").
- `src/java/app.properties` chua bi mat, khong commit; chi sua `app.properties.example` khi them khoa cau hinh moi.
- Luu log bang `java.util.logging` (khong dung `System.err.println`).
- Sau khi sua `sql/new.sql` can them file `sql/migrate_*.sql` idempotent cho DB da co du lieu.
