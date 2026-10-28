package com.cinema.dao;

import com.cinema.model.PointCustomer;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PointDAO {
    public List<PointCustomer> findCustomers(String keyword) throws SQLException {
        String filter = keyword == null || keyword.trim().isEmpty() ? "" : " AND (a.full_name LIKE ? OR a.email LIKE ?)";
        String sql = "SELECT c.customer_id, a.full_name, a.email, c.my_point_balance "
                + "FROM Customer c JOIN Account a ON a.account_id = c.customer_id WHERE 1=1" + filter
                + " ORDER BY c.my_point_balance DESC, a.full_name";
        List<PointCustomer> result = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            if (!filter.isEmpty()) {
                ps.setString(1, "%" + keyword.trim() + "%");
                ps.setString(2, "%" + keyword.trim() + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PointCustomer item = new PointCustomer();
                    item.setCustomerId(rs.getInt("customer_id"));
                    item.setFullName(rs.getString("full_name"));
                    item.setEmail(rs.getString("email"));
                    item.setPointBalance(rs.getInt("my_point_balance"));
                    result.add(item);
                }
            }
        }
        return result;
    }

    public void adjust(int customerId, int points) throws SQLException {
        if (points == 0) throw new SQLException("Số điểm điều chỉnh phải khác 0.");
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try (PreparedStatement update = c.prepareStatement(
                    "UPDATE Customer SET my_point_balance = my_point_balance + ? "
                    + "WHERE customer_id = ? AND my_point_balance + ? >= 0");
                 PreparedStatement insert = c.prepareStatement(
                    "INSERT INTO MyPointTransaction(customer_id, txn_type, points) VALUES (?, 'Adjust', ?)")) {
                update.setInt(1, points);
                update.setInt(2, customerId);
                update.setInt(3, points);
                if (update.executeUpdate() != 1) throw new SQLException("Khách hàng không tồn tại hoặc số dư không đủ.");
                insert.setInt(1, customerId);
                insert.setInt(2, points);
                insert.executeUpdate();
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }
}
