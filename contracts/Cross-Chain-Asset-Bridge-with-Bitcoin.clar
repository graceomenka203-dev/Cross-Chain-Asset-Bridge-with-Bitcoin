(define-fungible-token wbtc)

(define-data-var owner (optional principal) none)
(define-data-var paused bool false)
(define-data-var next-req-id uint u1)

(define-map claims
  {
    txid: (buff 32)
  }
  {
    recipient: principal,
    amount: uint,
    claimed: bool,
    attested-at: uint
  }
)

(define-map burns
  {
    id: uint
  }
  {
    sender: principal,
    amount: uint,
    btc: (buff 64),
    processed: bool,
    created-at: uint,
    processed-at: (optional uint),
    btc-txid: (optional (buff 32))
  }
)

(define-read-only (get-owner)
  (var-get owner)
)

(define-read-only (get-paused)
  (var-get paused)
)

(define-read-only (get-next-request-id)
  (var-get next-req-id)
)

(define-read-only (get-claim (txid (buff 32)))
  (map-get? claims { txid: txid })
)

(define-read-only (get-withdraw (id uint))
  (map-get? burns { id: id })
)

(define-read-only (get-wbtc-balance (who principal))
  (ft-get-balance wbtc who)
)

(define-private (is-initialized)
  (is-some (var-get owner))
)

(define-private (is-owner)
  (let ((ow (var-get owner)))
    (match ow o
      (is-eq o tx-sender)
      false
    )
  )
)

(define-private (not-paused)
  (not (var-get paused))
)

(define-public (bootstrap (new-owner principal))
  (begin
    (asserts! (is-none (var-get owner)) (err u103))
    (var-set owner (some new-owner))
    (ok true)
  )
)

(define-public (set-paused (p bool))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (is-owner) (err u101))
    (var-set paused p)
    (ok p)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (is-owner) (err u101))
    (var-set owner (some new-owner))
    (ok true)
  )
)

(define-public (attest-btc-deposit (txid (buff 32)) (recipient principal) (amount uint))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (is-owner) (err u101))
    (asserts! (is-none (map-get? claims { txid: txid })) (err u200))
    (asserts! (>= amount u1) (err u201))
    (let ((h stacks-block-height))
      (map-set claims { txid: txid } { recipient: recipient, amount: amount, claimed: false, attested-at: h })
      (ok true)
    )
  )
)

(define-public (claim (txid (buff 32)))
  (let ((rec (map-get? claims { txid: txid })))
    (match rec r
      (begin
        (asserts! (is-eq (get claimed r) false) (err u202))
        (asserts! (is-eq (get recipient r) tx-sender) (err u203))
        (unwrap! (ft-mint? wbtc (get amount r) tx-sender) (err u205))
        (map-set claims { txid: txid } { recipient: (get recipient r), amount: (get amount r), claimed: true, attested-at: (get attested-at r) })
        (ok true)
      )
      (err u204)
    )
  )
)

(define-public (transfer (amount uint) (recipient principal))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (>= amount u1) (err u201))
    (unwrap! (ft-transfer? wbtc amount tx-sender recipient) (err u207))
    (ok true)
  )
)

(define-public (request-withdraw (amount uint) (btc (buff 64)))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (not-paused) (err u102))
    (asserts! (>= amount u1) (err u201))
    (unwrap! (ft-burn? wbtc amount tx-sender) (err u206))
    (let ((id (var-get next-req-id)) (h stacks-block-height))
      (map-set burns { id: id } { sender: tx-sender, amount: amount, btc: btc, processed: false, created-at: h, processed-at: none, btc-txid: none })
      (var-set next-req-id (+ id u1))
      (ok id)
    )
  )
)

(define-public (mark-withdraw-processed (id uint) (btc-txid (optional (buff 32))))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (is-owner) (err u101))
    (let ((bw (map-get? burns { id: id })))
      (match bw b
        (begin
          (asserts! (is-eq (get processed b) false) (err u301))
          (map-set burns { id: id } { sender: (get sender b), amount: (get amount b), btc: (get btc b), processed: true, created-at: (get created-at b), processed-at: (some stacks-block-height), btc-txid: btc-txid })
          (ok true)
        )
        (err u302)
      )
    )
  )
)

(define-read-only (can-claim (txid (buff 32)) (who principal))
  (let ((rec (map-get? claims { txid: txid })))
    (match rec r
      (and (is-eq (get recipient r) who) (is-eq (get claimed r) false))
      false
    )
  )
)

(define-read-only (can-attest (who principal))
  (let ((ow (var-get owner)))
    (match ow o
      (is-eq o who)
      false
    )
  )
)

(define-read-only (is-paused)
  (var-get paused)
)

(define-read-only (token-total-supply)
  (ft-get-supply wbtc)
)

(define-public (mint-to (recipient principal) (amount uint))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (is-owner) (err u101))
    (asserts! (>= amount u1) (err u201))
    (unwrap! (ft-mint? wbtc amount recipient) (err u205))
    (ok true)
  )
)

(define-public (burn-from (amount uint))
  (begin
    (asserts! (is-initialized) (err u100))
    (asserts! (>= amount u1) (err u201))
    (unwrap! (ft-burn? wbtc amount tx-sender) (err u206))
    (ok true)
  )
)
