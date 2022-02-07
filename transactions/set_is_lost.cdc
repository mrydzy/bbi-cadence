import BlockchainBackedItem from 0xf8d6e0586b0a20c7 

transaction(id: UInt64) {
    prepare(signer: AuthAccount) {
        let collectionRef = signer
            .borrow<&BlockchainBackedItem.Collection>(from: BlockchainBackedItem.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        collectionRef.setLostOrStolen(_id: id)
    }
}
