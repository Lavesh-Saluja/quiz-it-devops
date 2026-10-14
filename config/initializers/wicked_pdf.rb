# frozen_string_literal: true

# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.configure do |config|
  config.exe_path =
     if Rails.env.production?
       "/usr/local/bin/wkhtmltopdf"
     else
       Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
     end

  # Needed for wkhtmltopdf 0.12.6+ to use many wicked_pdf asset helpers
  # config.enable_local_file_access = true

  # Layout file to be used for all PDFs
  # config.layout = "pdf.html"

  # config.use_xvfb = true
end
