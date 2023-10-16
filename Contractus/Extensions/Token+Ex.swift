import ContractusAPI

extension Token: Identifiable {
    public var id: String {
        self.address ?? self.code
    }
}
