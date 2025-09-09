#!/usr/bin/env python3
"""
LlamaStack inference test script.

This script tests the LlamaStack deployment by:
1. Creating a LlamaStack client
2. Registering a model
3. Listing models
4. Performing a chat completion
"""

import sys

from llama_stack_client import LlamaStackClient  # type: ignore[import-untyped]


def main():
    """Main function to execute the LlamaStack inference test."""
    try:
        # Create client with the service URL
        service_url = "http://llamastack-custom-distribution-service.llamastack.svc.cluster.local:8321"
        client = LlamaStackClient(base_url=service_url)

        # Register the model
        client.models.register(provider_id="vllm-inference", model_type="llm", model_id="llama-3-2-3b-instruct")

        # List models to verify registration
        models = client.models.list()
        print("Models:", models)

        # Perform chat completion
        response = client.inference.chat_completion(
            messages=[
                {"role": "system", "content": "You are a friendly assistant."},
                {"role": "user", "content": "Write a two-sentence poem about llama."},
            ],
            model_id="llama-3-2-3b-instruct",
        )

        # Validate and print the response
        content = None
        if hasattr(response, "completion_message") and hasattr(response.completion_message, "content"):
            content = response.completion_message.content
        elif isinstance(response, dict):
            cm = response.get("completion_message") or {}
            if isinstance(cm, dict):
                content = cm.get("content")
        if not content:
            print("Empty completion from LlamaStack.", file=sys.stderr)
            sys.exit(2)
        print(content)

        print("LlamaStack inference test completed successfully!")

    except Exception as e:
        print(f"Error during LlamaStack inference test: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
