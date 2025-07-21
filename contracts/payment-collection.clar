;; Smart Public Parking Enforcement - Payment Collection Contract
;; Handles fine payments, installment plans, and penalty calculations

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-INPUT (err u301))
(define-constant ERR-PAYMENT-EXISTS (err u302))
(define-constant ERR-PAYMENT-NOT-FOUND (err u303))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u304))
(define-constant ERR-CITATION-NOT-FOUND (err u305))

;; Data Variables
(define-data-var next-payment-id uint u1)
(define-data-var payment-system-active bool true)
(define-data-var late-fee-percentage uint u25) ;; 25% late fee
(define-data-var grace-period-days uint u7)

;; Data Maps
(define-map payments
  { payment-id: uint }
  {
    citation-id: uint,
    amount-paid: uint,
    payment-method: (string-ascii 20),
    transaction-date: uint,
    transaction-id: (string-ascii 50),
    payer-info: (string-ascii 100),
    status: (string-ascii 20)
  }
)

(define-map installment-plans
  { citation-id: uint }
  {
    total-amount: uint,
    monthly-payment: uint,
    payments-made: uint,
    total-payments: uint,
    next-due-date: uint,
    status: (string-ascii 20),
    setup-date: uint
  }
)

(define-map citation-balances
  { citation-id: uint }
  {
    original-fine: uint,
    late-fees: uint,
    total-owed: uint,
    amount-paid: uint,
    remaining-balance: uint,
    last-updated: uint
  }
)

(define-map payment-methods
  { method-name: (string-ascii 20) }
  { active: bool, processing-fee: uint }
)

;; Private Functions
(define-private (calculate-late-fee (original-amount uint))
  (/ (* original-amount (var-get late-fee-percentage)) u100)
)

(define-private (is-payment-overdue (due-date uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (grace-period (* (var-get grace-period-days) u86400))
    )
    (> current-time (+ due-date grace-period))
  )
)

(define-private (is-valid-payment-method (method (string-ascii 20)))
  (match (map-get? payment-methods { method-name: method })
    method-data (get active method-data)
    false
  )
)

;; Public Functions

;; Process a payment for a citation
(define-public (process-payment
  (citation-id uint)
  (amount-paid uint)
  (payment-method (string-ascii 20))
  (transaction-id (string-ascii 50))
  (payer-info (string-ascii 100))
)
  (let
    (
      (payment-id (var-get next-payment-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (balance (map-get? citation-balances { citation-id: citation-id }))
    )
    (asserts! (var-get payment-system-active) ERR-NOT-AUTHORIZED)
    (asserts! (> amount-paid u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-payment-method payment-method) ERR-INVALID-INPUT)
    (asserts! (> (len transaction-id) u0) ERR-INVALID-INPUT)
    (asserts! (is-some balance) ERR-CITATION-NOT-FOUND)

    (let
      (
        (balance-data (unwrap-panic balance))
        (remaining-balance (get remaining-balance balance-data))
      )
      (asserts! (<= amount-paid remaining-balance) ERR-INSUFFICIENT-PAYMENT)

      ;; Record the payment
      (map-set payments
        { payment-id: payment-id }
        {
          citation-id: citation-id,
          amount-paid: amount-paid,
          payment-method: payment-method,
          transaction-date: current-time,
          transaction-id: transaction-id,
          payer-info: payer-info,
          status: "completed"
        }
      )

      ;; Update citation balance
      (map-set citation-balances
        { citation-id: citation-id }
        (merge balance-data {
          amount-paid: (+ (get amount-paid balance-data) amount-paid),
          remaining-balance: (- remaining-balance amount-paid),
          last-updated: current-time
        })
      )

      (var-set next-payment-id (+ payment-id u1))
      (ok payment-id)
    )
  )
)

;; Setup an installment plan
(define-public (setup-installment-plan
  (citation-id uint)
  (monthly-payment uint)
  (total-payments uint)
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (balance (map-get? citation-balances { citation-id: citation-id }))
      (next-due-date (+ current-time (* u86400 u30))) ;; 30 days from now
    )
    (asserts! (var-get payment-system-active) ERR-NOT-AUTHORIZED)
    (asserts! (> monthly-payment u0) ERR-INVALID-INPUT)
    (asserts! (> total-payments u0) ERR-INVALID-INPUT)
    (asserts! (< total-payments u25) ERR-INVALID-INPUT) ;; Max 24 payments
    (asserts! (is-some balance) ERR-CITATION-NOT-FOUND)

    (let
      (
        (balance-data (unwrap-panic balance))
        (total-amount (get remaining-balance balance-data))
      )
      (asserts! (>= (* monthly-payment total-payments) total-amount) ERR-INSUFFICIENT-PAYMENT)

      (map-set installment-plans
        { citation-id: citation-id }
        {
          total-amount: total-amount,
          monthly-payment: monthly-payment,
          payments-made: u0,
          total-payments: total-payments,
          next-due-date: next-due-date,
          status: "active",
          setup-date: current-time
        }
      )
      (ok true)
    )
  )
)

;; Calculate penalties for overdue citations
(define-public (calculate-penalties (citation-id uint) (due-date uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (balance (map-get? citation-balances { citation-id: citation-id }))
    )
    (asserts! (is-some balance) ERR-CITATION-NOT-FOUND)

    (if (is-payment-overdue due-date)
      (let
        (
          (balance-data (unwrap-panic balance))
          (original-fine (get original-fine balance-data))
          (current-late-fees (get late-fees balance-data))
          (additional-late-fee (calculate-late-fee original-fine))
        )
        (map-set citation-balances
          { citation-id: citation-id }
          (merge balance-data {
            late-fees: (+ current-late-fees additional-late-fee),
            total-owed: (+ (get total-owed balance-data) additional-late-fee),
            remaining-balance: (+ (get remaining-balance balance-data) additional-late-fee),
            last-updated: current-time
          })
        )
        (ok additional-late-fee)
      )
      (ok u0)
    )
  )
)

;; Initialize citation balance
(define-public (initialize-citation-balance (citation-id uint) (fine-amount uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> fine-amount u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? citation-balances { citation-id: citation-id })) ERR-PAYMENT-EXISTS)

    (map-set citation-balances
      { citation-id: citation-id }
      {
        original-fine: fine-amount,
        late-fees: u0,
        total-owed: fine-amount,
        amount-paid: u0,
        remaining-balance: fine-amount,
        last-updated: current-time
      }
    )
    (ok true)
  )
)

