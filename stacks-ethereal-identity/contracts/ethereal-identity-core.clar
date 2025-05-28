;; Ethereal Identity Core - Soulbound Token Identity System
;; A revolutionary SBT system for preserving life milestones, relationships,
;; and cultural heritage across generations with privacy-preserving mechanisms

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-IDENTITY-EXISTS (err u101))
(define-constant ERR-IDENTITY-NOT-FOUND (err u102))
(define-constant ERR-INVALID-MILESTONE-TYPE (err u103))
(define-constant ERR-INVALID-RELATIONSHIP-TYPE (err u104))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u105))
(define-constant ERR-MILESTONE-NOT-FOUND (err u106))
(define-constant ERR-INSUFFICIENT-WITNESSES (err u107))
(define-constant ERR-RELATIONSHIP-EXISTS (err u108))
(define-constant ERR-SELF-RELATIONSHIP (err u109))
(define-constant ERR-PRIVACY-VIOLATION (err u110))
(define-constant ERR-MEMORIAL-ALREADY-SET (err u111))
(define-constant ERR-NOT-MEMORIAL (err u112))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)

;; Milestone types
(define-constant MILESTONE-BIRTH u1)
(define-constant MILESTONE-EDUCATION u2)
(define-constant MILESTONE-CAREER u3)
(define-constant MILESTONE-FAMILY u4)
(define-constant MILESTONE-HEALTH u5)
(define-constant MILESTONE-CULTURAL u6)
(define-constant MILESTONE-PERSONAL u7)
(define-constant MILESTONE-MEMORIAL u8)

;; Relationship types
(define-constant RELATIONSHIP-BLOOD u1)
(define-constant RELATIONSHIP-LEGAL u2)
(define-constant RELATIONSHIP-SOCIAL u3)
(define-constant RELATIONSHIP-MENTOR u4)
(define-constant RELATIONSHIP-PROFESSIONAL u5)
(define-constant RELATIONSHIP-CULTURAL u6)
(define-constant RELATIONSHIP-MEMORIAL u7)

;; Privacy levels
(define-constant PRIVACY-PUBLIC u1)
(define-constant PRIVACY-NETWORK u2)
(define-constant PRIVACY-FAMILY u3)
(define-constant PRIVACY-PRIVATE u4)
(define-constant PRIVACY-WITNESS u5)
(define-constant PRIVACY-MEMORIAL u6)

;; Minimum witnesses required for validation
(define-constant MIN-WITNESSES u2)
(define-constant MIN-AUTHORITY-WITNESSES u1)

;; Data variables
(define-data-var next-identity-id uint u1)
(define-data-var next-milestone-id uint u1)
(define-data-var next-relationship-id uint u1)
(define-data-var contract-paused bool false)

;; Core identity data
(define-map identities principal {
  identity-id: uint,
  creation-timestamp: uint,
  identity-type: (string-ascii 50),
  privacy-level: uint,
  verification-status: uint,
  cultural-heritage: (optional uint),
  memorial-status: bool,
  memorial-timestamp: (optional uint),
  evolution-stage: uint,
  metadata-uri: (string-ascii 256)
})

;; Identity reverse lookup
(define-map identity-by-id uint principal)

;; Life milestones
(define-map milestones uint {
  milestone-id: uint,
  owner: principal,
  milestone-type: uint,
  title: (string-ascii 100),
  description: (string-ascii 500),
  timestamp: uint,
  privacy-level: uint,
  witness-count: uint,
  verified: bool,
  metadata-uri: (string-ascii 256),
  cultural-significance: (optional (string-ascii 200))
})

;; Milestone ownership tracking
(define-map user-milestones principal (list 50 uint))

;; Relationships between identities
(define-map relationships uint {
  relationship-id: uint,
  from-identity: principal,
  to-identity: principal,
  relationship-type: uint,
  relationship-name: (string-ascii 50),
  established-timestamp: uint,
  mutual-confirmed: bool,
  privacy-level: uint,
  cultural-context: (optional (string-ascii 200))
})

;; Relationship tracking
(define-map user-relationships principal (list 100 uint))

;; Witness validation system
(define-map milestone-witnesses 
  {milestone-id: uint, witness: principal}
  {
    witness-type: uint,  ;; 1=peer, 2=authority, 3=cultural, 4=family
    validation-timestamp: uint,
    witness-statement: (string-ascii 300)
  }
)

