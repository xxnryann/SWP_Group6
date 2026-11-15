package com.cinema.controller.movie;

import com.cinema.util.movie.MediaUploadUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

@WebServlet("/media/*")
public class MediaServlet extends HttpServlet {
    private record ByteRange(long start, long end) {
        long length() {
            return end - start + 1;
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        if (pathInfo == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        Path file;
        try {
            file = MediaUploadUtil.resolve("/media" + pathInfo);
        } catch (MediaUploadUtil.MediaNotFoundException e) {
            // DEF-005: máy vừa clone repo chưa có thư mục media.upload.root → tìm poster/avatar mẫu
            // đóng gói trong WEB-INF/seed-media; vẫn không có thì trả ảnh placeholder thay vì ảnh vỡ.
            Path seed = seedFile(pathInfo);
            if (seed != null) {
                file = seed;
            } else if (pathInfo.startsWith("/posters/")) {
                response.setHeader("Cache-Control", "no-cache");
                request.getRequestDispatcher(PLACEHOLDER_POSTER).forward(request, response);
                return;
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
        }
        long size = Files.size(file);
        response.setHeader("Accept-Ranges", "bytes");
        response.setHeader("Cache-Control", "public, max-age=86400, immutable");
        response.setContentType(MediaUploadUtil.contentType(file));
        String rangeHeader = request.getHeader("Range");
        ByteRange range = null;
        if (rangeHeader != null) {
            try {
                range = parseRange(rangeHeader, size);
            } catch (IllegalArgumentException e) {
                response.setStatus(HttpServletResponse.SC_REQUESTED_RANGE_NOT_SATISFIABLE);
                response.setHeader("Content-Range", "bytes */" + size);
                return;
            }
        }
        long start = range == null ? 0 : range.start();
        long length = range == null ? size : range.length();
        if (range != null) {
            response.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
            response.setHeader("Content-Range", "bytes " + range.start() + "-" + range.end() + "/" + size);
        }
        response.setContentLengthLong(length);
        try (InputStream input = Files.newInputStream(file, StandardOpenOption.READ);
                OutputStream output = response.getOutputStream()) {
            input.skipNBytes(start);
            byte[] buffer = new byte[16 * 1024];
            long remaining = length;
            while (remaining > 0) {
                int read = input.read(buffer, 0, (int) Math.min(buffer.length, remaining));
                if (read < 0) break;
                output.write(buffer, 0, read);
                remaining -= read;
            }
        }
    }

    private static final String PLACEHOLDER_POSTER = "/assets/img/poster-placeholder.svg";
    private static final String SEED_DIR = "/WEB-INF/seed-media";

    /** Tệp mẫu đi kèm repo (web/WEB-INF/seed-media/&lt;posters|avatars&gt;/&lt;uuid&gt;.&lt;ext&gt;), null nếu không có. */
    private Path seedFile(String pathInfo) {
        if (!pathInfo.matches("^/(posters|avatars)/[0-9a-fA-F-]{36}\\.(jpg|jpeg|png|webp)$")) return null;
        String real = getServletContext().getRealPath(SEED_DIR);
        if (real == null) return null;
        try {
            Path root = Path.of(real).toRealPath();
            Path candidate = root.resolve(pathInfo.substring(1)).normalize();
            if (candidate.startsWith(root) && Files.isRegularFile(candidate)) return candidate;
        } catch (IOException e) {
            // thư mục seed-media không tồn tại
        }
        return null;
    }

    private ByteRange parseRange(String header, long size) {
        if (!header.startsWith("bytes=") || header.indexOf(',') >= 0 || size == 0) {
            throw new IllegalArgumentException("Invalid byte range");
        }
        String value = header.substring("bytes=".length()).trim();
        int separator = value.indexOf('-');
        if (separator < 0) throw new IllegalArgumentException("Invalid byte range");
        String first = value.substring(0, separator).trim();
        String last = value.substring(separator + 1).trim();
        try {
            if (first.isEmpty()) {
                long suffixLength = Long.parseLong(last);
                if (suffixLength <= 0) throw new IllegalArgumentException("Invalid byte range");
                long start = Math.max(0, size - suffixLength);
                return new ByteRange(start, size - 1);
            }
            long start = Long.parseLong(first);
            long end = last.isEmpty() ? size - 1 : Long.parseLong(last);
            if (start < 0 || start >= size || end < start) throw new IllegalArgumentException("Invalid byte range");
            return new ByteRange(start, Math.min(end, size - 1));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid byte range");
        }
    }
}
