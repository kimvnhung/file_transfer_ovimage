import QtQuick
import QtMultimedia
import QtQuick.Controls

Rectangle {
    id: ocrCamera
    color: "black"
    
    property alias camera: camera
    property bool isCapturing: false
    property string recognizedText: ""
    
    signal textRecognized(string text)
    signal captureError(string error)
    
    Camera {
        id: camera
        active: true
        
        focusMode: Camera.FocusModeAutoNear
        exposureMode: Camera.ExposureAuto
        
        onErrorOccurred: function(error, errorString) {
            console.error("Camera error:", errorString)
            captureError(errorString)
        }
    }
    
    CaptureSession {
        id: captureSession
        camera: camera
        videoOutput: viewfinder
        imageCapture: imageCapture
    }
    
    VideoOutput {
        id: viewfinder
        anchors.fill: parent
        
        // OCR scanning overlay
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.3
            color: "transparent"
            border.color: isCapturing ? "#00ff00" : "#ffffff"
            border.width: 2
            radius: 8
            
            Text {
                anchors.top: parent.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                text: isCapturing ? "Scanning..." : "Align text within frame"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                style: Text.Outline
                styleColor: "black"
            }
        }
        
        // Recognized text overlay
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 120
            color: "#80000000"
            visible: recognizedText.length > 0
            
            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentHeight: textDisplay.height
                clip: true
                
                Text {
                    id: textDisplay
                    width: parent.width
                    text: recognizedText
                    color: "white"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
                
                ScrollBar.vertical: ScrollBar {}
            }
            
            // Copy button
            Button {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                text: "📋 Copy"
                
                onClicked: {
                    // Copy to clipboard
                    Qt.application.clipboard.text = recognizedText
                }
            }
        }
    }
    
    ImageCapture {
        id: imageCapture
        
        onImageCaptured: function(requestId, preview) {
            console.log("Image captured, processing OCR...")
            isCapturing = true
            
            // Process OCR on the captured image
            ocrProcessor.recognizeImage(preview)
        }
        
        onErrorOccurred: function(requestId, error, message) {
            console.error("Capture error:", message)
            isCapturing = false
            captureError(message)
        }
    }
    
    // OCR Processor (connects to C++ TesseractOCR)
    Item {
        id: ocrProcessor
        
        function recognizeImage(image) {
            // This will be connected to the C++ TesseractOCR instance
            if (typeof tesseractOCR !== 'undefined') {
                var text = tesseractOCR.recognizeText(image)
                handleRecognizedText(text)
            } else {
                console.error("TesseractOCR not available")
                isCapturing = false
            }
        }
        
        function handleRecognizedText(text) {
            recognizedText = text.trim()
            textRecognized(recognizedText)
            isCapturing = false
            
            console.log("OCR Result:", recognizedText)
        }
    }
    
    // Public methods
    function captureAndRecognize() {
        if (!isCapturing) {
            imageCapture.captureToFile("")
        }
    }
    
    function clearText() {
        recognizedText = ""
    }
    
    function startCamera() {
        camera.start()
    }
    
    function stopCamera() {
        camera.stop()
    }
}
