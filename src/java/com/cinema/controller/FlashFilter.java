package com.cinema.controller;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/** Moves one-shot flash messages from the session into the request. */
@WebFilter("/*")
public class FlashFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
            throws IOException, ServletException {
        HttpSession s = ((HttpServletRequest) req).getSession(false);
        if (s != null && s.getAttribute("flashMsg") != null) {
            req.setAttribute("flashType", s.getAttribute("flashType"));
            req.setAttribute("flashMsg", s.getAttribute("flashMsg"));
            s.removeAttribute("flashType");
            s.removeAttribute("flashMsg");
        }
        chain.doFilter(req, resp);
    }
}
