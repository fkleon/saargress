part of saargress_server;

const Map<String, String> corsHeader =
  const {'Access-Control-Allow-Origin': 'http://127.0.0.1:8080',
         'Access-Control-Allow-Methods': 'GET, OPTIONS',
         'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Saargress-Auth',
         'Access-Control-Allow-Credentials': 'true',
         'Access-Control-Expose-Headers': 'Authorization'
         };

shelf.Middleware corsHeaderMiddleware = shelf.createMiddleware(requestHandler: _options, responseHandler: _cors);

shelf.Response _options(shelf.Request request) => (request.method == 'OPTIONS') ?
    new shelf.Response.ok(null, headers: corsHeader) : null;

shelf.Response _cors(shelf.Response response) => response.change(headers: corsHeader);