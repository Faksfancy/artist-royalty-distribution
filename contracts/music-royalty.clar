;; SoundChain - Decentralized Music Streaming & Artist Royalty Platform
;; A comprehensive platform for music NFTs, streaming royalties, and fan engagement

;; Constants
(define-constant PLATFORM-ADMIN tx-sender)
(define-constant ERR-ACCESS-DENIED (err u700))
(define-constant ERR-TRACK-NOT-FOUND (err u701))
(define-constant ERR-INVALID-ROYALTY (err u702))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u703))
(define-constant ERR-TRACK-NOT-AVAILABLE (err u704))
(define-constant ERR-UNAUTHORIZED-ARTIST (err u705))
(define-constant ERR-INVALID-METADATA (err u706))
(define-constant ERR-ALREADY-OWNS-NFT (err u707))
(define-constant ERR-PLATFORM-PAUSED (err u708))
(define-constant ERR-INVALID-DURATION (err u709))
(define-constant ERR-COLLABORATION-ERROR (err u710))
(define-constant ERR-INVALID-PRINCIPAL (err u711))
(define-constant ERR-INVALID-PLAYLIST-ID (err u712))

;; Platform Configuration
(define-constant STREAMING-COST u100) ;; Cost per stream in tokens
(define-constant PLATFORM-FEE u250) ;; 2.5% platform fee (basis points)
(define-constant MIN-TRACK-PRICE u1000) ;; Minimum NFT price
(define-constant MAX-ROYALTY-RATE u5000) ;; Maximum 50% royalty rate
(define-constant MIN-TRACK-DURATION u30) ;; Minimum 30 seconds
(define-constant MAX-COLLABORATORS u10) ;; Maximum collaborators per track
(define-constant MAX-PLAYLIST-ID u999999) ;; Maximum playlist ID

;; Platform State
(define-data-var total-tracks uint u0)
(define-data-var total-streams uint u0)
(define-data-var platform-active bool true)
(define-data-var total-royalties-paid uint u0)
(define-data-var featured-track-id uint u0)

;; Storage Maps
(define-map music-tracks
    uint
    {
        track-title: (string-ascii 100),
        artist: principal,
        genre: (string-ascii 30),
        duration-seconds: uint,
        release-date: uint,
        track-hash: (string-ascii 64),
        metadata-uri: (string-ascii 200),
        streaming-enabled: bool,
        nft-price: uint,
        royalty-rate: uint,
        total-streams: uint,
        track-status: (string-ascii 20)
    }
)

(define-map track-nft-ownership
    uint
    {
        owner: principal,
        purchased-at: uint,
        purchase-price: uint,
        exclusive-rights: bool
    }
)

(define-map artist-profiles
    principal
    {
        artist-name: (string-ascii 50),
        bio: (string-ascii 300),
        social-links: (string-ascii 150),
        verified: bool,
        total-earnings: uint,
        track-count: uint,
        follower-count: uint
    }
)

(define-map fan-subscriptions
    {fan: principal, artist: principal}
    {
        subscription-type: (string-ascii 20),
        subscribed-at: uint,
        monthly-fee: uint,
        active: bool
    }
)

(define-map track-collaborators
    {track-id: uint, collaborator: principal}
    {
        role: (string-ascii 30),
        royalty-share: uint,
        contribution-type: (string-ascii 40)
    }
)

(define-map streaming-sessions
    {listener: principal, track-id: uint}
    {
        last-streamed: uint,
        total-plays: uint,
        total-paid: uint
    }
)

(define-map playlist-collections
    {creator: principal, playlist-id: uint}
    {
        playlist-name: (string-ascii 80),
        track-count: uint,
        created-at: uint,
        public: bool
    }
)

(define-map playlist-tracks
    {playlist-creator: principal, playlist-id: uint, position: uint}
    uint ;; track-id
)

(define-map artist-rewards principal uint)
(define-map fan-loyalty-points principal uint)

