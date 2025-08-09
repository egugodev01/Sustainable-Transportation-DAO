;; Sustainable Transportation DAO - Community-owned EV sharing network
;; Version: 1.0.0

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VEHICLE-NOT-FOUND (err u101))
(define-constant ERR-VEHICLE-UNAVAILABLE (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-ALREADY-MEMBER (err u104))
(define-constant ERR-NOT-MEMBER (err u105))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u106))
(define-constant ERR-ALREADY-VOTED (err u107))
(define-constant ERR-VEHICLE-IN-USE (err u108))
(define-constant ERR-INVALID-DURATION (err u109))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MEMBERSHIP-FEE u1000000) ;; 1 STX
(define-constant MIN-PROPOSAL-THRESHOLD u100) ;; Minimum tokens to create proposal
(define-constant VOTING-PERIOD u144) ;; ~24 hours in blocks

;; Data variables
(define-data-var total-vehicles uint u0)
(define-data-var total-members uint u0)
(define-data-var total-proposals uint u0)
(define-data-var treasury-balance uint u0)

;; Maps
(define-map members principal 
  {
    tokens: uint,
    joined-at: uint,
    reputation: uint
  })

(define-map vehicles uint 
  {
    owner: principal,
    model: (string-ascii 50),
    location: (string-ascii 100),
    rate-per-hour: uint,
    available: bool,
    battery-level: uint,
    total-trips: uint
  })

(define-map active-rentals uint 
  {
    renter: principal,
    vehicle-id: uint,
    start-time: uint,
    duration: uint,
    total-cost: uint
  })

(define-map proposals uint 
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: (string-ascii 20),
    target: (optional principal),
    amount: uint,
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    executed: bool
  })

(define-map proposal-votes {proposal-id: uint, voter: principal} bool)
(define-map rental-counter principal uint)

;; Public functions

;; Join DAO as member
(define-public (join-dao)
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? members caller)) ERR-ALREADY-MEMBER)
    (try! (stx-transfer? MEMBERSHIP-FEE caller (as-contract tx-sender)))
    (map-set members caller {
      tokens: u100,
      joined-at: block-height,
      reputation: u0
    })
    (var-set total-members (+ (var-get total-members) u1))
    (var-set treasury-balance (+ (var-get treasury-balance) MEMBERSHIP-FEE))
    (ok true)
  )
)

;; Add new vehicle to fleet
(define-public (add-vehicle (model (string-ascii 50)) (location (string-ascii 100)) (rate uint))
  (let ((vehicle-id (+ (var-get total-vehicles) u1))
        (caller tx-sender))
    (asserts! (is-some (map-get? members caller)) ERR-NOT-MEMBER)
    (map-set vehicles vehicle-id {
      owner: caller,
      model: model,
      location: location,
      rate-per-hour: rate,
      available: true,
      battery-level: u100,
      total-trips: u0
    })
    (var-set total-vehicles vehicle-id)
    ;; Reward vehicle owner with tokens
    (let ((member-data (unwrap! (map-get? members caller) ERR-NOT-MEMBER)))
      (map-set members caller (merge member-data {tokens: (+ (get tokens member-data) u50)}))
    )
    (ok vehicle-id)
  )
)

;; Rent a vehicle
(define-public (rent-vehicle (vehicle-id uint) (duration uint))
  (let ((vehicle (unwrap! (map-get? vehicles vehicle-id) ERR-VEHICLE-NOT-FOUND))
        (caller tx-sender)
        (member-data (unwrap! (map-get? members caller) ERR-NOT-MEMBER))
        (total-cost (* (get rate-per-hour vehicle) duration)))
    
    (asserts! (get available vehicle) ERR-VEHICLE-UNAVAILABLE)
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    (asserts! (>= (get tokens member-data) total-cost) ERR-INSUFFICIENT-BALANCE)
    
    ;; Update vehicle availability
    (map-set vehicles vehicle-id (merge vehicle {available: false}))
    
    ;; Create rental record
    (let ((rental-id (+ (default-to u0 (map-get? rental-counter caller)) u1)))
      (map-set active-rentals rental-id {
        renter: caller,
        vehicle-id: vehicle-id,
        start-time: block-height,
        duration: duration,
        total-cost: total-cost
      })
      (map-set rental-counter caller rental-id)
      
      ;; Deduct tokens from renter
      (map-set members caller (merge member-data {tokens: (- (get tokens member-data) total-cost)}))
      
      ;; Add tokens to vehicle owner
      (let ((owner-data (unwrap! (map-get? members (get owner vehicle)) ERR-NOT-MEMBER)))
        (map-set members (get owner vehicle) 
          (merge owner-data {tokens: (+ (get tokens owner-data) (/ (* total-cost u80) u100))}))
      )
      
      ;; Add to treasury (20% fee)
      (var-set treasury-balance (+ (var-get treasury-balance) (/ (* total-cost u20) u100)))
      
      (ok rental-id)
    )
  )
)

