package com.cinema.util.MovieUtil;

import com.cinema.util.AppConfig;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.NoSuchFileException;
import java.util.Locale;
import java.util.UUID;

public final class MediaUploadUtil {
    public static final class MediaNotFoundException extends IOException {
        public MediaNotFoundException(String message) {
            super(message);
        }
    }

    public enum MediaType {
        POSTER, TRAILER
    }

    private static final long POSTER_LIMIT = 5L * 1024L * 1024L;
    private static final long TRAILER_LIMIT = 100L * 1024L * 1024L;

    private MediaUploadUtil() {
    }

    public static Path root() throws IOException {
        String configured = AppConfig.get("media.upload.root");
        if (configured.isBlank()) configured = "media";
        Path root = Path.of(configured).toAbsolutePath().normalize();
        Files.createDirectories(root);
        return root.toRealPath();
    }

    public static String store(Part part, MediaType type) throws IOException {
        if (part == null || part.getSize() == 0) return null;
        long limit = type == MediaType.POSTER ? POSTER_LIMIT : TRAILER_LIMIT;
        if (part.getSize() > limit) {
            throw new IllegalArgumentException(type == MediaType.POSTER
                    ? "Ảnh poster vượt quá giới hạn 5 MB."
                    : "Video trailer vượt quá giới hạn 100 MB.");
        }
        String extension = extension(part.getSubmittedFileName());
        String contentType = part.getContentType();
        if (contentType == null) throw invalidType(type);
        contentType = contentType.split(";", 2)[0].trim().toLowerCase(Locale.ROOT);
        if (!isAllowed(extension, contentType, type)) throw invalidType(type);
        try (InputStream input = part.getInputStream()) {
            byte[] signature = input.readNBytes(12);
            if (!matchesSignature(extension, signature)) throw invalidType(type);
        }
        String folder = type == MediaType.POSTER ? "posters" : "trailers";
        Path directory = root().resolve(folder);
        Files.createDirectories(directory);
        Path realDirectory = directory.toRealPath();
        if (!realDirectory.startsWith(root())) throw new IOException("Thư mục lưu tệp không hợp lệ.");
        String fileName = UUID.randomUUID() + "." + extension;
        Path destination = realDirectory.resolve(fileName).normalize();
        if (!destination.getParent().equals(realDirectory)) throw new IOException("Đường dẫn tệp không hợp lệ.");
        try (InputStream input = part.getInputStream()) {
            Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            Files.deleteIfExists(destination);
            throw e;
        }
        return "/media/" + folder + "/" + fileName;
    }