;; Validation helper functions
(define-private (is-valid-principal (principal-to-check principal))
    (not (is-eq principal-to-check (as-contract tx-sender)))
)

(define-private (is-valid-playlist-id (playlist-id uint))
    (and (> playlist-id u0) (<= playlist-id MAX-PLAYLIST-ID))
)

(define-private (sanitize-social-links (social-links (string-ascii 150)))
    (if (> (len social-links) u0)
        social-links
        "")
)

;; Authorization helpers
(define-private (is-platform-admin)
    (is-eq tx-sender PLATFORM-ADMIN)
)

(define-private (is-track-artist (track-id uint))
    (match (map-get? music-tracks track-id)
        track (is-eq tx-sender (get artist track))
        false)
)

(define-private (calculate-platform-fee (amount uint))
    (/ (* amount PLATFORM-FEE) u10000)
)

(define-private (distribute-royalties (track-id uint) (payment-amount uint))
    (let (
        (track (unwrap-panic (map-get? music-tracks track-id)))
        (platform-fee (calculate-platform-fee payment-amount))
        (net-amount (- payment-amount platform-fee))
    )
        ;; Pay primary artist
        (map-set artist-rewards (get artist track)
            (+ (default-to u0 (map-get? artist-rewards (get artist track)))
               (/ (* net-amount (- u10000 (get royalty-rate track))) u10000)))
        
        ;; Distribute to collaborators if any
        (var-set total-royalties-paid (+ (var-get total-royalties-paid) net-amount))
        true
    )
)

;; Platform management
(define-public (toggle-platform (active bool))
    (begin
        (asserts! (is-platform-admin) ERR-ACCESS-DENIED)
        (var-set platform-active active)
        (ok true)
    )
)

(define-public (set-featured-track (track-id uint))
    (begin
        (asserts! (is-platform-admin) ERR-ACCESS-DENIED)
        (asserts! (is-some (map-get? music-tracks track-id)) ERR-TRACK-NOT-FOUND)
        (var-set featured-track-id track-id)
        (ok true)
    )
)

;; Artist profile management
(define-public (create-artist-profile 
    (artist-name (string-ascii 50))
    (bio (string-ascii 300))
    (social-links (string-ascii 150)))
    (begin
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (> (len artist-name) u0) ERR-INVALID-METADATA)
        (asserts! (> (len bio) u10) ERR-INVALID-METADATA)
        (asserts! (is-none (map-get? artist-profiles tx-sender)) ERR-ALREADY-OWNS-NFT)
        
        (let (
            (validated-name artist-name)
            (validated-bio bio)
            (sanitized-links (sanitize-social-links social-links))
        )
            (map-set artist-profiles tx-sender {
                artist-name: validated-name,
                bio: validated-bio,
                social-links: sanitized-links,
                verified: false,
                total-earnings: u0,
                track-count: u0,
                follower-count: u0
            })
            (ok true)
        )
    )
)

;; Update artist profile
(define-public (update-artist-profile 
    (bio (string-ascii 300))
    (social-links (string-ascii 150)))
    (let (
        (current-profile (unwrap! (map-get? artist-profiles tx-sender) ERR-UNAUTHORIZED-ARTIST))
        (validated-bio bio)
        (sanitized-links (sanitize-social-links social-links))
    )
        (asserts! (> (len validated-bio) u10) ERR-INVALID-METADATA)
        
        (map-set artist-profiles tx-sender
            (merge current-profile {
                bio: validated-bio,
                social-links: sanitized-links
            }))
        (ok true)
    )
)

