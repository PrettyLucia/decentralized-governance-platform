
;; Define the contract owner (admin)
(define-constant contract-owner 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Define the governance token contract address
(define-constant governance-token-contract 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)

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
