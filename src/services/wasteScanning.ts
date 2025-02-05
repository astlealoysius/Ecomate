// Add error handling for the waste scanning service
async function scanWaste(imageData: string) {
    try {
        const response = await fetch('/api/scan-waste', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ image: imageData })
        });

        if (!response.ok) {
            const errorData = await response.json();
            if (errorData.error.code === 500) {
                // Implement retry logic
                return await retryOperation(() => scanWaste(imageData));
            }
            throw new Error(errorData.message || 'Scanning failed');
        }

        return await response.json();
    } catch (error) {
        throw new Error('Failed to scan waste: ' + error.message);
    }
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
        }
    }
} 