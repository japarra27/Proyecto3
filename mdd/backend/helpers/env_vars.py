import os
import json
from google.cloud import secretmanager

PROJECT_ID = "60612234253"
secret_id = "dsc-mdc-secrets"
version_id = "4"


def access_secret_version(secret_id=secret_id, version_id="latest"):
    # Create the Secret Manager client.
    client = secretmanager.SecretManagerServiceClient()

    # Build the resource name of the secret version.
    name = f"projects/{PROJECT_ID}/secrets/{secret_id}/versions/{version_id}"

    # Access the secret version.
    response = client.access_secret_version(name=name)

    # Return the decoded payload.
    return json.loads(response.payload.data.decode("UTF-8"))


def main():
    env_keys = access_secret_version(secret_id)
    for i in env_keys.keys():
        print(i)
        os.environ[i] = env_keys[i]


if __name__ == "__main__":
    main()