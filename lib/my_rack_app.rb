class MyRackApp
  def call(env)
    method = env["REQUEST_METHOD"]
    path = env["PATH_INFO"]

    body = "Hello from my Rack App!
    Method: #{method}
    Path: #{path}"

    [
      200,
      { "content-type" => "text/plain" },
      [body]
    ]
  end
end