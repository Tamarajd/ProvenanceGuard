# ProvenanceGuard: AI-Powered NFT Tracking Protocol

## Overview

I have developed **ProvenanceGuard**, a sophisticated smart contract protocol written in Clarity for the Stacks blockchain. This system addresses the growing need for transparency, authenticity, and historical integrity in the digital asset ecosystem. By integrating AI model attributions and dynamic authenticity scoring directly into the on-chain metadata, ProvenanceGuard ensures that every transfer is not just a change of ownership, but a verified event in a comprehensive chain of custody.

The protocol moves beyond static NFT metadata by introducing a living provenance record. This record evolves through AI-powered fraud detection, authorized manual verifications, and cryptographic transfer hashing, providing marketplaces and collectors with a "trust-less" way to verify the legitimacy of high-value digital assets.

---

## Technical Architecture & Data Strategy

I have designed the contract with a highly relational structure using Clarity's `data-maps` to ensure efficient lookups and gas optimization. The architecture separates active provenance from historical audit trails.

### Core Data Structures

| Map Name | Purpose | Key Components |
| --- | --- | --- |
| `nft-provenance` | Current state of an asset | Owner, Score, AI Model ID, Flags |
| `ownership-history` | Historical audit trail | To/From addresses, Price, Verification Hash |
| `ai-models` | Registry of trusted AI engines | Model Name, Version, Confidence Level |
| `authorized-verifiers` | Permission management | Principal address, Authorization status |

### The Dynamic Authenticity Formula

I implemented a weighted calculation to determine the updated authenticity score during transfers. This formula balances the inherent reliability of the AI model with the asset's historical verification score:

---

## Detailed Function Documentation

### Private Functions

*These functions are internal utility methods used to ensure data integrity and security across the protocol.*

* **`is-valid-authenticity-score`**: Validates that any submitted score falls within the range of  to .
* **`is-authorized-verifier`**: Performs a lookup against the `authorized-verifiers` map to confirm if the caller has the permissions to modify asset scores.
* **`is-valid-ai-model`**: Checks if an AI model ID exists in the registry and is currently marked as `is-active`.
* **`calculate-weighted-authenticity`**: The mathematical core of the contract. It executes the weighted average calculation to adjust scores dynamically during ownership changes.

### Public Functions (Write Operations)

#### `register-ai-model`

Registers a new AI model into the ecosystem.

* **Access Control**: `CONTRACT-OWNER` only.
* **Logic**: It ensures the model ID is unique and the base confidence level meets the `MIN-AI-CONFIDENCE` threshold ().
* **Parameters**: `model-id` (string), `model-name` (string), `version` (string), `confidence-level` (uint).

#### `register-nft`

The initialization function for an asset. It creates the primary provenance entry.

* **Logic**: Verifies the AI model exists, checks the initial score, and sets the `creation-timestamp` using the current `block-height`.
* **Parameters**: `nft-id` (uint), `ai-model-id` (string), `authenticity-score` (uint).

#### `authorize-verifier`

Grants administrative permissions to a specific blockchain address.

* **Access Control**: `CONTRACT-OWNER` only.
* **Parameters**: `verifier` (principal).

#### `update-authenticity-score`

Allows specialized verifiers to update an NFT's score after manual forensic analysis.

* **Access Control**: Authorized verifiers only.
* **Logic**: Fetches current provenance, merges the new score, and updates the `last-verified` timestamp to the current block.

#### `transfer-nft-with-provenance`

The flagship function of the protocol. It handles asset movement while performing high-level validation.

1. **Authorization**: Asserts that `tx-sender` is the current owner.
2. **Safety Check**: Blocks the transfer if `is-flagged` is true.
3. **AI Validation**: Re-calculates the weighted authenticity score. If the new score drops below the  threshold, the transfer fails to prevent the spread of fraudulent assets.
4. **Logging**: Records the transaction price and a cryptographic `verification-hash` in the `ownership-history` map.

---

## Installation & Deployment

### Prerequisites

* [Clarinet](https://github.com/hirosystems/clarinet) installed for local testing.
* A Stacks wallet with STX for deployment.

### Steps

1. **Clone the repository:**
```bash
git clone https://github.com/your-repo/ProvenanceGuard.git
cd ProvenanceGuard

```


2. **Check the contract syntax:**
```bash
clarinet check

```


3. **Run unit tests:**
```bash
clarinet test

```



---

## License

**The MIT License (MIT)**

Copyright (c) 2026 ProvenanceGuard Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---
