# SoundChain 

**Decentralized Music Streaming & Artist Royalty Platform**

SoundChain is a comprehensive blockchain-based platform that revolutionizes the music industry by providing artists with direct control over their music distribution, fair royalty payments, and fan engagement tools. Built on Stacks blockchain using Clarity smart contracts.

## Features

### For Artists
- **Artist Profile Management**: Create verified profiles with bio, social links, and track portfolios
- **Music Upload & Distribution**: Upload tracks with metadata, set pricing, and control streaming rights
- **Royalty Management**: Automatic royalty distribution with customizable rates
- **Collaboration Tools**: Add collaborators to tracks with defined roles and royalty shares
- **Revenue Analytics**: Real-time tracking of streaming revenue and total earnings
- **NFT Creation**: Convert tracks into purchasable NFTs for exclusive ownership

### For Fans
- **Music Streaming**: Pay-per-stream model with transparent pricing
- **Artist Subscriptions**: Subscribe to favorite artists with monthly fees
- **Playlist Creation**: Create public and private playlists
- **NFT Collection**: Purchase and collect exclusive track NFTs
- **Loyalty Points**: Earn points through streaming and NFT purchases
- **Fan Engagement**: Direct support to artists through subscriptions and purchases

### Platform Features
- **Decentralized Architecture**: No central authority controls the platform
- **Transparent Royalties**: All payments and distributions are recorded on-chain
- **Featured Tracks**: Platform-curated featured music discovery
- **Platform Analytics**: Comprehensive statistics on tracks, streams, and revenue

## Smart Contract Overview

### Core Components

#### Data Storage
- **Music Tracks**: Complete track metadata, pricing, and streaming statistics
- **Artist Profiles**: Verified artist information and earnings tracking
- **NFT Ownership**: Track ownership records and purchase history
- **Fan Subscriptions**: Artist-fan relationship management
- **Playlists**: User-created music collections
- **Streaming Sessions**: Individual listening history and payments

#### Key Functions

**Artist Management**
```clarity
create-artist-profile(artist-name, bio, social-links)
update-artist-profile(bio, social-links) 
upload-music-track(title, genre, duration, hash, metadata-uri, nft-price, royalty-rate)
add-track-collaborator(track-id, collaborator, role, royalty-share, contribution-type)
claim-rewards()
```

**Fan Interactions**
```clarity
stream-track(track-id)
purchase-track-nft(track-id)
subscribe-to-artist(artist, subscription-type, monthly-fee)
create-playlist(playlist-id, playlist-name, public)
add-to-playlist(playlist-id, track-id, position)
```

**Platform Administration**
```clarity
toggle-platform(active)
set-featured-track(track-id)
verify-artist(artist)
```

## Economic Model

### Revenue Streams
- **Streaming Fees**: 100 tokens per stream
- **Platform Fee**: 2.5% on all transactions
- **NFT Sales**: Artist-set pricing with minimum 1000 tokens
- **Subscriptions**: Fan-to-artist monthly payments

### Royalty Distribution
- Primary artist receives base percentage
- Collaborators receive defined royalty shares
- Platform fee deducted before distribution
- Maximum 50% royalty rate allowed

## Technical Specifications

### Platform Constraints
- Minimum track duration: 30 seconds
- Maximum collaborators per track: 10
- Maximum playlist ID: 999,999
- Minimum NFT price: 1,000 tokens
- Maximum royalty rate: 50%

### Security Features
- Input validation for all user data
- Principal verification for artist operations  
- Access control for administrative functions
- Protection against unauthorized modifications
- Validation of social links and metadata

## Getting Started

### Prerequisites
- Stacks blockchain node or testnet access
- Clarinet CLI for local development
- STX tokens for contract interactions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Faksfancy/artist-royalty-distribution.git
cd artist-royalty-distribution
```

2. Install Clarinet:
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.8.0/clarinet-linux-x64.tar.gz | tar xz
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
clarinet test
```

### Deployment

1. Deploy to testnet:
```bash
clarinet deploy --testnet
```

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Artist Workflow
```clarity
;; 1. Create artist profile
(contract-call? .soundchain create-artist-profile 
    "Artist Name" 
    "Artist bio and background" 
    "twitter.com/artist")

;; 2. Upload a track
(contract-call? .soundchain upload-music-track
    "Song Title"
    "Pop"
    u180  ;; 3 minutes
    "track-hash-here"
    "ipfs://metadata-uri"
    u5000  ;; NFT price
    u1000) ;; 10% royalty

;; 3. Add collaborator
(contract-call? .soundchain add-track-collaborator
    u0      ;; track-id
    'SP1234... ;; collaborator principal
    "Producer"
    u2000   ;; 20% royalty share
    "Beat production")
```

### Fan Workflow
```clarity
;; 1. Stream a track
(contract-call? .soundchain stream-track u0)

;; 2. Purchase track NFT
(contract-call? .soundchain purchase-track-nft u0)

;; 3. Subscribe to artist
(contract-call? .soundchain subscribe-to-artist
    'SP5678...  ;; artist principal
    "premium"
    u1000)      ;; monthly fee

;; 4. Create playlist
(contract-call? .soundchain create-playlist
    u1
    "My Favorites"
    true)       ;; public playlist
```

## Query Functions

Access platform data with read-only functions:

```clarity
;; Get track information
(contract-call? .soundchain get-track-details u0)

;; Get artist profile
(contract-call? .soundchain get-artist-profile 'SP1234...)

;; Check streaming revenue
(contract-call? .soundchain calculate-streaming-revenue u0)

;; Get platform statistics
(contract-call? .soundchain get-platform-stats)
```

## Development

### Project Structure
```
soundchain/
├── contracts/
│   └── music-royalty.clar
├── tests/
│   └── music-royalty_test.ts
├── settings/
│   └── Devnet.toml
├── README.md
└── Clarinet.toml
```

### Testing
Run comprehensive tests covering:
- Artist profile creation and updates
- Track upload and metadata validation
- Streaming and payment processing
- NFT purchase and ownership
- Playlist management
- Royalty distribution
- Access control and permissions

### Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
5. Open Pull Request

## Security Considerations

- All inputs are validated before processing
- Access controls prevent unauthorized operations
- Platform can be paused for emergency maintenance
- Artist verification prevents impersonation
- Royalty calculations use safe arithmetic
- Principal validation prevents invalid addresses

## Roadmap

- [ ] **Phase 1**: Core platform launch with basic features
- [ ] **Phase 2**: Advanced analytics and reporting
- [ ] **Phase 3**: Mobile app integration
- [ ] **Phase 4**: Cross-chain compatibility
- [ ] **Phase 5**: AI-powered music discovery
- [ ] **Phase 6**: Virtual concert hosting