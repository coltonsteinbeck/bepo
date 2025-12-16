import { OpenAI } from "openai";
import dotenv from "dotenv";

dotenv.config();

// Initialize clients
const xAI = new OpenAI({
  apiKey: process.env.xAI_KEY,
  baseURL: "https://api.x.ai/v1",
});

const geminiAI = new OpenAI({
  apiKey: process.env.GEMINI_KEY,
  baseURL: "https://generativelanguage.googleapis.com/v1alpha/openai/",
});

const openAI = new OpenAI({
  apiKey: process.env.OPENAI_KEY,
});

/**
 * Generates an image based on the prompt and provider.
 * @param {Object} options
 * @param {string} options.prompt - The image description.
 * @param {string} options.provider - 'grok', 'gemini', or 'gpt-image-1.5'.
 * @param {string} [options.referenceImageUrl] - URL of a reference image (Gemini and GPT Image 1.5).
 * @returns {Promise<{buffer: Buffer, modelUsed: string}>} The generated image buffer and model used.
 */
export async function generateImage({ prompt, provider, referenceImageUrl }) {
  if (provider === "gemini") {
    const buffer = await generateWithGemini(prompt, referenceImageUrl);
    return { buffer, modelUsed: "Nano Banana Pro" };
  } else if (provider === "gpt-image-1.5") {
    return generateWithGPTImage(prompt, referenceImageUrl);
  } else {
    const buffer = await generateWithGrok(prompt);
    return { buffer, modelUsed: "Grok" };
  }
}

async function generateWithGPTImage(prompt, referenceImageUrl) {
  console.log(`[ImageGen] Generating with GPT Image: ${prompt}`);
  
  // Note: Reference images not yet supported by GPT Image models
  if (referenceImageUrl) {
    console.warn("[ImageGen] Reference images not yet supported by GPT Image, ignoring reference");
  }

  const models = ["gpt-image-1.5", "gpt-image-1"];
  
  for (const model of models) {
    try {
      console.log(`[ImageGen] Trying model: ${model}`);
      
      const response = await openAI.images.generate({
        model: model,
        prompt: prompt,
        n: 1,
        size: "1024x1024"
      });

      // Fetch the image from the returned URL
      if (response.data && response.data[0] && (response.data[0].url || response.data[0].b64_json)) {
        console.log(`[ImageGen] Successfully generated image with ${model}`);
        const modelDisplayName = model === "gpt-image-1.5" ? "GPT Image 1.5" : "GPT Image 1";
        if (response.data[0].url) {
          const imgResult = await fetch(response.data[0].url);
          const arrayBuffer = await imgResult.arrayBuffer();
          return { buffer: Buffer.from(arrayBuffer), modelUsed: modelDisplayName };
        } else {
          return { buffer: Buffer.from(response.data[0].b64_json, "base64"), modelUsed: modelDisplayName };
        }
      }
    } catch (error) {
      console.warn(`[ImageGen] Model ${model} failed: ${error.message}`);
      // If this isn't the last model, continue to next
      if (model !== models[models.length - 1]) {
        console.log(`[ImageGen] Falling back to next model...`);
        continue;
      }
      // Last model failed, throw the error
      throw error;
    }
  }
  
  throw new Error("No image data returned from GPT Image");
}

async function generateWithGrok(prompt) {
  console.log(`[ImageGen] Generating with Grok: ${prompt}`);
  
  const response = await xAI.images.generate({
    prompt,
    model: "grok-2-image",
    response_format: "b64_json",
    // size: "1024x1024", // Grok doesn't support size argument yet
  });

  const b64Data = response.data[0].b64_json;
  if (b64Data) {
    return Buffer.from(b64Data, "base64");
  } else if (response.data[0].url) {
    // Fallback if b64 not returned
    const imgResult = await fetch(response.data[0].url);
    const arrayBuffer = await imgResult.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }
  
  throw new Error("No image data returned from Grok");
}

async function generateWithGemini(prompt, referenceImageUrl) {
  console.log(`[ImageGen] Generating with Nano Banana Pro (Gemini): ${prompt}`);
  
  let finalPrompt = prompt;

  // If reference image is provided, use Gemini Vision to describe it and enhance the prompt
  if (referenceImageUrl) {
    console.log(`[ImageGen] Processing reference image: ${referenceImageUrl}`);
    try {
      const description = await describeImage(referenceImageUrl);
      finalPrompt = `Create an image based on this description: ${description}. \n\nAdditional User Request: ${prompt}`;
      console.log(`[ImageGen] Enhanced prompt: ${finalPrompt}`);
    } catch (error) {
      console.warn("[ImageGen] Failed to process reference image, proceeding with raw prompt:", error);
    }
  }

  // Use Gemini 3 Pro Image Preview via native fetch
  return generateWithGeminiNative(finalPrompt);
}

async function generateWithGeminiNative(prompt) {
  const API_KEY = process.env.GEMINI_KEY;
  const BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
  const url = `${BASE_URL}/models/gemini-3-pro-image-preview:generateContent?key=${API_KEY}`;
  
  const body = {
    contents: [{
      parts: [{ text: prompt }]
    }]
  };

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  
  const data = await response.json();
  
  if (!response.ok) {
    throw new Error(`Gemini API Error: ${data.error?.message || response.statusText}`);
  }

  const part = data.candidates?.[0]?.content?.parts?.[0];
  if (part?.inlineData?.data) {
    return Buffer.from(part.inlineData.data, "base64");
  }
  
  throw new Error("No image data returned from Gemini 3 Pro");
}

async function describeImage(imageUrl) {
  // Use Nano Banana Pro for vision
  // Note: OpenAI compatibility layer for Gemini Vision might require specific format
  // or might not support image_url directly in the way OpenAI does for all models.
  // Let's try using the native fetch approach for vision as well to be safe.
  
  const API_KEY = process.env.GEMINI_KEY;
  const BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
  const url = `${BASE_URL}/models/nano-banana-pro-preview:generateContent?key=${API_KEY}`;
  
  // Fetch the image first to convert to base64
  const imageResponse = await fetch(imageUrl);
  const arrayBuffer = await imageResponse.arrayBuffer();
  const base64Image = Buffer.from(arrayBuffer).toString("base64");
  const mimeType = imageResponse.headers.get("content-type") || "image/jpeg";

  const body = {
    contents: [{
      parts: [
        { text: "Describe this image in great detail, focusing on style, composition, colors, and subject matter. This description will be used to generate a similar image." },
        {
          inlineData: {
            mimeType: mimeType,
            data: base64Image
          }
        }
      ]
    }]
  };

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  
  const data = await response.json();
  
  if (!response.ok) {
    throw new Error(`Gemini Vision API Error: ${data.error?.message || response.statusText}`);
  }

  return data.candidates?.[0]?.content?.parts?.[0]?.text || "A reference image";
}
