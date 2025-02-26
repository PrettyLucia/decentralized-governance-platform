
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
            executed: bool
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
