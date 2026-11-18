class StorageController < ApplicationController
  def show
    path = Rails.root.join("storage", params[:path])
    return head :not_found unless File.file?(path)
    send_file path, disposition: "inline"
  end
end