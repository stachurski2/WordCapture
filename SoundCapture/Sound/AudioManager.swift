import CoreAudio
import AVFoundation
import Speech

protocol AudioManaging {
    func catchStream()
    var isListening: Bool { get }
    var stringCompletion: ((String) -> ())? { get set }
    
}

class AudioManager: NSObject, AudioManaging {
    
    var stringCompletion: ((String) -> ())? = nil
    
    private var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private let captureSession = AVCaptureSession()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let kDeviceName = "Soundflower (2ch)"
    private var captureDevices:[AVCaptureDevice]
    
    var isListening: Bool = false

    override init() {
        captureDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone],
                                                          mediaType: .audio,
                                                          position: .unspecified).devices
        
        super.init()
        
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
          if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
          } else {
            print("not authorized")
          }
        }
    }
    
    func catchStream() {
        let queue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
        var audioInput : AVCaptureDeviceInput? = nil
        var audioOutput : AVCaptureAudioDataOutput? = nil

        do {
            guard let device = captureDevices.first(where: { $0.localizedName == kDeviceName }) else {
                return
            }
            try device.lockForConfiguration()
            audioInput = try AVCaptureDeviceInput(device: device)
            device.unlockForConfiguration()
            audioOutput = AVCaptureAudioDataOutput()
            audioOutput?.setSampleBufferDelegate(self, queue: queue)
        } catch {
            print("Capture devices could not be set")
            print(error.localizedDescription)
        }

        if audioInput != nil && audioOutput != nil {
            captureSession.beginConfiguration()
            if (captureSession.canAddInput(audioInput!)) {
                captureSession.addInput(audioInput!)
            } else {
                print("cannot add input")
            }
            if (captureSession.canAddOutput(audioOutput!)) {
                captureSession.addOutput(audioOutput!)
            } else {
                print("cannot add output")
            }
            captureSession.commitConfiguration()
            }
            print("Starting capture session")
        
            startDictation()
           
        }
        
        private func startDictation() {
            captureSession.startRunning()
            speechRecognizer?.recognitionTask(with: self.recognitionRequest, delegate: self)
            isListening = true
        }
    
        private func endDictation() {
            captureSession.stopRunning()
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            speechRecognizer?.queue = OperationQueue()
            isListening = false
        }

    
}

extension AudioManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)
        let mediaType = CMFormatDescriptionGetMediaType(formatDesc!)
        if mediaType == kCMMediaType_Audio {
            recognitionRequest.appendAudioSampleBuffer(sampleBuffer)
        }
    }
}

extension AudioManager: SFSpeechRecognitionTaskDelegate {

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        stringCompletion?(transcription.formattedString)
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        endDictation()
        startDictation()
    }

}