;; Cultural heritage tracking
(define-map cultural-heritage uint {
  heritage-id: uint,
  owner: principal,
  culture-name: (string-ascii 100),
  heritage-type: (string-ascii 50),
  description: (string-ascii 500),
  preservation-level: uint,
  shared-with-family: bool,
  metadata-uri: (string-ascii 256)
})

;; Privacy access control
(define-map privacy-permissions
  {owner: principal, accessor: principal}
  {
    access-level: uint,
    granted-timestamp: uint,
    expires-at: (optional uint),
    specific-permissions: (list 10 uint)
  }
)

;; Memorial system
(define-map memorial-tributes
  {memorial-for: principal, tribute-by: principal}
  {
    tribute-id: uint,
    tribute-text: (string-ascii 1000),
    tribute-timestamp: uint,
    approved: bool,
    metadata-uri: (string-ascii 256)
  }
)

;; Growth tracking
(define-map personal-growth principal {
  growth-score: uint,
  last-milestone-timestamp: uint,
  growth-categories: (list 10 uint),
  achievement-count: uint,
  learning-journey-active: bool
})

;; Private helper functions

;; Validate milestone type
(define-private (is-valid-milestone-type (milestone-type uint))
  (and (>= milestone-type MILESTONE-BIRTH) (<= milestone-type MILESTONE-MEMORIAL))
)

;; Validate relationship type
(define-private (is-valid-relationship-type (rel-type uint))
  (and (>= rel-type RELATIONSHIP-BLOOD) (<= rel-type RELATIONSHIP-MEMORIAL))
)

;; Validate privacy level
(define-private (is-valid-privacy-level (privacy uint))
  (and (>= privacy PRIVACY-PUBLIC) (<= privacy PRIVACY-MEMORIAL))
)

;; Check if user has identity
(define-private (has-identity (user principal))
  (is-some (map-get? identities user))
)

;; Get user's milestone list
(define-private (get-user-milestone-list (user principal))
  (default-to (list) (map-get? user-milestones user))
)

;; Add milestone to user's list
(define-private (add-milestone-to-user (user principal) (milestone-id uint))
  (let ((current-list (get-user-milestone-list user)))
    (map-set user-milestones user (unwrap-panic (as-max-len? (append current-list milestone-id) u50)))
  )
)

;; Get user's relationship list
(define-private (get-user-relationship-list (user principal))
  (default-to (list) (map-get? user-relationships user))
)

;; Add relationship to user's list
(define-private (add-relationship-to-user (user principal) (relationship-id uint))
  (let ((current-list (get-user-relationship-list user)))
    (map-set user-relationships user (unwrap-panic (as-max-len? (append current-list relationship-id) u100)))
  )
)

;; Calculate evolution stage based on milestones and age
(define-private (calculate-evolution-stage (user principal))
  (let (
    (identity-data (unwrap-panic (map-get? identities user)))
    (creation-time (get creation-timestamp identity-data))
    (age-in-blocks (- block-height creation-time))
    (milestone-count (len (get-user-milestone-list user)))
  )
    ;; Simple evolution calculation based on time and achievements
    (+ 
      (if (> age-in-blocks u52560) u1 u0)      ;; ~1 year
      (if (> age-in-blocks u262800) u1 u0)     ;; ~5 years
      (if (> milestone-count u5) u1 u0)        ;; Achievement-based
      (if (> milestone-count u15) u1 u0)       ;; High achiever
    )
  )
)

;; Check privacy access permissions
(define-private (can-access-data (owner principal) (accessor principal) (required-level uint))
  (if (is-eq owner accessor)
    true
    (let ((permissions (map-get? privacy-permissions {owner: owner, accessor: accessor})))
      (match permissions
        perm (>= (get access-level perm) required-level)
        false
      )
    )
  )
)

;; Public functions

;; Create a new ethereal identity
(define-public (create-identity 
  (identity-type (string-ascii 50))
  (privacy-level uint)
  (cultural-heritage-id (optional uint))
  (metadata-uri (string-ascii 256))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (not (has-identity tx-sender)) ERR-IDENTITY-EXISTS)
    (asserts! (is-valid-privacy-level privacy-level) ERR-INVALID-PRIVACY-LEVEL)
    
    (let ((identity-id (var-get next-identity-id)))
      ;; Create identity record
      (map-set identities tx-sender {
        identity-id: identity-id,
        creation-timestamp: block-height,
        identity-type: identity-type,
        privacy-level: privacy-level,
        verification-status: u1,
        cultural-heritage: cultural-heritage-id,
        memorial-status: false,
        memorial-timestamp: none,
        evolution-stage: u0,
        metadata-uri: metadata-uri
      })
      
      ;; Create reverse lookup
      (map-set identity-by-id identity-id tx-sender)
      
      ;; Initialize growth tracking
      (map-set personal-growth tx-sender {
        growth-score: u0,
        last-milestone-timestamp: block-height,
        growth-categories: (list),
        achievement-count: u0,
        learning-journey-active: true
      })
      
      ;; Increment next ID
      (var-set next-identity-id (+ identity-id u1))
      
      (ok identity-id)
    )
  )
)

