## About the JWT generator 

The JWT generator can be used to create [JSON Web Tokens (JWT)](https://auth0.com/docs/secure/tokens/json-web-tokens). A JWT is an open standard for securely sharing information between a client and your apps. JWTs are commonly used to support stateless, simple, scalable, and interoperable authentication and authorization flows.

## How to use the JWT generator? 

The JWT generator is a shell script that creates JWT tokens that are issued by `solo.io`. You can customize the token and set your own `sub`, `team`, and `llms` claims. The JWT header will now automatically include a randomly generated `kid` field that is unique to each token generation.

1. Download the [`create-jwt.sh`](create-jwt.sh) script.
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
   ./create-jwt.sh <private_key_path> <subject> <team> <llm> <model>
   ```
   * `<private_key_path>`: Private key that you created earlier, such as `private_key.pem`. 
   * `<subject>`: The `sub` claim that identifies the entity (usually a user) the JWT token refers to.
   * `<team>`: The team the subject belongs to.
   * `<llm>`: The LLM provider that the JWT token has access to, such as `openai` or `mistral`.
   * `<model>`: The LLM model the JWT has access to, such as `gpt-3.5-turbo`.
  
   Example command: 
   ```sh
   ./create-jwt.sh private_key.pem alice dev openai gpt-3.5-turbo
   ```

   Example JWT:
   ```
   eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyAiaXNzIjogInNvbG8uaW8iLCAib3JnIjogInNvbG8uaW8iLCAic3ViIjogImFsaWNlIiwgInRlYW0iOiAiZGV2IiwgImxsbXMiOiB7ICJvcGVuYWkiOiBbICJncHQtMy41LXR1cmJvIiBdIH0gfQ.I7whTti0aDKxlILc5uLK9oo6TljGS6JUrjPVd6z1PxzucUa_cnuKkY0qj_wrkzyVN5djy4t2ggE1uBO8Llpwi-Ygru9hM84-1m53aO07JYFya1VTDsI25tCRG8rYhShDdAP5L935SIARta2QtHhrVcd1Ae7yfTDZ8G1DXLtjR2QelszCd2R8PioCQmqJ8PeKg4sURhu05GlBCZoXES9-rtPVbe6j3YLBTodJAvLHhyy3LgV_QbN7IiZ5qEywdKHoEF4D4aCUf_LqPp4NoqHXnGT4jLzWJEtZXHQ4sgRy_5T93NOLzWLdIjgMjGO_F0aVLwBzU-phykOVfcBPaMvetg
   ```

5. Review your JWT.
   1. Go to the [jwt.io](https://jwt.io/) site.
   2. Paste your JWT into the **Encoded** box.
   3. Review the JWT claims in the **Decoded** section.
  
   <img width="1225" alt="image" src="https://github.com/user-attachments/assets/7a57a156-3455-47c3-b5a3-5acb840307c8">


   
   
