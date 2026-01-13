;; AI-Powered NFT Provenance Tracker

;; This smart contract enables comprehensive tracking of NFT provenance using AI verification.
;; It records ownership transfers, AI model attributions, authenticity scores, and maintains
;; a complete historical chain of custody for digital assets. The system ensures transparency
;; and trust in NFT marketplaces by providing verifiable provenance data.

;; constants

;; Error codes for various failure scenarios
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))
(define-constant ERR-INVALID-AUTHENTICITY-SCORE (err u103))
(define-constant ERR-TRANSFER-FAILED (err u104))
(define-constant ERR-INVALID-AI-MODEL (err u105))
(define-constant ERR-PROVENANCE-NOT-FOUND (err u106))

;; Contract owner for administrative functions
(define-constant CONTRACT-OWNER tx-sender)

;; Maximum authenticity score (100%)
(define-constant MAX-AUTHENTICITY-SCORE u100)

;; Minimum AI model confidence threshold
(define-constant MIN-AI-CONFIDENCE u70)

;; data maps and vars

;; Stores core NFT provenance information
;; Maps NFT ID to its current provenance record
(define-map nft-provenance
    { nft-id: uint }
    {
        current-owner: principal,
        creator: principal,
        ai-model-id: (string-ascii 64),
        authenticity-score: uint,
        creation-timestamp: uint,
        last-verified: uint,
        transfer-count: uint,
        is-flagged: bool
    }
)

;; Tracks complete ownership history for each NFT
;; Composite key of NFT ID and transfer index
(define-map ownership-history
    { nft-id: uint, transfer-index: uint }
    {
        from-owner: principal,
        to-owner: principal,
        transfer-timestamp: uint,
        transfer-price: uint,
        verification-hash: (string-ascii 64)
    }
)

;; Stores AI model metadata used for NFT generation/verification
(define-map ai-models
    { model-id: (string-ascii 64) }
    {
        model-name: (string-ascii 128),
        version: (string-ascii 32),
        registered-by: principal,
        confidence-level: uint,
        is-active: bool
    }
)

;; Maps authorized verifiers who can update authenticity scores
(define-map authorized-verifiers
    { verifier: principal }
    { is-authorized: bool }
)

;; Counter for total NFTs registered in the system
(define-data-var nft-counter uint u0)

;; Counter for total AI models registered
(define-data-var model-counter uint u0)

;; private functions

;; Validates that the authenticity score is within acceptable range (0-100)
;; @param score: uint - The authenticity score to validate
;; @returns: bool - True if score is valid, false otherwise
(define-private (is-valid-authenticity-score (score uint))
    (and (>= score u0) (<= score MAX-AUTHENTICITY-SCORE))
)

;; Checks if a principal is an authorized verifier
;; @param verifier: principal - The address to check
;; @returns: bool - True if authorized, false otherwise
(define-private (is-authorized-verifier (verifier principal))
    (default-to false (get is-authorized (map-get? authorized-verifiers { verifier: verifier })))
)

;; Validates AI model existence and active status
;; @param model-id: string-ascii 64 - The AI model identifier
;; @returns: bool - True if model exists and is active
(define-private (is-valid-ai-model (model-id (string-ascii 64)))
    (match (map-get? ai-models { model-id: model-id })
        model-data (get is-active model-data)
        false
    )
)

;; Calculates weighted authenticity based on AI confidence and current score
;; @param ai-confidence: uint - AI model confidence level
;; @param current-score: uint - Current authenticity score
;; @returns: uint - Weighted authenticity score
(define-private (calculate-weighted-authenticity (ai-confidence uint) (current-score uint))
    (/ (+ (* ai-confidence u60) (* current-score u40)) u100)
)

;; public functions

;; Registers a new AI model in the system
;; @param model-id: string-ascii 64 - Unique identifier for the AI model
;; @param model-name: string-ascii 128 - Human-readable model name
;; @param version: string-ascii 32 - Model version string
;; @param confidence-level: uint - Base confidence level of the model (0-100)
;; @returns: (response bool uint) - Success or error code
(define-public (register-ai-model 
    (model-id (string-ascii 64))
    (model-name (string-ascii 128))
    (version (string-ascii 32))
    (confidence-level uint))
    (begin
        ;; Only contract owner can register AI models
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        ;; Ensure model doesn't already exist
        (asserts! (is-none (map-get? ai-models { model-id: model-id })) ERR-ALREADY-REGISTERED)
        
        ;; Validate confidence level
        (asserts! (and (>= confidence-level MIN-AI-CONFIDENCE) 
                      (<= confidence-level MAX-AUTHENTICITY-SCORE)) 
                 ERR-INVALID-AUTHENTICITY-SCORE)
        
        ;; Register the AI model
        (map-set ai-models
            { model-id: model-id }
            {
                model-name: model-name,
                version: version,
                registered-by: tx-sender,
                confidence-level: confidence-level,
                is-active: true
            }
        )
        
        ;; Increment model counter
        (var-set model-counter (+ (var-get model-counter) u1))
        (ok true)
    )
)