    public static Path resolve(String relativePath) throws IOException {
        if (relativePath == null || !relativePath.matches("^/(media)/(posters|trailers)/[0-9a-fA-F-]{36}\\.(jpg|jpeg|png|webp|mp4|webm)$")) {
            throw new MediaNotFoundException("Đường dẫn media không hợp lệ.");
        }
        String[] parts = relativePath.split("/");
        String folder = parts[2];
        String extension = relativePath.substring(relativePath.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
        if ("posters".equals(folder) && !SetExtensions.POSTERS.contains(extension)) throw new MediaNotFoundException("Định dạng media không hợp lệ.");
        if ("trailers".equals(folder) && !SetExtensions.TRAILERS.contains(extension)) throw new MediaNotFoundException("Định dạng media không hợp lệ.");
        Path realRoot = root();
        Path candidate = realRoot.resolve(folder).resolve(parts[3]).normalize();
        if (!candidate.startsWith(realRoot) || !Files.isRegularFile(candidate, LinkOption.NOFOLLOW_LINKS)) {
            throw new MediaNotFoundException("Không tìm thấy tệp media.");
        }
        Path realParent;
        try {
            realParent = candidate.getParent().toRealPath();
        } catch (NoSuchFileException e) {
            throw new MediaNotFoundException("Không tìm thấy tệp media.");
        }
        if (!realParent.startsWith(realRoot)) throw new IOException("Đường dẫn media không hợp lệ.");
        return candidate;
    }

    public static boolean delete(String relativePath) throws IOException {
        if (relativePath == null || !relativePath.startsWith("/media/")) return false;
        try {
            return Files.deleteIfExists(resolve(relativePath));
        } catch (MediaNotFoundException e) {
            if ("Không tìm thấy tệp media.".equals(e.getMessage())) return false;
            throw e;
        }
    }

    public static String contentType(Path file) {
        String name = file.getFileName().toString().toLowerCase(Locale.ROOT);
        if (name.endsWith(".jpg") || name.endsWith(".jpeg")) return "image/jpeg";
        if (name.endsWith(".png")) return "image/png";
        if (name.endsWith(".webp")) return "image/webp";
        if (name.endsWith(".mp4")) return "video/mp4";
        if (name.endsWith(".webm")) return "video/webm";
        return "application/octet-stream";
    }

    private static String extension(String submittedName) {
        if (submittedName == null || submittedName.isBlank()) throw new IllegalArgumentException("Vui lòng chọn tệp hợp lệ.");
        String safeName = submittedName.replace('\\', '/');
        int slash = safeName.lastIndexOf('/');
        int dot = safeName.lastIndexOf('.');
        if (dot <= slash || dot == safeName.length() - 1) throw new IllegalArgumentException("Tệp tải lên thiếu phần mở rộng.");
        return safeName.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private static boolean isAllowed(String extension, String contentType, MediaType type) {
        if (type == MediaType.POSTER) {
            return ("jpg".equals(extension) || "jpeg".equals(extension)) && "image/jpeg".equals(contentType)
                    || "png".equals(extension) && "image/png".equals(contentType)
                    || "webp".equals(extension) && "image/webp".equals(contentType);
        }
        return "mp4".equals(extension) && "video/mp4".equals(contentType)
                || "webm".equals(extension) && "video/webm".equals(contentType);
    }

    private static boolean matchesSignature(String extension, byte[] bytes) {
        if ("jpg".equals(extension) || "jpeg".equals(extension)) {
            return bytes.length >= 3 && (bytes[0] & 255) == 255 && (bytes[1] & 255) == 216 && (bytes[2] & 255) == 255;
        }
        if ("png".equals(extension)) {
            byte[] signature = {(byte) 137, 80, 78, 71, 13, 10, 26, 10};
            return startsWith(bytes, signature);
        }
        if ("webp".equals(extension)) {
            return bytes.length >= 12 && ascii(bytes, 0, 4, "RIFF") && ascii(bytes, 8, 4, "WEBP");
        }
        if ("mp4".equals(extension)) return bytes.length >= 8 && ascii(bytes, 4, 4, "ftyp");
        if ("webm".equals(extension)) {
            return bytes.length >= 4 && (bytes[0] & 255) == 0x1A && (bytes[1] & 255) == 0x45
                    && (bytes[2] & 255) == 0xDF && (bytes[3] & 255) == 0xA3;
        }
        return false;
    }

    private static boolean startsWith(byte[] bytes, byte[] signature) {
        if (bytes.length < signature.length) return false;
        for (int i = 0; i < signature.length; i++) {
            if (bytes[i] != signature[i]) return false;
        }
        return true;
    }

    private static boolean ascii(byte[] bytes, int offset, int length, String expected) {
        if (bytes.length < offset + length) return false;
        for (int i = 0; i < length; i++) {
            if (bytes[offset + i] != (byte) expected.charAt(i)) return false;
        }
        return true;
    }

    private static IllegalArgumentException invalidType(MediaType type) {
        return new IllegalArgumentException(type == MediaType.POSTER
                ? "Ảnh không hợp lệ. Chỉ chấp nhận JPG, JPEG, PNG hoặc WEBP."
                : "Video không hợp lệ. Chỉ chấp nhận MP4 hoặc WEBM.");
    }

    private static final class SetExtensions {
        private static final java.util.Set<String> POSTERS = java.util.Set.of("jpg", "jpeg", "png", "webp");
        private static final java.util.Set<String> TRAILERS = java.util.Set.of("mp4", "webm");
    }
}
