import BlockchainBackedItem from 0xf8d6e0586b0a20c7 
import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7

// This transaction is what an account would run
// to set itself up to receive NFTs

transaction {

    prepare(signer: AuthAccount) {
        if signer.borrow<&BlockchainBackedItem.Collection>(from: BlockchainBackedItem.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- BlockchainBackedItem.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: BlockchainBackedItem.CollectionStoragePath)

        // create a public capability for the collection
        signer.link<&{NonFungibleToken.CollectionPublic, BlockchainBackedItem.BlockchainBackedItemCollectionPublic}>(
            BlockchainBackedItem.CollectionPublicPath,
            target: BlockchainBackedItem.CollectionStoragePath
        )
    }
}
