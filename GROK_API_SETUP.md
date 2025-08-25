# GROK API Integration Setup

## Overview
The AI Fitness Coach feature in Streaks Flutter is powered by GROK API from X.AI. The assistant provides personalized fitness advice on nutrition, workouts, recovery, and motivation.

## Setup Instructions

### 1. Get Your GROK API Key
1. Visit [X.AI API Portal](https://x.ai/api)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Generate a new API key
5. Copy the API key for use in the app

### 2. Configure the API Key
Open the file `/lib/config/api_config.dart` and replace the placeholder with your actual API key:

```dart
class ApiConfig {
  // Replace with your actual GROK API key
  static const String grokApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  ...
}
```

### 3. API Configuration Options
You can customize the AI behavior by modifying these settings in `api_config.dart`:

- **Model Selection**: Choose between available models
  - `grok-beta` (default)
  - `grok-2-latest` (more advanced)
  - `grok-2-mini` (faster, lighter)

- **Temperature** (0.0 - 1.0): Controls response creativity
  - Lower values (0.3-0.5): More focused, deterministic responses
  - Higher values (0.7-0.9): More creative, varied responses

- **Max Tokens**: Maximum length of AI responses (default: 500)

- **Top P**: Nucleus sampling parameter for response diversity (default: 0.9)

## Features

### System Prompt
The AI fitness coach is configured with a comprehensive system prompt that makes it:
- Expert in nutrition planning and macro tracking
- Knowledgeable about workout programming
- Supportive and motivational
- Evidence-based in recommendations
- Safety-conscious (always recommends professional help for medical issues)

### Context Awareness
The chat integrates with user data to provide personalized responses based on:
- User profile (age, height, weight, fitness goals)
- Current streak and progress
- Today's nutrition intake (calories, protein, carbs, fat)
- Daily nutrition goals
- Conversation history (last 10 messages)

### Fallback Responses
If the API is unavailable or not configured, the app provides helpful fallback responses for common fitness queries:
- Diet and nutrition advice
- Workout recommendations
- Weight loss tips
- Muscle building guidance
- Motivation and encouragement

## Security Considerations

### For Development
- The API key is currently stored in source code for development convenience
- Add `/lib/config/api_config.dart` to `.gitignore` if it contains real API keys

### For Production
Consider these security best practices:

1. **Environment Variables**
   ```bash
   flutter run --dart-define=GROK_API_KEY=your_api_key_here
   ```

2. **Secure Storage**
   - Use `flutter_secure_storage` package to store the API key encrypted
   - Allow users to input their own API key through settings

3. **Backend Proxy**
   - Create a backend service that holds the API key
   - App communicates with your backend, which then calls GROK API
   - This prevents exposing the API key in the client app

4. **Key Rotation**
   - Regularly rotate API keys
   - Implement key versioning

## Testing the Integration

1. Open the app and navigate to the "AI Coach" tab
2. You should see welcome messages from the fitness coach
3. Try asking questions like:
   - "How can I lose weight effectively?"
   - "What should I eat for muscle gain?"
   - "Create a workout plan for me"
   - "How do I stay motivated?"

4. The AI will provide personalized responses based on your profile and goals

## Troubleshooting

### API Key Not Working
- Verify the key is correctly copied without extra spaces
- Check if the key has proper permissions
- Ensure your X.AI account is active

### No Response from AI
- Check internet connectivity
- Verify the API endpoint is correct
- Look for error messages in console logs

### Rate Limiting
- The app handles rate limiting gracefully
- If you hit limits, responses will use fallback messages
- Consider implementing request queuing for production

## API Response Format
The GROK API returns responses in this format:
```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Your personalized fitness advice here..."
      }
    }
  ]
}
```

## Cost Considerations
- GROK API usage is billed based on tokens used
- Monitor your usage in the X.AI dashboard
- Consider implementing usage limits per user
- Cache frequent queries to reduce API calls

## Support
For API-related issues:
- X.AI Support: https://x.ai/support
- API Documentation: https://x.ai/api/docs

For app-related issues:
- Check the app logs for error messages
- Verify the integration in `/lib/services/grok_service.dart`
- Ensure all dependencies are properly installed