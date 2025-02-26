
;; Define the contract owner (admin)
(define-constant contract-owner 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Define the governance token contract address
(define-constant governance-token-contract 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)


;; Error codes
(define-constant err-unauthorized u1)
(define-constant err-proposal-not-found u2)
(define-constant err-voting-closed u3)
(define-constant err-already-voted u4)
(define-constant err-execute-not-found u5)
(define-constant err-voting-not-ended u6)
(define-constant err-already-executed u7)
(define-constant err-quorum-not-reached u8)
(define-constant err-proposal-query-failed u9)
(define-constant err-insufficient-tokens u10)
(define-constant err-proposal-canceled u11)
(define-constant err-timelock-not-expired u12)
(define-constant err-proposal-threshold u13)

;; Define the proposal structure
(define-data-var proposals
    (list 100
        {
            id: uint,
            creator: principal,
            title: (string-ascii 100),
            description: (string-ascii 1000),
            start-block: uint,
            end-block: uint,
            for-votes: uint,
            against-votes: uint,
            abstain-votes: uint, ;; NEW FEATURE: Abstain option
            executed: bool,
            canceled: bool, ;; NEW FEATURE: Cancellation tracking
            timelock-end: uint, ;; NEW FEATURE: Timelock before execution
            execution-data: (optional (buff 1024)), ;; NEW FEATURE: Store execution data
            status: uint, ;; NEW FEATURE: Status enum
            created-at: uint ;; NEW FEATURE: Creation timestamp
        }
    )
    (list)
)

;; Define the votes structure
(define-map votes 
    { user: principal, proposal: uint } 
    { support: bool }
)


;; Define the quorum threshold (e.g., 10% of total token supply)
(define-constant quorum-threshold u1000000) ;; Replace with actual quorum value

;; Define the voting period length in blocks (e.g., 14400 blocks ~ 10 days)
(define-constant voting-period u14400)


;; Helper function to check if the caller is the contract owner
(define-private (is-contract-owner (caller principal))
    (is-eq caller contract-owner)
)

;; Helper function to check if a proposal exists
(define-private (proposal-exists (id uint))
    (let ((proposals-list (var-get proposals)))
        (and 
            (> (len proposals-list) u0)
            (<= id (len proposals-list))
            (> id u0)
        )
    )
)

;; Helper function to get a proposal by ID
(define-private (get-proposal-by-id (id uint))
    (unwrap-panic (element-at (var-get proposals) (- id u1)))
)


;; Function to get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (if (proposal-exists proposal-id)
        (ok (get-proposal-by-id proposal-id))
        (err u9)
    )
)

;; Function to get user's vote on a proposal
(define-read-only (get-user-vote (proposal-id uint) (user principal))
    (default-to 
        { support: false } 
        (map-get? votes { user: user, proposal: proposal-id })
    )
)

;; Function to get all proposals
(define-read-only (get-all-proposals)
    (ok (var-get proposals))
)



;; Define the proposal status enum (NEW FEATURE)
(define-constant status-active u1)
(define-constant status-canceled u2)
(define-constant status-defeated u3)
(define-constant status-succeeded u4)
(define-constant status-queued u5)
(define-constant status-executed u6)
(define-constant status-expired u7)

;; Define proposal creation threshold (NEW FEATURE)
(define-constant proposal-threshold u100000) ;; Minimum tokens required to create proposal

;; Define timelock period (NEW FEATURE)
(define-constant timelock-period u4320) ;; ~3 days in blocks

;; Define proposal expiration period (NEW FEATURE)
(define-constant execution-deadline u28800) ;; ~20 days in blocks

;; Governance parameters that can be updated
(define-data-var governance-params
    {
        proposal-threshold: uint,
        quorum-requirement: uint,
        voting-period: uint, 
        timelock-period: uint,
        execution-deadline: uint
    }
    {
        proposal-threshold: proposal-threshold,
        quorum-requirement: quorum-threshold,
        voting-period: voting-period,
        timelock-period: timelock-period,
        execution-deadline: execution-deadline
    }
)

;; Track total proposals created
(define-data-var proposal-count uint u0)


;; Update governance parameters (admin only)
(define-public (update-governance-params (new-params {
        proposal-threshold: uint,
        quorum-requirement: uint,
        voting-period: uint, 
        timelock-period: uint,
        execution-deadline: uint
    }))
    (begin
        (asserts! (is-contract-owner tx-sender) (err err-unauthorized))
        (var-set governance-params new-params)
        (ok true)
    )
)

;; ERROR CODES
(define-constant err-invalid-vote-type u14)
(define-constant err-delegate-not-allowed u15)
(define-constant err-proposal-limit-reached u16)
(define-constant err-insufficient-delegation u17)
(define-constant err-invalid-metadata u18)
(define-constant err-proposal-vetoed u19)

;; Vote delegation system
(define-map delegations
    { delegator: principal }
    { delegate: principal, amount: uint }
)


;; Per-user proposal creation limits
(define-map proposal-creation-limits
    { user: principal }
    { count: uint, last-reset-block: uint }
)

;; Proposal metadata for additional information
(define-map proposal-metadata
    { proposal-id: uint }
    { 
        tags: (list 10 (string-ascii 20)),
        category: (string-ascii 30),
        url: (string-ascii 255),
        discussion-forum: (string-ascii 255)
    }
)

;; Emergency veto power
(define-data-var emergency-committee 
    (list 5 principal)
    (list contract-owner)
)

;; Vote types (separate from the abstain feature)
(define-constant vote-type-standard u0)
(define-constant vote-type-quadratic u1)
(define-constant vote-type-conviction u2)

;; Voting strategy per proposal
(define-map proposal-vote-strategies
    { proposal-id: uint }
    { vote-type: uint }
)

;; Snapshot block for votes
(define-map proposal-vote-snapshots
    { proposal-id: uint }
    { snapshot-block: uint }
)


