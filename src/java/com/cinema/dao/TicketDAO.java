package com.cinema.dao;

import com.cinema.model.PointTransaction;
import com.cinema.model.Ticket;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** Read-only queries for a customer's ticket history and MyPoint ledger. */
public class TicketDAO {

    public List<Ticket> findByUser(int userId) throws SQLException {
        String sql = "SELECT TicketId, MovieTitle, CinemaName, RoomName, Seats, ShowTime, TotalPrice, Status, CreatedAt "
                + "FROM Tickets WHERE UserId = ? ORDER BY CreatedAt DESC";
        List<Ticket> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Ticket t = new Ticket();
                    t.setTicketId(rs.getInt("TicketId"));
                    t.setMovieTitle(rs.getString("MovieTitle"));
                    t.setCinemaName(rs.getString("CinemaName"));
                    t.setRoomName(rs.getString("RoomName"));
                    t.setSeats(rs.getString("Seats"));
                    t.setShowTime(rs.getTimestamp("ShowTime").toLocalDateTime());
                    t.setTotalPrice(rs.getBigDecimal("TotalPrice"));
                    t.setStatus(rs.getString("Status"));
                    t.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
                    list.add(t);
                }
            }
        }
        return list;
    }

    public List<PointTransaction> findPointHistory(int userId) throws SQLException {
        String sql = "SELECT TxId, Points, Reason, CreatedAt FROM PointTransactions "
                + "WHERE UserId = ? ORDER BY CreatedAt DESC";
        List<PointTransaction> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PointTransaction p = new PointTransaction();
                    p.setTxId(rs.getInt("TxId"));
                    p.setPoints(rs.getInt("Points"));
                    p.setReason(rs.getString("Reason"));
                    p.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
                    list.add(p);
                }
            }
        }
        return list;
    }
}