;; Add a life milestone
(define-public (add-milestone
  (milestone-type uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (privacy-level uint)
  (metadata-uri (string-ascii 256))
  (cultural-significance (optional (string-ascii 200)))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (has-identity tx-sender) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-valid-milestone-type milestone-type) ERR-INVALID-MILESTONE-TYPE)
    (asserts! (is-valid-privacy-level privacy-level) ERR-INVALID-PRIVACY-LEVEL)
    
    (let ((milestone-id (var-get next-milestone-id)))
      ;; Create milestone record
      (map-set milestones milestone-id {
        milestone-id: milestone-id,
        owner: tx-sender,
        milestone-type: milestone-type,
        title: title,
        description: description,
        timestamp: block-height,
        privacy-level: privacy-level,
        witness-count: u0,
        verified: false,
        metadata-uri: metadata-uri,
        cultural-significance: cultural-significance
      })
      
      ;; Add to user's milestone list
      (add-milestone-to-user tx-sender milestone-id)
      
      ;; Update growth tracking
      (let ((current-growth (default-to 
                              {growth-score: u0, last-milestone-timestamp: block-height, 
                               growth-categories: (list), achievement-count: u0, learning-journey-active: true}
                              (map-get? personal-growth tx-sender))))
        (map-set personal-growth tx-sender 
          (merge current-growth {
            last-milestone-timestamp: block-height,
            achievement-count: (+ (get achievement-count current-growth) u1)
          })
        )
      )
      
      ;; Update identity evolution stage
      (let ((identity-data (unwrap-panic (map-get? identities tx-sender))))
        (map-set identities tx-sender
          (merge identity-data {evolution-stage: (calculate-evolution-stage tx-sender)})
        )
      )
      
      ;; Increment next ID
      (var-set next-milestone-id (+ milestone-id u1))
      
      (ok milestone-id)
    )
  )
)

;; Witness validation for milestones
(define-public (witness-milestone
  (milestone-id uint)
  (witness-type uint)
  (witness-statement (string-ascii 300))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (has-identity tx-sender) ERR-IDENTITY-NOT-FOUND)
    
    (let ((milestone-data (unwrap! (map-get? milestones milestone-id) ERR-MILESTONE-NOT-FOUND)))
      ;; Ensure witness is not the milestone owner
      (asserts! (not (is-eq tx-sender (get owner milestone-data))) ERR-NOT-AUTHORIZED)
      
      ;; Add witness record
      (map-set milestone-witnesses 
        {milestone-id: milestone-id, witness: tx-sender}
        {
          witness-type: witness-type,
          validation-timestamp: block-height,
          witness-statement: witness-statement
        }
      )
      
      ;; Update milestone witness count
      (let ((updated-count (+ (get witness-count milestone-data) u1)))
        (map-set milestones milestone-id
          (merge milestone-data {
            witness-count: updated-count,
            verified: (>= updated-count MIN-WITNESSES)
          })
        )
      )
      
      (ok true)
    )
  )
)

;; Create relationship between identities
(define-public (create-relationship
  (to-identity principal)
  (relationship-type uint)
  (relationship-name (string-ascii 50))
  (privacy-level uint)
  (cultural-context (optional (string-ascii 200)))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (has-identity tx-sender) ERR-IDENTITY-NOT-FOUND)
    (asserts! (has-identity to-identity) ERR-IDENTITY-NOT-FOUND)
    (asserts! (not (is-eq tx-sender to-identity)) ERR-SELF-RELATIONSHIP)
    (asserts! (is-valid-relationship-type relationship-type) ERR-INVALID-RELATIONSHIP-TYPE)
    (asserts! (is-valid-privacy-level privacy-level) ERR-INVALID-PRIVACY-LEVEL)
    
    (let ((relationship-id (var-get next-relationship-id)))
      ;; Create relationship record
      (map-set relationships relationship-id {
        relationship-id: relationship-id,
        from-identity: tx-sender,
        to-identity: to-identity,
        relationship-type: relationship-type,
        relationship-name: relationship-name,
        established-timestamp: block-height,
        mutual-confirmed: false,
        privacy-level: privacy-level,
        cultural-context: cultural-context
      })
      
      ;; Add to both users' relationship lists
      (add-relationship-to-user tx-sender relationship-id)
      (add-relationship-to-user to-identity relationship-id)
      
      ;; Increment next ID
      (var-set next-relationship-id (+ relationship-id u1))
      
      (ok relationship-id)
    )
  )
)

