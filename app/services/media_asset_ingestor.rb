require "digest"
require "fileutils"
require "image_processing/vips"
require "tempfile"

class MediaAssetIngestor
  WEBP_INPUTS = %w[.jpg .jpeg .png .bmp .tif .tiff].freeze

  def self.call(upload, attributes = {})
    source_path = upload.tempfile.path
    source_extension = File.extname(upload.original_filename).downcase
    image = Vips::Image.new_from_file(source_path, access: :sequential)
    digest = Digest::SHA256.file(source_path).hexdigest
    asset = MediaAsset.new(attributes.merge(
      sha256: digest, source_byte_size: File.size(source_path), width: image.width, height: image.height
    ))

    if (duplicate = MediaAsset.where(sha256: digest).detect { |candidate| candidate.file.attached? })
      asset.format = duplicate.format
      asset.file.attach(duplicate.file.blob)
    else
      processed = optimize(source_path, File.basename(upload.original_filename, source_extension), source_extension)
      asset.format = processed[:format]
      File.open(processed[:path], "rb") do |io|
        asset.file.attach(io: io, filename: processed[:filename], content_type: processed[:content_type])
      end
    end

    asset.save!
    asset
  ensure
    FileUtils.rm_f(processed[:temporary]) if defined?(processed) && processed&.dig(:temporary)
  end

  def self.optimize(source_path, basename, extension)
    unless WEBP_INPUTS.include?(extension)
      return { path: source_path, filename: "#{basename}#{extension}", format: extension.delete_prefix("."),
        content_type: Marcel::MimeType.for(Pathname(source_path)), temporary: nil }
    end
    temporary = Tempfile.new([ basename, ".webp" ], Rails.root.join("tmp"))
    temporary.close
    ImageProcessing::Vips.source(source_path).convert("webp").saver(quality: 82, strip: true).call(destination: temporary.path)
    { path: temporary.path, filename: "#{basename}.webp", format: "webp", content_type: "image/webp", temporary: temporary.path }
  end
end
