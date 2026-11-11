# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :openid_connect,           # Provider identifier, affects route names
    scope: [:openid, :email, :profile],
    response_type: :code,
    issuer: ENV.fetch("OIDC_ISSUER", "https://example.com"), # Your OIDC provider's Issuer URL
    discovery: true,                  # Auto-discover endpoints (recommended)
    client_options: {
      identifier: ENV.fetch("OIDC_CLIENT_ID", ""),
      secret: ENV.fetch("OIDC_CLIENT_SECRET", ""),
      redirect_uri: ENV.fetch("OIDC_REDIRECT_URI", "https://yourapp.com/auth/openid_connect/callback"), # e.g., "https://yourapp.com/auth/openid_connect/callback"
    }
end

OpenIDConnect.http_config do |client|
  # Method 1: Add a custom CA certificate file
  # client.ssl.ca_file = ENV['CA_TRUST_CERTIFICATE'] if ENV['CA_TRUST_CERTIFICATE']

  # Method 2: If you want to temporarily disable verification (only for debugging, do not use in production)
  client.ssl.verify = false
end