;; Add payment method
(define-public (add-payment-method (method-name (string-ascii 20)) (processing-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len method-name) u0) ERR-INVALID-INPUT)

    (map-set payment-methods
      { method-name: method-name }
      { active: true, processing-fee: processing-fee }
    )
    (ok true)
  )
)

;; Process installment payment
(define-public (process-installment-payment (citation-id uint) (payment-amount uint))
  (let
    (
      (plan (map-get? installment-plans { citation-id: citation-id }))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-some plan) ERR-PAYMENT-NOT-FOUND)

    (let
      (
        (plan-data (unwrap-panic plan))
        (payments-made (get payments-made plan-data))
        (total-payments (get total-payments plan-data))
      )
      (asserts! (is-eq (get status plan-data) "active") ERR-INVALID-INPUT)
      (asserts! (< payments-made total-payments) ERR-INVALID-INPUT)
      (asserts! (>= payment-amount (get monthly-payment plan-data)) ERR-INSUFFICIENT-PAYMENT)

      (let
        (
          (new-payments-made (+ payments-made u1))
          (next-due-date (+ current-time (* u86400 u30)))
          (new-status (if (is-eq new-payments-made total-payments) "completed" "active"))
        )
        (map-set installment-plans
          { citation-id: citation-id }
          (merge plan-data {
            payments-made: new-payments-made,
            next-due-date: next-due-date,
            status: new-status
          })
        )

        ;; Process the actual payment
        (unwrap-panic (process-payment citation-id payment-amount "installment"
                     (concat "INST-" (int-to-ascii citation-id)) "Installment Payment"))
        (ok true)
      )
    )
  )
)

;; Read-only Functions

;; Get payment details
(define-read-only (get-payment-details (payment-id uint))
  (map-get? payments { payment-id: payment-id })
)

;; Get citation balance
(define-read-only (get-citation-balance (citation-id uint))
  (map-get? citation-balances { citation-id: citation-id })
)

;; Get installment plan
(define-read-only (get-installment-plan (citation-id uint))
  (map-get? installment-plans { citation-id: citation-id })
)

;; Get payment method info
(define-read-only (get-payment-method-info (method-name (string-ascii 20)))
  (map-get? payment-methods { method-name: method-name })
)

;; Get next payment ID
(define-read-only (get-next-payment-id)
  (var-get next-payment-id)
)

;; Check if payment system is active
(define-read-only (is-payment-system-active)
  (var-get payment-system-active)
)

;; Get late fee percentage
(define-read-only (get-late-fee-percentage)
  (var-get late-fee-percentage)
)

;; Toggle payment system status
(define-public (toggle-payment-system)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set payment-system-active (not (var-get payment-system-active)))
    (ok (var-get payment-system-active))
  )
)

;; Update late fee percentage
(define-public (update-late-fee-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-percentage u100) ERR-INVALID-INPUT)
    (var-set late-fee-percentage new-percentage)
    (ok true)
  )
)