;; Return vehicle
(define-public (return-vehicle (rental-id uint))
  (let ((rental (unwrap! (map-get? active-rentals rental-id) ERR-VEHICLE-NOT-FOUND))
        (caller tx-sender)
        (vehicle-id (get vehicle-id rental))
        (vehicle (unwrap! (map-get? vehicles vehicle-id) ERR-VEHICLE-NOT-FOUND)))
    
    (asserts! (is-eq caller (get renter rental)) ERR-NOT-AUTHORIZED)
    
    ;; Update vehicle
    (map-set vehicles vehicle-id (merge vehicle {
      available: true,
      total-trips: (+ (get total-trips vehicle) u1)
    }))
    
    ;; Update renter reputation
    (let ((member-data (unwrap! (map-get? members caller) ERR-NOT-MEMBER)))
      (map-set members caller (merge member-data {reputation: (+ (get reputation member-data) u1)}))
    )
    
    ;; Remove active rental
    (map-delete active-rentals rental-id)
    (ok true)
  )
)

;; Create governance proposal
(define-public (create-proposal 
  (title (string-ascii 100)) 
  (description (string-ascii 500))
  (proposal-type (string-ascii 20))
  (target (optional principal))
  (amount uint))
  (let ((caller tx-sender)
        (member-data (unwrap! (map-get? members caller) ERR-NOT-MEMBER))
        (proposal-id (+ (var-get total-proposals) u1)))
    
    (asserts! (>= (get tokens member-data) MIN-PROPOSAL-THRESHOLD) ERR-INSUFFICIENT-BALANCE)
    
    (map-set proposals proposal-id {
      proposer: caller,
      title: title,
      description: description,
      proposal-type: proposal-type,
      target: target,
      amount: amount,
      votes-for: u0,
      votes-against: u0,
      created-at: block-height,
      executed: false
    })
    
    (var-set total-proposals proposal-id)
    (ok proposal-id)
  )
)

;; Vote on proposal
(define-public (vote-proposal (proposal-id uint) (vote-for bool))
  (let ((caller tx-sender)
        (member-data (unwrap! (map-get? members caller) ERR-NOT-MEMBER))
        (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (vote-key {proposal-id: proposal-id, voter: caller}))
    
    (asserts! (is-none (map-get? proposal-votes vote-key)) ERR-ALREADY-VOTED)
    (asserts! (< (- block-height (get created-at proposal)) VOTING-PERIOD) ERR-NOT-AUTHORIZED)
    
    (map-set proposal-votes vote-key true)
    
    (let ((vote-weight (get tokens member-data)))
      (if vote-for
        (map-set proposals proposal-id 
          (merge proposal {votes-for: (+ (get votes-for proposal) vote-weight)}))
        (map-set proposals proposal-id 
          (merge proposal {votes-against: (+ (get votes-against proposal) vote-weight)}))
      )
    )
    (ok true)
  )
)

;; Execute approved proposal
(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
    (asserts! (not (get executed proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (- block-height (get created-at proposal)) VOTING-PERIOD) ERR-NOT-AUTHORIZED)
    
    ;; Mark as executed
    (map-set proposals proposal-id (merge proposal {executed: true}))
    
    ;; Execute based on proposal type
    (if (is-eq (get proposal-type proposal) "treasury")
      (begin
        (asserts! (>= (var-get treasury-balance) (get amount proposal)) ERR-INSUFFICIENT-BALANCE)
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender 
          (unwrap! (get target proposal) ERR-NOT-AUTHORIZED))))
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
      )
      ;; Add more proposal types as needed
      true
    )
    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-member (member principal))
  (map-get? members member)
)

(define-read-only (get-vehicle (vehicle-id uint))
  (map-get? vehicles vehicle-id)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-rental (rental-id uint))
  (map-get? active-rentals rental-id)
)

(define-read-only (get-dao-stats)
  {
    total-vehicles: (var-get total-vehicles),
    total-members: (var-get total-members),
    total-proposals: (var-get total-proposals),
    treasury-balance: (var-get treasury-balance)
  }
)

(define-read-only (get-available-vehicles)
  (ok (var-get total-vehicles)) ;; Simplified - in practice would filter available vehicles
)