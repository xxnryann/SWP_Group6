package com.cinema.util;

/**
 * Tiện ích cho điều hướng dashboard dựa trên vai trò người dùng.
 */
public final class RoleDashboard {
    
    private RoleDashboard() {}
    
    /**
     * Lấy đường dẫn dashboard tương ứng với vai trò.
     * @param role vai trò (ADMIN, MANAGER, STAFF, CUSTOMER)
     * @return đường dẫn dashboard, mặc định /dashboard/customer nếu không xác định
     */
    public static String pathFor(String role) {
        if (role == null) {
            return "/dashboard/customer";
        }
        
        switch (role.toUpperCase()) {
            case "ADMIN":
                return "/dashboard/admin";
            case "MANAGER":
                return "/dashboard/manager";
            case "STAFF":
                return "/dashboard/staff";
            case "CUSTOMER":
            default:
                return "/dashboard/customer";
        }
    }
    
    /**
     * Kiểm tra xem một đường dẫn có được phép cho vai trò hay không.
     * @param role vai trò
     * @param path đường dẫn cần kiểm tra
     * @return true nếu đường dẫn hợp lệ cho vai trò, false nếu cần điều hướng lại
     */
    public static boolean isAllowedForRole(String role, String path) {
        if (path == null || path.isEmpty()) {
            return false;
        }
        
        // Các trang account được phép cho tất cả người dùng đã đăng nhập
        if (path.startsWith("/account/")) {
            return true;
        }
        
        // Kiểm tra xem path có phải dashboard không
        if (path.startsWith("/dashboard/")) {
            // Admin, Manager, Staff chỉ được truy cập dashboard của họ
            if (role != null) {
                String dashboardPath = pathFor(role);
                // Cho phép truy cập dashboard của mình
                if (path.equals(dashboardPath)) {
                    return true;
                }
                // Admin có thể truy cập tất cả dashboard
                if ("ADMIN".equalsIgnoreCase(role)) {
                    return path.startsWith("/dashboard/");
                }
            }
            return false;
        }
        
        // Các trang khác không phải account cũng được phép (home, showtimes, v.v.)
        return !path.startsWith("/dashboard/");
    }
}
