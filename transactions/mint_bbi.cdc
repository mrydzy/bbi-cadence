import NonFungibleToken from 0xf8d6e0586b0a20c7 
import MetadataViews from 0xf8d6e0586b0a20c7 
import BlockchainBackedItem from 0xf8d6e0586b0a20c7

// This script uses the NFTMinter from BlockchainBackedItem resource to mint a new BBI
// It must be run with the account that has the minter resource

transaction(
    recipient: Address,
    name: String,
    description: String,
    thumbnail: String,
    message: String
) {

    // local variable for storing the minter reference
    let minter: &BlockchainBackedItem.NFTMinter

    prepare(signer: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&BlockchainBackedItem.NFTMinter>(from: BlockchainBackedItem.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // Borrow the recipient's public NFT collection reference
        let receiver = getAccount(recipient)
            .getCapability(BlockchainBackedItem.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Mint the NFT and deposit it to the recipient's collection
        self.minter.mintNFT(
            recipient: receiver,
            name: name,
            description: description,
            thumbnail: thumbnail,
            message: message
        )
    }
}
