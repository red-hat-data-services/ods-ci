#!/usr/bin/env python3
"""
LlamaStack inference test script.

This script tests the LlamaStack deployment by:
1. Creating a LlamaStack client
2. Registering a model
3. Listing models
4. Performing a chat completion
"""

import os
import sys


def main():
    """Main function to execute the LlamaStack inference test."""
    try:
        # Import LlamaStack client components
        from llama_stack_client import Agent, AgentEventLogger, RAGDocument, LlamaStackClient
        
        # Create client with the service URL
        client = LlamaStackClient(base_url="http://llamastack-custom-distribution-service.llamastack.svc.cluster.local:8321")
        
        # Register the model
        client.models.register(provider_id="vllm-inference", model_type="llm", model_id="llama-3-2-3b-instruct")
        
        # List models to verify registration
        models = client.models.list()
        print('Models:', models)
        
        # Perform chat completion
        response = client.inference.chat_completion(
            messages=[
                {"role": "system", "content": "You are a friendly assistant."},
                {"role": "user", "content": "Write a two-sentence poem about llama."}
            ],
            model_id='llama-3-2-3b-instruct',
        )
        
        # Print the response
        print(response.completion_message.content)
        
        print("LlamaStack inference test completed successfully!")
        
    except Exception as e:
        print(f"Error during LlamaStack inference test: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()