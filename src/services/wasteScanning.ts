import { GoogleGenerativeAI } from "@google/generative-ai";

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.NEXT_PUBLIC_GEMINI_API_KEY || '');

// Add error handling for the waste scanning service
export async function scanWaste(imageData: string) {
    try {
        // Convert base64 to Uint8Array for Gemini
        const imageBytes = base64ToBytes(imageData);

        // Initialize the model
        const model = genAI.getGenerativeModel({ model: "gemini-pro-vision" });

        // Create prompt for waste classification
        const prompt = `Analyze this image and provide:
            1. Waste Category: (Recyclable/Organic/Non-recyclable)
            2. Explanation: Why it belongs in this category
            3. Disposal Instructions: How to properly dispose of this item
            4. Environmental Impact: Brief impact if not disposed properly`;

        // Prepare the image part
        const imagePart = {
            inlineData: {
                data: imageBytes,
                mimeType: "image/jpeg"
            },
        };

        // Generate content
        const result = await model.generateContent([prompt, imagePart]);
        const response = await result.response;
        const text = response.text();

        return {
            classification: text,
            timestamp: new Date().toISOString()
        };

    } catch (error) {
        console.error('Gemini scanning error:', error);
        throw new Error('Failed to scan waste: ' + (error as Error).message);
    }
}

// Helper function to convert base64 to bytes
function base64ToBytes(base64: string): Uint8Array {
    // Remove data URL prefix if present
    const base64String = base64.split(',')[1] || base64;
    const binaryString = window.atob(base64String);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}

// Add retry logic
async function retryOperation(operation: () => Promise<any>, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await operation();
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            // Wait for 2^i * 1000 ms before retrying (exponential backoff)
            await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
            console.log(`Retry attempt ${i + 1} of ${maxRetries}`);
        }
    }
}

export function validateImage(file: File): boolean {
    // Check file type
    const validTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (!validTypes.includes(file.type)) {
        throw new Error('Invalid file type. Please upload a JPEG or PNG image.');
    }

    // Check file size (5MB limit)
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (file.size > maxSize) {
        throw new Error('File too large. Please upload an image smaller than 5MB.');
    }

    return true;
} 
} 