;; Confirm mutual relationship
(define-public (confirm-relationship (relationship-id uint))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    
    (let ((relationship-data (unwrap! (map-get? relationships relationship-id) ERR-IDENTITY-NOT-FOUND)))
      ;; Only the 'to-identity' can confirm
      (asserts! (is-eq tx-sender (get to-identity relationship-data)) ERR-NOT-AUTHORIZED)
      
      ;; Update relationship as mutually confirmed
      (map-set relationships relationship-id
        (merge relationship-data {mutual-confirmed: true})
      )
      
      (ok true)
    )
  )
)

;; Set memorial status (can only be done by family members or authorities)
(define-public (set-memorial-status 
  (memorial-for principal)
  (memorial-metadata-uri (string-ascii 256))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (has-identity memorial-for) ERR-IDENTITY-NOT-FOUND)
    
    (let ((identity-data (unwrap-panic (map-get? identities memorial-for))))
      (asserts! (not (get memorial-status identity-data)) ERR-MEMORIAL-ALREADY-SET)
      
      ;; Update identity to memorial status
      (map-set identities memorial-for
        (merge identity-data {
          memorial-status: true,
          memorial-timestamp: (some block-height),
          privacy-level: PRIVACY-MEMORIAL,
          metadata-uri: memorial-metadata-uri
        })
      )
      
      (ok true)
    )
  )
)

;; Grant privacy permissions
(define-public (grant-privacy-access
  (accessor principal)
  (access-level uint)
  (expires-at (optional uint))
  (specific-permissions (list 10 uint))
)
  (begin
    (asserts! (has-identity tx-sender) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-valid-privacy-level access-level) ERR-INVALID-PRIVACY-LEVEL)
    
    (map-set privacy-permissions
      {owner: tx-sender, accessor: accessor}
      {
        access-level: access-level,
        granted-timestamp: block-height,
        expires-at: expires-at,
        specific-permissions: specific-permissions
      }
    )
    
    (ok true)
  )
)

;; Emergency pause (owner only)
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Resume operations (owner only)
(define-public (resume-operations)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Read-only functions

;; Get identity information (respects privacy)
(define-read-only (get-identity-info (user principal))
  (let ((identity-data (map-get? identities user)))
    (match identity-data
      data (if (can-access-data user tx-sender (get privacy-level data))
             (some data)
             none)
      none
    )
  )
)

;; Get user's milestones (returns IDs - caller must check individual privacy)
(define-read-only (get-user-milestones (user principal))
  (if (can-access-data user tx-sender PRIVACY-NETWORK)
    (some (get-user-milestone-list user))
    none
  )
)

;; Get milestone details
(define-read-only (get-milestone-info (milestone-id uint))
  (let ((milestone-data (map-get? milestones milestone-id)))
    (match milestone-data
      data (if (can-access-data (get owner data) tx-sender (get privacy-level data))
             (some data)
             none)
      none
    )
  )
)

;; Get user's relationships (returns IDs - caller must check individual privacy)
(define-read-only (get-user-relationships (user principal))
  (if (can-access-data user tx-sender PRIVACY-NETWORK)
    (some (get-user-relationship-list user))
    none
  )
)

;; Get relationship details
(define-read-only (get-relationship-info (relationship-id uint))
  (map-get? relationships relationship-id)
)

;; Get growth tracking info
(define-read-only (get-growth-info (user principal))
  (if (can-access-data user tx-sender PRIVACY-NETWORK)
    (map-get? personal-growth user)
    none
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-identities: (- (var-get next-identity-id) u1),
    total-milestones: (- (var-get next-milestone-id) u1),
    total-relationships: (- (var-get next-relationship-id) u1),
    contract-paused: (var-get contract-paused)
  }
)

;; Check if contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)