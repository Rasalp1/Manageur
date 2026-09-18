# Security policy

Manageur is a local-first inventory application. Its records are plain JSON files on the selected local storage volume; it is not a password manager or encrypted vault. Do not store passwords, API keys, recovery codes, or other secrets in service notes.

When a service logo is not cached, Manageur may request the service domain from Google or DuckDuckGo to retrieve a favicon. No credentials or other inventory fields are sent.

Workspace and service filenames are treated as path components and rejected if they contain traversal, separators, or control characters. Logo lookups accept DNS-style domains only; arbitrary URLs and paths are not fetched.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting for this repository when it is enabled. Do not disclose sensitive records or exploit details in a public issue. Include the affected version or commit, reproduction steps, impact, and a minimal safe proof of concept.