;; Upload music track
(define-public (upload-music-track 
    (track-title (string-ascii 100))
    (genre (string-ascii 30))
    (duration-seconds uint)
    (track-hash (string-ascii 64))
    (metadata-uri (string-ascii 200))
    (nft-price uint)
    (royalty-rate uint))
    (begin
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-UNAUTHORIZED-ARTIST)
        (asserts! (> (len track-title) u0) ERR-INVALID-METADATA)
        (asserts! (> (len genre) u0) ERR-INVALID-METADATA)
        (asserts! (>= duration-seconds MIN-TRACK-DURATION) ERR-INVALID-DURATION)
        (asserts! (> (len track-hash) u40) ERR-INVALID-METADATA)
        (asserts! (> (len metadata-uri) u10) ERR-INVALID-METADATA)
        (asserts! (>= nft-price MIN-TRACK-PRICE) ERR-INSUFFICIENT-PAYMENT)
        (asserts! (<= royalty-rate MAX-ROYALTY-RATE) ERR-INVALID-ROYALTY)
        
        (let (
            (track-id (var-get total-tracks))
            (artist-profile (unwrap! (map-get? artist-profiles tx-sender) ERR-UNAUTHORIZED-ARTIST))
            (validated-title track-title)
            (validated-genre genre)
            (validated-hash track-hash)
            (validated-uri metadata-uri)
        )
            (map-set music-tracks track-id {
                track-title: validated-title,
                artist: tx-sender,
                genre: validated-genre,
                duration-seconds: duration-seconds,
                release-date: block-height,
                track-hash: validated-hash,
                metadata-uri: validated-uri,
                streaming-enabled: true,
                nft-price: nft-price,
                royalty-rate: royalty-rate,
                total-streams: u0,
                track-status: "active"
            })
            
            ;; Update artist track count
            (map-set artist-profiles tx-sender
                (merge artist-profile {track-count: (+ (get track-count artist-profile) u1)}))
            
            (var-set total-tracks (+ track-id u1))
            (ok track-id)
        )
    )
)

;; Add track collaborator
(define-public (add-track-collaborator 
    (track-id uint)
    (collaborator principal)
    (role (string-ascii 30))
    (royalty-share uint)
    (contribution-type (string-ascii 40)))
    (let (
        (track (unwrap! (map-get? music-tracks track-id) ERR-TRACK-NOT-FOUND))
        (validated-role role)
        (validated-contribution contribution-type)
    )
        (asserts! (is-track-artist track-id) ERR-ACCESS-DENIED)
        (asserts! (is-valid-principal collaborator) ERR-INVALID-PRINCIPAL)
        (asserts! (not (is-eq collaborator tx-sender)) ERR-COLLABORATION-ERROR)
        (asserts! (<= royalty-share u5000) ERR-INVALID-ROYALTY)
        (asserts! (> (len validated-role) u0) ERR-INVALID-METADATA)
        (asserts! (> (len validated-contribution) u5) ERR-INVALID-METADATA)
        
        (map-set track-collaborators {track-id: track-id, collaborator: collaborator} {
            role: validated-role,
            royalty-share: royalty-share,
            contribution-type: validated-contribution
        })
        (ok true)
    )
)

;; Stream music track
(define-public (stream-track (track-id uint))
    (let (
        (track (unwrap! (map-get? music-tracks track-id) ERR-TRACK-NOT-FOUND))
        (current-session (default-to 
            {last-streamed: u0, total-plays: u0, total-paid: u0}
            (map-get? streaming-sessions {listener: tx-sender, track-id: track-id})))
    )
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (get streaming-enabled track) ERR-TRACK-NOT-AVAILABLE)
        (asserts! (is-eq (get track-status track) "active") ERR-TRACK-NOT-AVAILABLE)
        
        ;; Update streaming session
        (map-set streaming-sessions {listener: tx-sender, track-id: track-id} {
            last-streamed: block-height,
            total-plays: (+ (get total-plays current-session) u1),
            total-paid: (+ (get total-paid current-session) STREAMING-COST)
        })
        
        ;; Update track streams
        (map-set music-tracks track-id
            (merge track {total-streams: (+ (get total-streams track) u1)}))
        
        ;; Distribute payment
        (distribute-royalties track-id STREAMING-COST)
        
        ;; Award fan loyalty points
        (map-set fan-loyalty-points tx-sender
            (+ (default-to u0 (map-get? fan-loyalty-points tx-sender)) u10))
        
        (var-set total-streams (+ (var-get total-streams) u1))
        (ok true)
    )
)

