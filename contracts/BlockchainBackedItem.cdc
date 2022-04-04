// NonFungibleToken on mainnet - 0x1d7e57aa55817448
// NonFungibleToken on testnet - 0x631e88ae7f1d7c20
// Implementation based on Flow Non-Fungible Token as of Jan 2022
// https://docs.onflow.org/core-contracts/non-fungible-token/
// There is a plan to make breaking changes to the standard
// which will require upgrading this contract

import NonFungibleToken from 0xf8d6e0586b0a20c7 
import MetadataViews from 0xf8d6e0586b0a20c7 

pub contract BlockchainBackedItem: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub struct MetadataDisplay {
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub var isLostOrStolen: Bool
        pub var ownerMessage: String

        init(
            name: String,
            description: String,
            thumbnail: String,
            isLostOrStolen: Bool
            message: String,
        ) {
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.isLostOrStolen = isLostOrStolen
            self.ownerMessage = message
        }
    }

    // NFT resource extended with the fields needed for Blockchain Backed Item
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        
        // base variables supported by NFTs
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String

        // writable in the current and inner scopes,
        // and readable in all scopes.
        //
        pub var isLostOrStolen: Bool
        pub var ownerMessage: String

        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            isLostOrStolen: Bool,
            ownerMessage: String
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.ownerMessage = ownerMessage
            // once we create the NFT the object can't be already lost
            self.isLostOrStolen = isLostOrStolen
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataDisplay>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataDisplay>():
                    return MetadataDisplay(
                        name: self.name,
                        description: self.description,
                        thumbnail: self.thumbnail,
                        isLostOrStolen: self.isLostOrStolen,
                        message: self.ownerMessage
                    )
            }

            return nil
        }

        access(contract) fun setLostOrStolen() {
            self.isLostOrStolen = true
        }

        access(contract) fun setFound() {
            self.isLostOrStolen = false
        }

        access(contract) fun setOwnerMessage(message: String) {
            self.ownerMessage = message
        }
    }

    pub resource interface BlockchainBackedItemCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBlockchainBackedItem(id: UInt64): &BlockchainBackedItem.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BlockchainBackedItem reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource interface BBIAdmin {
        pub fun setLostOrStolen(_id: UInt64)
        pub fun setFound(_id: UInt64)
        pub fun setOwnerMessage(_id: UInt64, _message: String)
    }

    pub resource Collection: BlockchainBackedItemCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, BBIAdmin {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @BlockchainBackedItem.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }
 
        pub fun borrowBlockchainBackedItem(id: UInt64): &BlockchainBackedItem.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &BlockchainBackedItem.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            let BlockchainBackedItem = nft as! &BlockchainBackedItem.NFT
            return BlockchainBackedItem as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun setLostOrStolen(_id: UInt64) {
            let bbi = self.borrowBlockchainBackedItem(id: _id)!
            bbi.setLostOrStolen()
        }

        pub fun setFound(_id: UInt64) {
            let bbi = self.borrowBlockchainBackedItem(id: _id)!
            bbi.setFound()
        }

        pub fun setOwnerMessage(_id: UInt64, _message: String) {
            let bbi = self.borrowBlockchainBackedItem(id: _id)!
            bbi.setOwnerMessage(message: _message)
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }
    

    pub resource NFTMinter {

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            thumbnail: String,
            message: String
        ) {

            // create a new NFT
            var blockchainBackedItem <- create NFT(
                id: BlockchainBackedItem.totalSupply,
                name: name,
                description: description,
                thumbnail: thumbnail,
                isLostOrStolen: false, // newly created item can't be already lost
                ownerMessage: message
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-blockchainBackedItem)

            BlockchainBackedItem.totalSupply = BlockchainBackedItem.totalSupply + UInt64(1)
        }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/BlockchainBackedItemCollection
        self.CollectionPublicPath = /public/BlockchainBackedItemCollection
        self.MinterStoragePath = /storage/BlockchainBackedItemMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&BlockchainBackedItem.Collection{NonFungibleToken.CollectionPublic, BlockchainBackedItem.BlockchainBackedItemCollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
