require 'rubygems'
require 'opencv'
require 'logger'

include OpenCV

# Compare 2 files, and draw where changes occurred

if $0 == __FILE__

  diff_window = GUI::Window.new "diff"
  bin_window  = GUI::Window.new "bin"

  logger = Logger.new(STDERR)
  logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'WARN').upcase)

  threshold = 0x66
  accuracy  = 1

  diff_window.set_trackbar("threshold", 0xFF, threshold) {|v| threshold = v}
  diff_window.set_trackbar("accuracy",    10, accuracy ) {|v| accuracy  = v}

  img_before = IplImage.load(File.join(File.dirname(__FILE__), "file-1.jpg"))
  img_after  = IplImage.load(File.join(File.dirname(__FILE__), "file-2.jpg"))

  marker = 0

  loop do
    logger.info "threshold: #{threshold} accuracy: #{accuracy}" if marker % 20 == 0
    img_diff = img_after.abs_diff(img_before)
    gray     = img_diff.BGR2GRAY
    binary   = gray.threshold(threshold, 0xFF, :binary)
    contours = binary.find_contours

    while contours
      poly = contours.approx(accuracy: accuracy)
        img_diff.draw_contours!(poly, CvColor::Red, CvColor::Black, 2, thickness: 2, line_type: :aa)
      begin
      end while (poly = poly.h_next)

      contours = contours.h_next
    end

    bin_window.show binary
    diff_window.show img_diff
    marker += 1
    exit if GUI.wait_key(5)
  end

end

