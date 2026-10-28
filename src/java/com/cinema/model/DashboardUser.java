package com.cinema.model;

/**
 * Model để hiển thị thông tin user trong dashboard.
 */
public class DashboardUser {
    private int userId;
    private String email;
    private String fullName;
    private String phone;
    private String role;
    
    public DashboardUser() {}
    
    public DashboardUser(int userId, String email, String fullName, String phone, String role) {
        this.userId = userId;
        this.email = email;
        this.fullName = fullName;
        this.phone = phone;
        this.role = role;
    }
    
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}
