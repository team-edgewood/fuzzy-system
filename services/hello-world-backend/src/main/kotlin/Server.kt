import io.vertx.core.AbstractVerticle
class Server : AbstractVerticle() {
    override fun start() {
        vertx.createHttpServer()
                .requestHandler { req ->
                    req.response()
                            .putHeader("content-type", "text/plain")
                            .end("Hello from Vert.x")
                }.listen(8080)
    }
}
