import Foundation
import Dispatch
import Rainbow
import Signals

public final class Spinner {

    /// Pattern holding frames to be animated    
    var pattern: SpinnerPattern {
        didSet {
            self.frameIndex = 0
        }
    }
    /// Text that is  displayed next to spinner
    var text: String
    /// Boolean repersenting fs the spinner is currently animating
    var running: Bool
    /// Int repersenitng the current frame
    var frameIndex: Int
    /// Double repsenting the wait time for frame animation
    var speed: Double
    /// Dispatch queue that the spinner will run within
    var queue: DispatchQueue
    /// Color of the spinner
    var color: Color

    public init(_ pattern: SpinnerPattern, _ text: String = "", speed: Double? = nil, color: Color = .white) {
        self.pattern = pattern
        self.text = text
        self.speed = speed ?? pattern.defaultSpeed
        self.color = color

        self.frameIndex = 0
        self.running = false
        self.queue = DispatchQueue(label: "io.Swift.Spinner")

        Signals.trap(signal: .int) { _ in
            print("\u{001B}[?25h", terminator: "")
            exit(0)
        }
    }

    /**
    Starts the animation for the spinner.
    */
    public func start() {
        self.hideCursor()
        self.running = true
        self.queue.async { [weak self] in

            guard let `self` = self else { return }

            while self.running {
                self.renderSpinner()
                self.sleep(seconds: self.speed)
            }
        }
    }

    /**
    Stops the animation for the spinner.

    - Parameter finalFrame: The persistant frame that will be dispalyed on the compleed spinner, defult is 'nil' this will keep the current frame the spinner is on
    - Parameter text: The persistant text that will be dispalyed on the compleed spinner, defult is 'nil' this will keep the current text the spinner has
    - Parameter terminator: The terminator used for ending writing a line to the terminal, defult is '\n' this will return the curser to a new line
    */
    public func stop(finalFrame: String? = nil, text: String? = nil, terminator: String = "\n") {
        self.stopSpinner(finalFrame: finalFrame, text: text, terminator: terminator)
    }

    /**
    Clears the spinner from the terminal and returns the curser to the start of the spinner
    */
    public func clear() {
        self.stopSpinner(finalFrame: "", text: "", terminator: "\r")
    }

    /**
    Updates the pattern dispalyed by the spinner
    */
    public func updatePattern(_ newPattern: SpinnerPattern) {
        self.setPattern(newPattern)
    }

    /**
    Updates the text dispalyed next to the spinner
    */
    public func updateText(_ newText: String) {
        self.setText(newText)
    }

    /**
    Updates the speed of the spinner
    */
    public func updateSpeed(_ newSpeed: Double) {
        self.setSpeed(newSpeed)
    } 


    public func updateColor(_ newColor: Color) {
        self.setColor(newColor)
    }
    /**
    Stops the spinner and displays a green ✔ witht the provied text

   - Parameter text: The persistant text that will be dispalyed on the compleed spinner
    */
    public func succeed(_ text: String? = nil) {
        self.stopSpinner(finalFrame: "✔".green, text: text)
    }

    /**
    Stops the spinner and displays a red ✖ witht the provied text

    - Parameter text: The persistant text that will be dispalyed on the compleed spinner
    */
    public func failure(_ text: String? = nil) {
        self.stopSpinner(finalFrame: "✖".red, text: text)
    }

    /**
    Stops the spinner and displays a yellow ⚠ witht the provied text

    - Parameter text: The persistant text that will be dispalyed on the compleed spinner
    */
    public func warning(_ text: String? = nil) {
        self.stopSpinner(finalFrame: "⚠".yellow, text: text)
    }

    /**
    Stops the spinner and displays a blue ℹ witht the provied text

    - Parameter text: The persistant text that will be dispalyed on the compleed spinner
    */
    public func information(_ text: String? = nil) {
        self.stopSpinner(finalFrame: "ℹ".blue, text: text)
    }

    func stopSpinner(finalFrame: String? = nil, text: String? = nil, terminator: String = "\n") {
        if let text = text {
            setText(text)
        }
        var finalPattern: SpinnerPattern?
        if let frame = finalFrame {
            finalPattern = SpinnerPattern(singleFrame: frame)
        }
        if let pattern = finalPattern {
            self.text += Array(repeating: " ", count: self.getPatternPadding(pattern))
            self.pattern = pattern
        }
        self.running = false
        self.unhideCursor()
        self.renderSpinner()
        print(terminator: terminator)
    }

    func setColor(_ newColor: Color) {
        self.color = newColor
    }

    func setPattern(_ newPattern: SpinnerPattern) {
        self.text += Array(repeating: " ", count: self.getPatternPadding(newPattern))
        self.pattern = newPattern
    }

    func setSpeed(_ newSpeed: Double) {
        self.speed = newSpeed
    }

    func setText(_ newString: String) {

        let newText = Rainbow.extractModes(for: newString)
        let oldText = Rainbow.extractModes(for: self.text)

        let textLengthDifferance: Int = oldText.text.count - newText.text.count
        
        if textLengthDifferance > 0 {
            self.text = newString
            self.text += Array(repeating: " ", count: textLengthDifferance)
        } else {
            self.text = newString
        }
    }

    func getPatternPadding(_ newPattern: SpinnerPattern) -> Int {
        
        let newPatternFrameWidth: Int = Rainbow.extractModes(for: newPattern.frames[0]).text.count
        let oldPatternFrameWidth: Int = Rainbow.extractModes(for: self.pattern.frames[0]).text.count

        let patternFrameWidthDifferance: Int = oldPatternFrameWidth - newPatternFrameWidth

        if patternFrameWidthDifferance > 0 {
            return patternFrameWidthDifferance
        }else {
            return 0
        }
    }

    func sleep(seconds: Double) {
        usleep(useconds_t(seconds * 1_000_000))
    }

    func currentFrame() -> String {

        let currentFrame = self.pattern.frames[self.frameIndex].applyingCodes(self.color)

        self.frameIndex = (self.frameIndex + 1) % self.pattern.frames.count

        return currentFrame
    }

    func renderSpinner() {

        // Reset cursor to start of line
        print("\r", terminator: "")
        // Print the spinner frame and text
        print("\(self.currentFrame()) \(self.text)", terminator: "")
        // Flush STDOUT
        fflush(stdout)

    }

    func hideCursor() {
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)
    }
    
    func unhideCursor() {
        print("\u{001B}[?25h", terminator: "")
        fflush(stdout)
    }

}
