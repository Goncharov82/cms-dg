class MediaController < ApplicationController
  def blog
    send_asset MediaAsset.find_by_public_filename!(params[:filename])
  end

  def show
    asset = MediaAsset.find(params[:id])
    raise ActiveRecord::RecordNotFound unless asset.file.attached?

    send_asset asset
  end

  def author_avatar
    author = Author.find(params[:id])
    raise ActiveRecord::RecordNotFound unless author.avatar.attached?

    expires_in 1.day, public: true
    send_data author.avatar.download,
      filename: author.avatar.filename.to_s,
      type: author.avatar.content_type,
      disposition: "inline"
  end

  private

  def send_asset(asset)
    expires_in 1.day, public: true
    send_data asset.file.download,
      filename: asset.file.filename.to_s,
      type: asset.file.content_type,
      disposition: "inline"
  end
end
