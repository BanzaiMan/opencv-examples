require 'rubygems'
require 'opencv'
require 'logger'
require 'socket'

include OpenCV

camera_id = ARGV[0].to_i || 0
socket_path = ARGV[1] || '/tmp/die.socket'

def bits(pips)
  {
    1 => 0b00,
    2 => 0b01,
    3 => 0b10,
    4 => 0b11,
    5 => 0b0,
    6 => 0b1
  }[pips]
end

# Compare 2 files, and draw where changes occurred

if $0 == __FILE__
  diff_window = GUI::Window.new "diff"
  bin_window  = GUI::Window.new "bin"

  CONTOUR_LENGTH_MIN = 60
  CONTOUR_LENGTH_MAX = 150

  serv = UNIXServer.new(socket_path)
  socket = serv.accept

  logger = Logger.new(STDERR)
  logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'WARN').upcase)

  logger.into "state=ready"

  threshold = 0x66
  accuracy  = 1
  interval = 1000

  diff_window.set_trackbar("threshold", 0xFF, threshold) {|v| threshold = v}
  diff_window.set_trackbar("accuracy",    10, accuracy ) {|v| accuracy  = v}

  capture = CvCapture.open(camera_id)

  capture.grab
  base_image = capture.retrieve
  img_before = base_image.dup
  GUI.wait_key interval

  loop do
    begin
      last_pips = pips = 0

      capture.grab
      img_after = capture.retrieve

      img_diff = img_after.abs_diff(base_image)
      gray     = img_diff.BGR2GRAY
      binary   = gray.threshold(threshold, 0xFF, :binary)
      contours = binary.find_contours

      while contours
        poly = contours.approx(accuracy: accuracy)
        if contours.hole?
          contours = contours.h_next
          next
        end

        begin
          if contours.length >= CONTOUR_LENGTH_MIN && contours.length <= CONTOUR_LENGTH_MAX
            img_diff.draw_contours!(poly, CvColor::Red, CvColor::Black, 0, thickness: 2, line_type: :aa)
            pips += 1
          end
        end while (poly = poly.h_next)


        contours = contours.h_next
      end
      logger.warn "pips=#{pips} last_pips=#{last_pips}"
      socket.write(bits(pips)) if bits(pips) && last_pips == 0

      bin_window.show binary
      diff_window.show img_diff

      img_before = img_after
      capture.grab
      img_after = capture.retrieve

      exit if GUI.wait_key(interval)

    rescue
      socket.close
    end
  end
end
