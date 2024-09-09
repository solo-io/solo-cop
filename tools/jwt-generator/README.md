## About the JWT generator 

The JWT generator can be used to create [JSON Web Tokens (JWT)](https://auth0.com/docs/secure/tokens/json-web-tokens). A JWT is an open standard for securely sharing information between a client and your apps. JWTs are commonly used to support stateless, simple, scalable, and interoperable authentication and authorization flows.

## How to use the JWT generator? 

The JWT generator is a shell script that creates JWT tokens that are issued by `solo.io`. You can customize the token and set your own `sub`, `team`, and `llms` claims. 

1. Download the [`create-jwt.sh`](../create-jwt.sh) script.
2. Make the script executable.
   ```sh
   chmod +x create-jwt.sh
   ``` 

3. Create a private key to allow verification of the JWT. 
   ```sh
   openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out private_key.pem
   ```

4. Run the JWT generator. The command requires the following values: 
   ```sh
   ./create_jwt.sh <private_key_path> <subject> <team> <llm> <model>
   ```
   * `<private_key_path>`: Private key that you created earlier, such as `private_key.pem`. 
   * `<subject>`: The `sub` claim that identifies the entity (usually a user) the JWT token refers to.
   * `<team>`: The team the subject belongs to.
   * `<llm>`: The LLM provider that the JWT token has access to, such as `openai` or `mistral`
   * `<model>`: The LLM model the JWT has access to, such as `gpt-3.5-turbo`.
  
   Example command: 
   ```sh
   ./create_jwt.sh private_key.pem alice dev openai gpt-3.5-turbo
   ``` 
   
