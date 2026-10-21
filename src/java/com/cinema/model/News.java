package com.cinema.model;

import java.time.LocalDateTime;

/**
 * Tin tức — STT 12 (quản lý), STT 16 (khách xem).
 * Khớp 100% bảng News trong script database của nhóm.
 */
public class News {
    private int newsId;
    private String title;
    private String content;
    private String thumbnailUrl;
    private String status;      // "Draft" | "Published" | "Hidden" (đúng CHECK trong DB)
    private int createdBy;      // Account.account_id (NOT NULL trong DB)
    private String authorName;  // Account.full_name — join để hiển thị, không insert
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public int getNewsId() { return newsId; }
    public void setNewsId(int newsId) { this.newsId = newsId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getCreatedBy() { return createdBy; }
    public void setCreatedBy(int createdBy) { this.createdBy = createdBy; }

    public String getAuthorName() { return authorName; }
    public void setAuthorName(String authorName) { this.authorName = authorName; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public boolean isPublished() { return "Published".equalsIgnoreCase(status); }

    /** Nhãn tiếng Việt cho JSP. */
    public String getStatusLabel() {
        if ("Published".equalsIgnoreCase(status)) return "Đã xuất bản";
        if ("Hidden".equalsIgnoreCase(status)) return "Đã ẩn";
        return "Bản nháp";
    }
}