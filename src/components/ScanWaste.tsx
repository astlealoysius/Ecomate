import React, { useState, useRef } from 'react';
import { scanWaste, validateImage } from '../services/wasteScanning';
import Webcam from 'react-webcam';
import '../styles/ScanWaste.css';

function ScanWaste() {
    const [error, setError] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [result, setResult] = useState<any>(null);
    const [useCamera, setUseCamera] = useState(false);
    const webcamRef = useRef<Webcam>(null);

    const handleImageSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        try {
            // Validate the image first
            validateImage(file);

            // Convert image to base64
            const reader = new FileReader();
            reader.onload = async (e) => {
                const base64Image = e.target?.result as string;
                await handleScan(base64Image);
            };
            reader.readAsDataURL(file);
        } catch (error) {
            setError((error as Error).message);
        }
    };

    const handleCameraCapture = async () => {
        if (webcamRef.current) {
            const imageSrc = webcamRef.current.getScreenshot();
            if (imageSrc) {
                await handleScan(imageSrc);
            }
        }
    };

    const handleScan = async (imageData: string) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await scanWaste(imageData);
            setResult(result);
            // Send result to chat context if needed
            if (window.sendToChatbot) {
                window.sendToChatbot(`Based on the scan, this waste is ${result.classification}`);
            }
        } catch (error) {
            setError('Unable to scan waste. Please try again or use the chat feature for assistance.');
            console.error('Scan error:', error);
        } finally {
            setIsLoading(false);
            setUseCamera(false);
        }
    };

    return (
        <div className="scan-waste-container">
            <h2>Waste Scanner</h2>
            <p>Upload an image or take a photo to classify the waste</p>
            
            <div className="input-options">
                <button 
                    className="option-button"
                    onClick={() => setUseCamera(!useCamera)}
                >
                    {useCamera ? 'Cancel Camera' : 'Use Camera'}
                </button>
                
                {!useCamera && (
                    <input
                        type="file"
                        accept="image/*"
                        onChange={handleImageSelect}
                        className="image-input"
                    />
                )}
            </div>

            {useCamera && (
                <div className="camera-container">
                    <Webcam
                        ref={webcamRef}
                        screenshotFormat="image/jpeg"
                        className="webcam"
                    />
                    <button 
                        onClick={handleCameraCapture}
                        className="capture-button"
                    >
                        Take Photo
                    </button>
                </div>
            )}

            {isLoading && (
                <div className="loading-indicator">
                    Analyzing image with AI...
                </div>
            )}

            {error && (
                <div className="error-message">
                    {error}
                    <button onClick={() => setError(null)}>Try Again</button>
                </div>
            )}

            {result && (
                <div className="result-container">
                    <h3>Classification Results:</h3>
                    <div className="classification-text">
                        {result.classification}
                    </div>
                    <div className="timestamp">
                        Scanned at: {new Date(result.timestamp).toLocaleString()}
                    </div>
                    <button 
                        className="chat-button"
                        onClick={() => {
                            if (window.openChatbot) {
                                window.openChatbot();
                            }
                        }}
                    >
                        Ask Questions in Chat
                    </button>
                </div>
            )}
        </div>
    );
}

export default ScanWaste; 