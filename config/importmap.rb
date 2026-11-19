# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"

pin_all_from "app/javascript/components", under: "components"
pin_all_from "app/javascript/utils", under: "utils"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from TrainingAdminEngine::Engine.root.join("app/javascript/controllers"), under: "controllers"
