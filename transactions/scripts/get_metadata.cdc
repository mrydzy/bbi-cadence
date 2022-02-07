import BlockchainBackedItem from 0xf8d6e0586b0a20c7

pub struct NFTResult {
    pub(set) var name: String
    pub(set) var description: String
    pub(set) var thumbnail: String
    pub(set) var owner: Address
    pub(set) var type: String
    pub(set) var isLostOrStolen: Bool
    pub(set) var message: String

    init() {
        self.name = ""
        self.description = ""
        self.thumbnail = ""
        self.owner = 0x0
        self.type = ""
        self.isLostOrStolen = false
        self.message = ""
    }
}

pub fun main(address: Address, id: UInt64): NFTResult {
    let account = getAccount(address)

    let collection = account
        .getCapability(BlockchainBackedItem.CollectionPublicPath)
        .borrow<&{BlockchainBackedItem.BlockchainBackedItemCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowBlockchainBackedItem(id: id)!

    var data = NFTResult()

    // Get the basic display information for this Blockchain Backed Item
    if let view = nft.resolveView(Type<BlockchainBackedItem.MetadataDisplay>()) {
        let display = view as! BlockchainBackedItem.MetadataDisplay

        data.name = display.name
        data.description = display.description
        data.thumbnail = display.thumbnail
        data.isLostOrStolen = display.isLostOrStolen
        data.message = display.ownerMessage
    }

    // The owner is stored directly on the NFT object
    let owner: Address = nft.owner!.address!

    data.owner = owner

    // Inspect the type of this NFT to verify its origin
    let nftType = nft.getType()

    data.type = nftType.identifier

    return data
}
