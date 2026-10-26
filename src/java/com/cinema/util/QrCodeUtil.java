package com.cinema.util;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.EnumMap;
import java.util.Map;
import javax.imageio.ImageIO;

/**
 * Sinh mã QR cho vé điện tử (UC18 — vé điện tử QR).
 *
 * <p>QR chứa <b>mã vé</b> ({@code Ticket.ticket_code}) — đúng chuỗi mà
 * {@code sp_CheckInTicket} tra cứu — nên nhân viên quét mã này ở quầy là
 * soát vé được (UC39).</p>
 *
 * <p>Dùng ZXing ({@code com.google.zxing}) ở tầng tiện ích để cả màn hình
 * lịch sử vé và màn hình hóa đơn tại quầy dùng chung <b>một</b> cách dựng
 * ảnh — không nhân bản logic vẽ QR ở nhiều nơi.</p>
 */
public final class QrCodeUtil {

    /** Cạnh của ảnh QR (px). Vừa để in/mở trên điện thoại. */
    private static final int DEFAULT_SIZE = 260;

    /** Mức chịu lỗi: M — chịu được ~15% che, đủ cho màn hình rạp bị lóe. */
    private static final ErrorCorrectionLevel ERROR_CORRECTION = ErrorCorrectionLevel.M;

    /** Lề trắng (module) bắt buộc theo chuẩn QR để scanner nhận. */
    private static final int QUIET_ZONE = 1;

    private QrCodeUtil() {
    }

    /**
     * Sinh ảnh QR (PNG) chứa nội dung cho trước.
     *
     * @param content nội dung cần mã hoá (mã vé)
     * @param size    cạnh ảnh (px)
     * @return ảnh PNG dạng byte[]
     * @throws IOException khi ghi ảnh lỗi
     */
    public static byte[] toPngBytes(String content, int size) throws IOException {
        BufferedImage image = toImage(content, size);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "PNG", out);
        return out.toByteArray();
    }

    /**
     * Sinh ảnh QR chứa nội dung cho trước.
     *
     * @param content nội dung cần mã hoá (mã vé)
     * @param size    cạnh ảnh (px)
     * @return ảnh QR (đen trên nền trắng)
     */
    public static BufferedImage toImage(String content, int size) {
        int side = size > 0 ? size : DEFAULT_SIZE;
        try {
            Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
            hints.put(EncodeHintType.ERROR_CORRECTION, ERROR_CORRECTION);
            hints.put(EncodeHintType.MARGIN, QUIET_ZONE);
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");

            BitMatrix matrix = new QRCodeWriter().encode(
                    content == null ? "" : content, BarcodeFormat.QR_CODE, side, side, hints);

            int width = matrix.getWidth();
            int height = matrix.getHeight();
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    // BitMatrix: true = module đen.
                    image.setRGB(x, y, matrix.get(x, y) ? 0xFF000000 : 0xFFFFFFFF);
                }
            }
            return image;
        } catch (WriterException e) {
            // Nội dung rỗng/quá dài → dùng ảnh trắng thay vì làm sập trang.
            throw new IllegalArgumentException(
                    "Không tạo được mã QR: " + e.getMessage(), e);
        }
    }

    /**
     * Sinh ảnh QR với kích thước mặc định.
     *
     * @param content nội dung cần mã hoá (mã vé)
     * @return ảnh PNG dạng byte[]
     * @throws IOException khi ghi ảnh lỗi
     */
    public static byte[] toPngBytes(String content) throws IOException {
        return toPngBytes(content, DEFAULT_SIZE);
    }
}
