package org.jwendell.cluster1;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class StoreInSession extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static final String KEY = "key";

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
	    HttpSession session = request.getSession();
        PrintWriter out = response.getWriter();
        String value = request.getParameter(KEY);

        if (value == null || value.isEmpty()) {
            Object attribute = session.getAttribute(KEY);
            out.print(String.valueOf(attribute));
        } else {
            session.setAttribute(KEY, value);
            out.print("OK");
        }
	}
}