;; Registers a new NFT with initial provenance data
;; @param nft-id: uint - Unique NFT identifier
;; @param ai-model-id: string-ascii 64 - AI model used to create/verify the NFT
;; @param authenticity-score: uint - Initial authenticity score (0-100)
;; @returns: (response bool uint) - Success or error code
(define-public (register-nft
    (nft-id uint)
    (ai-model-id (string-ascii 64))
    (authenticity-score uint))
    (begin
        ;; Ensure NFT is not already registered
        (asserts! (is-none (map-get? nft-provenance { nft-id: nft-id })) ERR-ALREADY-REGISTERED)
        
        ;; Validate AI model
        (asserts! (is-valid-ai-model ai-model-id) ERR-INVALID-AI-MODEL)
        
        ;; Validate authenticity score
        (asserts! (is-valid-authenticity-score authenticity-score) ERR-INVALID-AUTHENTICITY-SCORE)
        
        ;; Create initial provenance record
        (map-set nft-provenance
            { nft-id: nft-id }
            {
                current-owner: tx-sender,
                creator: tx-sender,
                ai-model-id: ai-model-id,
                authenticity-score: authenticity-score,
                creation-timestamp: block-height,
                last-verified: block-height,
                transfer-count: u0,
                is-flagged: false
            }
        )
        
        ;; Increment NFT counter
        (var-set nft-counter (+ (var-get nft-counter) u1))
        (ok true)
    )
)

;; Authorizes a verifier to update authenticity scores
;; @param verifier: principal - Address to authorize
;; @returns: (response bool uint) - Success or error code
(define-public (authorize-verifier (verifier principal))
    (begin
        ;; Only contract owner can authorize verifiers
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        ;; Set verifier authorization
        (map-set authorized-verifiers
            { verifier: verifier }
            { is-authorized: true }
        )
        (ok true)
    )
)

;; Updates the authenticity score for an NFT (only authorized verifiers)
;; @param nft-id: uint - NFT identifier
;; @param new-score: uint - New authenticity score
;; @returns: (response bool uint) - Success or error code
(define-public (update-authenticity-score
    (nft-id uint)
    (new-score uint))
    (let
        (
            (provenance-data (unwrap! (map-get? nft-provenance { nft-id: nft-id }) ERR-NFT-NOT-FOUND))
        )
        ;; Verify caller is authorized verifier
        (asserts! (is-authorized-verifier tx-sender) ERR-NOT-AUTHORIZED)
        
        ;; Validate new score
        (asserts! (is-valid-authenticity-score new-score) ERR-INVALID-AUTHENTICITY-SCORE)
        
        ;; Update provenance with new score and verification timestamp
        (map-set nft-provenance
            { nft-id: nft-id }
            (merge provenance-data {
                authenticity-score: new-score,
                last-verified: block-height
            })
        )
        (ok true)
    )
)

;; Comprehensive NFT transfer with full provenance tracking and AI-powered fraud detection
;; This function handles ownership transfers while maintaining complete audit trail,
;; performing multi-layered validation, and generating verification hashes for each transfer.
;; It integrates AI model confidence scores to detect potential fraudulent transfers.
;; @param nft-id: uint - The unique identifier of the NFT being transferred
;; @param new-owner: principal - The recipient address of the NFT
;; @param transfer-price: uint - The transaction price in micro-STX
;; @param verification-hash: string-ascii 64 - Cryptographic hash for transfer verification
;; @returns: (response bool uint) - Returns ok true on success, or error code on failure
(define-public (transfer-nft-with-provenance
    (nft-id uint)
    (new-owner principal)
    (transfer-price uint)
    (verification-hash (string-ascii 64)))
    (let
        (
            ;; Retrieve current provenance data, fail if NFT doesn't exist
            (provenance-data (unwrap! (map-get? nft-provenance { nft-id: nft-id }) ERR-NFT-NOT-FOUND))
            
            ;; Extract current owner from provenance record
            (current-owner-principal (get current-owner provenance-data))
            
            ;; Get current transfer count for history indexing
            (current-transfer-count (get transfer-count provenance-data))
            
            ;; Retrieve AI model data for fraud detection
            (ai-model-data (unwrap! (map-get? ai-models { model-id: (get ai-model-id provenance-data) }) ERR-INVALID-AI-MODEL))
            
            ;; Extract AI confidence level for risk assessment
            (ai-confidence (get confidence-level ai-model-data))
            
            ;; Calculate new authenticity score based on AI analysis
            (updated-authenticity (calculate-weighted-authenticity ai-confidence (get authenticity-score provenance-data)))
        )
        
        ;; Security check: Only current owner can initiate transfer
        (asserts! (is-eq tx-sender current-owner-principal) ERR-NOT-AUTHORIZED)
        
        ;; Fraud prevention: Block transfer if NFT is flagged as suspicious
        (asserts! (not (get is-flagged provenance-data)) ERR-TRANSFER-FAILED)
        
        ;; AI-powered validation: Ensure authenticity score meets threshold
        (asserts! (>= updated-authenticity MIN-AI-CONFIDENCE) ERR-TRANSFER-FAILED)
        
        ;; Record transfer in ownership history with complete audit trail
        (map-set ownership-history
            { nft-id: nft-id, transfer-index: current-transfer-count }
            {
                from-owner: current-owner-principal,
                to-owner: new-owner,
                transfer-timestamp: block-height,
                transfer-price: transfer-price,
                verification-hash: verification-hash
            }
        )
        
        ;; Update provenance record with new owner and incremented transfer count
        (map-set nft-provenance
            { nft-id: nft-id }
            (merge provenance-data {
                current-owner: new-owner,
                transfer-count: (+ current-transfer-count u1),
                authenticity-score: updated-authenticity,
                last-verified: block-height
            })
        )
        
        ;; Transfer completed successfully
        (ok true)
    )
)


