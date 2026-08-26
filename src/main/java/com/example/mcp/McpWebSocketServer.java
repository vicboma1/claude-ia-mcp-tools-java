package com.example.mcp;

import com.example.api.ApiClient;
import com.example.business.UserService;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.java_websocket.server.WebSocketServer;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetSocketAddress;

public class McpWebSocketServer extends WebSocketServer {
    private static final Logger logger = LoggerFactory.getLogger(McpWebSocketServer.class);
    private final McpServer mcpServer;
    private final Gson gson = new Gson();

    public McpWebSocketServer(int port) {
        super(new InetSocketAddress(port));
        ApiClient apiClient = new ApiClient();
        UserService userService = new UserService(apiClient);
        this.mcpServer = new McpServer(userService);
    }

    @Override
    public void onStart() {
        logger.info("MCP WebSocket Server started on port {}", this.getPort());
    }

    @Override
    public void onOpen(WebSocket conn, ClientHandshake handshake) {
        logger.info("Client connected: {}", conn.getRemoteSocketAddress());
    }

    @Override
    public void onClose(WebSocket conn, int code, String reason, boolean remote) {
        logger.info("Client disconnected: {} ({})", conn.getRemoteSocketAddress(), reason);
    }

    @Override
    public void onMessage(WebSocket conn, String message) {
        try {
            logger.debug("Received message: {}", message);

            if (message.trim().isEmpty()) {
                return;
            }

            JsonObject request = gson.fromJson(message, JsonObject.class);
            JsonObject response = mcpServer.handleRequest(request);

            conn.send(gson.toJson(response));
        } catch (Exception e) {
            logger.error("Error processing message: {}", e.getMessage(), e);
            JsonObject errorResponse = new JsonObject();
            errorResponse.addProperty("jsonrpc", "2.0");
            JsonObject error = new JsonObject();
            error.addProperty("code", -32603);
            error.addProperty("message", "Internal error: " + e.getMessage());
            errorResponse.add("error", error);
            conn.send(gson.toJson(errorResponse));
        }
    }

    @Override
    public void onError(WebSocket conn, Exception ex) {
        logger.error("WebSocket error: {}", ex.getMessage(), ex);
    }

    public static void main(String[] args) {
        int port = 8080;
        if (args.length > 0) {
            try {
                port = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                logger.warn("Invalid port argument, using default: {}", port);
            }
        }

        McpWebSocketServer server = new McpWebSocketServer(port);
        try {
            server.start();
            logger.info("MCP WebSocket Server running on ws://localhost:{}", port);
        } catch (Exception e) {
            logger.error("Failed to start server: {}", e.getMessage(), e);
            System.exit(1);
        }
    }
}