;; Purchase track NFT
(define-public (purchase-track-nft (track-id uint))
    (let (
        (track (unwrap! (map-get? music-tracks track-id) ERR-TRACK-NOT-FOUND))
        (platform-fee (calculate-platform-fee (get nft-price track)))
        (artist-payment (- (get nft-price track) platform-fee))
    )
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (is-none (map-get? track-nft-ownership track-id)) ERR-ALREADY-OWNS-NFT)
        (asserts! (not (is-eq tx-sender (get artist track))) ERR-ACCESS-DENIED)
        
        ;; Create NFT ownership record
        (map-set track-nft-ownership track-id {
            owner: tx-sender,
            purchased-at: block-height,
            purchase-price: (get nft-price track),
            exclusive-rights: false
        })
        
        ;; Pay artist
        (map-set artist-rewards (get artist track)
            (+ (default-to u0 (map-get? artist-rewards (get artist track))) artist-payment))
        
        ;; Award bonus loyalty points for NFT purchase
        (map-set fan-loyalty-points tx-sender
            (+ (default-to u0 (map-get? fan-loyalty-points tx-sender)) u500))
        
        (ok true)
    )
)

;; Subscribe to artist
(define-public (subscribe-to-artist 
    (artist principal) 
    (subscription-type (string-ascii 20))
    (monthly-fee uint))
    (let (
        (artist-profile (unwrap! (map-get? artist-profiles artist) ERR-UNAUTHORIZED-ARTIST))
        (validated-type subscription-type)
    )
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (is-valid-principal artist) ERR-INVALID-PRINCIPAL)
        (asserts! (not (is-eq tx-sender artist)) ERR-ACCESS-DENIED)
        (asserts! (> monthly-fee u0) ERR-INSUFFICIENT-PAYMENT)
        (asserts! (> (len validated-type) u3) ERR-INVALID-METADATA)
        
        (map-set fan-subscriptions {fan: tx-sender, artist: artist} {
            subscription-type: validated-type,
            subscribed-at: block-height,
            monthly-fee: monthly-fee,
            active: true
        })
        
        ;; Update artist follower count
        (map-set artist-profiles artist
            (merge artist-profile {follower-count: (+ (get follower-count artist-profile) u1)}))
        
        (ok true)
    )
)

;; Create playlist
(define-public (create-playlist 
    (playlist-id uint)
    (playlist-name (string-ascii 80))
    (public bool))
    (let (
        (validated-name playlist-name)
        (validated-playlist-id playlist-id)
    )
        (asserts! (var-get platform-active) ERR-PLATFORM-PAUSED)
        (asserts! (> (len validated-name) u0) ERR-INVALID-METADATA)
        (asserts! (is-valid-playlist-id validated-playlist-id) ERR-INVALID-PLAYLIST-ID)
        (asserts! (is-none (map-get? playlist-collections 
            {creator: tx-sender, playlist-id: validated-playlist-id})) ERR-ALREADY-OWNS-NFT)
        
        (map-set playlist-collections {creator: tx-sender, playlist-id: validated-playlist-id} {
            playlist-name: validated-name,
            track-count: u0,
            created-at: block-height,
            public: public
        })
        (ok true)
    )
)

;; Add track to playlist
(define-public (add-to-playlist 
    (playlist-id uint) 
    (track-id uint) 
    (position uint))
    (let (
        (validated-playlist-id playlist-id)
        (playlist (unwrap! (map-get? playlist-collections 
            {creator: tx-sender, playlist-id: validated-playlist-id}) ERR-TRACK-NOT-FOUND))
        (track (unwrap! (map-get? music-tracks track-id) ERR-TRACK-NOT-FOUND))
    )
        (asserts! (is-valid-playlist-id validated-playlist-id) ERR-INVALID-PLAYLIST-ID)
        (asserts! (is-eq (get track-status track) "active") ERR-TRACK-NOT-AVAILABLE)
        (asserts! (< position u1000) ERR-INVALID-METADATA)
        
        (map-set playlist-tracks 
            {playlist-creator: tx-sender, playlist-id: validated-playlist-id, position: position}
            track-id)
        
        (map-set playlist-collections {creator: tx-sender, playlist-id: validated-playlist-id}
            (merge playlist {track-count: (+ (get track-count playlist) u1)}))
        
        (ok true)
    )
)

