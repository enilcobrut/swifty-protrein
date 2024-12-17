import SceneKit

struct Atom {
    let serialNumber: Int
    let name: String
    let element: String
    let position: SCNVector3
}

struct Bond {
    let atom1Serial: Int
    let atom2Serial: Int
}
