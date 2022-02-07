import BlockchainBackedItem from 0xf8d6e0586b0a20c7 

transaction(ownerAddress: Address, id: UInt64) {
    prepare(signer: AuthAccount) {
        let owner = getAccount(ownerAddress)   

        let collectionRef = signer
            .borrow<&BlockchainBackedItem.Collection>(from: BlockchainBackedItem.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        let bbi = collectionRef.borrowExampleNFT(id: id)!

        bbi.ownerInfo = "Reach me at ..."
    }
}
