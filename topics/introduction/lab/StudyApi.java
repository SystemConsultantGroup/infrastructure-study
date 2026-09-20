import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public class StudyApi {
    public static void main(String[] args) {
        try {
            String bind = System.getenv().getOrDefault("BIND_ADDRESS", "127.0.0.1");
            int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
            var server = HttpServer.create(new InetSocketAddress(bind, port), 0);
            server.createContext("/", StudyApi::handle);
            server.start();
            System.out.println("study-api listening on " + bind + ":" + server.getAddress().getPort());
        } catch (IllegalArgumentException | IOException invalid) {
            System.err.println("Cannot start API. Check BIND_ADDRESS, PORT (0..65535), and port availability: " + invalid.getMessage());
            System.exit(1);
        }
    }

    private static void handle(HttpExchange request) throws IOException {
        if (!request.getRequestMethod().equals("GET")) {
            request.getResponseHeaders().set("Allow", "GET");
            send(request, 405, "GET only\n");
            return;
        }
        switch (request.getRequestURI().getPath()) {
            case "/health" -> send(request, 200, "ok\n");
            case "/message" -> send(request, 200,
                System.getenv().getOrDefault("APP_MESSAGE", "hello from the app") + "\n");
            case "/info" -> send(request, 200,
                "environment=" + System.getenv().getOrDefault("APP_ENV", "local") + "\n"
                + "java=" + System.getProperty("java.version") + "\n"
                + "os=" + System.getProperty("os.name") + "\n"
                + "arch=" + System.getProperty("os.arch") + "\n");
            default -> send(request, 404, "not found\n");
        }
    }

    private static void send(HttpExchange request, int status, String text) throws IOException {
        byte[] body = text.getBytes(StandardCharsets.UTF_8);
        request.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
        request.sendResponseHeaders(status, body.length);
        try (var output = request.getResponseBody()) {
            output.write(body);
        } finally {
            request.close();
        }
    }
}
