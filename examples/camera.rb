require 'rubygems'
require 'opencv'

module Examples
  class Camera
    include OpenCV

    def initialize(dev)
      @count = 0
      @device = dev
    end

    private def filename
      @count = @count.next
      "file-#{@count}.jpg"
    end

    private def device
      @device
    end

    # Streams video from `camera` and shows in `window`.
    # Saves the image to a file when `c` (for capture) is pressed.
    # Quits the program on `q`.
    # @param window [OpenCV::GUI::Window] window to display live image
    # @param camera [OpenCV::CvCapture] camera device
    def live_update_and_grab(window)
      while true
        device.grab
        window.show(img = device.retrieve)
        key = GUI.wait_key(33)
        if key == 'q'.ord
          break
        elsif key == 'c'.ord
          open(filename, 'wb') do |f|
            f.write img.encode('.jpg').pack("c*")
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  # 1 is (probably) the first external camera
  camera = Examples::Camera.new(OpenCV::CvCapture.open(1))

  camera.live_update_and_grab(OpenCV::GUI::Window.new("camera"))
end
