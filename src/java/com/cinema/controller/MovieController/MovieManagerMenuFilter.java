package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class MovieManagerMenuFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpSession session = httpRequest.getSession(false);
        User user = session == null ? null : (User) session.getAttribute(BaseServlet.SESSION_USER);
        httpRequest.setAttribute("isManager", user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole()));
        String path = httpRequest.getServletPath();
        httpRequest.setAttribute("movieModule", path.startsWith("/movies")
                || path.startsWith("/showtimes") || path.startsWith("/manage/movies")
                || path.startsWith("/manage/showtimes"));
        chain.doFilter(request, response);
    }
}
