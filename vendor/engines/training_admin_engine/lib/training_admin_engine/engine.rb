module TrainingAdminEngine
  class Engine < ::Rails::Engine
    isolate_namespace TrainingAdminEngine

    initializer "training_admin_engine.importmap", before: "importmap" do |app|
      # https://github.com/rails/importmap-rails#composing-import-maps
      app.config.importmap.paths << root.join("config/importmap.rb")

      # https://github.com/rails/importmap-rails#sweeping-the-cache-in-development-and-test
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    initializer "training_admin_engine.assets" do |app|
      # my_engine/app/javascript needs to be in the asset path
      app.config.assets.paths << root.join("app/javascript")
      app.config.assets.paths << root.join("app/assets/javascripts")
      app.config.assets.precompile += %w[application.js]

      # manifest has to be precompiled
      app.config.assets.precompile += %w[training_admin_engine/manifest.js]
    end
  end
end
