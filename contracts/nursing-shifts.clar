;; NursingShifts - Decentralized Shift Scheduling System
;; Manages nursing shift assignments and scheduling

(define-map shifts
  { shift-id: uint }
  {
    hospital-unit: (string-ascii 50),
    shift-date: uint,
    shift-type: (string-ascii 20),
    required-nurses: uint,
    hourly-rate: uint,
    created-by: principal,
    is-active: bool
  }
)

(define-map shift-assignments
  { assignment-id: uint }
  {
    shift-id: uint,
    nurse: principal,
    assigned-by: principal,
    assigned-at: uint,
    status: (string-ascii 20),
    hours-worked: uint
  }
)

(define-map nurse-profiles
  { nurse: principal }
  {
    name: (string-ascii 100),
    specialization: (string-ascii 50),
    experience-years: uint,
    hourly-rate: uint,
    availability-status: (string-ascii 20)
  }
)

(define-data-var next-shift-id uint u1)
(define-data-var next-assignment-id uint u1)

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u300))
(define-constant err-not-found (err u301))
(define-constant err-shift-full (err u302))
(define-constant err-already-assigned (err u303))
(define-constant err-invalid-input (err u304))
(define-constant err-shift-inactive (err u305))

;; Create a new shift
(define-public (create-shift
  (hospital-unit (string-ascii 50))
  (shift-date uint)
  (shift-type (string-ascii 20))
  (required-nurses uint)
  (hourly-rate uint)
)
  (let
    (
      (shift-id (var-get next-shift-id))
    )
    (asserts! (> shift-date stacks-block-height) err-invalid-input)
    (asserts! (> required-nurses u0) err-invalid-input)
    (asserts! (> hourly-rate u0) err-invalid-input)
    (asserts! (> (len hospital-unit) u0) err-invalid-input)
    
    (map-set shifts
      { shift-id: shift-id }
      {
        hospital-unit: hospital-unit,
        shift-date: shift-date,
        shift-type: shift-type,
        required-nurses: required-nurses,
        hourly-rate: hourly-rate,
        created-by: tx-sender,
        is-active: true
      }
    )
    
    (var-set next-shift-id (+ shift-id u1))
    (ok shift-id)
  )
)

;; Register nurse profile
(define-public (register-nurse-profile
  (name (string-ascii 100))
  (specialization (string-ascii 50))
  (experience-years uint)
  (hourly-rate uint)
)
  (begin
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> hourly-rate u0) err-invalid-input)
    
    (map-set nurse-profiles
      { nurse: tx-sender }
      {
        name: name,
        specialization: specialization,
        experience-years: experience-years,
        hourly-rate: hourly-rate,
        availability-status: "available"
      }
    )
    (ok true)
  )
)

;; Assign nurse to shift
(define-public (assign-nurse-to-shift (shift-id uint) (nurse principal))
  (let
    (
      (shift-data (unwrap! (map-get? shifts { shift-id: shift-id }) err-not-found))
      (assignment-id (var-get next-assignment-id))
      (current-assignments (get count (count-shift-assignments shift-id)))
    )
    (asserts! (get is-active shift-data) err-shift-inactive)
    (asserts! (< current-assignments (get required-nurses shift-data)) err-shift-full)
    (asserts! (is-none (get found (get-nurse-assignment shift-id nurse))) err-already-assigned)
    (asserts! (is-some (map-get? nurse-profiles { nurse: nurse })) err-not-found)
    
    (map-set shift-assignments
      { assignment-id: assignment-id }
      {
        shift-id: shift-id,
        nurse: nurse,
        assigned-by: tx-sender,
        assigned-at: stacks-block-height,
        status: "assigned",
        hours-worked: u0
      }
    )
    
    (var-set next-assignment-id (+ assignment-id u1))
    (ok assignment-id)
  )
)

;; Complete shift and record hours
(define-public (complete-shift (assignment-id uint) (hours-worked uint))
  (let
    (
      (assignment-data (unwrap! (map-get? shift-assignments { assignment-id: assignment-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get nurse assignment-data)) err-unauthorized)
    (asserts! (is-eq (get status assignment-data) "assigned") err-invalid-input)
    (asserts! (> hours-worked u0) err-invalid-input)
    (asserts! (<= hours-worked u24) err-invalid-input)
    
    (map-set shift-assignments
      { assignment-id: assignment-id }
      (merge assignment-data {
        status: "completed",
        hours-worked: hours-worked
      })
    )
    (ok true)
  )
)

;; Get shift information
(define-read-only (get-shift (shift-id uint))
  (map-get? shifts { shift-id: shift-id })
)

;; Get assignment information
(define-read-only (get-assignment (assignment-id uint))
  (map-get? shift-assignments { assignment-id: assignment-id })
)

;; Get nurse profile
(define-read-only (get-nurse-profile (nurse principal))
  (map-get? nurse-profiles { nurse: nurse })
)

;; Check if nurse is assigned to shift
(define-read-only (get-nurse-assignment (shift-id uint) (nurse principal))
  (fold check-assignment-match 
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) 
    { shift-id: shift-id, nurse: nurse, found: none }
  )
)

;; Helper function to check assignment match
(define-read-only (check-assignment-match 
  (assignment-id uint) 
  (search-data { shift-id: uint, nurse: principal, found: (optional uint) })
)
  (if (is-some (get found search-data))
    search-data
    (match (map-get? shift-assignments { assignment-id: assignment-id })
      assignment
      (if (and 
        (is-eq (get shift-id assignment) (get shift-id search-data))
        (is-eq (get nurse assignment) (get nurse search-data))
      )
        (merge search-data { found: (some assignment-id) })
        search-data
      )
      search-data
    )
  )
)

;; Count assignments for a shift
(define-read-only (count-shift-assignments (shift-id uint))
  (fold count-assignments 
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) 
    { shift-id: shift-id, count: u0 }
  )
)

;; Helper function to count assignments
(define-read-only (count-assignments 
  (assignment-id uint) 
  (count-data { shift-id: uint, count: uint })
)
  (match (map-get? shift-assignments { assignment-id: assignment-id })
    assignment
    (if (is-eq (get shift-id assignment) (get shift-id count-data))
      (merge count-data { count: (+ (get count count-data) u1) })
      count-data
    )
    count-data
  )
)

;; Cancel shift
(define-public (cancel-shift (shift-id uint))
  (let
    (
      (shift-data (unwrap! (map-get? shifts { shift-id: shift-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get created-by shift-data)) err-unauthorized)
    
    (map-set shifts
      { shift-id: shift-id }
      (merge shift-data { is-active: false })
    )
    (ok true)
  )
)