package com.consol.sampleapp;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Servlet implementation class SessionInfoServlet
 */
@WebServlet("/SessionInfoServlet")
public class SessionInfoServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public SessionInfoServlet() {
		super();
		// TODO Auto-generated constructor stub
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.setContentType("text/html");
		// response.getWriter().append("Served at:
		// ").append(request.getContextPath());

		PrintWriter out = response.getWriter();

		// Create a session object if it is already not created.
		HttpSession session = request.getSession(true);
		// Get session creation time.
		Date createTime = new Date(session.getCreationTime());
		// Get last access time of this web page.
		Date lastAccessTime = new Date(session.getLastAccessedTime());

		if (request.getParameterMap().containsKey("attr1")) {
			String attr_val = request.getParameter("attr1");
			//System.out.println(attr_val);
			session.setAttribute("attr1", attr_val);
		}

		Cookie cookies[] = request.getCookies();

		out.println("<pre>");
		out.println("Hostname: " + System.getenv("HOSTNAME"));
		out.println("Served at: " + request.getContextPath());
		out.println("");
		out.println("request host: " + request.getServerName());
		out.println("request port: " + request.getServerPort());
		out.println("");
		out.println("application server: " + this.getServletContext().getServerInfo());
		out.println("");
		out.println("session id:             " + session.getId());
		out.println("session createTime:     " + createTime);
		out.println("session lastAccessTime: " + lastAccessTime);
		out.println("");

		out.println("=== cookies ===");

		if ((cookies == null) || (cookies.length == 0)) {
			out.println("no cookies found");
		} else {
			for (int i = 0; i < cookies.length; i++) {
				Cookie c = cookies[i];
				out.println("name: " + c.getName() + ", value: " + c.getValue() + ", comment: " + c.getComment()
						+ ", MaxAge: " + c.getMaxAge() + ", Path: " + c.getPath());
			}
		}

		out.println("");
		out.println("=== attributes ===");
		// Enumeration<String> attributes =
		// getServletContext().getAttributeNames();
		Enumeration<String> attributes = session.getAttributeNames();
		for (; attributes.hasMoreElements();) {
			String name = (String) attributes.nextElement();
			out.println("attribute name:  " + name);

			// Get the value of the attribute
			// Object value = getServletContext().getAttribute(name);

			Object value = session.getAttribute(name);

			if (value instanceof String) {
				out.println("attribute type:  String");
				out.println("attribute value: " + value.toString());
			} else if (value instanceof HashMap) {
				HashMap hmap = (HashMap) value;
				out.println("attribute type: HashMap");
				// iterate and print key value pair here
			} else if (value instanceof ArrayList) {
				// do arraylist iterate here and print
				out.println("attribute type: ArrayList");
			} else {
				out.println("attribute type: unknown");
			}
			out.println("\n");
		}

		out.println("</pre>");

		out.println("<a href=\"" + request.getContextPath() + "/form.html\" target=\"_blank\">set attribute</a>");

	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