;; Verify artist
(define-public (verify-artist (artist principal))
    (let (
        (validated-artist artist)
        (artist-profile (unwrap! (map-get? artist-profiles validated-artist) ERR-UNAUTHORIZED-ARTIST))
    )
        (asserts! (is-platform-admin) ERR-ACCESS-DENIED)
        (asserts! (is-valid-principal validated-artist) ERR-INVALID-PRINCIPAL)
        
        (map-set artist-profiles validated-artist
            (merge artist-profile {verified: true}))
        (ok true)
    )
)

;; Claim artist rewards
(define-public (claim-rewards)
    (let (
        (reward-amount (default-to u0 (map-get? artist-rewards tx-sender)))
        (artist-profile (unwrap! (map-get? artist-profiles tx-sender) ERR-UNAUTHORIZED-ARTIST))
    )
        (asserts! (> reward-amount u0) ERR-INSUFFICIENT-PAYMENT)
        
        (map-set artist-rewards tx-sender u0)
        (map-set artist-profiles tx-sender
            (merge artist-profile {total-earnings: (+ (get total-earnings artist-profile) reward-amount)}))
        
        (ok reward-amount)
    )
)

;; Read-only functions
(define-read-only (get-track-details (track-id uint))
    (map-get? music-tracks track-id)
)

(define-read-only (get-artist-profile (artist principal))
    (map-get? artist-profiles artist)
)

(define-read-only (get-track-nft-owner (track-id uint))
    (map-get? track-nft-ownership track-id)
)

(define-read-only (get-streaming-session (listener principal) (track-id uint))
    (map-get? streaming-sessions {listener: listener, track-id: track-id})
)

(define-read-only (get-subscription-status (fan principal) (artist principal))
    (map-get? fan-subscriptions {fan: fan, artist: artist})
)

(define-read-only (get-playlist-info (creator principal) (playlist-id uint))
    (map-get? playlist-collections {creator: creator, playlist-id: playlist-id})
)

(define-read-only (get-playlist-track (creator principal) (playlist-id uint) (position uint))
    (map-get? playlist-tracks {playlist-creator: creator, playlist-id: playlist-id, position: position})
)

(define-read-only (get-artist-rewards (artist principal))
    (default-to u0 (map-get? artist-rewards artist))
)

(define-read-only (get-fan-loyalty-points (fan principal))
    (default-to u0 (map-get? fan-loyalty-points fan))
)

(define-read-only (get-track-collaborator (track-id uint) (collaborator principal))
    (map-get? track-collaborators {track-id: track-id, collaborator: collaborator})
)

(define-read-only (get-platform-stats)
    {
        total-tracks: (var-get total-tracks),
        total-streams: (var-get total-streams),
        total-royalties-paid: (var-get total-royalties-paid),
        platform-active: (var-get platform-active),
        featured-track: (var-get featured-track-id)
    }
)

(define-read-only (calculate-streaming-revenue (track-id uint))
    (match (map-get? music-tracks track-id)
        track (some {
            total-streams: (get total-streams track),
            gross-revenue: (* (get total-streams track) STREAMING-COST),
            platform-fee: (calculate-platform-fee (* (get total-streams track) STREAMING-COST)),
            artist-share: (- (* (get total-streams track) STREAMING-COST)
                           (calculate-platform-fee (* (get total-streams track) STREAMING-COST)))
        })
        none)
)

(define-read-only (is-track-available (track-id uint))
    (match (map-get? music-tracks track-id)
        track (and 
            (get streaming-enabled track)
            (is-eq (get track-status track) "active"))
        false)
)